import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chess/application/game_controller.dart';
import '../../chess/domain/game_state.dart';
import '../../chess/domain/match_authority.dart';
import '../data/lan_client_connector.dart';
import '../data/lan_host_server.dart';
import '../domain/lan_error.dart';
import '../domain/message_channel.dart';
import 'lan_client_session.dart';
import 'lan_host_session.dart';

/// Where the "play with a friend" flow currently is.
@immutable
sealed class LobbyState {
  const LobbyState();
}

class LobbyIdle extends LobbyState {
  const LobbyIdle();
}

/// Starting the server or connecting to a host.
class LobbyBusy extends LobbyState {
  const LobbyBusy();
}

/// The room is open; waiting for the friend.
class LobbyHosting extends LobbyState {
  const LobbyHosting({
    required this.roomCode,
    required this.address,
    required this.variant,
  });

  final String roomCode;
  final String address;
  final GameVariant variant;
}

/// Both phones are connected: the game screen takes over.
class LobbyConnected extends LobbyState {
  const LobbyConnected();
}

class LobbyFailed extends LobbyState {
  const LobbyFailed(this.error);

  final LanError error;
}

final lobbyControllerProvider = NotifierProvider<LobbyController, LobbyState>(
  LobbyController.new,
);

/// Creates and joins LAN games, then hands a ready session to the
/// [GameController].
class LobbyController extends Notifier<LobbyState> {
  LanHostServer? _server;
  StreamSubscription<JoinedPeer>? _joins;
  LanHostSession? _hostSession;
  int _attempt = 0;

  @override
  LobbyState build() {
    ref.onDispose(() => unawaited(_closeServer()));
    return const LobbyIdle();
  }

  Future<void> host(GameVariant variant) async {
    final attempt = ++_attempt;
    await _closeServer();
    state = const LobbyBusy();
    try {
      final server = await LanHostServer.start(variant: variant);
      if (attempt != _attempt) {
        await server.close();
        return;
      }
      _server = server;
      server.allowRejoin = () => _hostSession?.acceptsRejoin ?? false;
      _joins = server.joins.listen((peer) => _onPeer(peer, variant));
      state = LobbyHosting(
        roomCode: server.roomCode,
        address: server.address,
        variant: variant,
      );
    } on LanException catch (error) {
      if (attempt == _attempt) state = LobbyFailed(error.error);
    } catch (_) {
      if (attempt == _attempt) state = const LobbyFailed(LanError.cannotHost);
    }
  }

  void _onPeer(JoinedPeer peer, GameVariant variant) {
    final existing = _hostSession;
    if (peer.isRejoin && existing != null && existing.acceptsRejoin) {
      existing.reattach(peer.channel);
      return;
    }
    final session = LanHostSession(
      config: GameConfig(variant: variant, opponent: OpponentType.lan),
      channel: peer.channel,
      timings: ref.read(sessionTimingsProvider),
    );
    _hostSession = session;
    ref
        .read(gameControllerProvider.notifier)
        .attach(session, onClose: _onGameClosed);
    state = const LobbyConnected();
  }

  Future<void> join(String code, {String? manualHost}) => _join(
    (connector) => connector.joinWithCode(code, manualHost: manualHost),
  );

  Future<void> joinDiscovered(DiscoveredGame game) => _join(
    (connector) => connector.connect(
      host: game.host,
      port: game.port,
      roomCode: game.roomCode,
    ),
  );

  Future<void> _join(
    Future<JoinedGame> Function(LanClientConnector connector) connect,
  ) async {
    final attempt = ++_attempt;
    state = const LobbyBusy();
    final connector = LanClientConnector();
    try {
      final joined = await connect(connector);
      if (attempt != _attempt) {
        await joined.channel.close();
        return;
      }
      Future<MessageChannel?> reconnect() async {
        try {
          final again = await connector.connect(
            host: joined.host,
            port: joined.port,
            roomCode: joined.roomCode,
          );
          return again.channel;
        } on LanException {
          return null;
        }
      }

      final session = LanClientSession(
        config: GameConfig(variant: joined.variant, opponent: OpponentType.lan),
        channel: joined.channel,
        reconnect: reconnect,
        timings: ref.read(sessionTimingsProvider),
      );
      ref
          .read(gameControllerProvider.notifier)
          .attach(session, onClose: _onGameClosed);
      state = const LobbyConnected();
    } on LanException catch (error) {
      if (attempt == _attempt) state = LobbyFailed(error.error);
    } catch (_) {
      if (attempt == _attempt) state = const LobbyFailed(LanError.unknown);
    }
  }

  /// Games announced on the local network. Empty when none answer.
  Future<List<DiscoveredGame>> discover() async {
    try {
      return await LanClientConnector().discover();
    } on LanException {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  /// Leaves the lobby before a game started.
  Future<void> cancel() async {
    _attempt++;
    await _closeServer();
    state = const LobbyIdle();
  }

  /// Clears a failure message so the user can try again.
  void clearError() {
    if (state is LobbyFailed) state = const LobbyIdle();
  }

  Future<void> _onGameClosed() async {
    await _closeServer();
    state = const LobbyIdle();
  }

  Future<void> _closeServer() async {
    final server = _server;
    _server = null;
    _hostSession = null;
    await _joins?.cancel();
    _joins = null;
    await server?.close();
  }
}
