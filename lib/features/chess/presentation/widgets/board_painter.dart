import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/board_theme.dart';

/// Maps squares to pixels for a board of a given size and orientation.
@immutable
class BoardGeometry {
  const BoardGeometry(this.size, this.orientation);

  final double size;

  /// Side shown at the bottom.
  final Side orientation;

  double get square => size / 8;

  Offset offsetOf(Square s) {
    final column = orientation == Side.white ? s.file.value : 7 - s.file.value;
    final row = orientation == Side.white ? 7 - s.rank.value : s.rank.value;
    return Offset(column * square, row * square);
  }

  Rect rectOf(Square s) => offsetOf(s) & Size.square(square);

  Square? squareAt(Offset position) {
    if (position.dx < 0 ||
        position.dy < 0 ||
        position.dx >= size ||
        position.dy >= size) {
      return null;
    }
    final column = (position.dx / square).floor().clamp(0, 7);
    final row = (position.dy / square).floor().clamp(0, 7);
    return Square.fromCoords(
      File(orientation == Side.white ? column : 7 - column),
      Rank(orientation == Side.white ? 7 - row : row),
    );
  }
}

/// Paints the squares, coordinates and every highlight of the board.
class BoardPainter extends CustomPainter {
  const BoardPainter({
    required this.colors,
    required this.orientation,
    this.lastMove = const {},
    this.selected,
    this.check,
    this.moveTargets = const {},
    this.captureTargets = const {},
    this.goldTargets = const {},
    this.dimmed = const {},
    this.fontFamily,
  });

  final BoardColors colors;
  final Side orientation;
  final Set<Square> lastMove;
  final Square? selected;
  final Square? check;

  /// Empty squares the selected piece can move to (dots).
  final Set<Square> moveTargets;

  /// Occupied squares the selected piece can capture on (rings).
  final Set<Square> captureTargets;

  /// Squares offered for a special action, e.g. rescuing a king.
  final Set<Square> goldTargets;

  /// Squares drawn darker (outside the area the player may use).
  final Set<Square> dimmed;

  /// Font of the coordinates; the app font when the caller passes it.
  final String? fontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = BoardGeometry(size.width, orientation);
    final square = geometry.square;
    final light = Paint()..color = colors.light;
    final dark = Paint()..color = colors.dark;

    for (var i = 0; i < 64; i++) {
      final s = Square(i);
      final rect = geometry.rectOf(s);
      final isLight = (s.file.value + s.rank.value).isOdd;
      canvas.drawRect(rect, isLight ? light : dark);
      if (colors.woodGrain) _grain(canvas, rect, i);
      if (lastMove.contains(s)) {
        canvas.drawRect(rect, Paint()..color = colors.lastMove);
      }
      if (s == selected) {
        canvas.drawRect(rect, Paint()..color = colors.selected);
      }
      if (dimmed.contains(s)) {
        canvas.drawRect(rect, Paint()..color = const Color(0x66000000));
      }
    }

    final checkSquare = check;
    if (checkSquare != null) {
      final rect = geometry.rectOf(checkSquare);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              colors.check,
              colors.check.withValues(alpha: 0.55),
              colors.check.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(rect),
      );
    }

    final dot = Paint()..color = colors.moveDot;
    for (final s in moveTargets) {
      canvas.drawCircle(geometry.rectOf(s).center, square * 0.16, dot);
    }
    final ring = Paint()
      ..color = colors.moveDot
      ..style = PaintingStyle.stroke
      ..strokeWidth = square * 0.09;
    for (final s in captureTargets) {
      canvas.drawCircle(geometry.rectOf(s).center, square * 0.44, ring);
    }
    final gold = Paint()..color = const Color(0x99F2C94C);
    final goldRing = Paint()
      ..color = const Color(0xFFF2C94C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = square * 0.06;
    for (final s in goldTargets) {
      final center = geometry.rectOf(s).center;
      canvas
        ..drawCircle(center, square * 0.2, gold)
        ..drawCircle(center, square * 0.3, goldRing);
    }

    _coordinates(canvas, geometry);
  }

  void _grain(Canvas canvas, Rect rect, int seed) {
    final paint = Paint()
      ..color = const Color(0x12000000)
      ..strokeWidth = 1;
    for (var k = 1; k < 5; k++) {
      final y = rect.top + rect.height * ((k * 0.21 + (seed % 7) * 0.03) % 1);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
    }
  }

  void _coordinates(Canvas canvas, BoardGeometry geometry) {
    final square = geometry.square;
    final fontSize = square * 0.2;
    void draw(String text, Offset at, bool onLight) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            height: 1,
            color: onLight ? colors.coordinateOnLight : colors.coordinateOnDark,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, at);
      painter.dispose();
    }

    for (var i = 0; i < 8; i++) {
      // Files along the bottom row, ranks along the left column.
      final bottom = Square.fromCoords(
        File(orientation == Side.white ? i : 7 - i),
        orientation == Side.white ? Rank.first : Rank.eighth,
      );
      final rect = geometry.rectOf(bottom);
      draw(
        bottom.file.name,
        Offset(rect.right - fontSize * 0.85, rect.bottom - fontSize * 1.25),
        (bottom.file.value + bottom.rank.value).isOdd,
      );
      final left = Square.fromCoords(
        orientation == Side.white ? File.a : File.h,
        Rank(orientation == Side.white ? 7 - i : i),
      );
      final leftRect = geometry.rectOf(left);
      draw(
        left.rank.name,
        Offset(leftRect.left + fontSize * 0.3, leftRect.top + fontSize * 0.3),
        (left.file.value + left.rank.value).isOdd,
      );
    }
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) =>
      oldDelegate.colors != colors ||
      oldDelegate.orientation != orientation ||
      oldDelegate.fontFamily != fontFamily ||
      oldDelegate.selected != selected ||
      oldDelegate.check != check ||
      !setEquals(oldDelegate.lastMove, lastMove) ||
      !setEquals(oldDelegate.moveTargets, moveTargets) ||
      !setEquals(oldDelegate.captureTargets, captureTargets) ||
      !setEquals(oldDelegate.goldTargets, goldTargets) ||
      !setEquals(oldDelegate.dimmed, dimmed);
}

/// Rounded frame around a board.
class BoardFrame extends StatelessWidget {
  const BoardFrame({super.key, required this.colors, required this.child});

  final BoardColors colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colors.frame,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(9), child: child),
    );
  }
}
