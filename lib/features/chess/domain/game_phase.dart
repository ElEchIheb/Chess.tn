/// Every stage a match can be in. The UI renders from this single value
/// instead of a set of scattered booleans.
enum GamePhase {
  /// Players are connected (or the game was just created) and not started.
  lobby,

  /// Special mode: white is privately building their army.
  setupWhite,

  /// Special mode: black is privately building their army.
  setupBlack,

  /// The local player is done and waits for the opponent.
  waitingForPlayer,

  /// Special mode: countdown and curtain opening.
  reveal,

  /// Special mode: a king was under fire at reveal and must be relocated.
  kingRescue,

  playing,

  /// The opponent's connection dropped; waiting for them to come back.
  paused,

  gameOver,

  /// The match can no longer continue (peer left for good).
  abandoned;

  bool get isSetup => this == setupWhite || this == setupBlack;
  bool get isTerminal => this == gameOver || this == abandoned;
}

/// Explicit transition table of the match state machine.
abstract final class GamePhaseMachine {
  static const Map<GamePhase, Set<GamePhase>> _transitions = {
    GamePhase.lobby: {
      GamePhase.setupWhite,
      GamePhase.setupBlack,
      GamePhase.playing,
      GamePhase.paused,
      GamePhase.abandoned,
    },
    GamePhase.setupWhite: {
      GamePhase.setupBlack,
      GamePhase.waitingForPlayer,
      GamePhase.reveal,
      GamePhase.paused,
      GamePhase.abandoned,
    },
    GamePhase.setupBlack: {
      GamePhase.setupWhite,
      GamePhase.waitingForPlayer,
      GamePhase.reveal,
      GamePhase.paused,
      GamePhase.abandoned,
    },
    GamePhase.waitingForPlayer: {
      GamePhase.setupWhite,
      GamePhase.setupBlack,
      GamePhase.reveal,
      GamePhase.paused,
      GamePhase.abandoned,
    },
    GamePhase.reveal: {
      GamePhase.kingRescue,
      GamePhase.playing,
      GamePhase.setupWhite,
      GamePhase.setupBlack,
      GamePhase.paused,
      GamePhase.abandoned,
    },
    GamePhase.kingRescue: {
      GamePhase.kingRescue,
      GamePhase.playing,
      GamePhase.setupWhite,
      GamePhase.setupBlack,
      GamePhase.paused,
      GamePhase.abandoned,
    },
    GamePhase.playing: {
      GamePhase.gameOver,
      GamePhase.paused,
      GamePhase.abandoned,
    },
    GamePhase.paused: {
      GamePhase.lobby,
      GamePhase.setupWhite,
      GamePhase.setupBlack,
      GamePhase.waitingForPlayer,
      GamePhase.reveal,
      GamePhase.kingRescue,
      GamePhase.playing,
      GamePhase.gameOver,
      GamePhase.abandoned,
    },
    GamePhase.gameOver: {
      GamePhase.lobby,
      GamePhase.setupWhite,
      GamePhase.setupBlack,
      GamePhase.playing,
      GamePhase.abandoned,
    },
    GamePhase.abandoned: {},
  };

  static bool canTransition(GamePhase from, GamePhase to) =>
      from == to || (_transitions[from]?.contains(to) ?? false);

  /// Returns [to] when the transition is allowed, throws otherwise.
  static GamePhase transition(GamePhase from, GamePhase to) {
    if (!canTransition(from, to)) {
      throw StateError('Illegal phase transition: ${from.name} -> ${to.name}');
    }
    return to;
  }
}
