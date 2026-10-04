import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/developer_links.dart';
import '../../../core/utils/l10n_ext.dart';
import '../application/link_launcher.dart';
import '../domain/contact_email.dart';

/// Opens [uri]; when the device cannot, copies the address instead and says
/// so, so the player is never left with a dead button.
Future<void> openLink(BuildContext context, WidgetRef ref, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  final failedMessage = context.l10n.linkOpenFailed;
  final opened = await ref.read(linkLauncherProvider).open(uri);
  if (opened) return;
  await Clipboard.setData(
    ClipboardData(
      text: uri.scheme == 'mailto' ? DeveloperLinks.email : uri.toString(),
    ),
  );
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(failedMessage)));
}

/// Opens an email draft for feedback, a suggestion or general contact.
Future<void> openContactDraft(
  BuildContext context,
  WidgetRef ref,
  ContactTopic topic,
) async {
  final version = await ref
      .read(appVersionProvider.future)
      .catchError((Object _) => '');
  if (!context.mounted) return;
  await openLink(
    context,
    ref,
    topic == ContactTopic.general
        ? ContactEmail.compose(topic)
        : ContactEmail.message(topic, version: version),
  );
}
