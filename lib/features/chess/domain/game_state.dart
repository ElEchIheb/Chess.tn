import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

import '../../ai/domain/ai_level.dart';
import '../../special_mode/domain/army_placement.dart';
import '../../special_mode/domain/special_position_validator.dart';
import '../../special_mode/domain/special_rules.dart';
import 'chess_game.dart';
import 'game_phase.dart';
import 'match_authority.dart';

enum OpponentType { ai, lan, passAndPlay }

@immutable
class GameConfig {
  const GameConfig({
    required this.variant,
    required this.opponent,
    this.aiLevel = AiLevel.medium,
    this.humanSide = Side.white,
    this.rules = const SpecialRules(),
  });

  final GameVariant variant;
  final OpponentType opponent;
  final AiLevel aiLevel;

  /// Side played by the human against the AI.
  final Side humanSide;
  final SpecialRules rules;

  bool get isSpecial => variant == GameVariant.special;
}

/// What the local player may know about the setup phase. It never contains
/// the opponent's piece positions — only whether they are done and how many
/// pieces they have placed.
@immutable
class SetupView {
  const SetupView({
    required this.side,
    this.localReady = false,
    this.opponentReady = false,
    this.opponentPlaced = 0,
    this.locked = false,
    required this.deadline,
    this.round = 0,
  });

  /// The side currently building its army on this device.
  final Side side;
  final bool localReady;
  final bool opponentReady;
  final int opponentPlaced;

  /// Both players are committed: the army can no longer be edited.
  final bool locked;
  final DateTime deadline;

  /// Increments every time a fresh setup starts (new board, new timer).
  final int round;

  SetupView copyWith({
    Side? side,
    bool? localReady,
    bool? opponentReady,
    int? opponentPlaced,
    bool? locked,
    DateTime? deadline,
    int? round,
  }) => SetupView(
    side: side ?? this.side,
    localReady: localReady ?? this.localReady,
    opponentReady: opponentReady ?? this.opponentReady,
    opponentPlaced: opponentPlaced ?? this.opponentPlaced,
    locked: locked ?? this.locked,
    deadline: deadline ?? this.deadline,
    round: round ?? this.round,
  );
}

/// Immutable snapshot of a match as seen from this device.
@immutable
class GameState {
  const GameState({
    required this.config,
    required this.phase,
    this.pausedFrom,
    required this.orientation,
    required this.localSides,
    required this.game,
    this.setup,
    this.whiteArmy,
    this.blackArmy,
    this.rescueSide,
    this.rescueSquares = const {},
    this.outcome,
    this.aiThinking = false,
    this.drawOfferFrom,
    this.localReady = false,
    this.opponentReady = false,
    this.opponentConnected = true,
    this.startedAt,
    this.endedAt,
    this.revealCount = 0,
  });

  final GameConfig config;
  final GamePhase phase;
  final GamePhase? pausedFrom;

  /// Side shown at the bottom of the board.
  final Side orientation;

  /// Sides controlled from this device (both in pass-and-play).
  final Set<Side> localSides;
  final ChessGame game;
  final SetupView? setup;

  /// Public armies — `null` until the curtain opens.
  final ArmyPlacement? whiteArmy;
  final ArmyPlacement? blackArmy;

  final Side? rescueSide;
  final Set<Square> rescueSquares;
  final GameOutcome? outcome;
  final bool aiThinking;
  final Side? drawOfferFrom;

  /// Lobby / rematch "I'm ready" flags.
  final bool localReady;
  final bool opponentReady;
  final bool opponentConnected;
  final DateTime? startedAt;
  final DateTime? endedAt;

  /// Increments at each reveal so the UI can restart its animation.
  final int revealCount;

  bool controls(Side side) => localSides.contains(side);

  bool get canMove =>
      phase == GamePhase.playing && !aiThinking && controls(game.turn);

  bool get canRescue =>
      phase == GamePhase.kingRescue &&
      rescueSide != null &&
      controls(rescueSide!);

  bool get isLan => config.opponent == OpponentType.lan;
  bool get isVsAi => config.opponent == OpponentType.ai;

  /// The local player's result: true = won, false = lost, null = draw or
  /// not applicable (pass-and-play).
  bool? get localWon {
    final winner = outcome?.winner;
    if (winner == null || localSides.length != 1) return null;
    return localSides.contains(winner);
  }

  Duration get elapsed {
    final start = startedAt;
    if (start == null) return Duration.zero;
    return (endedAt ?? DateTime.now()).difference(start);
  }

  ArmyPlacement? armyOf(Side side) =>
      side == Side.white ? whiteArmy : blackArmy;

  GameState copyWith({
    GamePhase? phase,
    Object? pausedFrom = _keep,
    Side? orientation,
    Set<Side>? localSides,
    ChessGame? game,
    Object? setup = _keep,
    Object? whiteArmy = _keep,
    Object? blackArmy = _keep,
    Object? rescueSide = _keep,
    Set<Square>? rescueSquares,
    Object? outcome = _keep,
    bool? aiThinking,
    Object? drawOfferFrom = _keep,
    bool? localReady,
    bool? opponentReady,
    bool? opponentConnected,
    Object? startedAt = _keep,
    Object? endedAt = _keep,
    int? revealCount,
  }) => GameState(
    config: config,
    phase: phase ?? this.phase,
    pausedFrom: pausedFrom == _keep
        ? this.pausedFrom
        : pausedFrom as GamePhase?,
    orientation: orientation ?? this.orientation,
    localSides: localSides ?? this.localSides,
    game: game ?? this.game,
    setup: setup == _keep ? this.setup : setup as SetupView?,
    whiteArmy: whiteArmy == _keep
        ? this.whiteArmy
        : whiteArmy as ArmyPlacement?,
    blackArmy: blackArmy == _keep
        ? this.blackArmy
        : blackArmy as ArmyPlacement?,
    rescueSide: rescueSide == _keep ? this.rescueSide : rescueSide as Side?,
    rescueSquares: rescueSquares ?? this.rescueSquares,
    outcome: outcome == _keep ? this.outcome : outcome as GameOutcome?,
    aiThinking: aiThinking ?? this.aiThinking,
    drawOfferFrom: drawOfferFrom == _keep
        ? this.drawOfferFrom
        : drawOfferFrom as Side?,
    localReady: localReady ?? this.localReady,
    opponentReady: opponentReady ?? this.opponentReady,
    opponentConnected: opponentConnected ?? this.opponentConnected,
    startedAt: startedAt == _keep ? this.startedAt : startedAt as DateTime?,
    endedAt: endedAt == _keep ? this.endedAt : endedAt as DateTime?,
    revealCount: revealCount ?? this.revealCount,
  );

  static const Object _keep = Object();
}

/// One-shot notifications for sound, haptics and transient messages.
enum GameEventType {
  gameStart,
  move,
  capture,
  castle,
  promotion,
  check,
  illegalMove,
  setupInvalid,
  setupReady,
  opponentReady,
  revealStart,
  curtainOpen,
  battleStart,
  kingRescue,
  setupRedo,
  drawOffered,
  drawDeclined,
  opponentLeft,
  opponentDisconnected,
  opponentReconnected,
  connectionLost,
  protocolError,
  gameOver,
}

@immutable
class GameEvent {
  const GameEvent(this.type, {this.issues = const []});

  final GameEventType type;

  /// Filled for [GameEventType.setupInvalid].
  final List<SetupIssue> issues;

  @override
  String toString() => 'GameEvent(${type.name})';
}
