import 'package:chess_tn/features/chess/domain/chess_game.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

ChessGame playAll(ChessGame game, List<String> ucis) {
  for (final uci in ucis) {
    final next = game.tryPlayUci(uci);
    expect(next, isNotNull, reason: 'move $uci should be legal');
    game = next!;
  }
  return game;
}

void main() {
  group('ChessGame', () {
    test('normal mode starts from the standard position', () {
      final game = ChessGame.standard();
      expect(
        game.fen,
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );
      expect(game.turn, Side.white);
      expect(game.outcome, isNull);
    });

    test('pieces move legally and illegal moves are rejected', () {
      var game = ChessGame.standard();
      expect(game.legalDestinations(Square.e2), {Square.e3, Square.e4});
      expect(game.legalDestinations(Square.g1), {Square.f3, Square.h3});
      expect(
        game.legalDestinations(Square.e7),
        isEmpty,
        reason: 'not black to move',
      );
      expect(game.tryPlayUci('e2e5'), isNull);
      expect(
        () => game.play(const NormalMove(from: Square.a1, to: Square.a5)),
        throwsA(isA<PlayException>()),
      );
      game = playAll(game, ['e2e4', 'e7e5', 'g1f3']);
      expect(game.ply, 3);
      expect(game.lastMove!.san, 'Nf3');
    });

    test('check is detected', () {
      final game = playAll(ChessGame.standard(), ['e2e4', 'f7f6', 'd1h5']);
      expect(game.isCheck, isTrue);
      expect(game.lastMove!.givesCheck, isTrue);
      expect(game.outcome, isNull);
    });

    test('checkmate ends the game (fool\'s mate)', () {
      final game = playAll(ChessGame.standard(), [
        'f2f3',
        'e7e5',
        'g2g4',
        'd8h4',
      ]);
      expect(
        game.outcome,
        const GameOutcome(winner: Side.black, reason: GameEndReason.checkmate),
      );
    });

    test('stalemate is a draw', () {
      final game = playAll(
        ChessGame.fromFen('7k/5K2/8/6Q1/8/8/8/8 w - - 0 1'),
        ['g5g6'],
      );
      expect(
        game.outcome,
        const GameOutcome(winner: null, reason: GameEndReason.stalemate),
      );
    });

    test('promotion replaces the pawn', () {
      var game = ChessGame.fromFen('8/4P3/8/8/8/8/k7/4K3 w - - 0 1');
      expect(game.isPromotionMove(Square.e7, Square.e8), isTrue);
      game = game.play(
        const NormalMove(from: Square.e7, to: Square.e8, promotion: Role.rook),
      );
      expect(game.position.board.pieceAt(Square.e8), Piece.whiteRook);
      expect(game.lastMove!.isPromotion, isTrue);
      expect(game.lastMove!.uci, 'e7e8r');
    });

    test('castling works on both wings and moves the rook', () {
      var game = ChessGame.fromFen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
      expect(
        game.legalDestinations(Square.e1),
        containsAll([Square.g1, Square.c1]),
      );
      game = game.play(const NormalMove(from: Square.e1, to: Square.g1));
      expect(game.lastMove!.isCastle, isTrue);
      expect(game.lastMove!.rookFrom, Square.h1);
      expect(game.lastMove!.rookTo, Square.f1);
      expect(game.lastMove!.uci, 'e1g1');
      expect(game.position.board.pieceAt(Square.f1), Piece.whiteRook);
      game = game.play(const NormalMove(from: Square.e8, to: Square.c8));
      expect(game.position.board.pieceAt(Square.d8), Piece.blackRook);
      expect(game.position.board.pieceAt(Square.c8), Piece.blackKing);
    });

    test('castling is refused through check', () {
      final game = ChessGame.fromFen('4kr2/8/8/8/8/8/8/R3K2R w KQ - 0 1');
      expect(game.legalDestinations(Square.e1), isNot(contains(Square.g1)));
      expect(game.legalDestinations(Square.e1), contains(Square.c1));
    });

    test('en passant captures the pawn beside', () {
      var game = playAll(ChessGame.standard(), [
        'e2e4',
        'a7a6',
        'e4e5',
        'd7d5',
      ]);
      expect(game.legalDestinations(Square.e5), contains(Square.d6));
      game = playAll(game, ['e5d6']);
      expect(game.lastMove!.isCapture, isTrue);
      expect(game.lastMove!.capturedSquare, Square.d5);
      expect(game.position.board.pieceAt(Square.d5), isNull);
      expect(game.capturedBy(Side.white), [Piece.blackPawn]);
    });

    test('threefold repetition is a draw', () {
      final game = playAll(ChessGame.standard(), [
        'g1f3', 'g8f6', 'f3g1', 'f6g8', //
        'g1f3', 'g8f6', 'f3g1', 'f6g8',
      ]);
      expect(game.outcome?.reason, GameEndReason.threefoldRepetition);
    });

    test('fifty-move rule is a draw', () {
      final game = playAll(
        ChessGame.fromFen('7k/8/8/8/8/8/R7/K7 w - - 99 80'),
        ['a2b2'],
      );
      expect(game.outcome?.reason, GameEndReason.fiftyMoveRule);
    });

    test('insufficient material is a draw', () {
      final game = playAll(ChessGame.fromFen('7k/8/8/8/8/8/1p6/K7 w - - 0 1'), [
        'a1b2',
      ]);
      expect(game.outcome?.reason, GameEndReason.insufficientMaterial);
    });

    test('undo restores the previous position', () {
      final start = ChessGame.standard();
      final game = playAll(start, ['e2e4', 'e7e5', 'g1f3']);
      final back = game.undo(2);
      expect(back.ply, 1);
      expect(back.fen, playAll(start, ['e2e4']).fen);
      expect(game.undo(10).fen, start.fen);
    });
  });
}
