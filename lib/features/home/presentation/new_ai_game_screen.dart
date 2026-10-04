import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/board_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/tilt_carousel.dart';
import '../../../core/widgets/tunisian_pattern.dart';
import '../../ai/domain/ai_level.dart';
import '../../chess/application/game_controller.dart';
import '../../chess/domain/game_state.dart';
import '../../chess/domain/match_authority.dart';
import '../../chess/presentation/game_screen.dart';
import '../../chess/presentation/widgets/chess_piece.dart';
import '../../settings/application/settings_controller.dart';

enum _ColorChoice { white, random, black }

/// Match settings against the AI: swipe (or use the arrows) through the
/// five levels, pick the pieces you play, start.
class NewAiGameScreen extends ConsumerStatefulWidget {
  const NewAiGameScreen({super.key, required this.variant});

  final GameVariant variant;

  @override
  ConsumerState<NewAiGameScreen> createState() => _NewAiGameScreenState();
}

class _NewAiGameScreenState extends ConsumerState<NewAiGameScreen> {
  static const double _fraction = 0.56;

  late AiLevel _level = ref.read(settingsProvider).aiLevel;
  late final PageController _levels = PageController(
    initialPage: _level.index,
    viewportFraction: _fraction,
  );
  _ColorChoice _color = _ColorChoice.white;

  @override
  void dispose() {
    _levels.dispose();
    super.dispose();
  }

  void _step(int by) {
    final target = (_level.index + by).clamp(0, AiLevel.values.length - 1);
    _levels.animateToPage(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _start() {
    final side = switch (_color) {
      _ColorChoice.white => Side.white,
      _ColorChoice.black => Side.black,
      _ColorChoice.random => Random().nextBool() ? Side.white : Side.black,
    };
    ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(aiLevel: _level));
    ref
        .read(gameControllerProvider.notifier)
        .startLocal(
          GameConfig(
            variant: widget.variant,
            opponent: OpponentType.ai,
            aiLevel: _level,
            humanSide: side,
          ),
        );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pieceTheme = ref.watch(settingsProvider.select((s) => s.pieceTheme));
    final first = _level.index == 0;
    final last = _level.index == AiLevel.values.length - 1;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('${l10n.variantName(widget.variant)} · ${l10n.vsAi}'),
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: Column(
                        children: [
                          _Heading(l10n.chooseLevel),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 206,
                            // Numbers run 1 to 5 from left to right in every
                            // language.
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: TiltCarousel(
                                controller: _levels,
                                initialPage: _level.index,
                                viewportFraction: _fraction,
                                tilt: 0.7,
                                itemCount: AiLevel.values.length,
                                onPageChanged: (index) => setState(
                                  () => _level = AiLevel.values[index],
                                ),
                                itemBuilder: (context, index, focus) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 6,
                                  ),
                                  child: _LevelCard(
                                    level: AiLevel.values[index],
                                    name: l10n.levelName(AiLevel.values[index]),
                                    selected: AiLevel.values[index] == _level,
                                    onTap: () => _step(index - _level.index),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GameIconButton(
                                  key: const Key('level-prev'),
                                  icon: Icons.chevron_left_rounded,
                                  tooltip: l10n.levelNumber(
                                    max(_level.number - 1, 1),
                                  ),
                                  size: 44,
                                  onPressed: first ? null : () => _step(-1),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  child: DiamondDots(
                                    count: AiLevel.values.length,
                                    active: _level.index,
                                  ),
                                ),
                                GameIconButton(
                                  key: const Key('level-next'),
                                  icon: Icons.chevron_right_rounded,
                                  tooltip: l10n.levelNumber(
                                    min(_level.number + 1, 5),
                                  ),
                                  size: 44,
                                  onPressed: last ? null : () => _step(1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          _Heading(l10n.chooseColor),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Row(
                              children: [
                                for (final (choice, label) in [
                                  (_ColorChoice.white, l10n.colorWhite),
                                  (_ColorChoice.random, l10n.colorRandom),
                                  (_ColorChoice.black, l10n.colorBlack),
                                ])
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
                                      child: _SideTile(
                                        choice: choice,
                                        label: label,
                                        pieceTheme: pieceTheme,
                                        selected: _color == choice,
                                        onTap: () =>
                                            setState(() => _color = choice),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: GameButton(
                      label: l10n.startGame,
                      icon: Icons.play_arrow_rounded,
                      height: 58,
                      onPressed: _start,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(text, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const DiamondDivider(),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final AiLevel level;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      accent: selected,
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.red : AppColors.surfaceHigh,
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: Text(
              '${level.number}',
              style: const TextStyle(
                fontSize: 30,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name,
              maxLines: 1,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          // Strength meter.
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 1; i <= 5; i++)
                Container(
                  width: 7,
                  height: 6.0 + i * 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i <= level.number
                        ? AppColors.gold
                        : AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Play as" tile: the king you will command.
class _SideTile extends StatelessWidget {
  const _SideTile({
    required this.choice,
    required this.label,
    required this.pieceTheme,
    required this.selected,
    required this.onTap,
  });

  final _ColorChoice choice;
  final String label;
  final PieceTheme pieceTheme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final board = BoardTheme.tunisian.colors;
    Widget king(Side side, double size) => ChessPiece(
      piece: Piece(color: side, role: Role.king),
      theme: pieceTheme,
      size: size,
    );

    return GameCard(
      accent: selected,
      selected: selected,
      onTap: onTap,
      radius: 20,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 64,
              child: switch (choice) {
                _ColorChoice.white => ColoredBox(
                  color: board.dark,
                  child: Center(child: king(Side.white, 58)),
                ),
                _ColorChoice.black => ColoredBox(
                  color: board.light,
                  child: Center(child: king(Side.black, 58)),
                ),
                _ColorChoice.random => Row(
                  children: [
                    Expanded(
                      child: ColoredBox(
                        color: board.dark,
                        child: Center(child: king(Side.white, 40)),
                      ),
                    ),
                    Expanded(
                      child: ColoredBox(
                        color: board.light,
                        child: Center(child: king(Side.black, 40)),
                      ),
                    ),
                  ],
                ),
              },
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.gold : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
