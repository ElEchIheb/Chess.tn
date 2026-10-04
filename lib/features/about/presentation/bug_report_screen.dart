import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/tunisian_pattern.dart';
import '../application/link_launcher.dart';
import '../domain/contact_email.dart';
import 'contact_actions.dart';

/// "Report a Bug": the player describes the problem, optionally adds the
/// game mode and device, and the report opens as an email draft in their
/// own email app. There is no server behind this screen.
class BugReportScreen extends ConsumerStatefulWidget {
  const BugReportScreen({super.key});

  @override
  ConsumerState<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends ConsumerState<BugReportScreen> {
  final TextEditingController _description = TextEditingController();
  String? _gameMode;
  bool _includeDevice = true;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    final version = await ref
        .read(appVersionProvider.future)
        .catchError((Object _) => '');
    if (!mounted) return;
    await openLink(
      context,
      ref,
      ContactEmail.bugReport(
        description: _description.text,
        version: version,
        platform: _includeDevice ? ref.read(platformDescriptionProvider) : null,
        gameMode: _gameMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final modes = [
      '${l10n.normalChess} · ${l10n.vsAi}',
      '${l10n.normalChess} · ${l10n.vsFriend}',
      '${l10n.specialChess} · ${l10n.vsAi}',
      '${l10n.specialChess} · ${l10n.vsFriend}',
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.reportBug),
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: AppBackground(
        glow: false,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Text(
                l10n.bugWhatWentWrong,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                minLines: 5,
                maxLines: 9,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(hintText: l10n.bugDescriptionHint),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.bugGameMode,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final mode in modes)
                    ChoiceChip(
                      label: Text(mode),
                      selected: _gameMode == mode,
                      showCheckmark: false,
                      selectedColor: AppColors.redDark,
                      backgroundColor: AppColors.surfaceHigh,
                      side: BorderSide(
                        color: _gameMode == mode
                            ? AppColors.red
                            : Colors.transparent,
                      ),
                      onSelected: (selected) =>
                          setState(() => _gameMode = selected ? mode : null),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.outline),
                ),
                clipBehavior: Clip.antiAlias,
                child: SwitchListTile(
                  value: _includeDevice,
                  onChanged: (value) => setState(() => _includeDevice = value),
                  title: Text(
                    l10n.bugIncludeDevice,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: _includeDevice
                      ? Text(
                          ref.watch(platformDescriptionProvider),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 18),
              GameButton(
                label: l10n.contactDeveloper,
                icon: Icons.mail_outline_rounded,
                onPressed: _description.text.trim().isEmpty ? null : _send,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.bugPrivacyNote,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
