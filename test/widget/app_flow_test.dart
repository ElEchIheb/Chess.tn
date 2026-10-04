import 'package:chess_tn/core/audio/sound_service.dart';
import 'package:chess_tn/core/constants/developer_links.dart';
import 'package:chess_tn/core/widgets/brand_logo.dart';
import 'package:chess_tn/core/widgets/game_button.dart';
import 'package:chess_tn/core/widgets/tilt_carousel.dart';
import 'package:chess_tn/features/home/presentation/new_ai_game_screen.dart';
import 'package:chess_tn/features/home/presentation/splash_screen.dart';
import 'package:chess_tn/core/theme/board_theme.dart';
import 'package:chess_tn/core/utils/l10n_ext.dart';
import 'package:chess_tn/features/ai/domain/ai_level.dart';
import 'package:chess_tn/features/chess/domain/chess_game.dart';
import 'package:chess_tn/features/chess/domain/game_phase.dart';
import 'package:chess_tn/features/chess/domain/game_state.dart';
import 'package:chess_tn/features/chess/domain/match_authority.dart';
import 'package:chess_tn/features/chess/presentation/game_screen.dart';
import 'package:chess_tn/features/chess/presentation/widgets/chess_board.dart';
import 'package:chess_tn/features/chess/presentation/widgets/chess_piece.dart';
import 'package:chess_tn/features/chess/presentation/widgets/result_panel.dart';
import 'package:chess_tn/features/home/presentation/home_screen.dart';
import 'package:chess_tn/features/settings/application/settings_controller.dart';
import 'package:chess_tn/features/settings/domain/app_settings.dart';
import 'package:chess_tn/features/settings/presentation/settings_screen.dart';
import 'package:chess_tn/features/special_mode/presentation/reveal_stage.dart';
import 'package:chess_tn/features/special_mode/presentation/setup_stage.dart';
import 'package:chess_tn/features/special_mode/presentation/widgets/curtain.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  group('Launch', () {
    testWidgets('opens on the home screen in Tunisian Arabic, no login', (
      tester,
    ) async {
      final app = await AppHarness.start(tester);
      // Splash: the official logo and the developer line...
      await app.wait(1200);
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(BrandLogo), findsOneWidget);
      expect(
        find.text(app.l10n('ar').developedBy(DeveloperLinks.name)),
        findsOneWidget,
      );
      // ...then home.
      await app.wait(2200);
      final ar = app.l10n('ar');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text(ar.normalChess), findsOneWidget);
      expect(find.text(ar.specialChess), findsOneWidget);
      expect(find.text(ar.specialChessSubtitle), findsOneWidget);
      expect(find.text(ar.vsAi), findsNWidgets(2));
      expect(find.text(ar.vsFriend), findsNWidgets(2));
      expect(
        Directionality.of(tester.element(find.byType(HomeScreen))),
        TextDirection.rtl,
      );
      expect(find.byType(TextField), findsNothing, reason: 'no sign-in form');
      expect(app.container.read(settingsProvider).language, AppLanguage.darija);
      await app.finish();
    });
  });

  group('Language', () {
    testWidgets('Darija -> English -> French updates every screen', (
      tester,
    ) async {
      final app = await AppHarness.start(tester, home: const HomeScreen());
      final ar = app.l10n('ar');
      final en = app.l10n('en');
      final fr = app.l10n('fr');
      expect(find.text(ar.normalChess), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await app.wait(600);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text(ar.settings), findsOneWidget);

      await tester.tap(find.text(ar.languageEnglish));
      await app.wait(300);
      expect(find.text(en.settings), findsOneWidget);
      expect(find.text(en.sound), findsOneWidget);
      expect(find.text(ar.settings), findsNothing);

      await tester.tap(find.text(en.languageFrench));
      await app.wait(300);
      expect(find.text(fr.settings), findsOneWidget);
      expect(find.text(fr.music), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await app.wait(600);
      expect(find.text(fr.normalChess), findsOneWidget);
      expect(find.text(fr.specialChessSubtitle), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(HomeScreen))),
        TextDirection.ltr,
      );

      // The game screen follows too.
      app.game.startLocal(
        const GameConfig(
          variant: GameVariant.normal,
          opponent: OpponentType.passAndPlay,
        ),
      );
      Navigator.of(tester.element(find.byType(HomeScreen)))
          .push(MaterialPageRoute<void>(builder: (_) => const GameScreen()));
      await app.wait(800);
      expect(find.text(fr.whiteToMove), findsOneWidget);
      expect(find.text(fr.resign), findsOneWidget);

      // The choice is remembered.
      expect(app.container.read(settingsProvider).language, AppLanguage.french);
      await app.finish();
    });

    testWidgets('a saved language is restored at launch', (tester) async {
      final app = await AppHarness.start(
        tester,
        home: const HomeScreen(),
        preferences: {'language': 'en'},
      );
      expect(find.text(app.l10n('en').normalChess), findsOneWidget);
      await app.finish();
    });
  });

  group('Normal chess vs AI', () {
    testWidgets('home -> level 1 -> play moves on the board', (tester) async {
      final app = await AppHarness.start(tester, home: const HomeScreen());
      final ar = app.l10n('ar');

      await tester.tap(find.text(ar.vsAi).first);
      await app.wait(800);
      expect(find.byType(NewAiGameScreen), findsOneWidget);
      expect(find.text(ar.chooseLevel), findsOneWidget);
      expect(find.text(ar.chooseColor), findsOneWidget);
      // The level wheel opens on the saved level (3); step down to 1.
      expect(find.text(ar.level3), findsOneWidget);
      await tester.tap(find.byKey(const Key('level-prev')));
      await app.wait(500);
      await tester.tap(find.byKey(const Key('level-prev')));
      await app.wait(500);
      expect(find.text(ar.level1), findsOneWidget);
      // Swiping the wheel works too: forward one level and back again.
      await tester.fling(find.byType(TiltCarousel), const Offset(-140, 0), 900);
      await app.wait(700);
      expect(
        tester
            .widget<GameIconButton>(find.byKey(const Key('level-prev')))
            .onPressed,
        isNotNull,
        reason: 'no longer on the first level',
      );
      await tester.tap(find.byKey(const Key('level-prev')));
      await app.wait(500);
      await tester.tap(find.text(ar.startGame));
      await app.wait(1400);

      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.byType(ChessBoard), findsOneWidget);
      expect(find.byType(ChessPiece), findsNWidgets(32 + 2));
      final state = app.state!;
      expect(state.config.aiLevel, AiLevel.veryEasy);
      expect(state.phase, GamePhase.playing);
      expect(state.game.fen, ChessGame.standard().fen);
      expect(find.text(ar.yourTurn), findsOneWidget);

      // Tap-to-move: e2 then e4. The AI answers by itself.
      await app.tapSquare(Square.e2);
      await app.tapSquare(Square.e4);
      await app.wait(1500);
      expect(app.state!.game.ply, 2);
      expect(app.state!.game.history.first.uci, 'e2e4');
      expect(app.sound.played, contains(Sfx.move));

      // A tap on an illegal target does nothing.
      await app.tapSquare(Square.d2);
      await app.tapSquare(Square.d5);
      await app.wait(300);
      expect(app.state!.game.ply, 2);

      // Take back.
      await tester.tap(find.text(ar.undo));
      await app.wait(300);
      expect(app.state!.game.ply, 0);
      await app.finish();
    });

    testWidgets('drag and drop moves a piece', (tester) async {
      final app = await AppHarness.start(tester, home: const GameScreen());
      app.game.startLocal(
        const GameConfig(
          variant: GameVariant.normal,
          opponent: OpponentType.passAndPlay,
        ),
      );
      await app.wait(500);
      await tester.dragFrom(
        app.squareCenter(Square.g1),
        app.squareCenter(Square.f3) - app.squareCenter(Square.g1),
      );
      await app.wait(400);
      expect(app.state!.game.history.single.san, 'Nf3');
      await app.finish();
    });

    testWidgets('promotion asks which piece', (tester) async {
      final app = await AppHarness.start(tester, home: const GameScreen());
      app.game.startLocal(
        const GameConfig(
          variant: GameVariant.normal,
          opponent: OpponentType.passAndPlay,
        ),
      );
      await app.wait(300);
      // Fast-forward to a promotion: 1.h4 g5 2.hxg5 h6 3.g6 Nf6 4.g7 Ne4.
      for (final uci in [
        'h2h4',
        'g7g5',
        'h4g5',
        'h7h6',
        'g5g6',
        'g8f6',
        'g6g7',
        'f6e4',
      ]) {
        app.game.session!.playMove(Move.parse(uci)! as NormalMove);
      }
      await app.wait(600);
      await app.tapSquare(Square.g7);
      await app.tapSquare(Square.h8);
      await app.wait(600);
      final ar = app.l10n('ar');
      expect(find.text(ar.promoteTitle), findsOneWidget);
      await tester.tap(find.text(ar.pieceKnight));
      await app.wait(600);
      expect(app.state!.game.lastMove!.uci, 'g7h8n');
      expect(
        app.state!.game.position.board.pieceAt(Square.h8),
        Piece.whiteKnight,
      );
      await app.finish();
    });

    testWidgets('checkmate shows the result screen and a rematch works', (
      tester,
    ) async {
      final app = await AppHarness.start(tester, home: const GameScreen());
      app.game.startLocal(
        const GameConfig(
          variant: GameVariant.normal,
          opponent: OpponentType.passAndPlay,
        ),
      );
      await app.wait(300);
      for (final uci in ['f2f3', 'e7e5', 'g2g4', 'd8h4']) {
        app.game.session!.playMove(Move.parse(uci)! as NormalMove);
      }
      await app.wait(2200);
      final ar = app.l10n('ar');
      expect(find.byType(ResultPanel), findsOneWidget);
      expect(find.text(ar.blackWins), findsOneWidget);
      expect(find.text(ar.reasonCheckmate), findsOneWidget);
      expect(app.sound.played, contains(Sfx.win));

      await tester.tap(find.text(ar.playAgain));
      await app.wait(800);
      expect(app.state!.phase, GamePhase.playing);
      expect(app.state!.game.ply, 0);
      await app.finish();
    });
  });

  group('Special chess vs AI', () {
    testWidgets('private setup, curtain, reveal, then battle', (tester) async {
      final app = await AppHarness.start(tester, home: const HomeScreen());
      final ar = app.l10n('ar');

      // Swipe the 3D carousel to the Special card.
      await app.swipeToNextMode();
      await tester.tap(
        find.descendant(
          of: find.widgetWithText(GameCard, ar.specialChess),
          matching: find.text(ar.vsAi),
        ),
      );
      await app.wait(800);
      await tester.tap(find.text(ar.startGame));
      await app.wait(1200);

      // Private setup: the curtain is down, no AI piece exists in the UI.
      expect(find.byType(SetupStage), findsOneWidget);
      expect(find.byType(Curtain), findsOneWidget);
      expect(find.text(ar.buildYourArmy), findsOneWidget);
      expect(find.text(ar.opponentHidden), findsOneWidget);
      expect(app.state!.blackArmy, isNull);
      Iterable<ChessPiece> pieces() =>
          tester.widgetList<ChessPiece>(find.byType(ChessPiece));
      expect(pieces().where((p) => p.piece.color == Side.black), isEmpty);

      // "Done" is disabled until the army is complete.
      GameButton done() =>
          tester.widget<GameButton>(find.widgetWithText(GameButton, ar.done));
      expect(done().onPressed, isNull);

      // Place the king by tap: tray piece is preselected, tap g1.
      final board = tester.getRect(find.byType(Curtain));
      final cell = board.width / 8;
      Offset square(int file, int rankFromBottom) => Offset(
        board.left + (file + 0.5) * cell,
        board.top + (8 - rankFromBottom - 0.5) * cell,
      );
      await tester.tapAt(square(6, 0));
      await app.wait(200);
      expect(find.text('×0'), findsOneWidget, reason: 'king placed');

      // A pawn on the back rank is refused with an explanation.
      await tester.tap(find.text('×8'));
      await app.wait(200);
      await tester.tapAt(square(0, 0));
      await app.wait(200);
      expect(find.text(ar.pawnBackRank), findsOneWidget);
      expect(find.text('×8'), findsOneWidget);
      expect(app.sound.played, contains(Sfx.illegal));

      // Let the game place the rest, then confirm.
      await tester.tap(find.byIcon(Icons.auto_awesome_rounded));
      await app.wait(400);
      expect(find.text(ar.allPlaced), findsOneWidget);
      expect(pieces().where((p) => p.piece.color == Side.black), isEmpty);
      expect(done().onPressed, isNotNull);
      await tester.tap(find.text(ar.done));
      await app.wait(300);

      // Reveal: countdown, curtain, both armies.
      expect(find.byType(RevealStage), findsOneWidget);
      expect(find.text(ar.armiesReady), findsOneWidget);
      expect(app.state!.phase, GamePhase.reveal);
      expect(app.state!.blackArmy!.total, 16);
      await app.wait(1300);
      expect(find.text('3'), findsOneWidget);
      await app.wait(2600);
      expect(find.text(ar.revealWord), findsOneWidget);
      expect(
        app.sound.played,
        containsAll([Sfx.tick, Sfx.curtain, Sfx.reveal]),
      );
      await app.wait(1800);
      expect(find.text(ar.battleBegins), findsOneWidget);
      await app.wait(1500);

      // Battle (possibly after rescuing a king under fire).
      var state = app.state!;
      if (state.phase == GamePhase.kingRescue) {
        if (state.canRescue) {
          await app.tapSquare(state.rescueSquares.first);
        }
        await app.wait(2500);
        state = app.state!;
      }
      expect(state.phase, GamePhase.playing);
      expect(find.byType(ChessBoard), findsOneWidget);
      expect(state.game.initialFen, isNot(ChessGame.standard().fen));
      expect(
        state.game.initialPosition.board.kingOf(Side.white),
        state.whiteArmy!.kingSquare,
      );
      expect(state.game.initialPosition.board.bySide(Side.black).size, 16);
      await app.finish();
    });
  });

  group('Special chess on one phone', () {
    testWidgets('the phone changes hands behind a privacy screen', (
      tester,
    ) async {
      final app = await AppHarness.start(tester, home: const GameScreen());
      app.game.startLocal(
        const GameConfig(
          variant: GameVariant.special,
          opponent: OpponentType.passAndPlay,
        ),
      );
      await app.wait(500);
      final ar = app.l10n('ar');

      expect(find.text(ar.passPhoneTo(ar.white)), findsOneWidget);
      expect(find.byType(SetupStage), findsNothing);
      await tester.tap(find.text(ar.imHere));
      await app.wait(500);
      await tester.tap(find.byIcon(Icons.auto_awesome_rounded));
      await app.wait(300);
      await tester.tap(find.text(ar.done));
      await app.wait(500);

      // Black's turn: white's pieces are gone from the screen.
      expect(find.text(ar.passPhoneTo(ar.black)), findsOneWidget);
      expect(find.byType(ChessPiece), findsNothing);
      await tester.tap(find.text(ar.imHere));
      await app.wait(500);
      expect(app.state!.phase, GamePhase.setupBlack);
      expect(app.state!.whiteArmy, isNull);
      final shown = tester.widgetList<ChessPiece>(find.byType(ChessPiece));
      expect(shown.where((p) => p.piece.color == Side.white), isEmpty);

      await tester.tap(find.byIcon(Icons.auto_awesome_rounded));
      await app.wait(300);
      await tester.tap(find.text(ar.done));
      await app.wait(300);
      expect(app.state!.phase, GamePhase.reveal);
      expect(app.state!.whiteArmy!.total, 16);
      expect(app.state!.blackArmy!.total, 16);
      await app.finish();
    });
  });

  group('Settings', () {
    testWidgets('board and piece themes apply to the game', (tester) async {
      final app = await AppHarness.start(tester, home: const SettingsScreen());
      final ar = app.l10n('ar');
      expect(
        app.container.read(settingsProvider).boardTheme,
        BoardTheme.tunisian,
      );
      for (final theme in BoardTheme.values) {
        expect(find.text(ar.boardThemeName(theme)), findsWidgets);
      }
      await tester.tap(find.text(ar.boardThemeWood));
      await app.wait(300);
      expect(app.container.read(settingsProvider).boardTheme, BoardTheme.wood);

      await tester.tap(find.text(ar.sound));
      await app.wait(300);
      expect(app.container.read(settingsProvider).sound, isFalse);
      await app.finish();
    });

    testWidgets('fits a small phone without overflowing', (tester) async {
      final app = await AppHarness.start(
        tester,
        home: const GameScreen(),
        size: const Size(320, 568),
      );
      app.game.startLocal(
        const GameConfig(
          variant: GameVariant.special,
          opponent: OpponentType.ai,
        ),
      );
      await app.wait(600);
      expect(find.byType(SetupStage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.auto_awesome_rounded));
      await app.wait(300);
      await tester.tap(find.text(app.l10n('ar').done));
      await app.wait(9000);
      expect(tester.takeException(), isNull);
      await app.finish();
    });
  });
}
