import 'dart:math';

import 'package:dartchess/dartchess.dart';

/// Parameters of one search. Plain data so it can cross an isolate boundary.
class SearchRequest {
  const SearchRequest({
    required this.fen,
    required this.maxDepth,
    required this.maxTimeMs,
    this.blunderChance = 0,
    this.evalNoise = 0,
    required this.seed,
  });

  final String fen;
  final int maxDepth;
  final int maxTimeMs;
  final double blunderChance;
  final int evalNoise;
  final int seed;
}

const int _mate = 100000;

const Map<Role, int> _value = {
  Role.pawn: 100,
  Role.knight: 320,
  Role.bishop: 330,
  Role.rook: 500,
  Role.queen: 900,
  Role.king: 0,
};

// Piece-square tables from white's point of view, a1 first.
const List<int> _pawnTable = [
  0, 0, 0, 0, 0, 0, 0, 0, //
  5, 10, 10, -20, -20, 10, 10, 5,
  5, -5, -10, 0, 0, -10, -5, 5,
  0, 0, 0, 20, 20, 0, 0, 0,
  5, 5, 10, 25, 25, 10, 5, 5,
  10, 10, 20, 30, 30, 20, 10, 10,
  50, 50, 50, 50, 50, 50, 50, 50,
  0, 0, 0, 0, 0, 0, 0, 0,
];
const List<int> _knightTable = [
  -50, -40, -30, -30, -30, -30, -40, -50, //
  -40, -20, 0, 5, 5, 0, -20, -40,
  -30, 5, 10, 15, 15, 10, 5, -30,
  -30, 0, 15, 20, 20, 15, 0, -30,
  -30, 5, 15, 20, 20, 15, 5, -30,
  -30, 0, 10, 15, 15, 10, 0, -30,
  -40, -20, 0, 0, 0, 0, -20, -40,
  -50, -40, -30, -30, -30, -30, -40, -50,
];
const List<int> _bishopTable = [
  -20, -10, -10, -10, -10, -10, -10, -20, //
  -10, 5, 0, 0, 0, 0, 5, -10,
  -10, 10, 10, 10, 10, 10, 10, -10,
  -10, 0, 10, 10, 10, 10, 0, -10,
  -10, 5, 5, 10, 10, 5, 5, -10,
  -10, 0, 5, 10, 10, 5, 0, -10,
  -10, 0, 0, 0, 0, 0, 0, -10,
  -20, -10, -10, -10, -10, -10, -10, -20,
];
const List<int> _rookTable = [
  0, 0, 0, 5, 5, 0, 0, 0, //
  -5, 0, 0, 0, 0, 0, 0, -5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  5, 10, 10, 10, 10, 10, 10, 5,
  0, 0, 0, 0, 0, 0, 0, 0,
];
const List<int> _queenTable = [
  -20, -10, -10, -5, -5, -10, -10, -20, //
  -10, 0, 5, 0, 0, 0, 0, -10,
  -10, 5, 5, 5, 5, 5, 0, -10,
  0, 0, 5, 5, 5, 5, 0, -5,
  -5, 0, 5, 5, 5, 5, 0, -5,
  -10, 0, 5, 5, 5, 5, 0, -10,
  -10, 0, 0, 0, 0, 0, 0, -10,
  -20, -10, -10, -5, -5, -10, -10, -20,
];
const List<int> _kingTable = [
  20, 30, 10, 0, 0, 10, 30, 20, //
  20, 20, 0, 0, 0, 0, 20, 20,
  -10, -20, -20, -20, -20, -20, -20, -10,
  -20, -30, -30, -40, -40, -30, -30, -20,
  -30, -40, -40, -50, -50, -40, -40, -30,
  -30, -40, -40, -50, -50, -40, -40, -30,
  -30, -40, -40, -50, -50, -40, -40, -30,
  -30, -40, -40, -50, -50, -40, -40, -30,
];

const Map<Role, List<int>> _tables = {
  Role.pawn: _pawnTable,
  Role.knight: _knightTable,
  Role.bishop: _bishopTable,
  Role.rook: _rookTable,
  Role.queen: _queenTable,
  Role.king: _kingTable,
};

class _Timeout implements Exception {
  const _Timeout();
}

/// Static evaluation in centipawns from white's point of view.
int evaluateBoard(Board board) {
  var score = 0;
  for (final (square, piece) in board.pieces) {
    final table = _tables[piece.role]!;
    if (piece.color == Side.white) {
      score += _value[piece.role]! + table[square];
    } else {
      score -= _value[piece.role]! + table[square ^ 56];
    }
  }
  return score;
}

List<NormalMove> _moves(Position pos) {
  final captures = <(int, NormalMove)>[];
  final quiet = <NormalMove>[];
  final board = pos.board;
  for (final entry in pos.legalMoves.entries) {
    final from = entry.key;
    final role = board.roleAt(from)!;
    for (final to in entry.value.squares) {
      final victim = board.pieceAt(to);
      final promotes = role == Role.pawn && (to.rank == 7 || to.rank == 0);
      if (promotes) {
        captures.add((
          900,
          NormalMove(from: from, to: to, promotion: Role.queen),
        ));
        quiet.add(NormalMove(from: from, to: to, promotion: Role.knight));
      } else if (victim != null && victim.color != pos.turn) {
        // Most valuable victim, least valuable attacker first.
        captures.add((
          _value[victim.role]! * 10 - _value[role]!,
          NormalMove(from: from, to: to),
        ));
      } else {
        quiet.add(NormalMove(from: from, to: to));
      }
    }
  }
  captures.sort((a, b) => b.$1.compareTo(a.$1));
  return [for (final c in captures) c.$2, ...quiet];
}

class _Searcher {
  _Searcher(this.deadline);

  final Stopwatch clock = Stopwatch()..start();
  final int deadline;
  int nodes = 0;

  void _tick() {
    if ((++nodes & 511) == 0 && clock.elapsedMilliseconds > deadline) {
      throw const _Timeout();
    }
  }

  int _relative(Position pos) {
    final score = evaluateBoard(pos.board);
    return pos.turn == Side.white ? score : -score;
  }

  int quiesce(Position pos, int alpha, int beta, int depth) {
    _tick();
    final stand = _relative(pos);
    if (depth == 0) return stand;
    if (stand >= beta) return beta;
    if (stand > alpha) alpha = stand;
    final board = pos.board;
    for (final move in _moves(pos)) {
      final victim = board.pieceAt(move.to);
      if (move.promotion == null &&
          (victim == null || victim.color == pos.turn)) {
        continue;
      }
      final score = -quiesce(pos.playUnchecked(move), -beta, -alpha, depth - 1);
      if (score >= beta) return beta;
      if (score > alpha) alpha = score;
    }
    return alpha;
  }

  int negamax(Position pos, int depth, int alpha, int beta, int ply) {
    _tick();
    final moves = _moves(pos);
    if (moves.isEmpty) return pos.isCheck ? -_mate + ply : 0;
    if (pos.halfmoves >= 100 || pos.isInsufficientMaterial) return 0;
    if (depth == 0) return quiesce(pos, alpha, beta, 4);
    var best = -_mate * 2;
    for (final move in moves) {
      final score = -negamax(
        pos.playUnchecked(move),
        depth - 1,
        -beta,
        -alpha,
        ply + 1,
      );
      if (score > best) best = score;
      if (best > alpha) alpha = best;
      if (alpha >= beta) break;
    }
    return best;
  }
}

/// Iterative-deepening alpha-beta search. Top-level so it can run in an
/// isolate. Returns the chosen move in UCI, or `null` when there is no move.
String? searchBestMove(SearchRequest request) {
  final pos = Chess.fromSetup(
    Setup.parseFen(request.fen),
    ignoreImpossibleCheck: true,
  );
  final moves = _moves(pos);
  if (moves.isEmpty) return null;
  final random = Random(request.seed);

  if (request.blunderChance > 0 &&
      random.nextDouble() < request.blunderChance) {
    return moves[random.nextInt(moves.length)].uci;
  }

  final searcher = _Searcher(request.maxTimeMs);
  var bestMove = moves.first;
  try {
    for (var depth = 1; depth <= request.maxDepth; depth++) {
      var bestScore = -_mate * 2;
      NormalMove? candidate;
      // The window stays fully open at the root so every move gets an exact
      // score: that is what the random noise is applied to.
      for (final move in moves) {
        var score = -searcher.negamax(
          pos.playUnchecked(move),
          depth - 1,
          -_mate * 2,
          _mate * 2,
          1,
        );
        if (request.evalNoise > 0 && score.abs() < _mate - 1000) {
          score +=
              random.nextInt(request.evalNoise * 2 + 1) - request.evalNoise;
        }
        if (score > bestScore) {
          bestScore = score;
          candidate = move;
        }
      }
      if (candidate != null) {
        bestMove = candidate;
        moves
          ..remove(candidate)
          ..insert(0, candidate);
      }
      if (bestScore.abs() >= _mate - 1000) break;
    }
  } on _Timeout {
    // Keep the best move of the last fully searched depth.
  }
  return bestMove.uci;
}
