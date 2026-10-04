import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../chess/application/game_session.dart';
import '../../chess/domain/game_state.dart';
import '../../chess/presentation/widgets/board_painter.dart';
import '../../chess/presentation/widgets/chess_piece.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/army_placement.dart';
import 'widgets/curtain.dart';

/// Pieces of both armies as a board map. Only callable with public armies.
Map<Square, Piece> armiesToPieces(ArmyPlacement? white, ArmyPlacement? black) =>
    {
      for (final army in [white, black])
        if (army != null)
          for (final entry in army.pieces.entries)
            entry.key: Piece(color: army.side, role: entry.value),
    };

/// The reveal: "both armies are ready…", 3, 2, 1, the curtain opens, and
/// the battle is announced. Both armies are public from this point on.
class RevealStage extends ConsumerStatefulWidget {
  const RevealStage({super.key, required this.state});

  final GameState state;

  @override
  ConsumerState<RevealStage> createState() => _RevealStageState();
}

class _RevealStageState extends ConsumerState<RevealStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: RevealTimeline.total,
  );
  int _lastCount = -1;

  static int get _total => RevealTimeline.total.inMilliseconds;
  static int get _intro => RevealTimeline.intro.inMilliseconds;
  static int get _step => RevealTimeline.countStep.inMilliseconds;
  static int get _curtainAt => RevealTimeline.curtainAt.inMilliseconds;
  static int get _curtain => RevealTimeline.curtain.inMilliseconds;

  @override
  void initState() {
    super.initState();
    _controller
      ..addListener(_onTick)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _elapsed => _controller.value * _total;

  /// 3, 2, 1 during the countdown, otherwise 0.
  int get _count {
    final t = _elapsed;
    if (t < _intro || t >= _curtainAt) return 0;
    return RevealTimeline.counts - ((t - _intro) ~/ _step);
  }

  void _onTick() {
    final count = _count;
    if (count != _lastCount) {
      _lastCount = count;
      if (count > 0) {
        ref.read(soundServiceProvider)
          ..play(Sfx.tick)
          ..haptic();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final state = widget.state;
    final pieces = armiesToPieces(state.whiteArmy, state.blackArmy);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _elapsed;
        final open = Curves.easeInOutCubic.transform(
          ((t - _curtainAt) / _curtain).clamp(0.0, 1.0),
        );
        final count = _count;
        final opening = t >= _curtainAt && t < _curtainAt + _curtain;
        final headline = t < _intro
            ? l10n.armiesReady
            : count > 0
            ? l10n.curtainRising
            : opening
            ? l10n.revealWord
            : l10n.battleBegins;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: SizedBox(
                height: 58,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      headline,
                      key: ValueKey(headline),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: opening ? AppColors.gold : null),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: BoardFrame(
                      colors: settings.boardTheme.colors,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = constraints.biggest.shortestSide;
                          final geometry = BoardGeometry(
                            size,
                            state.orientation,
                          );
                          return Stack(
                            children: [
                              RepaintBoundary(
                                child: Stack(
                                  children: [
                                    CustomPaint(
                                      size: Size.square(size),
                                      painter: BoardPainter(
                                        fontFamily: DefaultTextStyle.of(context)
                                            .style
                                            .fontFamily,
                                        colors: settings.boardTheme.colors,
                                        orientation: state.orientation,
                                      ),
                                    ),
                                    for (final entry in pieces.entries)
                                      Positioned.fromRect(
                                        rect: geometry.rectOf(entry.key),
                                        child: ChessPiece(
                                          piece: entry.value,
                                          theme: settings.pieceTheme,
                                          size: geometry.square,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: 0,
                                top: 0,
                                width: size,
                                height: size / 2,
                                child: Curtain(
                                  open: open,
                                  animateIdle: false,
                                  child: CurtainLabel(
                                    title: l10n.opponentHidden,
                                  ),
                                ),
                              ),
                              if (count > 0)
                                Center(
                                  child: _CountNumber(
                                    key: ValueKey(count),
                                    value: count,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: SizedBox(
                height: 48,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: t >= _curtainAt + _curtain ? 1 : 0,
                  child: Text(
                    l10n.letsSee,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One number of the countdown: pops in, then fades.
class _CountNumber extends StatelessWidget {
  const _CountNumber({super.key, required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: RevealTimeline.countStep,
      builder: (context, t, child) {
        final scale = 0.6 + 0.6 * Curves.easeOutBack.transform(t.clamp(0, 1));
        return Opacity(
          opacity: (1.6 - 1.6 * t).clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Container(
        width: 150,
        height: 150,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xCC0F1115),
        ),
        child: Text(
          '$value',
          style: const TextStyle(
            fontSize: 92,
            height: 1,
            fontWeight: FontWeight.w900,
            color: AppColors.gold,
          ),
        ),
      ),
    );
  }
}
