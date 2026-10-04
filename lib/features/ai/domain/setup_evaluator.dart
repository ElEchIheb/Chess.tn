import 'package:dartchess/dartchess.dart';

import '../../special_mode/domain/army_placement.dart';

/// Heuristic score of one army arrangement, judged **in isolation**.
///
/// The evaluator only ever receives a single [ArmyPlacement]: it has no way
/// to look at the opponent, which is what keeps the Special mode fair.
///
/// Scores king safety, pawn structure, piece activity, control of the
/// centre, development and how exposed valuable pieces are on the front
/// line (the enemy army starts right across the middle of the board).
class SetupEvaluator {
  const SetupEvaluator();

  static const Map<Role, int> _worth = {
    Role.pawn: 1,
    Role.knight: 3,
    Role.bishop: 3,
    Role.rook: 5,
    Role.queen: 9,
    Role.king: 0,
  };

  static final SquareSet _center = SquareSet.fromSquares(const [
    Square.d4,
    Square.e4,
    Square.d5,
    Square.e5,
  ]);
  static final SquareSet _wideCenter = SquareSet.fromSquares(const [
    Square.c3, Square.d3, Square.e3, Square.f3, //
    Square.c4, Square.f4, Square.c5, Square.f5,
    Square.c6, Square.d6, Square.e6, Square.f6,
  ]);

  double score(ArmyPlacement army) {
    // Work from white's point of view: mirror a black army vertically.
    final pieces = <Square, Role>{
      for (final e in army.pieces.entries)
        (army.side == Side.white ? e.key : Square(e.key ^ 56)): e.value,
    };
    var board = Board.empty;
    pieces.forEach((square, role) {
      board = board.setPieceAt(square, Piece(color: Side.white, role: role));
    });
    final occupied = board.occupied;

    var total = 0.0;
    total += _kingSafety(pieces, board);
    total += _pawnStructure(pieces, board);

    final bishopColors = <bool>{};
    for (final entry in pieces.entries) {
      final square = entry.key;
      final role = entry.value;
      if (role == Role.pawn || role == Role.king) continue;
      final rank = square.rank.value;
      final worth = _worth[role]!;

      // A piece on the front rank can be hit by an enemy pawn immediately.
      if (rank == 3) total -= 7.0 * worth;
      if (rank == 2) total -= 1.5 * worth;

      final defended = board.attacksTo(square, Side.white).isNotEmpty;
      if (defended) {
        total += 5;
      } else if (rank >= 2) {
        total -= 4.0 * worth;
      }

      final reach = attacks(
        Piece(color: Side.white, role: role),
        square,
        occupied,
      ).diff(occupied);
      final mobilityWeight = switch (role) {
        Role.knight => 3.0,
        Role.bishop => 2.5,
        Role.rook => 1.5,
        _ => 0.8,
      };
      total += mobilityWeight * reach.size;
      total += 6.0 * reach.intersect(_center).size;
      total += 2.0 * reach.intersect(_wideCenter).size;

      if (role == Role.knight && (square.file == 0 || square.file == 7)) {
        total -= 10;
      }
      if (role == Role.rook) {
        final ahead = SquareSet.fromFile(square.file)
            .intersect(board.pawns)
            .squares
            .any((s) => s.rank > square.rank);
        if (!ahead) total += 12;
      }
      if (role == Role.bishop) {
        bishopColors.add(SquareSet.lightSquares.has(square));
      }
    }
    if (bishopColors.length == 2) total += 25;

    // Keeping the right to castle is a small extra.
    if (pieces[Square.e1] == Role.king &&
        (pieces[Square.a1] == Role.rook || pieces[Square.h1] == Role.rook)) {
      total += 8;
    }
    return total;
  }

  double _kingSafety(Map<Square, Role> pieces, Board board) {
    final king = board.kingOf(Side.white);
    if (king == null) return -1000;
    const rankPenalty = [0.0, 70.0, 170.0, 280.0];
    var total = -rankPenalty[king.rank.value.clamp(0, 3)];

    // Corners are easier to defend than the centre.
    total += 5.0 * (king.file.value - 3.5).abs();

    // Shield: own men on the three squares in front of the king.
    for (final df in [-1, 0, 1]) {
      final file = king.file.value + df;
      if (file < 0 || file > 7 || king.rank.value >= 7) continue;
      final front = Square.fromCoords(File(file), Rank(king.rank.value + 1));
      final role = pieces[front];
      if (role == Role.pawn) {
        total += 18;
      } else if (role != null) {
        total += 8;
      } else {
        total -= 14;
      }
    }

    // Lines the enemy could use: open file or diagonals towards the king.
    for (final delta in [8, 7, 9]) {
      var blocked = false;
      Square? cursor = king;
      while (true) {
        final from = cursor!;
        cursor = from.offset(delta);
        if (cursor == null || (cursor.file - from.file).abs() > 1) break;
        if (pieces.containsKey(cursor)) {
          blocked = true;
          break;
        }
        if (cursor.rank.value >= 3) break;
      }
      if (!blocked) total -= 35;
    }
    return total;
  }

  double _pawnStructure(Map<Square, Role> pieces, Board board) {
    var total = 0.0;
    final perFile = List<int>.filled(8, 0);
    for (final square in board.pawns.squares) {
      perFile[square.file]++;
    }
    for (final square in board.pawns.squares) {
      final file = square.file.value;
      final rank = square.rank.value;
      if (perFile[file] > 1) total -= 7;
      final left = file > 0 ? perFile[file - 1] : 0;
      final right = file < 7 ? perFile[file + 1] : 0;
      if (left + right == 0) total -= 8;

      final central = file >= 2 && file <= 5;
      if (central && rank == 2) total += 10;
      if (central && rank == 3) total += 12;
      if (!central && rank == 1) total += 4;

      final protectedByPawn = pawnAttacks(
        Side.black,
        square,
      ).intersect(board.pawns).isNotEmpty;
      if (protectedByPawn) {
        total += 7;
      } else if (rank == 3) {
        total -= 10;
      }
    }
    return total;
  }
}
