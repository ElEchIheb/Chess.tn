import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/contact_email.dart';

/// Opens links outside the game (email app, browser, social apps).
abstract interface class LinkLauncher {
  /// Returns false when nothing on the device could open [uri].
  Future<bool> open(Uri uri);
}

final linkLauncherProvider = Provider<LinkLauncher>(
  (ref) => const UrlLinkLauncher(),
);

class UrlLinkLauncher implements LinkLauncher {
  const UrlLinkLauncher();

  @override
  Future<bool> open(Uri uri) async {
    // Preferred: hand over to the matching app (Instagram, Facebook, the
    // email client...). Fallbacks: whatever the platform offers, and for
    // email a bare address when a pre-filled draft is refused.
    if (await _try(uri, LaunchMode.externalApplication)) return true;
    if (await _try(uri, LaunchMode.platformDefault)) return true;
    if (uri.scheme == 'mailto' && uri.hasQuery) {
      return _try(ContactEmail.bare, LaunchMode.externalApplication);
    }
    return false;
  }

  static Future<bool> _try(Uri uri, LaunchMode mode) async {
    try {
      return await launchUrl(uri, mode: mode);
    } catch (_) {
      return false;
    }
  }
}

/// Version from the app package (pubspec `version:`), read at runtime so it
/// is never written twice.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

/// Short description of the device, offered (optionally) in bug reports.
final platformDescriptionProvider = Provider<String>((ref) {
  try {
    return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  } catch (_) {
    return '-';
  }
});
