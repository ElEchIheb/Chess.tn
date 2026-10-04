import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/board_theme.dart';
import '../../../../core/utils/l10n_ext.dart';
import 'chess_piece.dart';

/// Asks which piece a pawn becomes. Returns `null` when dismissed.
Future<Role?> showPromotionSheet(
  BuildContext context, {
  required Side side,
  required PieceTheme pieceTheme,
}) {
  const roles = [Role.queen, Role.rook, Role.bishop, Role.knight];
  return showModalBottomSheet<Role>(
    context: context,
    builder: (context) {
      final l10n = context.l10n;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.promoteTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    for (final role in roles)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.of(context).pop(role),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHigh,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  ChessPiece(
                                    piece: Piece(color: side, role: role),
                                    theme: pieceTheme,
                                    size: 58,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.roleName(role),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
