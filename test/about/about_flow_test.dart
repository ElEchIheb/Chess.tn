import 'package:chess_tn/core/constants/app_branding.dart';
import 'package:chess_tn/core/constants/developer_links.dart';
import 'package:chess_tn/core/widgets/brand_logo.dart';
import 'package:chess_tn/core/widgets/game_button.dart';
import 'package:chess_tn/features/about/presentation/about_screen.dart';
import 'package:chess_tn/features/about/presentation/bug_report_screen.dart';
import 'package:chess_tn/features/home/presentation/home_screen.dart';
import 'package:chess_tn/features/settings/presentation/settings_screen.dart';
import 'package:chess_tn/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

AppLocalizations lookupL10n(String code) =>
    lookupAppLocalizations(Locale(code));

void main() {
  testWidgets('the app is called chess.tn and shows the official logo', (
    tester,
  ) async {
    final app = await AppHarness.start(tester, home: const HomeScreen());
    final material = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(material.title, 'chess.tn');

    final logo = tester.widget<Image>(
      find.descendant(of: find.byType(BrandLogo), matching: find.byType(Image)),
    );
    expect((logo.image as AssetImage).assetName, AppBranding.logo);
    expect(logo.fit, BoxFit.contain, reason: 'never stretched');
    expect(logo.color, isNull, reason: 'never tinted');
    expect(tester.takeException(), isNull, reason: 'the asset is bundled');

    expect(find.textContaining('Tounsi'), findsNothing);
    await app.finish();
  });

  testWidgets('home leads to About chess.tn', (tester) async {
    final app = await AppHarness.start(tester, home: const HomeScreen());
    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await app.wait(600);
    expect(find.byType(AboutScreen), findsOneWidget);
    await app.finish();
  });

  testWidgets('settings has About, bug report, feedback and the signature', (
    tester,
  ) async {
    final app = await AppHarness.start(tester, home: const SettingsScreen());
    final ar = app.l10n('ar');
    final about = find.text(ar.aboutTitle(AppBranding.name));
    await app.reveal(about);
    await app.reveal(find.byType(DeveloperSignature));
    expect(find.text(ar.reportBug), findsOneWidget);
    expect(find.text(ar.sendFeedback), findsOneWidget);
    expect(
      find.text('chess.tn · ${ar.developedBy(DeveloperLinks.name)}'),
      findsOneWidget,
    );

    await tester.tap(find.text(ar.sendFeedback));
    await app.wait(300);
    expect(
      app.links.opened.single.queryParameters['subject'],
      '[chess.tn Feedback]',
    );

    await tester.tap(about);
    await app.wait(600);
    expect(find.byType(AboutScreen), findsOneWidget);
    await app.finish();
  });

  for (final code in ['ar', 'en', 'fr']) {
    testWidgets('About page content is localized ($code)', (tester) async {
      final app = await AppHarness.start(
        tester,
        home: const AboutScreen(),
        preferences: {'language': code},
      );
      final l10n = app.l10n(code);
      expect(find.text(l10n.aboutTitle('chess.tn')), findsOneWidget);
      expect(find.byType(BrandLogo), findsOneWidget);
      expect(find.text(l10n.aboutSlogan), findsOneWidget);
      expect(find.text(l10n.aboutSpecialBody), findsOneWidget);

      await app.reveal(find.text(l10n.developedBy('Iheb El Ech')));
      expect(find.text(l10n.madeInTunisiaFlag), findsOneWidget);

      await app.reveal(find.text(l10n.linkEmail));
      expect(find.text(l10n.contactDeveloper), findsOneWidget);
      expect(find.text(l10n.reportBug), findsOneWidget);
      expect(find.text(l10n.sendFeedback), findsOneWidget);
      expect(find.text(l10n.followDeveloper), findsOneWidget);

      await app.reveal(find.text('© 2026 Iheb El Ech'));
      // The version comes from the package, not from a string in the UI.
      expect(find.text(l10n.versionLabel(AppHarness.version)), findsOneWidget);
      // Long URLs are never shown as text.
      expect(find.textContaining('http'), findsNothing);
      expect(find.textContaining('@gmail'), findsNothing);
      await app.finish();
    });
  }

  testWidgets('every contact button opens the right link', (tester) async {
    final app = await AppHarness.start(
      tester,
      home: const AboutScreen(),
      preferences: {'language': 'en'},
    );
    final en = app.l10n('en');

    Future<Uri> tap(String label) async {
      final finder = find.text(label);
      await app.reveal(finder);
      await tester.tap(finder);
      await app.wait(300);
      return app.links.opened.last;
    }

    final contact = await tap(en.contactDeveloper);
    expect(contact.scheme, 'mailto');
    expect(contact.path, DeveloperLinks.email);
    expect(contact.queryParameters['subject'], '[chess.tn Contact]');

    final feedback = await tap(en.sendFeedback);
    expect(feedback.queryParameters['subject'], '[chess.tn Feedback]');
    expect(feedback.queryParameters['body'], contains('chess.tn 1.0.0'));

    final suggestion = await tap(en.sendSuggestion);
    expect(suggestion.queryParameters['subject'], '[chess.tn Suggestion]');

    expect(await tap(en.linkGithub), DeveloperLinks.github);
    expect(await tap(en.linkLinkedin), DeveloperLinks.linkedin);
    expect(await tap(en.linkInstagram), DeveloperLinks.instagram);
    expect(await tap(en.linkFacebook), DeveloperLinks.facebook);
    expect(
      (await tap(en.linkEmail)).toString(),
      'mailto:ihebelleuch6@gmail.com',
    );
    expect(app.links.opened, hasLength(8));
    await app.finish();
  });

  testWidgets('a link that cannot be opened is copied instead', (tester) async {
    final app = await AppHarness.start(
      tester,
      home: const AboutScreen(),
      preferences: {'language': 'en'},
    );
    final en = app.l10n('en');
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    app.links.succeeds = false;
    await app.reveal(find.text(en.linkGithub));
    await tester.tap(find.text(en.linkGithub));
    await app.wait(600);
    expect(find.text(en.linkOpenFailed), findsOneWidget);
    expect(copied, 'https://github.com/ElEchIheb/');
    await app.finish();
  });

  testWidgets('Report a Bug builds an email draft, and nothing else', (
    tester,
  ) async {
    final app = await AppHarness.start(
      tester,
      home: const BugReportScreen(),
      preferences: {'language': 'en'},
    );
    final en = app.l10n('en');
    expect(find.text(en.bugWhatWentWrong), findsOneWidget);

    GameButton send() => tester.widget<GameButton>(
      find.widgetWithText(GameButton, en.contactDeveloper),
    );
    expect(send().onPressed, isNull, reason: 'a description is required');

    await tester.enterText(find.byType(TextField), 'Rook vanished on reveal');
    await app.wait(200);
    await tester.tap(find.text('${en.specialChess} · ${en.vsFriend}'));
    await app.wait(200);
    expect(send().onPressed, isNotNull);
    expect(app.links.opened, isEmpty, reason: 'nothing is sent by itself');

    await tester.tap(find.text(en.contactDeveloper));
    await app.wait(400);
    final draft = app.links.opened.single;
    expect(draft.scheme, 'mailto');
    expect(draft.path, 'ihebelleuch6@gmail.com');
    expect(draft.queryParameters['subject'], '[chess.tn Bug Report]');
    expect(
      draft.queryParameters['body'],
      'Game version: 1.0.0\n'
      'Platform: android 15\n'
      'Game mode: Special Chess · vs a friend\n'
      'Description:\n'
      'Rook vanished on reveal',
    );

    // Device information is optional.
    await tester.tap(find.text(en.bugIncludeDevice));
    await app.wait(200);
    await tester.tap(find.text(en.contactDeveloper));
    await app.wait(400);
    expect(
      app.links.opened.last.queryParameters['body'],
      contains('Platform: -'),
    );
    await app.finish();
  });

  testWidgets('the bug report form is localized', (tester) async {
    for (final code in ['ar', 'fr']) {
      final app = await AppHarness.start(
        tester,
        home: const BugReportScreen(),
        preferences: {'language': code},
      );
      final l10n = app.l10n(code);
      expect(find.text(l10n.reportBug), findsOneWidget);
      expect(find.text(l10n.bugWhatWentWrong), findsOneWidget);
      expect(find.text(l10n.contactDeveloper), findsOneWidget);
      await app.finish();
    }
    expect(lookupL10n('ar').bugWhatWentWrong, 'شنوة المشكلة؟');
    expect(lookupL10n('fr').bugWhatWentWrong, 'Quel est le problème ?');
    expect(lookupL10n('fr').aboutTitle('chess.tn'), 'À propos de chess.tn');
    expect(lookupL10n('ar').madeInTunisia, 'مصنوعة في تونس');
  });
}
