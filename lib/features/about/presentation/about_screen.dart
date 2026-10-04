import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/constants/app_branding.dart';
import '../../../core/constants/developer_links.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/tunisian_pattern.dart';
import '../application/link_launcher.dart';
import '../domain/contact_email.dart';
import 'bug_report_screen.dart';
import 'contact_actions.dart';

/// "About chess.tn": the brand, what the game is, who made it and how to
/// reach them.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final version = ref.watch(appVersionProvider).value;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.aboutTitle(AppBranding.name)),
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  const Center(child: BrandLogo(size: 220)),
                  const SizedBox(height: 20),
                  Text(
                    l10n.aboutSlogan,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.aboutDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _AboutCard(
                    icon: Icons.local_fire_department_rounded,
                    label: l10n.aboutSpecialTitle,
                    accent: true,
                    child: Text(
                      l10n.aboutSpecialBody,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _AboutCard(
                    icon: Icons.code_rounded,
                    label: l10n.aboutDeveloperTitle,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.developedBy(DeveloperLinks.name),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.madeInTunisiaFlag,
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _AboutCard(
                    icon: Icons.forum_rounded,
                    label: l10n.contactTitle,
                    child: _ContactSection(),
                  ),
                  const SizedBox(height: 8),
                  if (version != null)
                    Text(
                      l10n.versionLabel(version),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '© ${AppBranding.copyrightYear} ${DeveloperLinks.name}',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.icon,
    required this.label,
    required this.child,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent ? AppColors.redDeep : AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent ? AppColors.red : AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ContactSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.contactQuestion,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.contactBody,
          style: const TextStyle(
            fontSize: 14.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        GameButton(
          label: l10n.contactDeveloper,
          icon: Icons.mail_outline_rounded,
          onPressed: () => openContactDraft(context, ref, ContactTopic.general),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.bug_report_outlined,
                  label: l10n.reportBug,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BugReportScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  icon: Icons.rate_review_outlined,
                  label: l10n.sendFeedback,
                  onTap: () =>
                      openContactDraft(context, ref, ContactTopic.feedback),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  icon: Icons.lightbulb_outline_rounded,
                  label: l10n.sendSuggestion,
                  onTap: () =>
                      openContactDraft(context, ref, ContactTopic.suggestion),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.followDeveloper,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        // Brand names read left to right in every language.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _LinkButton(
                      icon: FontAwesomeIcons.github,
                      label: l10n.linkGithub,
                      onTap: () =>
                          openLink(context, ref, DeveloperLinks.github),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LinkButton(
                      icon: FontAwesomeIcons.linkedinIn,
                      label: l10n.linkLinkedin,
                      onTap: () =>
                          openLink(context, ref, DeveloperLinks.linkedin),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _LinkButton(
                      icon: FontAwesomeIcons.instagram,
                      label: l10n.linkInstagram,
                      onTap: () =>
                          openLink(context, ref, DeveloperLinks.instagram),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LinkButton(
                      icon: FontAwesomeIcons.facebookF,
                      label: l10n.linkFacebook,
                      onTap: () =>
                          openLink(context, ref, DeveloperLinks.facebook),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _LinkButton(
                icon: FontAwesomeIcons.solidEnvelope,
                label: l10n.linkEmail,
                onTap: () => openLink(context, ref, ContactEmail.bare),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: AppColors.cream),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final FaIconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 18, color: AppColors.cream),
            const SizedBox(width: 10),
            Flexible(child: FittedBox(child: Text(label))),
          ],
        ),
      ),
    );
  }
}

/// Small "chess.tn · Developed by …" line for the bottom of quiet screens.
class DeveloperSignature extends StatelessWidget {
  const DeveloperSignature({super.key, this.color = AppColors.textMuted});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${AppBranding.name} · ${context.l10n.developedBy(DeveloperLinks.name)}',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12.5, color: color),
    );
  }
}
