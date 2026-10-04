import 'package:chess_tn/core/widgets/game_button.dart';
import 'package:chess_tn/core/widgets/tilt_carousel.dart';
import 'package:chess_tn/features/chess/domain/game_state.dart';
import 'package:chess_tn/features/chess/domain/match_authority.dart';
import 'package:chess_tn/features/chess/presentation/game_screen.dart';
import 'package:chess_tn/features/home/presentation/home_screen.dart';
import 'package:chess_tn/features/home/presentation/new_ai_game_screen.dart';
import 'package:chess_tn/features/multiplayer/presentation/friend_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('a GameButton presses down and fires once', (tester) async {
    final app = await AppHarness.start(
      tester,
      home: const NewAiGameScreen(variant: GameVariant.normal),
    );
    final label = app.l10n('ar').startGame;
    final button = find.widgetWithText(GameButton, label);
    final face = find.descendant(
      of: button,
      matching: find.byType(AnimatedContainer),
    );
    final restingTop = tester.getTopLeft(find.text(label)).dy;
    expect(tester.widget<AnimatedContainer>(face).margin, isNotNull);

    final gesture = await tester.startGesture(tester.getCenter(button));
    await app.wait(200);
    expect(
      tester.getTopLeft(find.text(label)).dy,
      greaterThan(restingTop),
      reason: 'the face sinks while the finger is down',
    );
    await gesture.up();
    await app.wait(1200);
    expect(find.byType(GameScreen), findsOneWidget);
    await app.finish();
  });

  testWidgets('a disabled GameButton does nothing', (tester) async {
    var taps = 0;
    final app = await AppHarness.start(
      tester,
      home: Scaffold(
        body: Column(
          children: [
            const GameButton(label: 'off', onPressed: null),
            GameButton(label: 'on', onPressed: () => taps++),
          ],
        ),
      ),
    );
    await tester.tap(find.text('off'));
    await tester.tap(find.text('on'));
    await app.wait(200);
    expect(taps, 1);
    await app.finish();
  });

  testWidgets('swiping the home carousel changes the mode in front', (
    tester,
  ) async {
    final app = await AppHarness.start(tester, home: const HomeScreen());
    final ar = app.l10n('ar');
    DiamondDots dots() => tester.widget<DiamondDots>(find.byType(DiamondDots));
    expect(dots().active, 0);
    expect(find.text(ar.normalChess), findsOneWidget);

    await app.swipeToNextMode();
    expect(dots().active, 1);

    // The card in front opens the friend menu for its own mode.
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(GameCard, ar.specialChess),
        matching: find.text(ar.vsFriend),
      ),
    );
    await app.wait(800);
    final menu = tester.widget<FriendMenuScreen>(find.byType(FriendMenuScreen));
    expect(menu.variant, GameVariant.special);
    await app.finish();
  });

  testWidgets('the play-as tiles choose the side', (tester) async {
    final app = await AppHarness.start(
      tester,
      home: const NewAiGameScreen(variant: GameVariant.normal),
    );
    final ar = app.l10n('ar');
    await tester.tap(find.text(ar.colorBlack));
    await app.wait(200);
    await tester.tap(find.text(ar.startGame));
    await app.wait(1500);
    expect(app.state!.config.opponent, OpponentType.ai);
    expect(app.state!.orientation.name, 'black');
    await app.finish();
  });

  for (final size in [const Size(320, 568), const Size(360, 640)]) {
    testWidgets('home and match settings fit a ${size.width.round()}px phone', (
      tester,
    ) async {
      final app = await AppHarness.start(
        tester,
        home: const HomeScreen(),
        size: size,
      );
      expect(tester.takeException(), isNull);
      await app.swipeToNextMode();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(app.l10n('ar').vsAi).last);
      await app.wait(800);
      expect(find.byType(NewAiGameScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await app.finish();
    });
  }
}
