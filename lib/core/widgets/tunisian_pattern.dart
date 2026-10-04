import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A very faint lattice of eight-pointed stars, the kind found on Tunisian
/// tiles and doors. Used as a quiet background texture.
class TunisianPatternPainter extends CustomPainter {
  const TunisianPatternPainter({
    this.color = AppColors.white,
    this.opacity = 0.035,
    this.tile = 64,
  });

  final Color color;
  final double opacity;
  final double tile;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final radius = tile * 0.36;
    final star = Path();
    for (var i = 0; i < 16; i++) {
      final r = i.isEven ? radius : radius * 0.72;
      final angle = i * pi / 8;
      final point = Offset(r * cos(angle), r * sin(angle));
      if (i == 0) {
        star.moveTo(point.dx, point.dy);
      } else {
        star.lineTo(point.dx, point.dy);
      }
    }
    star.close();

    for (var y = 0.0, row = 0; y < size.height + tile; y += tile, row++) {
      for (
        var x = row.isEven ? 0.0 : tile / 2;
        x < size.width + tile;
        x += tile
      ) {
        canvas
          ..save()
          ..translate(x, y)
          ..drawPath(star, paint)
          ..drawCircle(Offset.zero, radius * 0.28, paint)
          ..restore();
      }
    }
  }

  @override
  bool shouldRepaint(TunisianPatternPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.opacity != opacity ||
      oldDelegate.tile != tile;
}

/// Standard screen background: dark surface, soft red glow at the top and
/// the tile pattern.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.glow = true});

  final Widget child;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        gradient: glow
            ? const RadialGradient(
                center: Alignment(0, -1.15),
                radius: 1.1,
                colors: [Color(0x55E31B23), Color(0x000F1115)],
              )
            : null,
      ),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: const TunisianPatternPainter(),
          child: child,
        ),
      ),
    );
  }
}
