import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/board_theme.dart';
import '../../../../core/utils/l10n_ext.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../special_mode/domain/army_placement.dart';
import '../../domain/chess_game.dart';
import '../../domain/game_state.dart';
import 'chess_piece.dart';

/// End-of-game summary: who won and how, the numbers of the game, and in
/// Special mode the two armies as they were built.
class ResultPanel extends StatelessWidget {
  const ResultPanel({
    super.key,
    required this.state,
    required this.boardTheme,
    required this.pieceTheme,
    required this.onPlayAgain,
    required this.onHome,
    required this.onViewBoard,
  });

  final GameState state;
  final BoardTheme boardTheme;
  final PieceTheme pieceTheme;
  final VoidCallback? onPlayAgain;
  final VoidCallback onHome;
  final VoidCallback onViewBoard;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final outcome = state.outcome!;
    final won = state.localWon;
    final winner = outcome.winner;

    final String title;
    final String subtitle;
    final Color accent;
    final IconData icon;
    if (winner == null) {
      title = l10n.draw;
      subtitle = l10n.drawSubtitle;
      accent = AppColors.textSecondary;
      icon = Icons.balance_rounded;
    } else if (won == null) {
      title = winner == Side.white ? l10n.whiteWins : l10n.blackWins;
      subtitle = l10n.wonSubtitle;
      accent = AppColors.gold;
      icon = Icons.emoji_events_rounded;
    } else if (won) {
      title = l10n.youWon;
      subtitle = outcome.reason == GameEndReason.checkmate
          ? l10n.checkmateWin
          : l10n.wonSubtitle;
      accent = AppColors.gold;
      icon = Icons.emoji_events_rounded;
    } else {
      title = l10n.youLost;
      subtitle = l10n.lostSubtitle;
      accent = AppColors.red;
      icon = Icons.sentiment_dissatisfied_rounded;
    }

    final captured = state.game.history.where((r) => r.isCapture).length;
    final lan = state.isLan;
    final String? rematchNote = !lan
        ? null
        : !state.opponentConnected
        ? l10n.friendLeft
        : state.localReady
        ? l10n.rematchRequested
        : state.opponentReady
        ? l10n.rematchOffered
        : null;

    final white = state.whiteArmy;
    final black = state.blackArmy;
    final mine = state.localSides.length == 1 ? state.localSides.first : null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card + 6),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The trophy spins in once.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1, end: 0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateY(t * 6.2832)
                    ..scaleByDouble(1 - 0.5 * t, 1 - 0.5 * t, 1, 1),
                  child: child,
                ),
                child: Icon(icon, size: 46, color: accent),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: accent),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.endReason(outcome.reason),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Stat(
                    label: l10n.statMode,
                    value: l10n.variantName(state.config.variant),
                  ),
                  _Stat(
                    label: l10n.statMoves,
                    value: '${state.game.fullMoves}',
                  ),
                  _Stat(
                    label: l10n.statDuration,
                    value: formatClock(state.elapsed),
                  ),
                  _Stat(label: l10n.statCaptured, value: '$captured'),
                ],
              ),
              if (state.config.isSpecial && white != null && black != null) ...[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ArmyPreview(
                        army: mine == Side.black ? black : white,
                        label: mine == null ? l10n.whiteArmy : l10n.yourArmy,
                        boardTheme: boardTheme,
                        pieceTheme: pieceTheme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ArmyPreview(
                        army: mine == Side.black ? white : black,
                        label: mine == null
                            ? l10n.blackArmy
                            : l10n.opponentArmy,
                        boardTheme: boardTheme,
                        pieceTheme: pieceTheme,
                      ),
                    ),
                  ],
                ),
              ],
              if (rematchNote != null) ...[
                const SizedBox(height: 12),
                Text(
                  rematchNote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GameButton(
                      label: l10n.goHome,
                      icon: Icons.home_rounded,
                      tone: GameTone.dark,
                      onPressed: onHome,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: GameButton(
                      label: l10n.playAgain,
                      icon: Icons.replay_rounded,
                      onPressed: onPlayAgain,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onViewBoard,
                icon: const Icon(Icons.grid_on_rounded, size: 18),
                label: Text(l10n.viewBoard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            child: Text(
              value,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small picture of one army in its four-rank zone, back rank at the bottom.
class ArmyPreview extends StatelessWidget {
  const ArmyPreview({
    super.key,
    required this.army,
    required this.label,
    required this.boardTheme,
    required this.pieceTheme,
  });

  final ArmyPlacement army;
  final String label;
  final BoardTheme boardTheme;
  final PieceTheme pieceTheme;

  @override
  Widget build(BuildContext context) {
    final colors = boardTheme.colors;
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 2,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cell = constraints.maxWidth / 8;
                return Stack(
                  children: [
                    for (var row = 0; row < 4; row++)
                      for (var file = 0; file < 8; file++)
                        Positioned(
                          left: file * cell,
                          top: row * cell,
                          width: cell,
                          height: cell,
                          child: _cell(colors, file, row, cell),
                        ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _cell(BoardColors colors, int file, int row, double cell) {
    // Row 0 is the front of the zone, row 3 the player's back rank.
    final relativeRank = 3 - row;
    final rank = army.side == Side.white ? relativeRank : 7 - relativeRank;
    final square = Square.fromCoords(File(file), Rank(rank));
    final role = army.roleAt(square);
    return ColoredBox(
      color: (file + rank).isOdd ? colors.light : colors.dark,
      child: role == null
          ? null
          : ChessPiece(
              piece: Piece(color: army.side, role: role),
              theme: pieceTheme,
              size: cell,
            ),
    );
  }
}
