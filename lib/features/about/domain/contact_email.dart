import '../../../core/constants/app_branding.dart';
import '../../../core/constants/developer_links.dart';

/// Kinds of message a player can send to the developer.
enum ContactTopic {
  general('Contact'),
  bugReport('Bug Report'),
  feedback('Feedback'),
  suggestion('Suggestion');

  const ContactTopic(this.tag);

  final String tag;

  /// e.g. `[chess.tn Bug Report]`.
  String get subject => '[${AppBranding.name} $tag]';
}

/// Builds `mailto:` drafts addressed to the developer.
///
/// There is no backend: the draft opens in the player's own email app and
/// nothing leaves the phone until they press send themselves. The field
/// names in the body are in English on purpose, so reports look the same
/// whatever language the game is played in.
abstract final class ContactEmail {
  static Uri compose(ContactTopic topic, {String body = ''}) => Uri(
    scheme: 'mailto',
    path: DeveloperLinks.email,
    // Built by hand: Uri's own query encoding turns spaces into '+', which
    // email apps show literally.
    query: [
      'subject=${Uri.encodeComponent(topic.subject)}',
      if (body.isNotEmpty) 'body=${Uri.encodeComponent(body)}',
    ].join('&'),
  );

  /// Address only, for devices that refuse a pre-filled draft.
  static Uri get bare => Uri(scheme: 'mailto', path: DeveloperLinks.email);

  static Uri bugReport({
    required String description,
    required String version,
    String? platform,
    String? gameMode,
  }) => compose(
    ContactTopic.bugReport,
    body: [
      'Game version: $version',
      'Platform: ${platform ?? '-'}',
      'Game mode: ${gameMode ?? '-'}',
      'Description:',
      description.trim(),
    ].join('\n'),
  );

  /// Feedback or suggestion draft: the player writes the message.
  static Uri message(ContactTopic topic, {required String version}) =>
      compose(topic, body: '\n\n--\n${AppBranding.name} $version');
}
