import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Swipeable carousel with depth: the card in front faces you, its
/// neighbours turn away like pages of a book and fall back.
class TiltCarousel extends StatefulWidget {
  const TiltCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.initialPage = 0,
    this.viewportFraction = 0.8,
    this.onPageChanged,
    this.tilt = 0.55,
  });

  final int itemCount;

  /// [focus] is 1 for the card in front and falls to 0 for its neighbours.
  final Widget Function(BuildContext context, int index, double focus)
  itemBuilder;

  /// Optional controller; must use the same [viewportFraction].
  final PageController? controller;
  final int initialPage;
  final double viewportFraction;
  final ValueChanged<int>? onPageChanged;

  /// Rotation of a neighbouring card, in radians.
  final double tilt;

  @override
  State<TiltCarousel> createState() => _TiltCarouselState();
}

class _TiltCarouselState extends State<TiltCarousel> {
  late final PageController _controller =
      widget.controller ??
      PageController(
        initialPage: widget.initialPage,
        viewportFraction: widget.viewportFraction,
      );

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  double get _page =>
      _controller.hasClients && _controller.position.haveDimensions
      ? _controller.page ?? widget.initialPage.toDouble()
      : _controller.initialPage.toDouble();

  @override
  Widget build(BuildContext context) {
    // In right-to-left languages the pages run the other way, and so does
    // the turn of the cards.
    final direction = Directionality.of(context) == TextDirection.rtl
        ? -1.0
        : 1.0;
    return PageView.builder(
      controller: _controller,
      itemCount: widget.itemCount,
      clipBehavior: Clip.none,
      onPageChanged: widget.onPageChanged,
      itemBuilder: (context, index) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final delta = (_page - index).clamp(-1.0, 1.0);
          final distance = delta.abs();
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0013)
              ..rotateY(direction * delta * widget.tilt)
              ..scaleByDouble(1 - 0.1 * distance, 1 - 0.1 * distance, 1, 1),
            child: Opacity(
              opacity: 1 - 0.45 * distance,
              child: widget.itemBuilder(context, index, 1 - distance),
            ),
          );
        },
      ),
    );
  }
}

/// Page indicator made of small diamonds.
class DiamondDots extends StatelessWidget {
  const DiamondDots({super.key, required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Transform.rotate(
              angle: 0.785398,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: i == active ? 10 : 7,
                height: i == active ? 10 : 7,
                decoration: BoxDecoration(
                  color: i == active ? AppColors.gold : AppColors.outline,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
