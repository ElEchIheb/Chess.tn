import 'dart:async';
import 'dart:math';

import 'package:chess_tn/app.dart';
import 'package:chess_tn/core/audio/sound_service.dart';
import 'package:chess_tn/core/widgets/tilt_carousel.dart';
import 'package:chess_tn/features/about/application/link_launcher.dart';
import 'package:chess_tn/features/ai/data/minimax_engine.dart';
import 'package:chess_tn/features/chess/application/game_controller.dart';
import 'package:chess_tn/features/chess/domain/game_state.dart';
import 'package:chess_tn/features/chess/presentation/widgets/chess_board.dart';
import 'package:chess_tn/features/settings/application/settings_controller.dart';
import 'package:chess_tn/l10n/app_localizations.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records the links the app tries to open instead of leaving the test.
class FakeLinkLauncher implements LinkLauncher {
  final List<Uri> opened = [];

  /// Set to false to simulate a device with no app for the link.
  bool succeeds = true;

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return succeeds;
  }
}

/// The real app on a phone-sized screen, with silent audio and the built-in
/// engine running inline (no isolates, no native code).
class AppHarness {
  AppHarness._(this.tester, this.container, this.sound, this.links);

  final WidgetTester tester;
  final ProviderContainer container;
  final SilentSoundService sound;
  final FakeLinkLauncher links;

  static const String version = '1.0.0';

  static Future<AppHarness> start(
    WidgetTester tester, {
    Widget? home,
    Map<String, Object> preferences = const {},
    Size size = const Size(412, 892),
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(preferences);
    final prefs = await SharedPreferences.getInstance();
    final sound = SilentSoundService();
    final links = FakeLinkLauncher();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        soundServiceProvider.overrideWithValue(sound),
        linkLauncherProvider.overrideWithValue(links),
        appVersionProvider.overrideWith((ref) async => version),
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
        child: ChessTnApp(home: home),
      ),
    );
    final harness = AppHarness._(tester, container, sound, links);
    await harness.wait(400);
    return harness;
  }

  GameController get game => container.read(gameControllerProvider.notifier);
  GameState? get state => container.read(gameControllerProvider);

  AppLocalizations l10n(String code) => lookupAppLocalizations(Locale(code));

  /// Advances the clock; several frames so animations really progress.
  Future<void> wait(int milliseconds) async {
    const frame = 100;
    for (var t = 0; t < milliseconds; t += frame) {
      await tester.pump(const Duration(milliseconds: frame));
    }
  }

  /// Centre of [square] on the board currently on screen.
  Offset squareCenter(Square square) {
    final rect = tester.getRect(find.byType(ChessBoard));
    final cell = rect.width / 8;
    final orientation = state!.orientation;
    final column = orientation == Side.white
        ? square.file.value
        : 7 - square.file.value;
    final row = orientation == Side.white
        ? 7 - square.rank.value
        : square.rank.value;
    return rect.topLeft + Offset((column + 0.5) * cell, (row + 0.5) * cell);
  }

  Future<void> tapSquare(Square square) async {
    await tester.tapAt(squareCenter(square));
    await tester.pump();
  }

  /// Swipes the home carousel to the next game mode.
  Future<void> swipeToNextMode() async {
    final carousel = find.byType(TiltCarousel).first;
    final rtl =
        Directionality.of(tester.element(carousel)) == TextDirection.rtl;
    await tester.fling(carousel, Offset(rtl ? 320 : -320, 0), 1500);
    await wait(900);
  }

  /// Scrolls the page until [finder] is fully on screen.
  Future<void> reveal(Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await wait(300);
  }

  /// Leaves the game and unmounts the app so no timer outlives the test.
  Future<void> finish() async {
    // Not awaited: inside the test's fake clock that future only resolves
    // while frames are pumped, which the lines below do.
    unawaited(game.leave());
    await tester.pumpWidget(const SizedBox.shrink());
    await wait(1500);
  }
}
