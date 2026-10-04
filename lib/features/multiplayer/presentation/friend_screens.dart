import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/tunisian_pattern.dart';
import '../../chess/application/game_controller.dart';
import '../../chess/domain/game_state.dart';
import '../../chess/domain/match_authority.dart';
import '../../chess/presentation/game_screen.dart';
import '../application/lobby_controller.dart';
import '../data/lan_client_connector.dart';
import '../data/local_network.dart';

void _openGame(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const GameScreen()),
    (route) => route.isFirst,
  );
}

class _LobbyScaffold extends StatelessWidget {
  const _LobbyScaffold({required this.title, required this.child, this.onBack});

  final String title;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          tooltip: context.l10n.back,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
      ),
      body: AppBackground(child: SafeArea(child: child)),
    );
  }
}

/// "Play with a friend": create a game, join one, or share this phone.
class FriendMenuScreen extends ConsumerWidget {
  const FriendMenuScreen({super.key, required this.variant});

  final GameVariant variant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _LobbyScaffold(
      title: l10n.friendTitle,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            l10n.variantName(variant),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _OptionCard(
            icon: Icons.wifi_tethering_rounded,
            title: l10n.createGame,
            subtitle: l10n.createGameHint,
            highlighted: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => HostScreen(variant: variant),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _OptionCard(
            icon: Icons.login_rounded,
            title: l10n.joinGame,
            subtitle: l10n.joinGameHint,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const JoinScreen())),
          ),
          const SizedBox(height: 8),
          _OptionCard(
            icon: Icons.smartphone_rounded,
            title: l10n.samePhone,
            subtitle: l10n.samePhoneHint,
            onTap: () {
              ref
                  .read(gameControllerProvider.notifier)
                  .startLocal(
                    GameConfig(
                      variant: variant,
                      opponent: OpponentType.passAndPlay,
                    ),
                  );
              _openGame(context);
            },
          ),
          const SizedBox(height: 22),
          const _WifiHint(),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      onTap: onTap,
      accent: highlighted,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: highlighted ? AppColors.red : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
            ),
            child: Icon(icon, color: AppColors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: highlighted
                        ? AppColors.cream.withValues(alpha: 0.85)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _WifiHint extends StatelessWidget {
  const _WifiHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wifi_rounded, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            context.l10n.sameWifiHint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.redDeep.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.redDark),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The host's waiting room: shows the room code until the friend arrives.
class HostScreen extends ConsumerStatefulWidget {
  const HostScreen({super.key, required this.variant});

  final GameVariant variant;

  @override
  ConsumerState<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends ConsumerState<HostScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(lobbyControllerProvider.notifier).host(widget.variant),
    );
  }

  Future<void> _back() async {
    final navigator = Navigator.of(context);
    await ref.read(lobbyControllerProvider.notifier).cancel();
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(lobbyControllerProvider, (previous, next) {
      if (next is LobbyConnected) _openGame(context);
    });
    final state = ref.watch(lobbyControllerProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: _LobbyScaffold(
        title: l10n.createGame,
        onBack: _back,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: switch (state) {
            LobbyHosting(:final roomCode, :final address) => Column(
              children: [
                const Spacer(),
                Text(
                  l10n.roomCode,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _RoomCodeCard(code: roomCode),
                const SizedBox(height: 14),
                Text(
                  l10n.shareCodeHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 34),
                const SizedBox.square(
                  dimension: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.waitingFriend,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(flex: 2),
                const _WifiHint(),
                const SizedBox(height: 8),
                Text(
                  l10n.yourIp(address),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            LobbyFailed(:final error) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ErrorBox(message: l10n.lanError(error)),
                const SizedBox(height: 18),
                GameButton(
                  label: l10n.tryAgain,
                  icon: Icons.refresh_rounded,
                  onPressed: () => ref
                      .read(lobbyControllerProvider.notifier)
                      .host(widget.variant),
                ),
              ],
            ),
            _ => const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          },
        ),
      ),
    );
  }
}

class _RoomCodeCard extends StatelessWidget {
  const _RoomCodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Clipboard.setData(ClipboardData(text: code)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold, width: 1.8),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              code,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontSize: 52,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Join by code, by picking a game found on the network, or by IP.
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  final TextEditingController _code = TextEditingController();
  final TextEditingController _ip = TextEditingController();
  List<DiscoveredGame>? _nearby;
  bool _searching = false;
  bool _showIp = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(lobbyControllerProvider.notifier).clearError();
      _search();
    });
  }

  @override
  void dispose() {
    _code.dispose();
    _ip.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_searching) return;
    setState(() => _searching = true);
    final games = await ref.read(lobbyControllerProvider.notifier).discover();
    if (!mounted) return;
    setState(() {
      _nearby = games;
      _searching = false;
    });
  }

  void _join() {
    FocusScope.of(context).unfocus();
    final ip = _ip.text.trim();
    ref
        .read(lobbyControllerProvider.notifier)
        .join(_code.text, manualHost: _showIp && ip.isNotEmpty ? ip : null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(lobbyControllerProvider, (previous, next) {
      if (next is LobbyConnected) _openGame(context);
    });
    final state = ref.watch(lobbyControllerProvider);
    final busy = state is LobbyBusy;
    final nearby = _nearby;
    final ipValid =
        !_showIp ||
        _ip.text.trim().isEmpty ||
        LocalNetwork.isValidIpv4(_ip.text);

    return _LobbyScaffold(
      title: l10n.joinGame,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        children: [
          Text(
            l10n.enterCode,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _code,
              enabled: !busy,
              textAlign: TextAlign.center,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _join(),
              onChanged: (_) => setState(() {}),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\- ]')),
                LengthLimitingTextInputFormatter(8),
                _UpperCaseFormatter(),
              ],
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
              decoration: const InputDecoration(
                hintText: '${AppConstants.roomCodePrefix}-XXXX',
              ),
            ),
          ),
          if (_showIp) ...[
            const SizedBox(height: 12),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: _ip,
                enabled: !busy,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  LengthLimitingTextInputFormatter(15),
                ],
                decoration: InputDecoration(
                  labelText: l10n.hostIpLabel,
                  hintText: '192.168.1.20',
                  errorText: ipValid ? null : l10n.errInvalidIp,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          GameButton(
            label: busy ? l10n.joining : l10n.join,
            icon: Icons.login_rounded,
            busy: busy,
            onPressed: busy || _code.text.trim().isEmpty || !ipValid
                ? null
                : _join,
          ),
          if (!_showIp)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => setState(() => _showIp = true),
                child: Text(l10n.joinByIp),
              ),
            ),
          if (state is LobbyFailed) ...[
            const SizedBox(height: 12),
            _ErrorBox(message: l10n.lanError(state.error)),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.nearbyGames,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_searching)
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.gold,
                  ),
                )
              else
                IconButton(
                  tooltip: l10n.searchAgain,
                  onPressed: _search,
                  icon: const Icon(Icons.refresh_rounded),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (nearby != null && nearby.isEmpty && !_searching)
            Text(
              l10n.noGamesFound,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          for (final game in nearby ?? const <DiscoveredGame>[])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionCard(
                icon: Icons.sports_esports_rounded,
                title: game.roomCode,
                subtitle:
                    '${l10n.variantName(game.variant)} · ${l10n.gameOnNetwork}',
                onTap: busy
                    ? () {}
                    : () => ref
                          .read(lobbyControllerProvider.notifier)
                          .joinDiscovered(game),
              ),
            ),
          const SizedBox(height: 16),
          const _WifiHint(),
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
