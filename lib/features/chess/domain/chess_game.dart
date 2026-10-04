import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

enum GameEndReason {
  checkmate,
  stalemate,
  insufficientMaterial,
  threefoldRepetition,
  fiftyMoveRule,
  resignation,
  drawAgreement,
  abandonment,
}

@immutable
class GameOutcome {
  const GameOutcome({required this.winner, required this.reason});

  /// `null` means a draw.
  final Side? winner;
  final GameEndReason reason;

  bool get isDraw => winner == null;

  @override
  bool operator ==(Object other) =>
      other is GameOutcome && other.winner == winner && other.reason == reason;

  @override
  int get hashCode => Object.hash(winner, reason);

  @override
  String toString() => 'GameOutcome(${winner?.name ?? 'draw'}, ${reason.name})';
}

/// Everything the UI and the network need to know about one played move.
@immutable
class MoveRecord {
  const MoveRecord({
    required this.move,
    required this.uci,
    required this.san,
    required this.piece,
    required this.from,
    required this.to,
    this.captured,
    this.capturedSquare,
    this.rookFrom,
    this.rookTo,
    required this.givesCheck,
  });

  final NormalMove move;

  /// Standard UCI (castling as `e1g1`), understood by Stockfish.
  final String uci;
  final String san;
  final Piece piece;
  final Square from;

  /// Square the moved piece ends on (king destination when castling).
  final Square to;
  final Piece? captured;
  final Square? capturedSquare;
  final Square? rookFrom;
  final Square? rookTo;
  final bool givesCheck;

  bool get isCapture => captured != null;
  bool get isCastle => rookFrom != null;
  bool get isPromotion => move.promotion != null;
}

/// Immutable chess game: a start position plus the moves played from it.
///
/// Wraps `dartchess` and adds what a full game needs on top of a single
/// position: history, undo, threefold repetition and the fifty-move rule.
@immutable
class ChessGame {
  const ChessGame._(
    this.initialPosition,
    this._positions,
    this.history,
    this._hashes,
  );

  factory ChessGame.standard() => ChessGame.fromPosition(Chess.initial);

  /// Throws [FenException] / [PositionSetupException] on invalid input.
  factory ChessGame.fromFen(String fen) =>
      ChessGame.fromPosition(Chess.fromSetup(Setup.parseFen(fen)));

  factory ChessGame.fromPosition(Position position) =>
      ChessGame._(position, const [], const [], [position.zobristHash()]);

  final Position initialPosition;
  final List<Position> _positions;
  final List<MoveRecord> history;
  final List<int> _hashes;

  Position get position =>
      _positions.isEmpty ? initialPosition : _positions.last;

  String get fen => position.fen;
  String get initialFen => initialPosition.fen;
  Side get turn => position.turn;
  int get ply => history.length;
  MoveRecord? get lastMove => history.isEmpty ? null : history.last;
  bool get isCheck => position.isCheck;

  /// Number of full moves played (for the result screen).
  int get fullMoves => (history.length + 1) ~/ 2;

  List<String> get uciMoves => [for (final r in history) r.uci];

  bool get isThreefoldRepetition {
    final current = _hashes.last;
    var count = 0;
    for (final h in _hashes) {
      if (h == current) count++;
    }
    return count >= 3;
  }

  bool get isFiftyMoveRule => position.halfmoves >= 100;

  /// Outcome decided by the rules of chess, or `null` while the game goes on.
  GameOutcome? get outcome {
    final pos = position;
    if (pos.isCheckmate) {
      return GameOutcome(
        winner: pos.turn.opposite,
        reason: GameEndReason.checkmate,
      );
    }
    if (pos.isStalemate) {
      return const GameOutcome(winner: null, reason: GameEndReason.stalemate);
    }
    if (pos.isInsufficientMaterial) {
      return const GameOutcome(
        winner: null,
        reason: GameEndReason.insufficientMaterial,
      );
    }
    if (isThreefoldRepetition) {
      return const GameOutcome(
        winner: null,
        reason: GameEndReason.threefoldRepetition,
      );
    }
    if (isFiftyMoveRule) {
      return const GameOutcome(
        winner: null,
        reason: GameEndReason.fiftyMoveRule,
      );
    }
    return null;
  }

  /// Legal destinations for the piece on [square], with castling exposed as
  /// the usual two-square king move.
  Set<Square> legalDestinations(Square square) {
    final pos = position;
    final piece = pos.board.pieceAt(square);
    if (piece == null || piece.color != pos.turn) return const {};
    final result = <Square>{};
    for (final dest in pos.legalMovesOf(square).squares) {
      final target = pos.board.pieceAt(dest);
      if (piece.role == Role.king && target?.color == piece.color) {
        result.add(_castledKingSquare(square, dest));
      } else {
        result.add(dest);
      }
    }
    return result;
  }

  bool isLegal(NormalMove move) => position.isLegal(move);

  /// Whether moving from [from] to [to] is a pawn reaching the last rank.
  bool isPromotionMove(Square from, Square to) {
    final piece = position.board.pieceAt(from);
    return piece != null &&
        piece.role == Role.pawn &&
        (to.rank == Rank.eighth || to.rank == Rank.first);
  }

  /// Plays [move]. Throws [PlayException] if it is not legal.
  ChessGame play(NormalMove move) {
    final pos = position;
    if (!pos.isLegal(move)) {
      throw PlayException('Illegal move ${move.uci} on ${pos.fen}');
    }
    final piece = pos.board.pieceAt(move.from)!;
    final target = pos.board.pieceAt(move.to);
    final isCastle =
        piece.role == Role.king &&
        (target?.color == piece.color ||
            (move.to.file - move.from.file).abs() == 2);

    var to = move.to;
    Square? rookFrom;
    Square? rookTo;
    Piece? captured;
    Square? capturedSquare;

    if (isCastle) {
      final kingSide = move.to.file > move.from.file;
      rookFrom = pos.castles.rookOf(
        piece.color,
        kingSide ? CastlingSide.king : CastlingSide.queen,
      );
      to = Square.fromCoords(kingSide ? File.g : File.c, move.from.rank);
      rookTo = Square.fromCoords(kingSide ? File.f : File.d, move.from.rank);
    } else if (target != null) {
      captured = target;
      capturedSquare = move.to;
    } else if (piece.role == Role.pawn && move.from.file != move.to.file) {
      // En passant: the captured pawn is beside the origin square.
      capturedSquare = Square.fromCoords(move.to.file, move.from.rank);
      captured = pos.board.pieceAt(capturedSquare);
    }

    final (next, san) = pos.makeSan(move);
    final promotion = move.promotion;
    final record = MoveRecord(
      move: move,
      uci: '${move.from.name}${to.name}${promotion?.letter ?? ''}',
      san: san,
      piece: piece,
      from: move.from,
      to: to,
      captured: captured,
      capturedSquare: capturedSquare,
      rookFrom: rookFrom,
      rookTo: rookTo,
      givesCheck: next.isCheck,
    );
    return ChessGame._(
      initialPosition,
      List.unmodifiable([..._positions, next]),
      List.unmodifiable([...history, record]),
      List.unmodifiable([..._hashes, next.zobristHash()]),
    );
  }

  /// Plays a move given in UCI notation, or returns `null` if it is illegal.
  ChessGame? tryPlayUci(String uci) {
    final move = Move.parse(uci);
    if (move is! NormalMove || !position.isLegal(move)) return null;
    return play(move);
  }

  /// Takes back the last [plies] half-moves.
  ChessGame undo([int plies = 1]) {
    final keep = (history.length - plies).clamp(0, history.length);
    return ChessGame._(
      initialPosition,
      List.unmodifiable(_positions.take(keep)),
      List.unmodifiable(history.take(keep)),
      List.unmodifiable(_hashes.take(keep + 1)),
    );
  }

  /// Pieces captured so far *by* [side].
  List<Piece> capturedBy(Side side) => [
    for (final r in history)
      if (r.captured != null && r.piece.color == side) r.captured!,
  ];

  static Square _castledKingSquare(Square king, Square rook) =>
      Square.fromCoords(rook.file > king.file ? File.g : File.c, king.rank);
}
