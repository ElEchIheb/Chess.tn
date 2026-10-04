import 'package:chess_tn/features/chess/domain/chess_game.dart';
import 'package:chess_tn/features/chess/domain/game_phase.dart';
import 'package:chess_tn/features/chess/domain/match_authority.dart';
import 'package:chess_tn/features/special_mode/domain/army_placement.dart';
import 'package:chess_tn/features/special_mode/domain/special_position_composer.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/armies.dart';

Matcher violates(MatchViolation violation) => throwsA(
  isA<MatchRuleException>().having((e) => e.violation, 'violation', violation),
);

void main() {
  group('GamePhaseMachine', () {
    test('allows the documented flow', () {
      const flow = [
        GamePhase.lobby,
        GamePhase.setupWhite,
        GamePhase.setupBlack,
        GamePhase.reveal,
        GamePhase.playing,
        GamePhase.gameOver,
      ];
      for (var i = 0; i < flow.length - 1; i++) {
        expect(
          GamePhaseMachine.canTransition(flow[i], flow[i + 1]),
          isTrue,
          reason: '${flow[i]} -> ${flow[i + 1]}',
        );
      }
    });

    test('rejects impossible jumps', () {
      expect(
        GamePhaseMachine.canTransition(GamePhase.lobby, GamePhase.reveal),
        isFalse,
      );
      expect(
        GamePhaseMachine.canTransition(GamePhase.setupWhite, GamePhase.playing),
        isFalse,
      );
      expect(
        GamePhaseMachine.canTransition(GamePhase.playing, GamePhase.reveal),
        isFalse,
      );
      expect(
        GamePhaseMachine.canTransition(GamePhase.abandoned, GamePhase.playing),
        isFalse,
      );
      expect(
        () => GamePhaseMachine.transition(GamePhase.lobby, GamePhase.gameOver),
        throwsStateError,
      );
    });
  });

  group('MatchAuthority — normal chess', () {
    late MatchAuthority match;
    setUp(() => match = MatchAuthority(variant: GameVariant.normal)..start());

    test('starts playing from the standard position', () {
      expect(match.phase, GamePhase.playing);
      expect(match.game.fen, ChessGame.standard().fen);
    });

    test('refuses a move out of turn', () {
      expect(
        () => match.play(
          Side.black,
          const NormalMove(from: Square.e7, to: Square.e5),
        ),
        violates(MatchViolation.notYourTurn),
      );
    });

    test('refuses to move the opponent\'s piece', () {
      expect(
        () => match.play(
          Side.white,
          const NormalMove(from: Square.e7, to: Square.e5),
        ),
        violates(MatchViolation.notYourPiece),
      );
    });

    test('refuses an illegal move', () {
      expect(
        () => match.play(
          Side.white,
          const NormalMove(from: Square.e2, to: Square.e5),
        ),
        violates(MatchViolation.illegalMove),
      );
    });

    test('checkmate moves the match to gameOver', () {
      match
        ..play(Side.white, const NormalMove(from: Square.f2, to: Square.f3))
        ..play(Side.black, const NormalMove(from: Square.e7, to: Square.e5))
        ..play(Side.white, const NormalMove(from: Square.g2, to: Square.g4))
        ..play(Side.black, const NormalMove(from: Square.d8, to: Square.h4));
      expect(match.phase, GamePhase.gameOver);
      expect(match.outcome?.winner, Side.black);
      expect(
        () => match.play(
          Side.white,
          const NormalMove(from: Square.a2, to: Square.a3),
        ),
        violates(MatchViolation.wrongPhase),
      );
    });

    test('resignation and draw agreement end the game', () {
      match.resign(Side.white);
      expect(
        match.outcome,
        const GameOutcome(
          winner: Side.black,
          reason: GameEndReason.resignation,
        ),
      );

      final other = MatchAuthority(variant: GameVariant.normal)
        ..start()
        ..agreeDraw();
      expect(other.outcome?.reason, GameEndReason.drawAgreement);
    });

    test('pause blocks moves and resume restores the phase', () {
      match.pause();
      expect(match.phase, GamePhase.paused);
      expect(
        () => match.play(
          Side.white,
          const NormalMove(from: Square.e2, to: Square.e4),
        ),
        violates(MatchViolation.wrongPhase),
      );
      match.resume();
      expect(match.phase, GamePhase.playing);
    });

    test('abandoning a running game gives the win to the other side', () {
      match.abandon(Side.black);
      expect(match.phase, GamePhase.abandoned);
      expect(
        match.outcome,
        const GameOutcome(
          winner: Side.white,
          reason: GameEndReason.abandonment,
        ),
      );
    });

    test('a rematch restarts from the standard position', () {
      match
        ..resign(Side.white)
        ..start();
      expect(match.phase, GamePhase.playing);
      expect(match.outcome, isNull);
      expect(match.game.ply, 0);
    });
  });

  group('MatchAuthority — special chess', () {
    late MatchAuthority match;
    setUp(() => match = MatchAuthority(variant: GameVariant.special)..start());

    test('starts in the setup phase, not playing', () {
      expect(match.phase, GamePhase.setupWhite);
      expect(
        () => match.play(
          Side.white,
          const NormalMove(from: Square.e2, to: Square.e4),
        ),
        violates(MatchViolation.wrongPhase),
      );
    });

    test('armies stay hidden until the reveal', () {
      match.submitArmy(customWhite());
      expect(match.phase, GamePhase.setupBlack);
      expect(match.revealedArmy(Side.white), isNull);
      match.submitArmy(customBlack());
      expect(match.revealedArmy(Side.white), isNull);
      expect(match.revealedArmy(Side.black), isNull);

      match.reveal();
      expect(match.phase, GamePhase.reveal);
      expect(match.revealedArmy(Side.white), customWhite());
      expect(match.revealedArmy(Side.black), customBlack());
    });

    test('cannot reveal before both armies are in', () {
      match.submitArmy(customWhite());
      expect(match.reveal, violates(MatchViolation.wrongPhase));
    });

    test('rejects an invalid army with the list of issues', () {
      expect(
        () => match.submitArmy(customWhite().remove(Square.f2)),
        throwsA(
          isA<MatchRuleException>()
              .having(
                (e) => e.violation,
                'violation',
                MatchViolation.invalidSetup,
              )
              .having((e) => e.issues, 'issues', isNotEmpty),
        ),
      );
      expect(match.hasArmy(Side.white), isFalse);
    });

    test('the battle starts from the custom position', () {
      match
        ..submitArmy(customBlack())
        ..submitArmy(customWhite())
        ..reveal();
      expect(match.completeReveal(), RevealResult.battle);
      expect(match.phase, GamePhase.playing);
      expect(
        match.game.initialFen,
        const SpecialPositionComposer().fen(customWhite(), customBlack()),
      );
      expect(match.game.initialFen, isNot(ChessGame.standard().fen));
      // Standard rules apply from there.
      match.play(Side.white, const NormalMove(from: Square.d4, to: Square.e5));
      expect(match.game.lastMove!.isCapture, isTrue);
    });

    test('a king under fire must be relocated before the battle', () {
      final white = ArmyPlacement.standard(Side.white)
          .move(Square.d1, Square.d4)
          .move(Square.d2, Square.c3);
      final black = ArmyPlacement.standard(Side.black)
          .move(Square.e8, Square.d5);
      match
        ..submitArmy(white)
        ..submitArmy(black)
        ..reveal();
      expect(match.completeReveal(), RevealResult.kingRescue);
      expect(match.phase, GamePhase.kingRescue);
      expect(match.rescueSide, Side.black);
      expect(match.rescueSquares, isNotEmpty);

      // The wrong player, or an unsafe square, is refused.
      expect(
        () => match.relocateKing(Side.white, match.rescueSquares.first),
        violates(MatchViolation.notYourTurn),
      );
      expect(
        () => match.relocateKing(Side.black, Square.d6),
        violates(MatchViolation.invalidKingSquare),
      );

      match.relocateKing(Side.black, Square.e8);
      expect(match.phase, GamePhase.playing);
      expect(match.game.position.board.kingOf(Side.black), Square.e8);
      expect(match.game.isCheck, isFalse);
    });

    test('withdrawing an army returns to that player\'s setup', () {
      match
        ..submitArmy(customWhite())
        ..withdrawArmy(Side.white);
      expect(match.phase, GamePhase.setupWhite);
      expect(match.hasArmy(Side.white), isFalse);
    });
  });

  group('MatchAuthority.restoreBattle', () {
    test('replays a legal snapshot', () {
      final match = MatchAuthority(variant: GameVariant.normal)..start();
      expect(
        match.restoreBattle(
          initialFen: ChessGame.standard().fen,
          uciMoves: ['e2e4', 'e7e5'],
        ),
        isTrue,
      );
      expect(match.game.ply, 2);
    });

    test('refuses a snapshot with an illegal move', () {
      final match = MatchAuthority(variant: GameVariant.normal)..start();
      expect(
        match.restoreBattle(
          initialFen: ChessGame.standard().fen,
          uciMoves: ['e2e5'],
        ),
        isFalse,
      );
      expect(match.game.ply, 0);
    });
  });
}
