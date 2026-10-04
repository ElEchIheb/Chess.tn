import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/board_theme.dart';
import '../../../chess/presentation/widgets/chess_piece.dart';
import '../../domain/army_placement.dart';
import '../../domain/special_position_validator.dart';
import '../../domain/special_rules.dart';
import 'setup_drag.dart';

/// The pieces still to place, with how many of each are left. Pieces can be
/// tapped (then a square) or dragged onto the board; dropping a placed piece
/// back here removes it from the board.
class PieceTray extends StatelessWidget {
  const PieceTray({
    super.key,
    required this.army,
    required this.validator,
    required this.side,
    required this.pieceTheme,
    required this.selected,
    required this.onSelect,
    required this.onRemove,
  });

  final ArmyPlacement army;
  final SpecialPositionValidator validator;
  final Side side;
  final PieceTheme pieceTheme;
  final Role? selected;
  final ValueChanged<Role> onSelect;
  final ValueChanged<Square> onRemove;

  @override
  Widget build(BuildContext context) {
    return DragTarget<SetupDrag>(
      onWillAcceptWithDetails: (details) => details.data.from != null,
      onAcceptWithDetails: (details) => onRemove(details.data.from!),
      builder: (context, candidates, rejected) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty
              ? AppColors.redDark.withValues(alpha: 0.5)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: candidates.isNotEmpty ? AppColors.red : AppColors.outline,
          ),
        ),
        // Pieces read left to right like on the board, whatever the language.
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              for (final role in SpecialRules.trayOrder)
                Expanded(
                  child: _TrayTile(
                    piece: Piece(color: side, role: role),
                    pieceTheme: pieceTheme,
                    remaining: validator.remaining(army, role),
                    selected: role == selected,
                    onTap: () => onSelect(role),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrayTile extends StatelessWidget {
  const _TrayTile({
    required this.piece,
    required this.pieceTheme,
    required this.remaining,
    required this.selected,
    required this.onTap,
  });

  final Piece piece;
  final PieceTheme pieceTheme;
  final int remaining;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = remaining > 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (constraints.maxWidth - 10).clamp(28.0, 52.0);
        final image = ChessPiece(
          piece: piece,
          theme: pieceTheme,
          size: size,
          opacity: available ? 1 : 0.25,
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: available ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: selected && available
                  ? AppColors.gold.withValues(alpha: 0.16)
                  : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                width: 1.6,
                color: selected && available
                    ? AppColors.gold
                    : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (available)
                  Draggable<SetupDrag>(
                    data: SetupDrag.fromTray(piece.role),
                    dragAnchorStrategy: pointerDragAnchorStrategy,
                    onDragStarted: onTap,
                    feedback: DragFeedback(
                      piece: piece,
                      pieceTheme: pieceTheme,
                      size: size * 1.4,
                    ),
                    child: image,
                  )
                else
                  image,
                Text(
                  '×$remaining',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: available
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The piece that follows the finger while dragging.
class DragFeedback extends StatelessWidget {
  const DragFeedback({
    super.key,
    required this.piece,
    required this.pieceTheme,
    required this.size,
  });

  final Piece piece;
  final PieceTheme pieceTheme;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(-size / 2, -size * 0.8),
      child: ChessPiece(piece: piece, theme: pieceTheme, size: size),
    );
  }
}
