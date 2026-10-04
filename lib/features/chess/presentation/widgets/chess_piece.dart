import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/board_theme.dart';
import 'piece_shapes.dart';

/// One chess piece, drawn as vectors (no image assets).
class ChessPiece extends StatelessWidget {
  const ChessPiece({
    super.key,
    required this.piece,
    required this.theme,
    required this.size,
    this.opacity = 1,
  });

  final Piece piece;
  final PieceTheme theme;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final painted = RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: PiecePainter(
          role: piece.role,
          colors: piece.color == Side.white ? theme.white : theme.black,
          ornaments: theme.ornaments,
        ),
      ),
    );
    return opacity >= 1 ? painted : Opacity(opacity: opacity, child: painted);
  }
}

class PiecePainter extends CustomPainter {
  const PiecePainter({
    required this.role,
    required this.colors,
    required this.ornaments,
  });

  final Role role;
  final PieceColors colors;
  final bool ornaments;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 100, size.height / 100);

    // Soft contact shadow.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 90), width: 60, height: 9),
      Paint()..color = const Color(0x38000000),
    );

    final body = PieceShapes.body(role);
    final base = PieceShapes.base(role);
    final outline = Paint()
      ..color = colors.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeJoin = StrokeJoin.round;

    // Stroke every part first, then fill: only the outer contour of the
    // whole silhouette stays visible.
    for (final path in [...body, base]) {
      canvas.drawPath(path, outline);
    }
    final fill = Paint()..color = colors.fill;
    for (final path in body) {
      canvas.drawPath(path, fill);
    }
    canvas.drawPath(base, Paint()..color = colors.shade);

    _details(canvas);
    canvas.restore();
  }

  void _details(Canvas canvas) {
    final detail = Paint()..color = colors.detail;
    final line = Paint()
      ..color = colors.detail
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final seam = Paint()
      ..color = colors.outline.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    switch (role) {
      case Role.knight:
        canvas
          ..drawCircle(const Offset(40, 34), 2.8, detail)
          ..drawPath(
            Path()
              ..moveTo(57, 27)
              ..cubicTo(67, 37, 69, 55, 65, 71),
            seam,
          );
      case Role.bishop:
        canvas.drawLine(const Offset(55, 25), const Offset(47, 38), line);
      case Role.rook:
        canvas.drawLine(const Offset(36, 42), const Offset(64, 42), seam);
      case Role.queen:
        if (ornaments) {
          canvas.drawPath(PieceShapes.star(50, 52, 5.5), detail);
        }
      case Role.king:
        if (ornaments) {
          canvas.drawPath(PieceShapes.crescent(49, 47, 7.5), detail);
        } else {
          canvas.drawLine(const Offset(50, 40), const Offset(50, 56), seam);
        }
      case Role.pawn:
        break;
    }
  }

  @override
  bool shouldRepaint(PiecePainter oldDelegate) =>
      oldDelegate.role != role ||
      oldDelegate.colors != colors ||
      oldDelegate.ornaments != ornaments;
}
