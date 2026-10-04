import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_branding.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/board_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/widgets/tunisian_pattern.dart';
import '../../about/domain/contact_email.dart';
import '../../about/presentation/about_screen.dart';
import '../../about/presentation/bug_report_screen.dart';
import '../../about/presentation/contact_actions.dart';
import '../../ai/domain/ai_level.dart';
import '../../chess/presentation/widgets/chess_piece.dart';
import '../application/settings_controller.dart';
import '../domain/app_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: AppBackground(
        glow: false,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              _Section(
                title: l10n.language,
                children: [
                  for (final (language, label) in [
                    (AppLanguage.darija, l10n.languageDarija),
                    (AppLanguage.english, l10n.languageEnglish),
                    (AppLanguage.french, l10n.languageFrench),
                  ])
                    _SelectRow(
                      label: label,
                      selected: settings.language == language,
                      onTap: () => controller.update(
                        (s) => s.copyWith(language: language),
                      ),
                    ),
                ],
              ),
              _Section(
                title: l10n.sectionAudio,
                children: [
                  _SwitchRow(
                    icon: Icons.volume_up_rounded,
                    label: l10n.sound,
                    value: settings.sound,
                    onChanged: (v) =>
                        controller.update((s) => s.copyWith(sound: v)),
                  ),
                  _SwitchRow(
                    icon: Icons.music_note_rounded,
                    label: l10n.music,
                    value: settings.music,
                    onChanged: (v) =>
                        controller.update((s) => s.copyWith(music: v)),
                  ),
                  _SwitchRow(
                    icon: Icons.vibration_rounded,
                    label: l10n.vibration,
                    value: settings.vibration,
                    onChanged: (v) =>
                        controller.update((s) => s.copyWith(vibration: v)),
                  ),
                ],
              ),
              _Section(
                title: l10n.sectionAppearance,
                children: [
                  _Label(l10n.boardTheme),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: [
                        for (final theme in BoardTheme.values)
                          Expanded(
                            child: _BoardThemeTile(
                              theme: theme,
                              label: l10n.boardThemeName(theme),
                              selected: settings.boardTheme == theme,
                              onTap: () => controller.update(
                                (s) => s.copyWith(boardTheme: theme),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _Label(l10n.pieceTheme),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: [
                        for (final theme in PieceTheme.values)
                          Expanded(
                            child: _PieceThemeTile(
                              theme: theme,
                              boardTheme: settings.boardTheme,
                              label: l10n.pieceThemeName(theme),
                              selected: settings.pieceTheme == theme,
                              onTap: () => controller.update(
                                (s) => s.copyWith(pieceTheme: theme),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _SwitchRow(
                    icon: Icons.animation_rounded,
                    label: l10n.animations,
                    value: settings.animations,
                    onChanged: (v) =>
                        controller.update((s) => s.copyWith(animations: v)),
                  ),
                ],
              ),
              _Section(
                title: l10n.sectionGame,
                children: [
                  _SwitchRow(
                    icon: Icons.adjust_rounded,
                    label: l10n.showLegalMoves,
                    value: settings.showLegalMoves,
                    onChanged: (v) =>
                        controller.update((s) => s.copyWith(showLegalMoves: v)),
                  ),
                  _Label(l10n.defaultAiLevel),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                    child: Row(
                      children: [
                        for (final level in AiLevel.values)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: _LevelDot(
                                number: level.number,
                                selected: settings.aiLevel == level,
                                onTap: () => controller.update(
                                  (s) => s.copyWith(aiLevel: level),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Text(
                      l10n.levelName(settings.aiLevel),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              _Section(
                title: AppBranding.name,
                children: [
                  _LinkRow(
                    icon: Icons.info_outline_rounded,
                    label: l10n.aboutTitle(AppBranding.name),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AboutScreen(),
                      ),
                    ),
                  ),
                  _LinkRow(
                    icon: Icons.bug_report_outlined,
                    label: l10n.reportBug,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BugReportScreen(),
                      ),
                    ),
                  ),
                  _LinkRow(
                    icon: Icons.rate_review_outlined,
                    label: l10n.sendFeedback,
                    onTap: () =>
                        openContactDraft(context, ref, ContactTopic.feedback),
                  ),
                ],
              ),
              Text(
                l10n.aboutOffline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              const DeveloperSignature(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 6, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _SelectRow extends StatelessWidget {
  const _SelectRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.red : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _TileFrame extends StatelessWidget {
  const _TileFrame({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  width: 2.2,
                  color: selected ? AppColors.gold : Colors.transparent,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: AspectRatio(aspectRatio: 1, child: child),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.gold : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardThemeTile extends StatelessWidget {
  const _BoardThemeTile({
    required this.theme,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final BoardTheme theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return _TileFrame(
      label: label,
      selected: selected,
      onTap: onTap,
      child: Column(
        children: [
          for (var r = 0; r < 2; r++)
            Expanded(
              child: Row(
                children: [
                  for (var f = 0; f < 2; f++)
                    Expanded(
                      child: ColoredBox(
                        color: (r + f).isEven ? colors.light : colors.dark,
                        child: const SizedBox.expand(),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PieceThemeTile extends StatelessWidget {
  const _PieceThemeTile({
    required this.theme,
    required this.boardTheme,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final PieceTheme theme;
  final BoardTheme boardTheme;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = boardTheme.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: _TileFrame(
        label: label,
        selected: selected,
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final half = constraints.maxWidth / 2;
            return Row(
              children: [
                ColoredBox(
                  color: colors.dark,
                  child: Center(
                    child: ChessPiece(
                      piece: Piece.whiteKing,
                      theme: theme,
                      size: half,
                    ),
                  ),
                ),
                ColoredBox(
                  color: colors.light,
                  child: Center(
                    child: ChessPiece(
                      piece: Piece.blackQueen,
                      theme: theme,
                      size: half,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LevelDot extends StatelessWidget {
  const _LevelDot({
    required this.number,
    required this.selected,
    required this.onTap,
  });

  final int number;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.red : AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}
