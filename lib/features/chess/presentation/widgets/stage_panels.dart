import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/l10n_ext.dart';
import '../../../../core/widgets/game_button.dart';
import '../../domain/game_state.dart';

/// LAN lobby shown once both phones are connected: "Players ready?".
class LobbyPanel extends StatelessWidget {
  const LobbyPanel({
    super.key,
    required this.state,
    required this.isHost,
    required this.onReady,
  });

  final GameState state;
  final bool isHost;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final special = state.config.isSpecial;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.wifi_tethering_rounded,
                size: 46,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.connected,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              isHost
                  ? l10n.variantName(state.config.variant)
                  : special
                  ? l10n.friendChoseSpecial
                  : l10n.friendChoseNormal,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              l10n.playersReady,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            _ReadyRow(
              label: state.localReady ? l10n.youAreReady : l10n.you,
              ready: state.localReady,
            ),
            const SizedBox(height: 8),
            _ReadyRow(
              label: state.opponentReady
                  ? l10n.friendReady
                  : l10n.friendNotReady,
              ready: state.opponentReady,
            ),
            const SizedBox(height: 28),
            GameButton(
              label: l10n.imReady,
              icon: Icons.check_rounded,
              onPressed: state.localReady ? null : onReady,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadyRow extends StatelessWidget {
  const _ReadyRow({required this.label, required this.ready});

  final String label;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ready ? AppColors.success : AppColors.outline,
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          Icon(
            ready ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: ready ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pass-and-play privacy screen: shown before each player's private setup
/// so the phone can change hands without anyone seeing an army.
class HandoffGate extends StatelessWidget {
  const HandoffGate({super.key, required this.side, required this.onReady});

  final Side side;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.screen_rotation_alt_rounded,
              size: 64,
              color: AppColors.gold,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.passPhoneTo(l10n.sideName(side)),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.passPhoneHint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            GameButton(
              label: l10n.imHere,
              icon: Icons.check_rounded,
              onPressed: onReady,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card laid over the game for connection problems and abandoned games.
class NoticeOverlay extends StatelessWidget {
  const NoticeOverlay({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.busy = false,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final bool busy;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    return ColoredBox(
      color: const Color(0xCC0F1115),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(28),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.gold),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (busy) ...[
                const SizedBox(height: 18),
                const SizedBox.square(
                  dimension: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    color: AppColors.gold,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              GameButton(
                label: actionLabel,
                tone: busy ? GameTone.dark : GameTone.red,
                onPressed: onAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
