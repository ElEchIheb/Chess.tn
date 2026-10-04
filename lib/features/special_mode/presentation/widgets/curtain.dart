import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The red curtain that hides the opponent's half of the board.
///
/// [open] goes from 0 (closed) to 1 (fully drawn aside): the two panels
/// slide towards the edges while their pleats bunch up.
class CurtainPainter extends CustomPainter {
  CurtainPainter({required this.open, required this.sway, super.repaint});

  final double open;

  /// 0..1, loops; makes the pleats shimmer very slightly.
  final double sway;

  static const int _folds = 6;
  static const Color _deep = Color(0xFF5C0E13);
  static const Color _mid = Color(0xFF9E1820);
  static const Color _bright = Color(0xFFD9252F);

  @override
  void paint(Canvas canvas, Size size) {
    if (open >= 1) return;
    final panelWidth = size.width / 2 * (1 - 0.94 * open);
    final rail = size.height * 0.075;

    // Shadow the curtain throws on the board below it.
    final shadowRect = Rect.fromLTWH(0, size.height, size.width, 12);
    final shadow = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x55000000), Color(0x00000000)],
      ).createShader(shadowRect);

    void panel(double left) {
      final foldWidth = panelWidth / _folds;
      for (var i = 0; i < _folds; i++) {
        final rect = Rect.fromLTWH(
          left + i * foldWidth,
          0,
          foldWidth + 0.5,
          size.height,
        );
        final highlight =
            0.4 + 0.12 * sin(2 * pi * (sway + i * 0.17 + left * 0.001));
        canvas.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              colors: const [_deep, _bright, _mid, _deep],
              stops: [0, highlight, min(0.95, highlight + 0.3), 1],
            ).createShader(rect),
        );
      }
      canvas.drawRect(Rect.fromLTWH(left, size.height, panelWidth, 12), shadow);
      // Gold hem with a thin fringe.
      final hem = Paint()..color = AppColors.gold;
      canvas.drawRect(Rect.fromLTWH(left, size.height - 7, panelWidth, 3), hem);
      final fringe = Paint()
        ..color = AppColors.goldDark
        ..strokeWidth = 1.2;
      for (var x = left + 2; x < left + panelWidth; x += 5) {
        canvas.drawLine(
          Offset(x, size.height - 4),
          Offset(x, size.height),
          fringe,
        );
      }
    }

    panel(0);
    panel(size.width - panelWidth);

    // The rail stays in place while the panels slide.
    final railRect = Rect.fromLTWH(0, 0, size.width, rail);
    canvas
      ..drawRect(railRect, Paint()..color = _deep)
      ..drawRect(
        Rect.fromLTWH(0, rail - 2.5, size.width, 2.5),
        Paint()..color = AppColors.gold,
      );
  }

  @override
  bool shouldRepaint(CurtainPainter oldDelegate) =>
      oldDelegate.open != open || oldDelegate.sway != sway;
}

/// Curtain with its idle shimmer. [child] is shown on top of the closed
/// curtain (label, opponent status) and fades as it opens.
class Curtain extends StatefulWidget {
  const Curtain({
    super.key,
    required this.open,
    this.child,
    this.animateIdle = true,
  });

  final double open;
  final Widget? child;
  final bool animateIdle;

  @override
  State<Curtain> createState() => _CurtainState();
}

class _CurtainState extends State<Curtain> with SingleTickerProviderStateMixin {
  late final AnimationController _sway = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animateIdle) _sway.repeat();
  }

  @override
  void didUpdateWidget(Curtain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateIdle && !_sway.isAnimating) {
      _sway.repeat();
    } else if (!widget.animateIdle && _sway.isAnimating) {
      _sway.stop();
    }
  }

  @override
  void dispose() {
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _sway,
        builder: (context, child) => CustomPaint(
          painter: CurtainPainter(open: widget.open, sway: _sway.value),
          child: child,
        ),
        child: widget.child == null
            ? const SizedBox.expand()
            : Opacity(
                opacity: (1 - widget.open * 3).clamp(0.0, 1.0),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    // Shrinks on very small boards instead of overflowing.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Text plate shown on the closed curtain.
class CurtainLabel extends StatelessWidget {
  const CurtainLabel({
    super.key,
    required this.title,
    this.status,
    this.ready = false,
  });

  final String title;
  final String? status;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.visibility_off_rounded,
          color: AppColors.gold,
          size: 30,
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            shadows: [Shadow(color: Color(0xAA000000), blurRadius: 8)],
          ),
        ),
        if (status != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xB3000000),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  ready
                      ? Icons.check_circle_rounded
                      : Icons.hourglass_top_rounded,
                  size: 16,
                  color: ready ? AppColors.success : AppColors.gold,
                ),
                const SizedBox(width: 6),
                Text(
                  status,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
