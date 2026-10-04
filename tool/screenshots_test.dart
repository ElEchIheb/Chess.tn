// ignore_for_file: invalid_use_of_visible_for_testing_member

// Renders the main screens to docs/screenshots/*.png.
//
//   flutter test tool/screenshots_test.dart
//
// The screens are the real widgets driven by real sessions; only the sound
// and the chess engine are replaced by test doubles.
import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:chess_tn/app.dart';
import 'package:chess_tn/core/audio/sound_service.dart';
import 'package:chess_tn/core/constants/app_branding.dart';
import 'package:chess_tn/core/widgets/tilt_carousel.dart';
import 'package:chess_tn/features/home/presentation/new_ai_game_screen.dart';
import 'package:chess_tn/features/about/application/link_launcher.dart';
import 'package:chess_tn/features/about/presentation/about_screen.dart';
import 'package:chess_tn/features/about/presentation/bug_report_screen.dart';
import 'package:chess_tn/features/ai/data/minimax_engine.dart';
import 'package:chess_tn/features/ai/domain/ai_level.dart';
import 'package:chess_tn/features/chess/application/game_controller.dart';
import 'package:chess_tn/features/chess/domain/game_state.dart';
import 'package:chess_tn/features/chess/domain/match_authority.dart';
import 'package:chess_tn/features/chess/presentation/game_screen.dart';
import 'package:chess_tn/features/chess/presentation/widgets/chess_board.dart';
import 'package:chess_tn/features/home/presentation/home_screen.dart';
import 'package:chess_tn/features/multiplayer/presentation/friend_screens.dart';
import 'package:chess_tn/features/settings/application/settings_controller.dart';
import 'package:chess_tn/features/settings/presentation/settings_screen.dart';
import 'package:chess_tn/features/special_mode/domain/army_placement.dart';
import 'package:chess_tn/features/special_mode/presentation/setup_stage.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Size phone = Size(412, 892);
const double pixelRatio = 2;
const String fontFamily = 'ScreenshotFont';
final GlobalKey shotKey = GlobalKey();

Future<void> loadFonts() async {
  Future<void> load(String family, String path) async {
    final file = io.File(path);
    if (!file.existsSync()) return;
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();
  }

  // Any system font with Latin + Arabic glyphs will do for the pictures.
  await load(fontFamily, r'C:\Windows\Fonts\segoeuib.ttf');
  await load(fontFamily, r'C:\Windows\Fonts\segoeui.ttf');
  // Brand icons (GitHub, LinkedIn...) come from the font_awesome_flutter
  // package; tests do not load package fonts by themselves.
  final packages = jsonDecode(
    io.File('.dart_tool/package_config.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  for (final package in packages['packages'] as List<dynamic>) {
    if ((package as Map<String, dynamic>)['name'] != 'font_awesome_flutter') {
      continue;
    }
    final fonts =
        '${Uri.parse(package['rootUri'] as String).toFilePath()}'
        'lib/fonts';
    const prefix = 'packages/font_awesome_flutter';
    await load(
      '$prefix/FontAwesomeBrands',
      '$fonts/Font-Awesome-7-Brands-Regular-400.otf',
    );
    await load(
      '$prefix/FontAwesomeSolid',
      '$fonts/Font-Awesome-7-Free-Solid-900.otf',
    );
  }
  final flutterRoot = io.Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    await load(
      'MaterialIcons',
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
  }
}

Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  Widget? home,
  String language = 'ar',
}) async {
  tester.view.physicalSize = phone * pixelRatio;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'language': language});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      soundServiceProvider.overrideWithValue(SilentSoundService()),
      appVersionProvider.overrideWith((ref) async => '1.0.0'),
      platformDescriptionProvider.overrideWithValue('android 15'),
      chessEngineProvider.overrideWithValue(
        MinimaxEngine(random: Random(4), useIsolate: false),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(
        key: shotKey,
        child: ChessTnApp(home: home, fontFamily: fontFamily),
      ),
    ),
  );
  // Decode the logo for real: image decoding does not advance with the
  // test's fake clock.
  await tester.runAsync(() async {
    final context = tester.element(find.byType(MaterialApp));
    await precacheImage(const AssetImage(AppBranding.logo), context);
    await precacheImage(const AssetImage(AppBranding.emblem), context);
  });
  await tester.pump(const Duration(milliseconds: 400));
  return container;
}

Future<void> shoot(WidgetTester tester, String name) async {
  // Two extra frames so implicit animations started by the last change are
  // past their first frame.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
  final boundary =
      shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    io.File('docs/screenshots/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// Unmounts everything so periodic timers and animations stop.
Future<void> finish(WidgetTester tester, ProviderContainer container) async {
  unawaited(container.read(gameControllerProvider.notifier).leave());
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

ArmyPlacement army(Side side, List<String> rows) {
  final pieces = <Square, Role>{};
  for (var r = 0; r < rows.length; r++) {
    for (var f = 0; f < 8; f++) {
      final char = rows[r][f];
      if (char == '.') continue;
      pieces[Square.fromCoords(File(f), Rank(side == Side.white ? r : 7 - r))] =
          Role.fromChar(char)!;
    }
  }
  return ArmyPlacement(side, pieces);
}

final ArmyPlacement whiteArmy = army(Side.white, [
  '..r.r.k.',
  '..bbqppp',
  'ppp.nn..',
  '...pp...',
]);
final ArmyPlacement blackArmy = army(Side.black, [
  '.k.r.r..',
  'pppqbb..',
  '..nn.ppp',
  '....pp..',
]);

void main() {
  setUpAll(loadFonts);

  for (final language in ['ar', 'en', 'fr']) {
    testWidgets('home ($language)', (tester) async {
      final container = await pumpApp(
        tester,
        home: const HomeScreen(),
        language: language,
      );
      await shoot(tester, 'home_$language');
      await finish(tester, container);
    });
  }

  testWidgets('splash', (tester) async {
    final container = await pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 700));
    await shoot(tester, 'splash_ar');
    await tester.pump(const Duration(seconds: 3));
    await finish(tester, container);
  });

  for (final language in ['ar', 'en']) {
    testWidgets('about ($language)', (tester) async {
      final container = await pumpApp(
        tester,
        home: const AboutScreen(),
        language: language,
      );
      await shoot(tester, 'about_$language');
      await tester.drag(find.byType(ListView), const Offset(0, -620));
      await shoot(tester, 'about_contact_$language');
      await finish(tester, container);
    });
  }

  testWidgets('bug report', (tester) async {
    final container = await pumpApp(
      tester,
      home: const BugReportScreen(),
      language: 'en',
    );
    await tester.enterText(
      find.byType(TextField),
      'The curtain stayed closed after the countdown.',
    );
    await shoot(tester, 'bug_report_en');
    await finish(tester, container);
  });

  testWidgets('home, swiping to the Special card', (tester) async {
    final container = await pumpApp(tester, home: const HomeScreen());
    final carousel = find.byType(TiltCarousel).first;
    // Half-way through the swipe: both cards turned in 3D.
    final gesture = await tester.startGesture(tester.getCenter(carousel));
    await gesture.moveBy(const Offset(40, 0));
    await gesture.moveBy(const Offset(130, 0));
    await shoot(tester, 'home_swipe_ar');
    await gesture.moveBy(const Offset(200, 0));
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
    await shoot(tester, 'home_special_ar');
    await finish(tester, container);
  });

  testWidgets('match settings', (tester) async {
    final container = await pumpApp(
      tester,
      home: const NewAiGameScreen(variant: GameVariant.normal),
    );
    await shoot(tester, 'ai_levels_ar');
    await finish(tester, container);
  });

  testWidgets('settings', (tester) async {
    final container = await pumpApp(tester, home: const SettingsScreen());
    await shoot(tester, 'settings_ar');
    await finish(tester, container);
  });

  testWidgets('friend menu', (tester) async {
    final container = await pumpApp(
      tester,
      home: const FriendMenuScreen(variant: GameVariant.special),
    );
    await shoot(tester, 'friend_ar');
    await finish(tester, container);
  });

  testWidgets('normal game vs AI', (tester) async {
    final container = await pumpApp(tester, home: const GameScreen());
    final controller = container.read(gameControllerProvider.notifier)
      ..startLocal(
        const GameConfig(
          variant: GameVariant.normal,
          opponent: OpponentType.ai,
          aiLevel: AiLevel.medium,
        ),
      );
    await tester.pump(const Duration(milliseconds: 300));
    for (final uci in ['e2e4', 'g1f3', 'f1c4', 'd2d3']) {
      final move = Move.parse(uci)! as NormalMove;
      if (!controller.session!.current.game.isLegal(move)) break;
      controller.session!.playMove(move);
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump(const Duration(milliseconds: 600));
    }
    // Select a piece to show the legal-move hints.
    // Select the f3 knight to show the legal-move hints.
    final board = tester.getRect(find.byType(ChessBoard));
    final cell = board.width / 8;
    await tester.tapAt(board.topLeft + Offset(cell * 5.5, cell * 5.5));
    await shoot(tester, 'game_ar');
    await finish(tester, container);
  });

  testWidgets('special mode: setup, reveal, battle, result', (tester) async {
    final container = await pumpApp(tester, home: const GameScreen());
    final controller = container.read(gameControllerProvider.notifier)
      ..startLocal(
        const GameConfig(
          variant: GameVariant.special,
          opponent: OpponentType.ai,
          aiLevel: AiLevel.hard,
        ),
      );
    await tester.pump(const Duration(milliseconds: 500));
    await shoot(tester, 'special_setup_empty_ar');

    // Build an army through the real UI: tap squares with the tray's
    // currently selected piece, then let "auto place" finish the job.
    final stage = find.byType(SetupStage);
    expect(stage, findsOneWidget);
    await tester.tap(find.byIcon(Icons.auto_awesome_rounded));
    await tester.pump(const Duration(seconds: 5));
    await shoot(tester, 'special_setup_ready_ar');

    final session = controller.session!;
    session.submitSetup(whiteArmy);
    await tester.pump(const Duration(milliseconds: 100));
    await shoot(tester, 'special_reveal_1_ar');
    await tester.pump(const Duration(milliseconds: 900));
    await shoot(tester, 'special_reveal_2_ar');
    await tester.pump(const Duration(milliseconds: 1700));
    await shoot(tester, 'special_reveal_3_ar');
    await tester.pump(const Duration(milliseconds: 900));
    await shoot(tester, 'special_reveal_4_ar');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await shoot(tester, 'special_battle_ar');

    session.resign();
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 600));
    await shoot(tester, 'special_result_ar');
    await finish(tester, container);
  });
}
