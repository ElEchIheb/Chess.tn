import 'dart:math';

import 'package:chess_tn/features/ai/domain/ai_level.dart';
import 'package:chess_tn/features/ai/domain/ai_setup_generator.dart';
import 'package:chess_tn/features/chess/application/game_session.dart';
import 'package:chess_tn/features/chess/application/local_game_session.dart';
import 'package:chess_tn/features/chess/domain/chess_game.dart';
import 'package:chess_tn/features/chess/domain/game_phase.dart';
import 'package:chess_tn/features/chess/domain/game_state.dart';
import 'package:chess_tn/features/chess/domain/match_authority.dart';
import 'package:chess_tn/features/special_mode/domain/army_placement.dart';
import 'package:chess_tn/features/special_mode/domain/special_position_validator.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/armies.dart';
import '../support/fakes.dart';

LocalGameSession aiSession({
  GameVariant variant = GameVariant.normal,
  Side humanSide = Side.white,
  AiLevel level = AiLevel.veryEasy,
  FirstMoveEngine? engine,
  int seed = 1,
}) => LocalGameSession(
  config: GameConfig(
    variant: variant,
    opponent: OpponentType.ai,
    aiLevel: level,
    humanSide: humanSide,
  ),
  engine: engine ?? FirstMoveEngine(),
  setupGenerator: AiSetupGenerator(random: Random(seed)),
  timings: SessionTimings.fast,
);

void main() {
  group('Normal chess vs AI', () {
    test('starts from the standard position and the AI answers', () async {
      final session = aiSession()..start();
      addTearDown(session.dispose);
      expect(session.current.phase, GamePhase.playing);
      expect(session.current.game.fen, ChessGame.standard().fen);
      expect(session.current.canMove, isTrue);

      session.playMove(const NormalMove(from: Square.e2, to: Square.e4));
      expect(session.current.aiThinking, isTrue);
      final state = await waitForState(session, (s) => s.game.ply == 2);
      expect(state.aiThinking, isFalse);
      expect(state.game.turn, Side.white);
    });

    test('the AI opens when the human plays black', () async {
      final session = aiSession(humanSide: Side.black)..start();
      addTearDown(session.dispose);
      expect(session.current.orientation, Side.black);
      final state = await waitForState(session, (s) => s.game.ply == 1);
      expect(state.canMove, isTrue);
    });

    test('illegal moves are refused and reported', () async {
      final session = aiSession()..start();
      addTearDown(session.dispose);
      final events = <GameEventType>[];
      session.events.listen((e) => events.add(e.type));
      session.playMove(const NormalMove(from: Square.e2, to: Square.e5));
      await settle();
      expect(session.current.game.ply, 0);
      expect(events, contains(GameEventType.illegalMove));
    });

    test('the human cannot move while the AI is thinking', () async {
      final session = aiSession()..start();
      addTearDown(session.dispose);
      session
        ..playMove(const NormalMove(from: Square.e2, to: Square.e4))
        ..playMove(const NormalMove(from: Square.d2, to: Square.d4));
      final state = await waitForState(session, (s) => s.game.ply == 2);
      expect(state.game.history.first.uci, 'e2e4');
      expect(state.game.position.board.pieceAt(Square.d2), Piece.whitePawn);
    });

    test('undo takes back the human move and the reply', () async {
      final session = aiSession()..start();
      addTearDown(session.dispose);
      expect(session.canUndo, isFalse);
      session.playMove(const NormalMove(from: Square.e2, to: Square.e4));
      await waitForState(session, (s) => s.game.ply == 2);
      expect(session.canUndo, isTrue);
      session.undo();
      expect(session.current.game.ply, 0);
    });

    test('resigning ends the game and a rematch restarts it', () async {
      final session = aiSession()..start();
      addTearDown(session.dispose);
      session.resign();
      expect(session.current.phase, GamePhase.gameOver);
      expect(
        session.current.outcome,
        const GameOutcome(
          winner: Side.black,
          reason: GameEndReason.resignation,
        ),
      );
      expect(session.current.localWon, isFalse);
      session.rematch();
      expect(session.current.phase, GamePhase.playing);
      expect(session.current.outcome, isNull);
    });

    test('a complete game can be played to the end', () async {
      // Fool's mate against an engine that happens to cooperate.
      final session = LocalGameSession(
        config: const GameConfig(
          variant: GameVariant.normal,
          opponent: OpponentType.passAndPlay,
        ),
        timings: SessionTimings.fast,
      )..start();
      addTearDown(session.dispose);
      for (final uci in ['f2f3', 'e7e5', 'g2g4', 'd8h4']) {
        session.playMove(Move.parse(uci)! as NormalMove);
      }
      expect(session.current.phase, GamePhase.gameOver);
      expect(session.current.outcome?.reason, GameEndReason.checkmate);
      expect(session.current.outcome?.winner, Side.black);
    });
  });

  group('Special chess vs AI', () {
    test('the AI army is hidden during the setup phase', () async {
      final session = aiSession(variant: GameVariant.special)..start();
      addTearDown(session.dispose);
      final state = session.current;
      expect(state.phase, GamePhase.setupWhite);
      expect(state.setup!.side, Side.white);
      // Nothing about the AI's pieces is reachable from the public state.
      expect(state.whiteArmy, isNull);
      expect(state.blackArmy, isNull);
      expect(state.game.fen, ChessGame.standard().fen);

      // Even once the AI says it is ready, only that fact is published.
      final ready = await waitForState(
        session,
        (s) => s.setup?.opponentReady ?? false,
      );
      expect(ready.blackArmy, isNull);
    });

    test('an invalid army is refused with the reasons', () async {
      final session = aiSession(variant: GameVariant.special)..start();
      addTearDown(session.dispose);
      final events = <GameEvent>[];
      session.events.listen(events.add);
      session.submitSetup(customWhite().remove(Square.f2));
      await settle();
      expect(session.current.phase, GamePhase.setupWhite);
      final invalid = events
          .where((e) => e.type == GameEventType.setupInvalid)
          .toList();
      expect(invalid, hasLength(1));
      expect(invalid.single.issues, contains(SetupIssue.missingPieces));
    });

    test(
      'reveal shows both armies, then the battle uses both setups',
      () async {
        final session = aiSession(variant: GameVariant.special)..start();
        addTearDown(session.dispose);
        final events = <GameEventType>[];
        session.events.listen((e) => events.add(e.type));

        session.submitSetup(customWhite());
        var state = session.current;
        expect(state.phase, GamePhase.reveal);
        expect(state.revealCount, 1);
        expect(state.whiteArmy, customWhite());
        final aiArmy = state.blackArmy!;
        expect(const SpecialPositionValidator().validateArmy(aiArmy), isEmpty);
        expect(aiArmy, isNot(ArmyPlacement.standard(Side.black)));

        state = await waitForState(
          session,
          (s) =>
              s.phase == GamePhase.playing || s.phase == GamePhase.kingRescue,
        );
        if (state.phase == GamePhase.kingRescue) {
          // Whoever is under fire relocates; the human picks any safe square.
          if (state.canRescue) session.relocateKing(state.rescueSquares.first);
          state = await waitForPhase(session, GamePhase.playing);
        }
        expect(state.game.initialFen, isNot(ChessGame.standard().fen));
        final board = state.game.initialPosition.board;
        for (final entry in customWhite().pieces.entries) {
          if (entry.value == Role.king && state.whiteArmy != customWhite()) {
            continue; // the king may have been rescued
          }
          expect(
            board.pieceAt(entry.key),
            Piece(color: Side.white, role: entry.value),
          );
        }
        expect(board.bySide(Side.black).size, 16);
        await settle();
        expect(
          events,
          containsAllInOrder([
            GameEventType.setupReady,
            GameEventType.revealStart,
            GameEventType.curtainOpen,
          ]),
        );
        expect(events, contains(GameEventType.battleStart));
      },
    );

    test('the AI setup does not depend on the human setup', () async {
      // Same seed, two completely different human armies: same AI army.
      Future<ArmyPlacement> aiArmyAgainst(ArmyPlacement human) async {
        final session = aiSession(variant: GameVariant.special, seed: 42)
          ..start();
        session.submitSetup(human);
        final army = session.current.blackArmy!;
        await session.dispose();
        return army;
      }

      final a = await aiArmyAgainst(customWhite());
      final b = await aiArmyAgainst(ArmyPlacement.standard(Side.white));
      expect(a, b);
    });

    test('works when the human plays black', () async {
      final session = aiSession(
        variant: GameVariant.special,
        humanSide: Side.black,
      )..start();
      addTearDown(session.dispose);
      expect(session.current.phase, GamePhase.setupBlack);
      expect(session.current.orientation, Side.black);
      session.submitSetup(customBlack());
      expect(session.current.phase, GamePhase.reveal);
      expect(session.current.blackArmy, customBlack());
      expect(session.current.whiteArmy, isNotNull);
    });
  });

  group('Special chess, two players on one phone', () {
    test('black never sees white\'s army before the reveal', () async {
      final session = LocalGameSession(
        config: const GameConfig(
          variant: GameVariant.special,
          opponent: OpponentType.passAndPlay,
        ),
        timings: SessionTimings.fast,
      )..start();
      addTearDown(session.dispose);

      expect(session.current.phase, GamePhase.setupWhite);
      session.submitSetup(customWhite());

      final blackTurn = session.current;
      expect(blackTurn.phase, GamePhase.setupBlack);
      expect(blackTurn.setup!.side, Side.black);
      expect(blackTurn.orientation, Side.black);
      expect(blackTurn.whiteArmy, isNull);
      expect(blackTurn.blackArmy, isNull);

      // An army for the wrong side is ignored.
      session.submitSetup(customWhite());
      expect(session.current.phase, GamePhase.setupBlack);

      session.submitSetup(customBlack());
      expect(session.current.phase, GamePhase.reveal);
      expect(session.current.whiteArmy, customWhite());
      expect(session.current.blackArmy, customBlack());

      final playing = await waitForPhase(session, GamePhase.playing);
      expect(
        playing.game.initialFen,
        '1k1r1r2/pppqbb2/2nn1ppp/4pp2/3PP3/PPP1NN2/2BBQPPP/2R1R1K1 w - - 0 1',
      );
      expect(playing.localSides, {Side.white, Side.black});
    });
  });
}
