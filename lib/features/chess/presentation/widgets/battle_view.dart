import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/l10n_ext.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../settings/application/settings_controller.dart';
import '../../../special_mode/presentation/reveal_stage.dart';
import '../../application/game_session.dart';
import '../../domain/chess_game.dart';
import '../../domain/game_phase.dart';
import '../../domain/game_state.dart';
import 'board_painter.dart';
import 'chess_board.dart';
import 'player_bar.dart';
import 'promotion_sheet.dart';

/// The battle: both player bars, the board, the status line and actions.
/// Also used for the king-rescue step that can follow a Special reveal.
class BattleView extends ConsumerWidget {
  const BattleView({
    super.key,
    required this.state,
    required this.session,
    required this.onResign,
  });

  final GameState state;
  final GameSession session;
  final VoidCallback onResign;

  static const Map<Role, int> _worth = {
    Role.pawn: 1,
    Role.knight: 3,
    Role.bishop: 3,
    Role.rook: 5,
    Role.queen: 9,
    Role.king: 0,
  };

  int _material(List<Piece> pieces) =>
      pieces.fold(0, (sum, p) => sum + _worth[p.role]!);

  Future<void> _onMove(
    BuildContext context,
    WidgetRef ref,
    Square from,
    Square to,
  ) async {
    final game = state.game;
    Role? promotion;
    if (game.isPromotionMove(from, to)) {
      promotion = await showPromotionSheet(
        context,
        side: game.turn,
        pieceTheme: ref.read(settingsProvider).pieceTheme,
      );
      if (promotion == null) return;
    }
    session.playMove(NormalMove(from: from, to: to, promotion: promotion));
  }

  String _name(BuildContext context, Side side) {
    final l10n = context.l10n;
    return switch (state.config.opponent) {
      OpponentType.passAndPlay => l10n.sideName(side),
      OpponentType.ai => state.controls(side) ? l10n.you : l10n.ai,
      OpponentType.lan => state.controls(side) ? l10n.you : l10n.friend,
    };
  }

  String? _subtitle(BuildContext context, Side side) {
    final l10n = context.l10n;
    if (state.config.opponent == OpponentType.passAndPlay) return null;
    if (state.isVsAi && !state.controls(side)) {
      final level = state.config.aiLevel;
      return '${l10n.levelNumber(level.number)} · ${l10n.levelName(level)}';
    }
    return l10n.sideName(side);
  }

  String _status(BuildContext context) {
    final l10n = context.l10n;
    final game = state.game;
    if (state.phase == GamePhase.kingRescue) {
      if (!state.canRescue) return l10n.opponentKingInDanger;
      return state.localSides.length > 1
          ? l10n.kingRescueFor(l10n.sideName(state.rescueSide!))
          : l10n.kingInDanger;
    }
    if (state.phase != GamePhase.playing) return '';
    if (state.drawOfferFrom != null && state.controls(state.drawOfferFrom!)) {
      return l10n.drawOfferSent;
    }
    if (game.isCheck) return l10n.check;
    if (state.aiThinking) return l10n.aiThinking;
    if (state.localSides.length > 1) {
      return game.turn == Side.white ? l10n.whiteToMove : l10n.blackToMove;
    }
    return state.canMove ? l10n.yourTurn : l10n.opponentTurn;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final game = state.game;
    final rescuing = state.phase == GamePhase.kingRescue;
    final playing = state.phase == GamePhase.playing;
    final bottom = state.orientation;
    final top = bottom.opposite;

    final pieces = rescuing
        ? armiesToPieces(state.whiteArmy, state.blackArmy)
        : {
            for (final (square, piece) in game.position.board.pieces)
              square: piece,
          };

    final capturedWhite = game.capturedBy(Side.white);
    final capturedBlack = game.capturedBy(Side.black);
    final lead = _material(capturedWhite) - _material(capturedBlack);

    Square? checkSquare;
    Square? matedKing;
    if (rescuing) {
      checkSquare = state.armyOf(state.rescueSide!)?.kingSquare;
    } else if (game.isCheck) {
      checkSquare = game.position.board.kingOf(game.turn);
      if (state.outcome?.reason == GameEndReason.checkmate) {
        matedKing = checkSquare;
      }
    }

    PlayerBar bar(Side side) => PlayerBar(
      side: side,
      name: _name(context, side),
      subtitle: _subtitle(context, side),
      captured: side == Side.white ? capturedWhite : capturedBlack,
      materialLead: side == Side.white ? lead : -lead,
      active: playing && game.turn == side,
      pieceTheme: settings.pieceTheme,
      thinking: state.aiThinking && !state.controls(side),
    );

    final status = _status(context);
    final offer = state.drawOfferFrom;
    final incomingOffer = playing && offer != null && !state.controls(offer);

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Both player bars stay glued to the board, whatever the screen.
              const barHeight = 58.0;
              const gap = 10.0;
              final boardSize = (constraints.maxHeight - 2 * (barHeight + gap))
                  .clamp(120.0, constraints.maxWidth - 24);
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: barHeight, child: bar(top)),
                  const SizedBox(height: gap),
                  _BoardEntrance(
                    // A new game lays a fresh board down. In Special mode
                    // the board is already on the table after the reveal.
                    key: ValueKey(state.startedAt),
                    enabled: settings.animations && !state.config.isSpecial,
                    child: SizedBox.square(
                      dimension: boardSize,
                      child: BoardFrame(
                        colors: settings.boardTheme.colors,
                        child: ChessBoard(
                          pieces: pieces,
                          orientation: state.orientation,
                          boardTheme: settings.boardTheme,
                          pieceTheme: settings.pieceTheme,
                          lastMove: rescuing ? null : game.lastMove,
                          ply: game.ply,
                          checkSquare: checkSquare,
                          matedKing: matedKing,
                          interactiveSide: state.canMove ? game.turn : null,
                          legalDestinations: game.legalDestinations,
                          onMove: (from, to, {required dragged}) =>
                              _onMove(context, ref, from, to),
                          goldSquares: state.canRescue
                              ? state.rescueSquares
                              : const {},
                          onGoldSquareTap: session.relocateKing,
                          showLegalMoves: settings.showLegalMoves,
                          animate: settings.animations,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: gap),
                  SizedBox(height: barHeight, child: bar(bottom)),
                ],
              );
            },
          ),
        ),
        SizedBox(
          height: 44,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                status,
                key: ValueKey(status),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: (playing && game.isCheck) || rescuing
                      ? AppColors.gold
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        if (incomingOffer)
          _DrawOfferCard(
            text: l10n.drawOffered,
            accept: l10n.accept,
            decline: l10n.decline,
            onAnswer: (accept) => session.respondToDraw(accept: accept),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                if (state.isVsAi)
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.undo_rounded,
                      label: l10n.undo,
                      onTap: session.canUndo ? session.undo : null,
                    ),
                  ),
                if (state.isLan)
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.handshake_outlined,
                      label: l10n.offerDraw,
                      onTap: playing && offer == null
                          ? session.offerDraw
                          : null,
                    ),
                  ),
                if (state.isVsAi || state.isLan) const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.flag_outlined,
                    label: l10n.resign,
                    onTap: playing ? onResign : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The board starts lying back like on a table seen from the player's
/// chair, then rises to face them.
class _BoardEntrance extends StatelessWidget {
  const _BoardEntrance({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: (1.25 - t).clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(-t * 1.05)
            ..scaleByDouble(1 - 0.14 * t, 1 - 0.14 * t, 1, 1),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GameButton(
      label: label,
      icon: icon,
      tone: GameTone.dark,
      height: 46,
      onPressed: onTap,
    );
  }
}

class _DrawOfferCard extends StatelessWidget {
  const _DrawOfferCard({
    required this.text,
    required this.accept,
    required this.decline,
    required this.onAnswer,
  });

  final String text;
  final String accept;
  final String decline;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: () => onAnswer(false), child: Text(decline)),
          FilledButton(
            onPressed: () => onAnswer(true),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: Text(accept),
          ),
        ],
      ),
    );
  }
}
