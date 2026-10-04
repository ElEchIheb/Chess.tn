import 'package:dartchess/dartchess.dart';

import 'army_placement.dart';

/// Turns two private armies into one chess position / FEN.
class SpecialPositionComposer {
  const SpecialPositionComposer();

  Board board(ArmyPlacement white, ArmyPlacement black) {
    var board = Board.empty;
    for (final army in [white, black]) {
      for (final entry in army.pieces.entries) {
        board = board.setPieceAt(
          entry.key,
          Piece(color: army.side, role: entry.value),
        );
      }
    }
    return board;
  }

  /// Castling is available only when king and rook stand on their classical
  /// squares, exactly like in a normal game.
  SquareSet castlingRights(ArmyPlacement white, ArmyPlacement black) {
    var rights = SquareSet.empty;
    void check(ArmyPlacement army, Square king, Square rookA, Square rookH) {
      if (army.roleAt(king) != Role.king) return;
      if (army.roleAt(rookA) == Role.rook) rights = rights.withSquare(rookA);
      if (army.roleAt(rookH) == Role.rook) rights = rights.withSquare(rookH);
    }

    check(white, Square.e1, Square.a1, Square.h1);
    check(black, Square.e8, Square.a8, Square.h8);
    return rights;
  }

  Setup setup(ArmyPlacement white, ArmyPlacement black) => Setup(
    board: board(white, black),
    turn: Side.white,
    castlingRights: castlingRights(white, black),
    halfmoves: 0,
    fullmoves: 1,
  );

  String fen(ArmyPlacement white, ArmyPlacement black) =>
      setup(white, black).fen;

  /// Builds a playable position. Throws [PositionSetupException] when the
  /// combined armies do not form a legal chess position.
  Position position(ArmyPlacement white, ArmyPlacement black) =>
      Chess.fromSetup(setup(white, black), ignoreImpossibleCheck: true);
}
