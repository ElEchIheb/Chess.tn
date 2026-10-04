import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/constants/app_constants.dart';
import '../../chess/domain/match_authority.dart';
import '../domain/game_message.dart';
import '../domain/lan_error.dart';
import '../domain/message_channel.dart';
import '../domain/room_code.dart';
import 'local_network.dart';
import 'web_socket_channel.dart';

/// A player that passed the join handshake.
class JoinedPeer {
  const JoinedPeer({required this.channel, required this.isRejoin});

  final MessageChannel channel;
  final bool isRejoin;
}

/// The host side of LAN play: a tiny WebSocket server on this phone, plus a
/// UDP responder so nearby phones can list the game without typing a code.
///
/// No external server is involved; everything stays on the local network.
class LanHostServer {
  LanHostServer._(
    this._server,
    this._discovery, {
    required this.address,
    required this.variant,
  }) : roomCode = RoomCode.encode(hostAddress: address, port: _server.port) {
    _server.listen(_onRequest, onError: (Object _) {});
    _discovery?.listen(_onDiscovery);
  }

  static const String discoveryProbe = 'CHESS_TN_DISCOVER';

  final HttpServer _server;
  final RawDatagramSocket? _discovery;
  final String address;
  final GameVariant variant;
  final String roomCode;

  final StreamController<JoinedPeer> _joins = StreamController();
  String? _playerToken;
  bool _closed = false;

  /// Decides whether the known player may come back; set by the lobby.
  bool Function() allowRejoin = () => false;

  int get port => _server.port;
  Stream<JoinedPeer> get joins => _joins.stream;
  bool get hasPlayer => _playerToken != null;

  /// Throws [LanException] when there is no local network or no free port.
  static Future<LanHostServer> start({
    required GameVariant variant,
    String? addressOverride,
  }) async {
    final address =
        addressOverride ?? (await LocalNetwork.addresses()).firstOrNull;
    if (address == null) throw const LanException(LanError.noNetwork);

    HttpServer? server;
    for (var i = 0; i < AppConstants.lanPortSpan && server == null; i++) {
      try {
        server = await HttpServer.bind(
          InternetAddress.anyIPv4,
          AppConstants.lanBasePort + i,
        );
      } on SocketException {
        // Port busy: try the next one.
      }
    }
    if (server == null) throw const LanException(LanError.cannotHost);

    RawDatagramSocket? discovery;
    try {
      discovery = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        AppConstants.discoveryPort,
        reuseAddress: true,
      );
    } on SocketException {
      // Discovery is a convenience; the room code still works without it.
    }
    return LanHostServer._(
      server,
      discovery,
      address: address,
      variant: variant,
    );
  }

  Future<void> _onRequest(HttpRequest request) async {
    if (_closed || !WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    final WebSocket socket;
    try {
      socket = await WebSocketTransformer.upgrade(request);
    } catch (_) {
      return;
    }
    final channel = WebSocketMessageChannel(socket);
    try {
      final first = await channel.receiveOne(const Duration(seconds: 6));
      if (first is! JoinGameMessage) {
        await _reject(channel, DisconnectReason.protocolError);
      } else if (first.protocolVersion != AppConstants.protocolVersion) {
        await _reject(channel, DisconnectReason.versionMismatch);
      } else if (!RoomCode.sameCode(first.roomCode, roomCode)) {
        await _reject(channel, DisconnectReason.wrongCode);
      } else if (_playerToken == null) {
        _playerToken = first.playerToken;
        _accept(channel, isRejoin: false);
      } else if (_playerToken == first.playerToken && allowRejoin()) {
        _accept(channel, isRejoin: true);
      } else {
        await _reject(channel, DisconnectReason.roomFull);
      }
    } catch (_) {
      await channel.close();
    }
  }

  void _accept(MessageChannel channel, {required bool isRejoin}) {
    channel.send(JoinAcceptedMessage(variant: variant));
    _joins.add(JoinedPeer(channel: channel, isRejoin: isRejoin));
  }

  Future<void> _reject(MessageChannel channel, DisconnectReason reason) async {
    channel.send(DisconnectMessage(reason: reason));
    await channel.close();
  }

  void _onDiscovery(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final datagram = _discovery?.receive();
    if (datagram == null || _closed || hasPlayer) return;
    if (utf8.decode(datagram.data, allowMalformed: true) != discoveryProbe) {
      return;
    }
    final reply = jsonEncode({
      'app': discoveryProbe,
      'code': roomCode,
      'port': port,
      'variant': variant.name,
    });
    _discovery?.send(utf8.encode(reply), datagram.address, datagram.port);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _discovery?.close();
    await _server.close(force: true);
    unawaited(_joins.close());
  }
}
