import 'package:chess_tn/features/chess/domain/chess_game.dart';
import 'package:chess_tn/features/special_mode/domain/army_placement.dart';
import 'package:chess_tn/features/special_mode/domain/king_rescue.dart';
import 'package:chess_tn/features/special_mode/domain/setup_commitment.dart';
import 'package:chess_tn/features/special_mode/domain/special_position_composer.dart';
import 'package:chess_tn/features/special_mode/domain/special_position_validator.dart';
import 'package:chess_tn/features/special_mode/domain/special_rules.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/armies.dart';

void main() {
  const rules = SpecialRules();
  const validator = SpecialPositionValidator();
  const composer = SpecialPositionComposer();

  group('SpecialRules', () {
    test('each player owns their first four ranks', () {
      expect(rules.inZone(Side.white, Square.a1), isTrue);
      expect(rules.inZone(Side.white, Square.h4), isTrue);
      expect(rules.inZone(Side.white, Square.a5), isFalse);
      expect(rules.inZone(Side.black, Square.a8), isTrue);
      expect(rules.inZone(Side.black, Square.h5), isTrue);
      expect(rules.inZone(Side.black, Square.h4), isFalse);
      expect(rules.zoneSquares(Side.white).length, 32);
      expect(rules.armySize, 16);
    });

    test('pawns are not allowed on the back rank', () {
      expect(rules.allows(Side.white, Role.pawn, Square.c1), isFalse);
      expect(rules.allows(Side.white, Role.pawn, Square.c2), isTrue);
      expect(rules.allows(Side.black, Role.pawn, Square.c8), isFalse);
      expect(rules.allows(Side.black, Role.rook, Square.c8), isTrue);
    });
  });

  group('SpecialPositionValidator', () {
    test('a full army inside the zone is valid', () {
      expect(validator.validateArmy(customWhite()), isEmpty);
      expect(validator.validateArmy(customBlack()), isEmpty);
      expect(
        validator.validateArmy(ArmyPlacement.standard(Side.white)),
        isEmpty,
      );
    });

    test('an incomplete army is reported', () {
      final army = customWhite().remove(Square.f2);
      expect(validator.validateArmy(army), [SetupIssue.missingPieces]);
      expect(validator.remaining(army, Role.pawn), 1);
      expect(validator.isComplete(army), isFalse);
    });

    test('a missing king is reported', () {
      final king = customWhite().kingSquare!;
      expect(
        validator.validateArmy(customWhite().remove(king)),
        containsAll([SetupIssue.kingCount, SetupIssue.missingPieces]),
      );
    });

    test('extra pieces are rejected', () {
      // A second queen instead of a pawn.
      final army = customWhite().place(Square.f2, Role.queen);
      expect(
        validator.validateArmy(army),
        containsAll([SetupIssue.wrongPieceCount, SetupIssue.missingPieces]),
      );
      final twoKings = customWhite().place(Square.f2, Role.king);
      expect(validator.validateArmy(twoKings), contains(SetupIssue.kingCount));
    });

    test('pieces outside the zone are rejected', () {
      final army = customWhite().move(Square.f2, Square.b5);
      expect(validator.validateArmy(army), [SetupIssue.outsideZone]);
    });

    test('a pawn on the back rank is rejected', () {
      final army = customWhite().move(Square.f2, Square.e1);
      expect(validator.validateArmy(army), contains(SetupIssue.pawnOnBackRank));
    });

    test('piece counts are exactly one army', () {
      final army = customWhite();
      expect(army.countOf(Role.king), 1);
      expect(army.countOf(Role.queen), 1);
      expect(army.countOf(Role.rook), 2);
      expect(army.countOf(Role.bishop), 2);
      expect(army.countOf(Role.knight), 2);
      expect(army.countOf(Role.pawn), 8);
      expect(army.total, 16);
    });
  });

  group('SpecialPositionComposer', () {
    test('generates the FEN of the custom position', () {
      final fen = composer.fen(customWhite(), customBlack());
      expect(
        fen,
        '1k1r1r2/pppqbb2/2nn1ppp/4pp2/3PP3/PPP1NN2/2BBQPPP/2R1R1K1 w - - 0 1',
      );
      final game = ChessGame.fromFen(fen);
      expect(game.turn, Side.white);
      expect(game.outcome, isNull);
    });

    test('two classical armies give the standard position, with castling', () {
      final fen = composer.fen(
        ArmyPlacement.standard(Side.white),
        ArmyPlacement.standard(Side.black),
      );
      expect(fen, 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
    });

    test('castling rights exist only for classical king and rook squares', () {
      final white = ArmyPlacement.standard(Side.white)
          .move(Square.a1, Square.a3);
      final rights = composer.castlingRights(white, customBlack());
      expect(rights.has(Square.h1), isTrue);
      expect(rights.has(Square.a1), isFalse);
      expect(rights.has(Square.a8), isFalse);
    });

    test('the combined position is playable', () {
      final check = validator.validateCombined(customWhite(), customBlack());
      expect(check.kingsInCheck, isEmpty);
      expect(check.playable, isTrue);
    });
  });

  group('KingRescueResolver', () {
    const resolver = KingRescueResolver();

    test('detects a king under fire at reveal and offers safe squares', () {
      // A white queen on d4 stands right next to a black king on d5.
      final white = ArmyPlacement.standard(Side.white)
          .move(Square.d1, Square.d4)
          .move(Square.d2, Square.c3);
      final black = ArmyPlacement.standard(Side.black)
          .move(Square.e8, Square.d5);
      expect(validator.kingsInCheck(white, black), {Side.black});
      expect(resolver.nextToRescue(white, black), Side.black);

      final safe = resolver.safeSquares(Side.black, white, black);
      expect(safe, isNotEmpty);
      for (final square in safe) {
        expect(rules.inZone(Side.black, square), isTrue);
        expect(
          validator.kingsInCheck(white, black.withKingAt(square)),
          isEmpty,
        );
      }
    });

    test('no rescue needed for quiet positions', () {
      expect(resolver.nextToRescue(customWhite(), customBlack()), isNull);
    });
  });

  group('SetupCommitment', () {
    test('verifies the committed army and nothing else', () {
      final army = customWhite();
      final salt = SetupCommitment.generateSalt();
      final commitment = SetupCommitment.commit(army, salt);
      expect(SetupCommitment.verify(army, salt, commitment), isTrue);
      expect(
        SetupCommitment.verify(
          army.move(Square.f2, Square.b4),
          salt,
          commitment,
        ),
        isFalse,
      );
      expect(SetupCommitment.verify(army, 'other-salt', commitment), isFalse);
    });

    test('the commitment does not contain the coordinates', () {
      final commitment = SetupCommitment.commit(customWhite(), 'salt');
      expect(commitment, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('equal armies hash equally whatever the insertion order', () {
      final a = ArmyPlacement(Side.white, {
        Square.a1: Role.rook,
        Square.b1: Role.king,
      });
      final b = ArmyPlacement(Side.white, {
        Square.b1: Role.king,
        Square.a1: Role.rook,
      });
      expect(a, b);
      expect(SetupCommitment.commit(a, 's'), SetupCommitment.commit(b, 's'));
    });
  });

  group('ArmyPlacement JSON', () {
    test('round-trips', () {
      final army = customBlack();
      expect(ArmyPlacement.fromJson(Side.black, army.toJson()), army);
    });

    test('rejects malformed input', () {
      expect(
        () => ArmyPlacement.fromJson(Side.white, 'nope'),
        throwsFormatException,
      );
      expect(
        () => ArmyPlacement.fromJson(Side.white, {'z9': 'k'}),
        throwsFormatException,
      );
      expect(
        () => ArmyPlacement.fromJson(Side.white, {'a1': 'x'}),
        throwsFormatException,
      );
      expect(
        () => ArmyPlacement.fromJson(Side.white, {'a1': 5}),
        throwsFormatException,
      );
    });
  });
}
