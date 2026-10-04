import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/board_theme.dart';
import '../../../chess/presentation/widgets/chess_piece.dart';
import '../../../special_mode/presentation/widgets/curtain.dart';

/// A little chess scene seen from an angle: a board lying in perspective
/// with pieces standing on it. With [curtain], a red curtain stands across
/// the middle and hides the far army — the Special mode in one picture.
class IsoBoardArt extends StatelessWidget {
  const IsoBoardArt({super.key, required this.curtain});

  final bool curtain;

  static const double _tilt = 0.9;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = (constraints.maxHeight * 1.02).clamp(
          60.0,
          constraints.maxWidth,
        );
        // Height of the board once it lies down.
        final lying = side * 0.7;
        final piece = side * 0.33;

        Widget stand(Role role, Side color, double x, double y, double scale) {
          final size = piece * scale;
          return Positioned(
            left: side * x - size / 2,
            bottom: lying * y,
            child: ChessPiece(
              piece: Piece(color: color, role: role),
              theme: PieceTheme.tunisian,
              size: size,
            ),
          );
        }

        return Center(
          child: SizedBox(
            width: side,
            height: lying + piece * 0.9,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0014)
                      ..rotateX(-_tilt),
                    child: _MiniBoard(size: side),
                  ),
                ),
                // Far side first so nearer pieces overlap it.
                if (!curtain) ...[
                  stand(Role.rook, Side.black, 0.3, 0.62, 0.62),
                  stand(Role.queen, Side.black, 0.52, 0.66, 0.66),
                  stand(Role.bishop, Side.black, 0.72, 0.6, 0.62),
                ],
                if (curtain)
                  Positioned(
                    left: side * 0.14,
                    bottom: lying * 0.5,
                    width: side * 0.72,
                    height: piece * 0.95,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CustomPaint(
                        painter: CurtainPainter(open: 0, sway: 0.3),
                      ),
                    ),
                  ),
                stand(Role.knight, Side.white, 0.24, 0.16, 0.9),
                stand(Role.king, Side.white, 0.5, 0.08, 1.05),
                stand(Role.pawn, Side.white, 0.76, 0.18, 0.8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniBoard extends StatelessWidget {
  const _MiniBoard({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.035),
      decoration: BoxDecoration(
        color: BoardTheme.tunisian.colors.frame,
        borderRadius: BorderRadius.circular(size * 0.05),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
        boxShadow: const [
          BoxShadow(color: Color(0x80000000), blurRadius: 16, spreadRadius: 2),
        ],
      ),
      child: CustomPaint(painter: _CheckerPainter(BoardTheme.tunisian.colors)),
    );
  }
}

class _CheckerPainter extends CustomPainter {
  const _CheckerPainter(this.colors);

  final BoardColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    const cells = 6;
    final cell = size.width / cells;
    for (var r = 0; r < cells; r++) {
      for (var f = 0; f < cells; f++) {
        canvas.drawRect(
          Rect.fromLTWH(f * cell, r * cell, cell + 0.5, cell + 0.5),
          Paint()..color = (r + f).isEven ? colors.light : colors.dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerPainter oldDelegate) => false;
}
