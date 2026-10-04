import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

import '../../special_mode/domain/army_placement.dart';
import '../domain/game_state.dart';

/// Shared timeline of the Special mode reveal, used by the sessions (to
/// know when the battle starts) and by the curtain animation.
abstract final class RevealTimeline {
  static const Duration intro = Duration(milliseconds: 1100);
  static const Duration countStep = Duration(milliseconds: 800);
  static const int counts = 3;
  static const Duration curtain = Duration(milliseconds: 1700);
  static const Duration banner = Duration(milliseconds: 1300);

  /// Moment the curtain starts opening.
  static Duration get curtainAt => intro + countStep * counts;
  static Duration get total => curtainAt + curtain + banner;
}

/// Durations used by sessions. Tests pass [SessionTimings.fast].
@immutable
class SessionTimings {
  const SessionTimings({
    this.revealDuration = const Duration(milliseconds: 6500),
    this.curtainAt = const Duration(milliseconds: 3500),
    this.aiMinThink = const Duration(milliseconds: 550),
    this.aiSetupDelay = const Duration(seconds: 4),
    this.aiRescueDelay = const Duration(milliseconds: 1500),
    this.heartbeatInterval = const Duration(seconds: 3),
    this.peerTimeout = const Duration(seconds: 10),
    this.reconnectWindow = const Duration(seconds: 40),
    this.reconnectRetry = const Duration(seconds: 2),
  });

  static const SessionTimings fast = SessionTimings(
    revealDuration: Duration(milliseconds: 30),
    curtainAt: Duration(milliseconds: 10),
    aiMinThink: Duration.zero,
    aiSetupDelay: Duration(milliseconds: 1),
    aiRescueDelay: Duration(milliseconds: 1),
    heartbeatInterval: Duration(milliseconds: 100),
    peerTimeout: Duration(milliseconds: 400),
    reconnectWindow: Duration(milliseconds: 600),
    reconnectRetry: Duration(milliseconds: 50),
  );

  final Duration revealDuration;
  final Duration curtainAt;
  final Duration aiMinThink;
  final Duration aiSetupDelay;
  final Duration aiRescueDelay;
  final Duration heartbeatInterval;
  final Duration peerTimeout;
  final Duration reconnectWindow;
  final Duration reconnectRetry;
}

/// One running match, whatever is on the other side (AI, a second player on
/// this phone, or a phone on the network). The UI talks to this interface
/// only and renders [state].
abstract class GameSession {
  GameSession(GameState initial) : _state = ValueNotifier(initial);

  final ValueNotifier<GameState> _state;
  final StreamController<GameEvent> _events = StreamController.broadcast();
  bool _disposed = false;

  ValueListenable<GameState> get state => _state;
  GameState get current => _state.value;
  Stream<GameEvent> get events => _events.stream;
  bool get isDisposed => _disposed;

  @protected
  void update(GameState next) {
    if (!_disposed) _state.value = next;
  }

  @protected
  void emit(GameEventType type) => emitEvent(GameEvent(type));

  @protected
  void emitEvent(GameEvent event) {
    if (!_disposed) _events.add(event);
  }

  /// Starts the match (or enters the lobby for LAN games).
  void start();

  /// Lobby / rematch: "I'm ready".
  void setReady() {}

  /// Special setup: tell the opponent how many pieces are placed so far.
  void reportSetupProgress(int placed) {}

  /// Special setup: "Done".
  void submitSetup(ArmyPlacement army);

  /// Special setup: go back to editing, when still allowed.
  void editSetup() {}

  void relocateKing(Square square);

  void playMove(NormalMove move);

  void resign();

  void offerDraw() {}

  void respondToDraw({required bool accept}) {}

  bool get canUndo => false;

  void undo() {}

  void rematch() {}

  @mustCallSuper
  Future<void> dispose() async {
    _disposed = true;
    await _events.close();
  }
}
