import 'package:dartchess/dartchess.dart';

import '../../special_mode/domain/army_placement.dart';
import '../../special_mode/domain/king_rescue.dart';
import '../../special_mode/domain/special_position_composer.dart';
import '../../special_mode/domain/special_position_validator.dart';
import '../../special_mode/domain/special_rules.dart';
import 'chess_game.dart';
import 'game_phase.dart';

enum GameVariant { normal, special }

enum MatchViolation {
  wrongPhase,
  notYourTurn,
  notYourPiece,
  illegalMove,
  invalidSetup,
  invalidKingSquare,
}

class MatchRuleException implements Exception {
  const MatchRuleException(this.violation, [this.issues = const []]);

  final MatchViolation violation;
  final List<SetupIssue> issues;

  @override
  String toString() => 'MatchRuleException(${violation.name}, $issues)';
}

enum RevealResult { battle, kingRescue, redoSetup }

/// The referee of a match: owns the rules and the phase state machine.
///
/// It has no timers, no I/O and no UI. Local games, the LAN host and the LAN
/// client replica all drive one instance, so every action — whoever it comes
/// from — goes through the same validation.
class MatchAuthority {
  MatchAuthority({required this.variant, this.rules = const SpecialRules()});

  final GameVariant variant;
  final SpecialRules rules;

  static const _composer = SpecialPositionComposer();

  GamePhase _phase = GamePhase.lobby;
  GamePhase? _pausedFrom;
  ChessGame _game = ChessGame.standard();
  GameOutcome? _outcome;
  final Map<Side, ArmyPlacement> _armies = {};
  Side? _rescueSide;
  Set<Square> _rescueSquares = const {};

  GamePhase get phase => _phase;
  GamePhase? get pausedFrom => _pausedFrom;
  ChessGame get game => _game;
  GameOutcome? get outcome => _outcome;
  Side? get rescueSide => _rescueSide;
  Set<Square> get rescueSquares => _rescueSquares;

  SpecialPositionValidator get validator => SpecialPositionValidator(rules);

  bool hasArmy(Side side) => _armies.containsKey(side);
  bool get armiesComplete => _armies.length == 2;

  /// Armies become readable only once the curtain is open.
  ArmyPlacement? revealedArmy(Side side) => _isRevealed ? _armies[side] : null;

  bool get _isRevealed => switch (_phase) {
    GamePhase.reveal ||
    GamePhase.kingRescue ||
    GamePhase.playing ||
    GamePhase.gameOver => true,
    GamePhase.paused =>
      _pausedFrom != null &&
          const {
            GamePhase.reveal,
            GamePhase.kingRescue,
            GamePhase.playing,
          }.contains(_pausedFrom),
    _ => false,
  };

  void _go(GamePhase to) => _phase = GamePhaseMachine.transition(_phase, to);

  void _require(bool condition, MatchViolation violation) {
    if (!condition) throw MatchRuleException(violation);
  }

  // ---------------------------------------------------------------- start

  /// Starts (or restarts, for a rematch) the match.
  void start() {
    _require(
      _phase == GamePhase.lobby || _phase == GamePhase.gameOver,
      MatchViolation.wrongPhase,
    );
    _outcome = null;
    _armies.clear();
    _rescueSide = null;
    _rescueSquares = const {};
    _game = ChessGame.standard();
    _go(
      variant == GameVariant.normal ? GamePhase.playing : GamePhase.setupWhite,
    );
  }

  // ---------------------------------------------------------------- setup

  /// Registers a finished army. Throws [MatchRuleException] with the list of
  /// [SetupIssue]s when it breaks the Special rules.
  void submitArmy(ArmyPlacement army) {
    _require(
      variant == GameVariant.special && _phase.isSetup,
      MatchViolation.wrongPhase,
    );
    final issues = validator.validateArmy(army);
    if (issues.isNotEmpty) {
      throw MatchRuleException(MatchViolation.invalidSetup, issues);
    }
    _armies[army.side] = army;
    _syncSetupPhase();
  }

  void withdrawArmy(Side side) {
    _require(_phase.isSetup, MatchViolation.wrongPhase);
    _armies.remove(side);
    _syncSetupPhase();
  }

  void _syncSetupPhase() {
    if (!_armies.containsKey(Side.white)) {
      _go(GamePhase.setupWhite);
    } else if (!_armies.containsKey(Side.black)) {
      _go(GamePhase.setupBlack);
    }
  }

  /// Opens the curtain: both armies become public.
  void reveal() {
    _require(_phase.isSetup && armiesComplete, MatchViolation.wrongPhase);
    _go(GamePhase.reveal);
  }

  /// Ends the reveal animation phase and decides what comes next.
  RevealResult completeReveal() {
    _require(_phase == GamePhase.reveal, MatchViolation.wrongPhase);
    return _resolveStart();
  }

  void relocateKing(Side side, Square to) {
    _require(_phase == GamePhase.kingRescue, MatchViolation.wrongPhase);
    _require(side == _rescueSide, MatchViolation.notYourTurn);
    _require(_rescueSquares.contains(to), MatchViolation.invalidKingSquare);
    _armies[side] = _armies[side]!.withKingAt(to);
    _resolveStart();
  }

  RevealResult _resolveStart() {
    final white = _armies[Side.white]!;
    final black = _armies[Side.black]!;
    final resolver = KingRescueResolver(rules);
    final side = resolver.nextToRescue(white, black);
    if (side != null) {
      final squares = resolver.safeSquares(side, white, black);
      if (squares.isEmpty) return _redoSetup();
      _rescueSide = side;
      _rescueSquares = squares;
      _go(GamePhase.kingRescue);
      return RevealResult.kingRescue;
    }
    if (!validator.validateCombined(white, black).playable) {
      return _redoSetup();
    }
    _rescueSide = null;
    _rescueSquares = const {};
    _game = ChessGame.fromPosition(_composer.position(white, black));
    _go(GamePhase.playing);
    return RevealResult.battle;
  }

  RevealResult _redoSetup() {
    _armies.clear();
    _rescueSide = null;
    _rescueSquares = const {};
    _go(GamePhase.setupWhite);
    return RevealResult.redoSetup;
  }

  // ----------------------------------------------------------------- play

  /// Validates and plays [move] for [side]. Nothing is trusted: the phase,
  /// the turn, the ownership of the piece and the legality are all checked.
  MoveRecord play(Side side, NormalMove move) {
    _require(_phase == GamePhase.playing, MatchViolation.wrongPhase);
    _require(_game.turn == side, MatchViolation.notYourTurn);
    final piece = _game.position.board.pieceAt(move.from);
    _require(piece != null && piece.color == side, MatchViolation.notYourPiece);
    _require(_game.isLegal(move), MatchViolation.illegalMove);
    _game = _game.play(move);
    final outcome = _game.outcome;
    if (outcome != null) _finish(outcome);
    return _game.lastMove!;
  }

  void undo(int plies) {
    _require(_phase == GamePhase.playing, MatchViolation.wrongPhase);
    _game = _game.undo(plies);
  }

  void resign(Side side) {
    _require(_phase == GamePhase.playing, MatchViolation.wrongPhase);
    _finish(
      GameOutcome(winner: side.opposite, reason: GameEndReason.resignation),
    );
  }

  void agreeDraw() {
    _require(_phase == GamePhase.playing, MatchViolation.wrongPhase);
    _finish(
      const GameOutcome(winner: null, reason: GameEndReason.drawAgreement),
    );
  }

  /// Applies an outcome decided elsewhere (the LAN host is the authority
  /// for the client replica).
  void forceOutcome(GameOutcome outcome) {
    if (_phase == GamePhase.paused) resume();
    if (_phase == GamePhase.playing) _finish(outcome);
  }

  void _finish(GameOutcome outcome) {
    _outcome = outcome;
    _go(GamePhase.gameOver);
  }

  // ----------------------------------------------------------- connection

  void pause() {
    if (_phase == GamePhase.paused || _phase.isTerminal) return;
    _pausedFrom = _phase;
    _go(GamePhase.paused);
  }

  void resume() {
    if (_phase != GamePhase.paused) return;
    final back = _pausedFrom!;
    _pausedFrom = null;
    _go(back);
  }

  /// [leaver] left for good. During a battle the other side wins.
  void abandon(Side leaver) {
    if (_phase == GamePhase.abandoned || _phase == GamePhase.gameOver) return;
    final wasPlaying =
        _phase == GamePhase.playing ||
        (_phase == GamePhase.paused && _pausedFrom == GamePhase.playing);
    if (wasPlaying) {
      _outcome = GameOutcome(
        winner: leaver.opposite,
        reason: GameEndReason.abandonment,
      );
    }
    _pausedFrom = null;
    _go(GamePhase.abandoned);
  }

  // ----------------------------------------------------------------- sync

  /// Rebuilds a battle from a trusted-but-verified snapshot (reconnection).
  /// Returns false and leaves the match untouched when the snapshot does not
  /// replay legally.
  bool restoreBattle({
    required String initialFen,
    required List<String> uciMoves,
    ArmyPlacement? white,
    ArmyPlacement? black,
  }) {
    try {
      var game = ChessGame.fromFen(initialFen);
      for (final uci in uciMoves) {
        final next = game.tryPlayUci(uci);
        if (next == null) return false;
        game = next;
      }
      _game = game;
    } on Exception {
      return false;
    }
    _armies.clear();
    if (white != null) _armies[Side.white] = white;
    if (black != null) _armies[Side.black] = black;
    _pausedFrom = null;
    _rescueSide = null;
    _rescueSquares = const {};
    _phase = GamePhase.playing;
    _outcome = null;
    final outcome = _game.outcome;
    if (outcome != null) _finish(outcome);
    return true;
  }
}
