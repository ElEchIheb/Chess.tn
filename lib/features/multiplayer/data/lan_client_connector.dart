import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/constants/app_constants.dart';
import '../../chess/domain/match_authority.dart';
import '../domain/game_message.dart';
import '../domain/lan_error.dart';
import '../domain/message_channel.dart';
import '../domain/room_code.dart';
import 'lan_host_server.dart';
import 'local_network.dart';
import 'web_socket_channel.dart';

/// A game found on the network by UDP discovery.
class DiscoveredGame {
  const DiscoveredGame({
    required this.roomCode,
    required this.host,
    required this.port,
    required this.variant,
  });

  final String roomCode;
  final String host;
  final int port;
  final GameVariant variant;
}

/// An accepted connection to a host.
class JoinedGame {
  const JoinedGame({
    required this.channel,
    required this.variant,
    required this.host,
    required this.port,
    required this.roomCode,
  });

  final MessageChannel channel;
  final GameVariant variant;
  final String host;
  final int port;
  final String roomCode;
}

/// The joining side of LAN play.
class LanClientConnector {
  LanClientConnector({String? playerToken})
    : playerToken = playerToken ?? LocalNetwork.newPlayerToken();

  /// Kept for the whole match so the host recognises us after a drop.
  final String playerToken;

  static const Duration _connectTimeout = Duration(seconds: 3);

  /// Joins with a room code alone, or with a code plus an explicit host IP
  /// when the phones do not share the usual address prefix.
  Future<JoinedGame> joinWithCode(String code, {String? manualHost}) async {
    final endpoint = RoomCode.decode(code);
    if (endpoint == null) throw const LanException(LanError.invalidCode);

    final List<String> hosts;
    if (manualHost != null && manualHost.trim().isNotEmpty) {
      if (!LocalNetwork.isValidIpv4(manualHost)) {
        throw const LanException(LanError.hostNotFound);
      }
      hosts = [manualHost.trim()];
    } else {
      final local = await LocalNetwork.addresses();
      if (local.isEmpty) throw const LanException(LanError.noNetwork);
      hosts = endpoint.candidateHosts(local);
    }

    LanException? lastError;
    for (final host in hosts) {
      try {
        return await connect(host: host, port: endpoint.port, roomCode: code);
      } on LanException catch (error) {
        lastError = error;
        // A definite answer from a real host: no point trying elsewhere.
        if (error.error != LanError.hostNotFound) rethrow;
      }
    }
    throw lastError ?? const LanException(LanError.hostNotFound);
  }

  /// Connects to a known address and performs the join handshake.
  Future<JoinedGame> connect({
    required String host,
    required int port,
    required String roomCode,
  }) async {
    final WebSocket socket;
    try {
      socket = await WebSocket.connect('ws://$host:$port/ws')
          .timeout(_connectTimeout);
    } on Exception catch (error) {
      throw LanException(LanError.hostNotFound, error);
    }
    final channel = WebSocketMessageChannel(socket);
    try {
      channel.send(
        JoinGameMessage(
          roomCode: roomCode,
          playerToken: playerToken,
          protocolVersion: AppConstants.protocolVersion,
        ),
      );
      final reply = await channel.receiveOne(const Duration(seconds: 6));
      switch (reply) {
        case JoinAcceptedMessage(:final variant):
          return JoinedGame(
            channel: channel,
            variant: variant,
            host: host,
            port: port,
            roomCode: roomCode,
          );
        case DisconnectMessage(:final reason):
          throw LanException(switch (reason) {
            DisconnectReason.roomFull => LanError.roomFull,
            DisconnectReason.wrongCode => LanError.wrongCode,
            DisconnectReason.versionMismatch => LanError.versionMismatch,
            _ => LanError.unknown,
          });
        default:
          throw const LanException(LanError.unknown);
      }
    } on LanException {
      await channel.close();
      rethrow;
    } on Exception catch (error) {
      await channel.close();
      throw LanException(LanError.hostNotFound, error);
    }
  }

  /// Broadcasts a probe and collects the games that answer within [wait].
  Future<List<DiscoveredGame>> discover({
    Duration wait = const Duration(milliseconds: 1500),
  }) async {
    final local = await LocalNetwork.addresses();
    if (local.isEmpty) throw const LanException(LanError.noNetwork);

    final RawDatagramSocket socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    } on SocketException catch (error) {
      throw LanException(LanError.noNetwork, error);
    }
    socket.broadcastEnabled = true;
    final found = <String, DiscoveredGame>{};
    final subscription = socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = socket.receive();
      if (datagram == null) return;
      final game = _parseAnnouncement(datagram);
      if (game != null) found['${game.host}:${game.port}'] = game;
    });

    final probe = utf8.encode(LanHostServer.discoveryProbe);
    final targets = <String>{
      '255.255.255.255',
      for (final ip in local) '${ip.substring(0, ip.lastIndexOf('.'))}.255',
    };
    for (final target in targets) {
      try {
        socket.send(probe, InternetAddress(target), AppConstants.discoveryPort);
      } on SocketException {
        // Some networks refuse broadcast; the room code still works.
      }
    }
    await Future<void>.delayed(wait);
    await subscription.cancel();
    socket.close();
    return found.values.toList();
  }

  static DiscoveredGame? _parseAnnouncement(Datagram datagram) {
    try {
      final json = jsonDecode(utf8.decode(datagram.data));
      if (json is! Map || json['app'] != LanHostServer.discoveryProbe) {
        return null;
      }
      final code = json['code'];
      final port = json['port'];
      final variant = GameVariant.values
          .where((v) => v.name == json['variant'])
          .firstOrNull;
      if (code is! String ||
          RoomCode.normalize(code) == null ||
          port is! int ||
          port < 1 ||
          port > 65535 ||
          variant == null) {
        return null;
      }
      return DiscoveredGame(
        roomCode: RoomCode.format(code)!,
        host: datagram.address.address,
        port: port,
        variant: variant,
      );
    } on FormatException {
      return null;
    }
  }
}
