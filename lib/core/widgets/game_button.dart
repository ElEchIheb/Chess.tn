import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/sound_service.dart';
import '../theme/app_colors.dart';

/// Colour families of the tactile controls, all from the Tunisian palette.
enum GameTone {
  /// Tunisian red: the main action.
  red(AppColors.red, Color(0xFF7A0F14), AppColors.white, Color(0x38FFFFFF)),

  /// Ivory, like the light squares: the secondary action.
  ivory(
    AppColors.cream,
    Color(0xFFBFA77C),
    AppColors.redDeep,
    Color(0x66FFFFFF),
  ),

  /// Dark slate: quiet actions on dark screens.
  dark(
    AppColors.surfaceHigh,
    Color(0xFF07080B),
    AppColors.textPrimary,
    Color(0x1FFFFFFF),
  ),

  /// Gold: rewards and highlights.
  gold(
    AppColors.gold,
    AppColors.goldDark,
    AppColors.redDeep,
    Color(0x66FFFFFF),
  );

  const GameTone(this.face, this.edge, this.content, this.highlight);

  final Color face;

  /// The side of the button, visible below the face.
  final Color edge;
  final Color content;

  /// Thin light rim on top of the face.
  final Color highlight;
}

/// Shared look of something you can physically press: a face standing on a
/// solid edge. Pressing pushes the face down onto the edge.
class _Pressable extends ConsumerStatefulWidget {
  const _Pressable({
    required this.onPressed,
    required this.tone,
    required this.radius,
    required this.depth,
    required this.child,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final GameTone tone;
  final double radius;
  final double depth;
  final Widget child;
  final String? semanticLabel;

  @override
  ConsumerState<_Pressable> createState() => _PressableState();
}

class _PressableState extends ConsumerState<_Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (mounted && _down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final tone = widget.tone;
    // A disabled control lies almost flat and loses its colour.
    final depth = enabled ? widget.depth : 2.0;
    final sink = _down ? depth : 0.0;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: enabled
            ? () {
                ref.read(soundServiceProvider).haptic();
                widget.onPressed!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(
            top: sink + (widget.depth - depth),
            bottom: depth - sink,
          ),
          decoration: BoxDecoration(
            color: enabled ? tone.face : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(
              color: enabled ? tone.highlight : AppColors.outline,
              width: 1.2,
            ),
            boxShadow: [
              // A hard, un-blurred shadow reads as the side of the button.
              BoxShadow(
                color: enabled ? tone.edge : const Color(0xFF07080B),
                offset: Offset(0, depth - sink),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// The game's main button: chunky, with real depth, and it presses down.
class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = GameTone.red,
    this.height = 54,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final GameTone tone;
  final double height;

  /// Shows a spinner in place of the icon.
  final bool busy;

  static const double depth = 6;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final color = enabled ? tone.content : AppColors.textMuted;
    final icon = this.icon;
    return _Pressable(
      onPressed: onPressed,
      tone: tone,
      radius: 18,
      depth: depth,
      semanticLabel: label,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 10),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: color,
                      ),
                    ),
                  )
                else if (icon != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 9),
                    child: Icon(icon, size: 21, color: color),
                  ),
                ExcludeSemantics(
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Square tactile button holding one icon.
class GameIconButton extends StatelessWidget {
  const GameIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.tone = GameTone.dark,
    this.size = 50,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final GameTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: _Pressable(
        onPressed: onPressed,
        tone: tone,
        radius: 16,
        depth: 5,
        semanticLabel: tooltip,
        child: SizedBox.square(
          dimension: size,
          child: Icon(
            icon,
            size: size * 0.46,
            color: onPressed == null ? AppColors.textMuted : tone.content,
          ),
        ),
      ),
    );
  }
}

/// A card with weight: it stands on a solid edge and, when it is tappable,
/// sinks under the finger. [selected] rings it in gold.
class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.child,
    this.onTap,
    this.accent = false,
    this.selected = false,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.depth = 7,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Deep red instead of slate (Special mode, selected choices).
  final bool accent;
  final bool selected;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double depth;

  @override
  Widget build(BuildContext context) {
    return _CardBody(
      onTap: onTap,
      accent: accent,
      selected: selected,
      radius: radius,
      depth: depth,
      child: Padding(padding: padding, child: child),
    );
  }
}

class _CardBody extends ConsumerStatefulWidget {
  const _CardBody({
    required this.child,
    required this.onTap,
    required this.accent,
    required this.selected,
    required this.radius,
    required this.depth,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool accent;
  final bool selected;
  final double radius;
  final double depth;

  @override
  ConsumerState<_CardBody> createState() => _CardBodyState();
}

class _CardBodyState extends ConsumerState<_CardBody> {
  bool _down = false;

  void _set(bool down) {
    if (mounted && _down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final tappable = widget.onTap != null;
    final sink = _down ? widget.depth - 2 : 0.0;
    final face = widget.accent ? AppColors.redDeep : AppColors.surface;
    final edge = widget.accent
        ? const Color(0xFF33070A)
        : const Color(0xFF07080B);
    final rim = widget.selected
        ? AppColors.gold
        : widget.accent
        ? AppColors.red
        : AppColors.outline;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      margin: EdgeInsets.only(top: sink, bottom: widget.depth - sink),
      decoration: BoxDecoration(
        color: face,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: rim, width: widget.selected ? 2.2 : 1.4),
        boxShadow: [
          BoxShadow(color: edge, offset: Offset(0, widget.depth - sink)),
          const BoxShadow(
            color: Color(0x40000000),
            blurRadius: 18,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: widget.child,
    );
    if (!tappable) return card;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: () {
          ref.read(soundServiceProvider).haptic();
          widget.onTap!();
        },
        child: card,
      ),
    );
  }
}

/// Gold rule with a red diamond, echoing the diamonds of the logo.
class DiamondDivider extends StatelessWidget {
  const DiamondDivider({super.key, this.width = 120});

  final double width;

  @override
  Widget build(BuildContext context) {
    Widget line() => Expanded(
      child: Container(
        height: 1.4,
        color: AppColors.gold.withValues(alpha: 0.5),
      ),
    );
    return SizedBox(
      width: width,
      child: Row(
        children: [
          line(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(width: 7, height: 7, color: AppColors.red),
            ),
          ),
          line(),
        ],
      ),
    );
  }
}
