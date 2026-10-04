import 'package:chess_tn/core/constants/app_branding.dart';
import 'package:chess_tn/core/constants/developer_links.dart';
import 'package:chess_tn/features/about/domain/contact_email.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the brand name is exactly chess.tn', () {
    expect(AppBranding.name, 'chess.tn');
  });

  test('developer links are the published ones', () {
    expect(DeveloperLinks.name, 'Iheb El Ech');
    expect(DeveloperLinks.email, 'ihebelleuch6@gmail.com');
    expect(DeveloperLinks.github.toString(), 'https://github.com/ElEchIheb/');
    expect(
      DeveloperLinks.linkedin.toString(),
      'https://www.linkedin.com/in/iheb-el-ech',
    );
    expect(
      DeveloperLinks.instagram.toString(),
      'https://www.instagram.com/elechiheb/',
    );
    expect(
      DeveloperLinks.facebook.toString(),
      'https://www.facebook.com/DangerNoob1920',
    );
    for (final link in [
      DeveloperLinks.github,
      DeveloperLinks.linkedin,
      DeveloperLinks.instagram,
      DeveloperLinks.facebook,
    ]) {
      expect(link.scheme, 'https');
    }
  });

  group('ContactEmail', () {
    test('subjects carry the brand and the topic', () {
      expect(ContactTopic.bugReport.subject, '[chess.tn Bug Report]');
      expect(ContactTopic.feedback.subject, '[chess.tn Feedback]');
      expect(ContactTopic.suggestion.subject, '[chess.tn Suggestion]');
    });

    test('a bug report is a mailto draft to the developer', () {
      final uri = ContactEmail.bugReport(
        description: '  The curtain did not open & the game froze.  ',
        version: '1.0.0',
        platform: 'android 15',
        gameMode: 'Special Chess · vs AI',
      );
      expect(uri.scheme, 'mailto');
      expect(uri.path, 'ihebelleuch6@gmail.com');
      expect(uri.queryParameters['subject'], '[chess.tn Bug Report]');
      expect(
        uri.queryParameters['body'],
        'Game version: 1.0.0\n'
        'Platform: android 15\n'
        'Game mode: Special Chess · vs AI\n'
        'Description:\n'
        'The curtain did not open & the game froze.',
      );
      // Spaces must be %20: email apps show a literal "+" otherwise.
      expect(uri.toString(), isNot(contains('+')));
      expect(uri.toString(), contains('%5Bchess.tn%20Bug%20Report%5D'));
    });

    test('optional fields are left blank, never invented', () {
      final body = ContactEmail.bugReport(
        description: 'x',
        version: '1.0.0',
      ).queryParameters['body']!;
      expect(body, contains('Platform: -'));
      expect(body, contains('Game mode: -'));
    });

    test('feedback and suggestion drafts leave the message to the player', () {
      final feedback = ContactEmail.message(
        ContactTopic.feedback,
        version: '1.0.0',
      );
      expect(feedback.queryParameters['subject'], '[chess.tn Feedback]');
      expect(feedback.queryParameters['body'], endsWith('chess.tn 1.0.0'));
      expect(
        ContactEmail.message(
          ContactTopic.suggestion,
          version: '1.0.0',
        ).queryParameters['subject'],
        '[chess.tn Suggestion]',
      );
      expect(ContactEmail.bare.toString(), 'mailto:ihebelleuch6@gmail.com');
    });
  });
}
