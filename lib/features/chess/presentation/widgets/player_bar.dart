import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/board_theme.dart';
import 'chess_piece.dart';

/// One player's strip above or below the board: who they are, what they
/// have captured, and whether it is their turn.
class PlayerBar extends StatelessWidget {
  const PlayerBar({
    super.key,
    required this.side,
    required this.name,
    this.subtitle,
    required this.captured,
    required this.materialLead,
    required this.active,
    required this.pieceTheme,
    this.thinking = false,
  });

  final Side side;
  final String name;
  final String? subtitle;

  /// Pieces this player has taken.
  final List<Piece> captured;

  /// Positive when this player is ahead in material.
  final int materialLead;
  final bool active;
  final PieceTheme pieceTheme;
  final bool thinking;

  static const Map<Role, int> _order = {
    Role.queen: 0,
    Role.rook: 1,
    Role.bishop: 2,
    Role.knight: 3,
    Role.pawn: 4,
    Role.king: 5,
  };

  @override
  Widget build(BuildContext context) {
    final sorted = [...captured]
      ..sort((a, b) => _order[a.role]!.compareTo(_order[b.role]!));
    final subtitle = this.subtitle;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: active ? AppColors.surfaceHigh : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 1.6,
          color: active ? AppColors.gold : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: side == Side.white
                  ? AppColors.redDark
                  : AppColors.cream.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ChessPiece(
              piece: Piece(color: side, role: Role.king),
              theme: pieceTheme,
              size: 40,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (thinking) ...[
                      const SizedBox(width: 8),
                      const _ThinkingDots(),
                    ],
                  ],
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (sorted.isNotEmpty)
            Flexible(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: SizedBox(
                  height: 24,
                  child: FittedBox(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final piece in sorted)
                          Align(
                            widthFactor: 0.62,
                            child: ChessPiece(
                              piece: piece,
                              theme: pieceTheme,
                              size: 24,
                            ),
                          ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (materialLead > 0)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4),
              child: Text(
                '+$materialLead',
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(
                  alpha:
                      0.3 +
                      0.7 *
                          (1 - ((_controller.value * 3 - i) % 3 / 3)).clamp(
                            0.0,
                            1.0,
                          ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
