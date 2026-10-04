import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_service.dart';
import '../../ai/data/adaptive_engine.dart';
import '../../ai/domain/chess_engine.dart';
import '../domain/game_state.dart';
import 'game_session.dart';
import 'local_game_session.dart';

/// One engine for the whole app, so Stockfish starts once.
final chessEngineProvider = Provider<ChessEngine>((ref) {
  final engine = AdaptiveEngine();
  ref.onDispose(engine.dispose);
  return engine;
});

/// Timings used by new sessions; tests override it to run instantly.
final sessionTimingsProvider = Provider<SessionTimings>(
  (ref) => const SessionTimings(),
);

final gameControllerProvider = NotifierProvider<GameController, GameState?>(
  GameController.new,
);

/// Owns the running [GameSession] and exposes its state to the widgets.
///
/// It is also where game events become sound and vibration, so no widget
/// has to care about audio.
class GameController extends Notifier<GameState?> {
  GameSession? _session;
  VoidCallback? _stateListener;
  StreamSubscription<GameEvent>? _eventSubscription;
  Future<void> Function()? _onClose;
  final StreamController<GameEvent> _events = StreamController.broadcast();

  @override
  GameState? build() {
    ref.onDispose(() {
      unawaited(_teardown());
      unawaited(_events.close());
    });
    return null;
  }

  GameSession? get session => _session;

  /// Events of the current session, for transient UI (toasts, dialogs).
  Stream<GameEvent> get events => _events.stream;

  /// Starts a game against the AI or on a shared phone.
  void startLocal(GameConfig config) {
    attach(
      LocalGameSession(
        config: config,
        engine: config.opponent == OpponentType.ai
            ? ref.read(chessEngineProvider)
            : null,
        timings: ref.read(sessionTimingsProvider),
      ),
    );
  }

  /// Takes ownership of [session] (LAN sessions are created by the lobby).
  /// [onClose] runs when the game is left, e.g. to stop the LAN server.
  void attach(GameSession session, {Future<void> Function()? onClose}) {
    unawaited(_teardown());
    _session = session;
    _onClose = onClose;
    void listener() => state = session.current;
    _stateListener = listener;
    session.state.addListener(listener);
    _eventSubscription = session.events.listen(_onEvent);
    session.start();
    state = session.current;
  }

  Future<void> leave() async {
    await _teardown();
    state = null;
  }

  Future<void> _teardown() async {
    final session = _session;
    final listener = _stateListener;
    final onClose = _onClose;
    final subscription = _eventSubscription;
    _session = null;
    _stateListener = null;
    _onClose = null;
    _eventSubscription = null;
    if (session != null && listener != null) {
      session.state.removeListener(listener);
    }
    // Both start before any await, so the session's timers stop right now.
    // The subscription goes first: closing a stream that still has a
    // listener waits for that listener to receive the "done" event.
    final cancellation = subscription?.cancel();
    final disposal = session?.dispose();
    await cancellation;
    await disposal;
    await onClose?.call();
  }

  void _onEvent(GameEvent event) {
    final sound = ref.read(soundServiceProvider);
    switch (event.type) {
      case GameEventType.move:
        sound.play(Sfx.move);
      case GameEventType.castle:
        sound.play(Sfx.move);
      case GameEventType.capture:
        sound
          ..play(Sfx.capture)
          ..haptic();
      case GameEventType.promotion:
        sound.play(Sfx.promotion);
      case GameEventType.check:
        sound
          ..play(Sfx.check)
          ..haptic(strong: true);
      case GameEventType.gameStart || GameEventType.battleStart:
        sound.play(Sfx.gameStart);
      case GameEventType.illegalMove || GameEventType.setupInvalid:
        sound
          ..play(Sfx.illegal)
          ..haptic();
      case GameEventType.setupReady:
        sound.play(Sfx.place);
      case GameEventType.curtainOpen:
        sound
          ..play(Sfx.curtain)
          ..play(Sfx.reveal)
          ..haptic(strong: true);
      case GameEventType.kingRescue:
        sound.play(Sfx.check);
      case GameEventType.gameOver:
        _playResult(sound);
      case GameEventType.drawOffered ||
          GameEventType.opponentReconnected ||
          GameEventType.opponentReady:
        sound.play(Sfx.tick);
      case GameEventType.revealStart ||
          GameEventType.setupRedo ||
          GameEventType.drawDeclined ||
          GameEventType.opponentLeft ||
          GameEventType.opponentDisconnected ||
          GameEventType.connectionLost ||
          GameEventType.protocolError:
        break;
    }
    if (!_events.isClosed) _events.add(event);
  }

  void _playResult(SoundService sound) {
    final current = _session?.current;
    final outcome = current?.outcome;
    if (current == null || outcome == null) return;
    sound.haptic(strong: true);
    if (outcome.isDraw) {
      sound.play(Sfx.draw);
    } else if (current.localWon == false) {
      sound.play(Sfx.lose);
    } else {
      sound.play(Sfx.win);
    }
  }
}
