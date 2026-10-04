import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_branding.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/tilt_carousel.dart';
import '../../../core/widgets/tunisian_pattern.dart';
import '../../about/presentation/about_screen.dart';
import '../../chess/domain/match_authority.dart';
import '../../multiplayer/presentation/friend_screens.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/settings_screen.dart';
import 'new_ai_game_screen.dart';
import 'widgets/iso_board_art.dart';

/// Home: the logo, the two game modes as cards you swipe through in 3D,
/// and a small dock for language, settings and About.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const List<GameVariant> _modes = [
    GameVariant.normal,
    GameVariant.special,
  ];
  int _page = 0;

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 640;
                  return Column(
                    children: [
                      SizedBox(height: compact ? 6 : 14),
                      _FloatingLogo(
                        size: compact ? 96 : 132,
                        animate: settings.animations,
                      ),
                      SizedBox(height: compact ? 8 : 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          l10n.tagline,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 6 : 12),
                      Expanded(
                        child: TiltCarousel(
                          itemCount: _modes.length,
                          onPageChanged: (page) => setState(() => _page = page),
                          itemBuilder: (context, index, focus) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: _ModeCard(
                              variant: _modes[index],
                              onAi: () => _push(
                                NewAiGameScreen(variant: _modes[index]),
                              ),
                              onFriend: () => _push(
                                FriendMenuScreen(variant: _modes[index]),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DiamondDots(count: _modes.length, active: _page),
                      SizedBox(height: compact ? 8 : 14),
                      _Dock(
                        language: settings.language,
                        onLanguage: (next) => ref
                            .read(settingsProvider.notifier)
                            .update((s) => s.copyWith(language: next)),
                        onSettings: () => _push(const SettingsScreen()),
                        onAbout: () => _push(const AboutScreen()),
                      ),
                      SizedBox(height: compact ? 8 : 14),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The official logo, gently swaying in space.
class _FloatingLogo extends StatefulWidget {
  const _FloatingLogo({required this.size, required this.animate});

  final double size;
  final bool animate;

  @override
  State<_FloatingLogo> createState() => _FloatingLogoState();
}

class _FloatingLogoState extends State<_FloatingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(_FloatingLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final phase = _controller.value * 2 * pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..translateByDouble(0, sin(phase) * 3, 0, 1)
            ..rotateY(sin(phase) * 0.14)
            ..rotateX(cos(phase) * 0.05),
          child: child,
        );
      },
      // The logo itself is untouched; only the card it sits on moves.
      child: BrandLogo(size: widget.size),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.variant,
    required this.onAi,
    required this.onFriend,
  });

  final GameVariant variant;
  final VoidCallback onAi;
  final VoidCallback onFriend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final special = variant == GameVariant.special;
    return GameCard(
      accent: special,
      radius: 28,
      depth: 9,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  special ? l10n.specialChess : l10n.normalChess,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (special)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 14,
                        color: AppColors.redDeep,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.specialBadge,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: AppColors.redDeep,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              special ? l10n.specialChessSubtitle : l10n.normalChessSubtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: special
                    ? AppColors.cream.withValues(alpha: 0.85)
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: IsoBoardArt(curtain: special),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GameButton(
                  label: l10n.vsAi,
                  icon: Icons.smart_toy_rounded,
                  tone: special ? GameTone.ivory : GameTone.red,
                  onPressed: onAi,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameButton(
                  label: l10n.vsFriend,
                  icon: Icons.people_alt_rounded,
                  tone: GameTone.dark,
                  onPressed: onFriend,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom dock: settings, language, about.
class _Dock extends StatelessWidget {
  const _Dock({
    required this.language,
    required this.onLanguage,
    required this.onSettings,
    required this.onAbout,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguage;
  final VoidCallback onSettings;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          GameIconButton(
            icon: Icons.settings_rounded,
            tooltip: l10n.settings,
            onPressed: onSettings,
          ),
          Expanded(
            child: Center(
              child: PopupMenuButton<AppLanguage>(
                tooltip: l10n.language,
                color: AppColors.surfaceHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: onLanguage,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: AppLanguage.darija,
                    child: Text(l10n.languageDarija),
                  ),
                  PopupMenuItem(
                    value: AppLanguage.english,
                    child: Text(l10n.languageEnglish),
                  ),
                  PopupMenuItem(
                    value: AppLanguage.french,
                    child: Text(l10n.languageFrench),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.language_rounded,
                        size: 20,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.languageShort,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_up_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          GameIconButton(
            icon: Icons.info_outline_rounded,
            tooltip: l10n.aboutTitle(AppBranding.name),
            onPressed: onAbout,
          ),
        ],
      ),
    );
  }
}
