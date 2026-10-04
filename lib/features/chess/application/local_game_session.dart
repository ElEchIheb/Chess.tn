import 'dart:async';

import 'package:dartchess/dartchess.dart';

import '../../ai/domain/ai_setup_generator.dart';
import '../../ai/domain/chess_engine.dart';
import '../../ai/domain/setup_evaluator.dart';
import '../../special_mode/domain/army_placement.dart';
import '../domain/game_phase.dart';
import '../domain/game_state.dart';
import '../domain/match_authority.dart';
import 'match_session.dart';

/// A match played entirely on this device: against the AI, or two players
/// passing the phone. Works with no network at all.
class LocalGameSession extends MatchSession {
  LocalGameSession({
    required super.config,
    ChessEngine? engine,
    AiSetupGenerator? setupGenerator,
    super.timings,
    super.clock,
  }) : assert(config.opponent != OpponentType.lan),
       assert(config.opponent != OpponentType.ai || engine != null),
       _engine = engine,
       _setupGenerator =
           setupGenerator ?? AiSetupGenerator(rules: config.rules),
       super(
         orientation: config.opponent == OpponentType.ai
             ? config.humanSide
             : Side.white,
         localSides: config.opponent == OpponentType.ai
             ? {config.humanSide}
             : {Side.white, Side.black},
       );

  final ChessEngine? _engine;
  final AiSetupGenerator _setupGenerator;

  /// The AI's hidden army. Private to the session: it is not part of
  /// [GameState] and reaches the authority only when the human is done.
  ArmyPlacement? _aiArmy;
  int _thinkToken = 0;

  bool get _vsAi => config.opponent == OpponentType.ai;
  Side get _aiSide => config.humanSide.opposite;

  @override
  void start() {
    authority.start();
    if (config.isSpecial) {
      beginSetup();
    } else {
      beginBattle();
    }
  }

  // ---------------------------------------------------------------- setup

  @override
  void beginSetup() {
    if (_vsAi) {
      // Built before the human places a single piece, from nothing but the
      // AI's own side and level: it cannot depend on the human's army.
      _aiArmy = _setupGenerator.generate(side: _aiSide, level: config.aiLevel);
      openSetup(config.humanSide);
      final round = setupView!.round;
      schedule(timings.aiSetupDelay, () {
        final view = setupView;
        if (view == null || view.round != round) return;
        setupView = view.copyWith(
          opponentReady: true,
          opponentPlaced: config.rules.armySize,
        );
        publish();
        emit(GameEventType.opponentReady);
      });
    } else {
      openSetup(Side.white);
    }
  }

  @override
  void submitSetup(ArmyPlacement army) {
    final view = setupView;
    if (view == null || !authority.phase.isSetup || army.side != view.side) {
      return;
    }
    try {
      authority.submitArmy(army);
    } on MatchRuleException catch (error) {
      emitEvent(GameEvent(GameEventType.setupInvalid, issues: error.issues));
      return;
    }
    emit(GameEventType.setupReady);
    if (_vsAi) {
      authority.submitArmy(_aiArmy!);
      _aiArmy = null;
      beginReveal();
    } else if (army.side == Side.white) {
      // Pass-and-play: white's army stays inside the authority, unreadable,
      // while black builds theirs.
      openSetup(Side.black);
    } else {
      beginReveal();
    }
  }

  @override
  void onKingRescue() {
    if (!_vsAi || authority.rescueSide != _aiSide) return;
    schedule(timings.aiRescueDelay, () {
      if (authority.phase != GamePhase.kingRescue ||
          authority.rescueSide != _aiSide) {
        return;
      }
      final army = authority.revealedArmy(_aiSide)!;
      const evaluator = SetupEvaluator();
      Square? best;
      var bestScore = double.negativeInfinity;
      for (final square in authority.rescueSquares) {
        final score = evaluator.score(army.withKingAt(square));
        if (score > bestScore) {
          bestScore = score;
          best = square;
        }
      }
      if (best != null) applyRescue(_aiSide, best);
    });
  }

  @override
  void relocateKing(Square square) {
    final side = authority.rescueSide;
    if (side == null || !localSides.contains(side)) return;
    if (!applyRescue(side, square)) emit(GameEventType.illegalMove);
  }

  // --------------------------------------------------------------- battle

  @override
  void onBattleStarted() => _maybeThink();

  @override
  void playMove(NormalMove move) {
    if (!current.canMove) return;
    final record = applyMove(authority.game.turn, move);
    if (record == null) {
      emit(GameEventType.illegalMove);
      return;
    }
    _maybeThink();
  }

  void _maybeThink() {
    if (!_vsAi ||
        authority.phase != GamePhase.playing ||
        authority.game.turn != _aiSide) {
      return;
    }
    unawaited(_think());
  }

  Future<void> _think() async {
    final token = ++_thinkToken;
    aiThinking = true;
    publish();
    final game = authority.game;
    NormalMove? move;
    try {
      final results = await Future.wait([
        _engine!.bestMove(game, config.aiLevel),
        Future<void>.delayed(timings.aiMinThink),
      ]);
      move = results.first as NormalMove?;
    } catch (_) {
      move = null;
    }
    if (isDisposed || token != _thinkToken) return;
    aiThinking = false;
    if (authority.phase != GamePhase.playing ||
        authority.game.turn != _aiSide) {
      publish();
      return;
    }
    // Never let an engine failure freeze the game: any legal move will do.
    move = (move != null && game.isLegal(move)) ? move : _anyLegalMove();
    if (move == null || applyMove(_aiSide, move) == null) publish();
  }

  NormalMove? _anyLegalMove() {
    final position = authority.game.position;
    for (final entry in position.legalMoves.entries) {
      final to = entry.value.first;
      if (to == null) continue;
      final promotes =
          position.board.roleAt(entry.key) == Role.pawn &&
          (to.rank == Rank.first || to.rank == Rank.eighth);
      return NormalMove(
        from: entry.key,
        to: to,
        promotion: promotes ? Role.queen : null,
      );
    }
    return null;
  }

  @override
  bool get canUndo {
    if (!_vsAi || authority.phase != GamePhase.playing || aiThinking) {
      return false;
    }
    final game = authority.game;
    return game.turn == config.humanSide &&
        game.history.any((r) => r.piece.color == config.humanSide);
  }

  /// Takes back the human's last move together with the AI's reply.
  @override
  void undo() {
    if (!canUndo) return;
    _thinkToken++;
    authority.undo(2);
    publish();
  }

  @override
  void resign() {
    if (authority.phase != GamePhase.playing) return;
    _thinkToken++;
    endWith(
      () => authority.resign(_vsAi ? config.humanSide : authority.game.turn),
    );
  }

  @override
  void rematch() {
    if (authority.phase != GamePhase.gameOver) return;
    _thinkToken++;
    aiThinking = false;
    start();
  }
}
