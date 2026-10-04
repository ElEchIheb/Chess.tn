import 'package:flutter/material.dart';

/// Screen change with depth: the new screen swings in from the side like a
/// door opening towards you, while the old one steps back.
class TiltPageTransitionsBuilder extends PageTransitionsBuilder {
  const TiltPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 420);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 320);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Screens enter from the "forward" side of the reading direction.
    final side = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    final enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final leave = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([enter, leave]),
      builder: (context, child) {
        final t = 1 - enter.value; // 1 = far away, 0 = in place
        final back = leave.value; // 1 = covered by the next screen
        return Opacity(
          opacity: (enter.value * 1.6).clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0011)
              ..translateByDouble(side * t * 90 - side * back * 40, 0, 0, 1)
              ..rotateY(-side * t * 0.42 + side * back * 0.16)
              ..scaleByDouble(1 - 0.06 * back, 1 - 0.06 * back, 1, 1),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
