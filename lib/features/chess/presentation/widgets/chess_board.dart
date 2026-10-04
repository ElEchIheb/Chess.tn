import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/board_theme.dart';
import '../../domain/chess_game.dart';
import 'board_painter.dart';
import 'chess_piece.dart';

/// The chess board: tap-to-move, drag-and-drop, legal move hints, last move
/// and check highlights, sliding pieces and fading captures.
///
/// It is a pure view: it shows [pieces] and reports what the player tried
/// to do. Legality comes from [legalDestinations].
class ChessBoard extends StatefulWidget {
  const ChessBoard({
    super.key,
    required this.pieces,
    required this.orientation,
    required this.boardTheme,
    required this.pieceTheme,
    this.lastMove,
    this.ply = 0,
    this.checkSquare,
    this.matedKing,
    this.interactiveSide,
    this.legalDestinations,
    this.onMove,
    this.goldSquares = const {},
    this.onGoldSquareTap,
    this.showLegalMoves = true,
    this.animate = true,
  });

  final Map<Square, Piece> pieces;
  final Side orientation;
  final BoardTheme boardTheme;
  final PieceTheme pieceTheme;
  final MoveRecord? lastMove;

  /// Number of half-moves played; drives the move animation.
  final int ply;
  final Square? checkSquare;
  final Square? matedKing;

  /// Side whose pieces can be picked up right now, or `null`.
  final Side? interactiveSide;
  final Set<Square> Function(Square from)? legalDestinations;
  final void Function(Square from, Square to, {required bool dragged})? onMove;

  /// Squares highlighted in gold and tappable (king rescue).
  final Set<Square> goldSquares;
  final void Function(Square square)? onGoldSquareTap;
  final bool showLegalMoves;
  final bool animate;

  @override
  State<ChessBoard> createState() => _ChessBoardState();
}

class _ChessBoardState extends State<ChessBoard> {
  static const Duration _slide = Duration(milliseconds: 190);

  Square? _selected;
  Square? _dragFrom;
  final ValueNotifier<Offset?> _dragPosition = ValueNotifier(null);

  /// Ply reached by a new move that should slide into place.
  int _slidePly = -1;

  /// Ply of a move made by dragging: the piece is already there.
  int _droppedPly = -1;

  @override
  void didUpdateWidget(ChessBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ply != oldWidget.ply) {
      _slidePly = widget.ply == oldWidget.ply + 1 && widget.ply != _droppedPly
          ? widget.ply
          : -1;
      _selected = null;
      _cancelDrag();
    } else if (widget.interactiveSide != oldWidget.interactiveSide) {
      _selected = null;
      _cancelDrag();
    }
  }

  @override
  void dispose() {
    _dragPosition.dispose();
    super.dispose();
  }

  void _cancelDrag() {
    _dragFrom = null;
    _dragPosition.value = null;
  }

  bool _isOwn(Square square) {
    final side = widget.interactiveSide;
    return side != null && widget.pieces[square]?.color == side;
  }

  Set<Square> _targets(Square? from) => from == null
      ? const {}
      : widget.legalDestinations?.call(from) ?? const {};

  void _move(Square from, Square to, {required bool dragged}) {
    if (dragged) _droppedPly = widget.ply + 1;
    setState(() => _selected = null);
    widget.onMove?.call(from, to, dragged: dragged);
  }

  void _onTap(Square square) {
    if (widget.goldSquares.contains(square)) {
      widget.onGoldSquareTap?.call(square);
      return;
    }
    final selected = _selected;
    if (selected != null && _targets(selected).contains(square)) {
      _move(selected, square, dragged: false);
    } else if (_isOwn(square)) {
      setState(() => _selected = selected == square ? null : square);
    } else if (selected != null) {
      setState(() => _selected = null);
    }
  }

  void _onPanStart(Square? square, Offset position) {
    if (square == null || !_isOwn(square)) return;
    setState(() {
      _selected = square;
      _dragFrom = square;
    });
    _dragPosition.value = position;
  }

  void _onPanEnd(BoardGeometry geometry) {
    final from = _dragFrom;
    final position = _dragPosition.value;
    if (from == null || position == null) return;
    final target = geometry.squareAt(position);
    setState(_cancelDrag);
    if (target != null && target != from && _targets(from).contains(target)) {
      _move(from, target, dragged: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        final geometry = BoardGeometry(size, widget.orientation);
        final square = geometry.square;
        final last = widget.lastMove;
        final targets = widget.showLegalMoves
            ? _targets(_selected)
            : const <Square>{};

        return SizedBox.square(
          dimension: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  size: Size.square(size),
                  painter: BoardPainter(
                    fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                    colors: widget.boardTheme.colors,
                    orientation: widget.orientation,
                    lastMove: last == null ? const {} : {last.from, last.to},
                    selected: _selected,
                    check: widget.checkSquare,
                    moveTargets: {
                      for (final s in targets)
                        if (!widget.pieces.containsKey(s)) s,
                    },
                    captureTargets: {
                      for (final s in targets)
                        if (widget.pieces.containsKey(s)) s,
                    },
                    goldTargets: widget.goldSquares,
                  ),
                ),
              ),
              if (last != null &&
                  last.captured != null &&
                  widget.animate &&
                  _slidePly == widget.ply)
                _CaptureGhost(
                  key: ValueKey('capture-${widget.ply}'),
                  offset: geometry.offsetOf(last.capturedSquare!),
                  size: square,
                  piece: last.captured!,
                  theme: widget.pieceTheme,
                ),
              for (final entry in widget.pieces.entries)
                if (entry.key != _dragFrom)
                  _buildPiece(entry.key, entry.value, geometry),
              ValueListenableBuilder<Offset?>(
                valueListenable: _dragPosition,
                builder: (context, position, _) {
                  final from = _dragFrom;
                  final piece = from == null ? null : widget.pieces[from];
                  if (position == null || piece == null) {
                    return const SizedBox.shrink();
                  }
                  final lifted = square * 1.35;
                  return Positioned(
                    left: position.dx - lifted / 2,
                    top: position.dy - lifted * 0.8,
                    child: IgnorePointer(
                      child: ChessPiece(
                        piece: piece,
                        theme: widget.pieceTheme,
                        size: lifted,
                      ),
                    ),
                  );
                },
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final s = geometry.squareAt(details.localPosition);
                    if (s != null) _onTap(s);
                  },
                  onPanStart: (details) => _onPanStart(
                    geometry.squareAt(details.localPosition),
                    details.localPosition,
                  ),
                  onPanUpdate: (details) {
                    if (_dragFrom != null) {
                      _dragPosition.value = details.localPosition;
                    }
                  },
                  onPanEnd: (_) => _onPanEnd(geometry),
                  onPanCancel: () => setState(_cancelDrag),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPiece(Square square, Piece piece, BoardGeometry geometry) {
    final offset = geometry.offsetOf(square);
    final last = widget.lastMove;
    Widget child = ChessPiece(
      piece: piece,
      theme: widget.pieceTheme,
      size: geometry.square,
    );

    if (square == widget.matedKing) {
      child = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInCubic,
        builder: (context, t, piece) => Transform.rotate(
          angle: t * 1.25,
          alignment: Alignment.bottomCenter,
          child: Opacity(opacity: 1 - 0.3 * t, child: piece),
        ),
        child: child,
      );
    }

    // Slide the piece that just moved (and the rook when castling).
    Square? slideFrom;
    if (widget.animate && last != null && _slidePly == widget.ply) {
      if (square == last.to) slideFrom = last.from;
      if (square == last.rookTo) slideFrom = last.rookFrom;
    }
    if (slideFrom != null) {
      final begin = geometry.offsetOf(slideFrom) - offset;
      child = TweenAnimationBuilder<Offset>(
        key: ValueKey('slide-${widget.ply}-${square.name}'),
        tween: Tween(begin: begin, end: Offset.zero),
        duration: _slide,
        curve: Curves.easeOutCubic,
        builder: (context, value, piece) =>
            Transform.translate(offset: value, child: piece),
        child: child,
      );
    }
    return Positioned(
      key: ValueKey('piece-${square.name}'),
      left: offset.dx,
      top: offset.dy,
      child: IgnorePointer(child: child),
    );
  }
}

/// The captured piece shrinking and fading away.
class _CaptureGhost extends StatelessWidget {
  const _CaptureGhost({
    super.key,
    required this.offset,
    required this.size,
    required this.piece,
    required this.theme,
  });

  final Offset offset;
  final double size;
  final Piece piece;
  final PieceTheme theme;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1, end: 0),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeIn,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
          ),
          child: ChessPiece(piece: piece, theme: theme, size: size),
        ),
      ),
    );
  }
}
