import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/widgets/tunisian_pattern.dart';
import '../../multiplayer/application/lan_host_session.dart';
import '../../settings/application/settings_controller.dart';
import '../../special_mode/presentation/reveal_stage.dart';
import '../../special_mode/presentation/setup_stage.dart';
import '../application/game_controller.dart';
import '../domain/game_phase.dart';
import '../domain/game_state.dart';
import 'widgets/battle_view.dart';
import 'widgets/result_panel.dart';
import 'widgets/stage_panels.dart';

/// The single screen a match lives on. It renders whatever the session's
/// [GamePhase] says: lobby, private setup, reveal, battle, result.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  StreamSubscription<GameEvent>? _events;
  GameState? _last;
  int _handoffDoneRound = -1;
  bool _resultHidden = false;
  bool _resultDue = false;
  Timer? _resultTimer;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _events = ref.read(gameControllerProvider.notifier).events.listen(_onEvent);
  }

  @override
  void dispose() {
    _events?.cancel();
    _resultTimer?.cancel();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.center),
          duration: const Duration(milliseconds: 1800),
        ),
      );
  }

  void _onEvent(GameEvent event) {
    if (!mounted) return;
    final l10n = context.l10n;
    switch (event.type) {
      case GameEventType.illegalMove:
        _toast(l10n.illegalMove);
      case GameEventType.setupInvalid:
        _toast(l10n.setupIssue(event.issues));
      case GameEventType.gameStart:
        _toast(l10n.gameStartToast);
      case GameEventType.setupRedo:
        _toast(l10n.setupRedo);
      case GameEventType.drawDeclined:
        _toast(l10n.drawDeclined);
      case GameEventType.opponentReconnected:
        _toast(l10n.friendBack);
      case GameEventType.gameOver:
        // Leave a moment to see the final position before the summary.
        _resultTimer?.cancel();
        _resultTimer = Timer(const Duration(milliseconds: 1100), () {
          if (mounted) setState(() => _resultDue = true);
        });
      default:
        break;
    }
  }

  Future<bool> _confirm(
    String title,
    String body,
    String yes,
    String no,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: body.isEmpty ? null : Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(no),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: Text(yes),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _leave({bool confirm = true}) async {
    if (_leaving) return;
    final state = _last;
    final l10n = context.l10n;
    final inProgress =
        state != null &&
        !state.phase.isTerminal &&
        (state.phase != GamePhase.lobby || state.isLan);
    if (confirm && inProgress) {
      final sure = await _confirm(
        l10n.leaveGame,
        l10n.leaveGameBody,
        l10n.leave,
        l10n.stay,
      );
      if (!sure || !mounted) return;
    }
    _leaving = true;
    final navigator = Navigator.of(context);
    final controller = ref.read(gameControllerProvider.notifier);
    navigator.popUntil((route) => route.isFirst);
    await controller.leave();
  }

  Future<void> _resign() async {
    final l10n = context.l10n;
    final sure = await _confirm(
      l10n.resign,
      l10n.resignConfirm,
      l10n.resign,
      l10n.cancel,
    );
    if (sure) ref.read(gameControllerProvider.notifier).session?.resign();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider) ?? _last;
    final controller = ref.read(gameControllerProvider.notifier);
    final session = controller.session;
    if (state == null) return const Scaffold(body: SizedBox.shrink());
    _last = state;
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);

    // A new game (rematch) clears the previous result.
    if (state.phase != GamePhase.gameOver &&
        state.phase != GamePhase.abandoned) {
      _resultDue = false;
      _resultHidden = false;
    }

    final shown = state.phase == GamePhase.paused
        ? state.pausedFrom ?? GamePhase.lobby
        : state.phase;
    final setup = state.setup;
    final passAndPlay = state.config.opponent == OpponentType.passAndPlay;

    final Widget stage;
    if (session == null) {
      stage = const SizedBox.shrink();
    } else if (shown == GamePhase.lobby) {
      stage = LobbyPanel(
        key: const ValueKey('lobby'),
        state: state,
        isHost: session is LanHostSession,
        onReady: session.setReady,
      );
    } else if ((shown.isSetup || shown == GamePhase.waitingForPlayer) &&
        setup != null) {
      stage = passAndPlay && _handoffDoneRound != setup.round
          ? HandoffGate(
              key: ValueKey('handoff-${setup.round}'),
              side: setup.side,
              onReady: () => setState(() => _handoffDoneRound = setup.round),
            )
          : SetupStage(
              key: ValueKey('setup-${setup.round}'),
              state: state,
              session: session,
            );
    } else if (shown == GamePhase.reveal) {
      stage = RevealStage(
        key: ValueKey('reveal-${state.revealCount}'),
        state: state,
      );
    } else {
      stage = BattleView(
        key: const ValueKey('battle'),
        state: state,
        session: session,
        onResign: _resign,
      );
    }

    final showResult =
        state.outcome != null &&
        !_resultHidden &&
        ((state.phase == GamePhase.gameOver && _resultDue) ||
            state.phase == GamePhase.abandoned);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        body: AppBackground(
          glow: false,
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _TopBar(
                      title: l10n.variantName(state.config.variant),
                      special: state.config.isSpecial,
                      onBack: _leave,
                      trailing: state.outcome != null && _resultHidden
                          ? IconButton(
                              tooltip: l10n.close,
                              onPressed: () =>
                                  setState(() => _resultHidden = false),
                              icon: const Icon(Icons.emoji_events_outlined),
                            )
                          : null,
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: Duration(
                          milliseconds: settings.animations ? 280 : 0,
                        ),
                        child: stage,
                      ),
                    ),
                  ],
                ),
                if (state.phase == GamePhase.paused)
                  Positioned.fill(
                    child: NoticeOverlay(
                      icon: Icons.wifi_off_rounded,
                      title: l10n.connectionLost,
                      message: session is LanHostSession
                          ? l10n.friendDisconnected
                          : l10n.reconnecting,
                      busy: true,
                      actionLabel: l10n.leave,
                      onAction: () => _leave(confirm: false),
                    ),
                  ),
                if (state.phase == GamePhase.abandoned && state.outcome == null)
                  Positioned.fill(
                    child: NoticeOverlay(
                      icon: Icons.person_off_rounded,
                      title: l10n.friendLeft,
                      message: l10n.sameWifiHint,
                      actionLabel: l10n.goHome,
                      onAction: () => _leave(confirm: false),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    offset: showResult ? Offset.zero : const Offset(0, 1.1),
                    child: state.outcome == null
                        ? const SizedBox.shrink()
                        : ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.sizeOf(context).height * 0.78,
                            ),
                            child: ResultPanel(
                              state: state,
                              boardTheme: settings.boardTheme,
                              pieceTheme: settings.pieceTheme,
                              onPlayAgain:
                                  state.phase == GamePhase.gameOver &&
                                      state.opponentConnected &&
                                      !state.localReady
                                  ? session?.rematch
                                  : null,
                              onHome: () => _leave(confirm: false),
                              onViewBoard: () =>
                                  setState(() => _resultHidden = true),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.special,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final bool special;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.back,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (special) ...[
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 18,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 48, child: trailing),
        ],
      ),
    );
  }
}
