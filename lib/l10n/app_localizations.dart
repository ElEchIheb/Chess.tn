import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'chess.tn'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Build your army in secret… then we lift the curtain.'**
  String get tagline;

  /// No description provided for @normalChess.
  ///
  /// In en, this message translates to:
  /// **'Classic Chess'**
  String get normalChess;

  /// No description provided for @normalChessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play chess the classic way'**
  String get normalChessSubtitle;

  /// No description provided for @specialChess.
  ///
  /// In en, this message translates to:
  /// **'Special Chess'**
  String get specialChess;

  /// No description provided for @specialBadge.
  ///
  /// In en, this message translates to:
  /// **'SPECIAL'**
  String get specialBadge;

  /// No description provided for @specialChessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build your army where they can\'t see it!'**
  String get specialChessSubtitle;

  /// No description provided for @vsAi.
  ///
  /// In en, this message translates to:
  /// **'vs AI'**
  String get vsAi;

  /// No description provided for @vsFriend.
  ///
  /// In en, this message translates to:
  /// **'vs a friend'**
  String get vsFriend;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @languageDarija.
  ///
  /// In en, this message translates to:
  /// **'العربية التونسية'**
  String get languageDarija;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @sectionGame.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get sectionGame;

  /// No description provided for @sectionAudio.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sectionAudio;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Look'**
  String get sectionAppearance;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get sound;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @boardTheme.
  ///
  /// In en, this message translates to:
  /// **'Board theme'**
  String get boardTheme;

  /// No description provided for @pieceTheme.
  ///
  /// In en, this message translates to:
  /// **'Piece style'**
  String get pieceTheme;

  /// No description provided for @showLegalMoves.
  ///
  /// In en, this message translates to:
  /// **'Show legal moves'**
  String get showLegalMoves;

  /// No description provided for @animations.
  ///
  /// In en, this message translates to:
  /// **'Animations'**
  String get animations;

  /// No description provided for @defaultAiLevel.
  ///
  /// In en, this message translates to:
  /// **'Default AI level'**
  String get defaultAiLevel;

  /// No description provided for @aboutOffline.
  ///
  /// In en, this message translates to:
  /// **'No account, no internet: just open and play.'**
  String get aboutOffline;

  /// No description provided for @boardThemeTunisian.
  ///
  /// In en, this message translates to:
  /// **'Tunisian'**
  String get boardThemeTunisian;

  /// No description provided for @boardThemeClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get boardThemeClassic;

  /// No description provided for @boardThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get boardThemeDark;

  /// No description provided for @boardThemeWood.
  ///
  /// In en, this message translates to:
  /// **'Wood'**
  String get boardThemeWood;

  /// No description provided for @pieceThemeClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get pieceThemeClassic;

  /// No description provided for @level1.
  ///
  /// In en, this message translates to:
  /// **'Very easy'**
  String get level1;

  /// No description provided for @level2.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get level2;

  /// No description provided for @level3.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get level3;

  /// No description provided for @level4.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get level4;

  /// No description provided for @level5.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get level5;

  /// No description provided for @levelNumber.
  ///
  /// In en, this message translates to:
  /// **'Level {n}'**
  String levelNumber(int n);

  /// No description provided for @chooseLevel.
  ///
  /// In en, this message translates to:
  /// **'Pick a level'**
  String get chooseLevel;

  /// No description provided for @chooseColor.
  ///
  /// In en, this message translates to:
  /// **'Which colour do you play?'**
  String get chooseColor;

  /// No description provided for @colorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colorWhite;

  /// No description provided for @colorBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get colorBlack;

  /// No description provided for @colorRandom.
  ///
  /// In en, this message translates to:
  /// **'Surprise me'**
  String get colorRandom;

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'Start the game'**
  String get startGame;

  /// No description provided for @friendTitle.
  ///
  /// In en, this message translates to:
  /// **'Play with a friend'**
  String get friendTitle;

  /// No description provided for @createGame.
  ///
  /// In en, this message translates to:
  /// **'Create a game'**
  String get createGame;

  /// No description provided for @createGameHint.
  ///
  /// In en, this message translates to:
  /// **'You open the game, your friend joins with the code'**
  String get createGameHint;

  /// No description provided for @joinGame.
  ///
  /// In en, this message translates to:
  /// **'Join a game'**
  String get joinGame;

  /// No description provided for @joinGameHint.
  ///
  /// In en, this message translates to:
  /// **'Got a code? Come in'**
  String get joinGameHint;

  /// No description provided for @samePhone.
  ///
  /// In en, this message translates to:
  /// **'On this phone'**
  String get samePhone;

  /// No description provided for @samePhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Two players, one phone'**
  String get samePhoneHint;

  /// No description provided for @roomCode.
  ///
  /// In en, this message translates to:
  /// **'Game code'**
  String get roomCode;

  /// No description provided for @shareCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Give this code to your friend'**
  String get shareCodeHint;

  /// No description provided for @waitingFriend.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your friend to join…'**
  String get waitingFriend;

  /// No description provided for @sameWifiHint.
  ///
  /// In en, this message translates to:
  /// **'Make sure both phones are on the same Wi-Fi.'**
  String get sameWifiHint;

  /// No description provided for @yourIp.
  ///
  /// In en, this message translates to:
  /// **'Your IP: {ip}'**
  String yourIp(String ip);

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Type the code'**
  String get enterCode;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @joining.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get joining;

  /// No description provided for @nearbyGames.
  ///
  /// In en, this message translates to:
  /// **'Games on this network'**
  String get nearbyGames;

  /// No description provided for @gameOnNetwork.
  ///
  /// In en, this message translates to:
  /// **'This game is on your network'**
  String get gameOnNetwork;

  /// No description provided for @noGamesFound.
  ///
  /// In en, this message translates to:
  /// **'No game found nearby. Try the code.'**
  String get noGamesFound;

  /// No description provided for @searchAgain.
  ///
  /// In en, this message translates to:
  /// **'Search again'**
  String get searchAgain;

  /// No description provided for @joinByIp.
  ///
  /// In en, this message translates to:
  /// **'Join by IP'**
  String get joinByIp;

  /// No description provided for @hostIpLabel.
  ///
  /// In en, this message translates to:
  /// **'Your friend\'s IP'**
  String get hostIpLabel;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected!'**
  String get connected;

  /// No description provided for @playersReady.
  ///
  /// In en, this message translates to:
  /// **'Players ready?'**
  String get playersReady;

  /// No description provided for @imReady.
  ///
  /// In en, this message translates to:
  /// **'I\'m ready'**
  String get imReady;

  /// No description provided for @youAreReady.
  ///
  /// In en, this message translates to:
  /// **'You\'re ready'**
  String get youAreReady;

  /// No description provided for @friendReady.
  ///
  /// In en, this message translates to:
  /// **'Your friend is ready'**
  String get friendReady;

  /// No description provided for @friendNotReady.
  ///
  /// In en, this message translates to:
  /// **'Your friend isn\'t ready yet…'**
  String get friendNotReady;

  /// No description provided for @friendChoseSpecial.
  ///
  /// In en, this message translates to:
  /// **'Your friend picked Special Chess'**
  String get friendChoseSpecial;

  /// No description provided for @friendChoseNormal.
  ///
  /// In en, this message translates to:
  /// **'Your friend picked Classic Chess'**
  String get friendChoseNormal;

  /// No description provided for @youPlayWhite.
  ///
  /// In en, this message translates to:
  /// **'You play White'**
  String get youPlayWhite;

  /// No description provided for @youPlayBlack.
  ///
  /// In en, this message translates to:
  /// **'You play Black'**
  String get youPlayBlack;

  /// No description provided for @errNoNetwork.
  ///
  /// In en, this message translates to:
  /// **'No local network. Turn on Wi-Fi and try again.'**
  String get errNoNetwork;

  /// No description provided for @errInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'That code doesn\'t look right.'**
  String get errInvalidCode;

  /// No description provided for @errHostNotFound.
  ///
  /// In en, this message translates to:
  /// **'Game not found. Make sure both phones are on the same Wi-Fi.'**
  String get errHostNotFound;

  /// No description provided for @errRoomFull.
  ///
  /// In en, this message translates to:
  /// **'That game is full: it already has two players.'**
  String get errRoomFull;

  /// No description provided for @errWrongCode.
  ///
  /// In en, this message translates to:
  /// **'Wrong code. Check it with your friend.'**
  String get errWrongCode;

  /// No description provided for @errVersion.
  ///
  /// In en, this message translates to:
  /// **'Both phones need the same version of the game.'**
  String get errVersion;

  /// No description provided for @errCannotHost.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the game. Try again.'**
  String get errCannotHost;

  /// No description provided for @errUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errUnknown;

  /// No description provided for @connectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost.'**
  String get connectionLost;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Trying to reconnect…'**
  String get reconnecting;

  /// No description provided for @friendLeft.
  ///
  /// In en, this message translates to:
  /// **'Your friend left the game.'**
  String get friendLeft;

  /// No description provided for @friendDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Your friend lost the connection. Waiting for them…'**
  String get friendDisconnected;

  /// No description provided for @friendBack.
  ///
  /// In en, this message translates to:
  /// **'Your friend is back!'**
  String get friendBack;

  /// No description provided for @protocolError.
  ///
  /// In en, this message translates to:
  /// **'A connection problem ended the game.'**
  String get protocolError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get goHome;

  /// No description provided for @yourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your move.'**
  String get yourTurn;

  /// No description provided for @opponentTurn.
  ///
  /// In en, this message translates to:
  /// **'Opponent\'s move.'**
  String get opponentTurn;

  /// No description provided for @aiThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get aiThinking;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check!'**
  String get check;

  /// No description provided for @whiteToMove.
  ///
  /// In en, this message translates to:
  /// **'White to move'**
  String get whiteToMove;

  /// No description provided for @blackToMove.
  ///
  /// In en, this message translates to:
  /// **'Black to move'**
  String get blackToMove;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @opponent.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get opponent;

  /// No description provided for @friend.
  ///
  /// In en, this message translates to:
  /// **'Your friend'**
  String get friend;

  /// No description provided for @ai.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai;

  /// No description provided for @white.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get white;

  /// No description provided for @black.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get black;

  /// No description provided for @resign.
  ///
  /// In en, this message translates to:
  /// **'Resign'**
  String get resign;

  /// No description provided for @resignConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sure you want to resign?'**
  String get resignConfirm;

  /// No description provided for @offerDraw.
  ///
  /// In en, this message translates to:
  /// **'Offer a draw'**
  String get offerDraw;

  /// No description provided for @drawOffered.
  ///
  /// In en, this message translates to:
  /// **'Your friend offers a draw.'**
  String get drawOffered;

  /// No description provided for @drawOfferSent.
  ///
  /// In en, this message translates to:
  /// **'Draw offer sent…'**
  String get drawOfferSent;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @drawDeclined.
  ///
  /// In en, this message translates to:
  /// **'Your friend declined the draw.'**
  String get drawDeclined;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Take back'**
  String get undo;

  /// No description provided for @leaveGame.
  ///
  /// In en, this message translates to:
  /// **'Leave the game?'**
  String get leaveGame;

  /// No description provided for @leaveGameBody.
  ///
  /// In en, this message translates to:
  /// **'The game will end.'**
  String get leaveGameBody;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Keep playing'**
  String get stay;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @illegalMove.
  ///
  /// In en, this message translates to:
  /// **'Whoa, what was that? 😂'**
  String get illegalMove;

  /// No description provided for @promoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Promote the pawn to…'**
  String get promoteTitle;

  /// No description provided for @gameStartToast.
  ///
  /// In en, this message translates to:
  /// **'And the war begins.'**
  String get gameStartToast;

  /// No description provided for @holdTight.
  ///
  /// In en, this message translates to:
  /// **'Hold tight!'**
  String get holdTight;

  /// No description provided for @pieceKing.
  ///
  /// In en, this message translates to:
  /// **'King'**
  String get pieceKing;

  /// No description provided for @pieceQueen.
  ///
  /// In en, this message translates to:
  /// **'Queen'**
  String get pieceQueen;

  /// No description provided for @pieceRook.
  ///
  /// In en, this message translates to:
  /// **'Rook'**
  String get pieceRook;

  /// No description provided for @pieceBishop.
  ///
  /// In en, this message translates to:
  /// **'Bishop'**
  String get pieceBishop;

  /// No description provided for @pieceKnight.
  ///
  /// In en, this message translates to:
  /// **'Knight'**
  String get pieceKnight;

  /// No description provided for @piecePawn.
  ///
  /// In en, this message translates to:
  /// **'Pawn'**
  String get piecePawn;

  /// No description provided for @buildYourArmy.
  ///
  /// In en, this message translates to:
  /// **'Build your army'**
  String get buildYourArmy;

  /// No description provided for @buildYourArmyHint.
  ///
  /// In en, this message translates to:
  /// **'Arrange your pieces any way you like.'**
  String get buildYourArmyHint;

  /// No description provided for @remainingPieces.
  ///
  /// In en, this message translates to:
  /// **'Pieces left'**
  String get remainingPieces;

  /// No description provided for @allPlaced.
  ///
  /// In en, this message translates to:
  /// **'Your whole army is on the board.'**
  String get allPlaced;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get reset;

  /// No description provided for @autoPlace.
  ///
  /// In en, this message translates to:
  /// **'Place for me'**
  String get autoPlace;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @editArmy.
  ///
  /// In en, this message translates to:
  /// **'Change my setup'**
  String get editArmy;

  /// No description provided for @opponentHidden.
  ///
  /// In en, this message translates to:
  /// **'Opponent\'s army is hidden'**
  String get opponentHidden;

  /// No description provided for @opponentPlacing.
  ///
  /// In en, this message translates to:
  /// **'Opponent placing: {n}/{total}'**
  String opponentPlacing(int n, int total);

  /// No description provided for @opponentArmyReady.
  ///
  /// In en, this message translates to:
  /// **'Opponent is ready'**
  String get opponentArmyReady;

  /// No description provided for @waitingOpponentArmy.
  ///
  /// In en, this message translates to:
  /// **'Your army is ready. Waiting for the opponent…'**
  String get waitingOpponentArmy;

  /// No description provided for @lockedIn.
  ///
  /// In en, this message translates to:
  /// **'Locked! Nobody can change anything now.'**
  String get lockedIn;

  /// No description provided for @pawnBackRank.
  ///
  /// In en, this message translates to:
  /// **'Pawns can\'t stand on your back rank.'**
  String get pawnBackRank;

  /// No description provided for @outsideZone.
  ///
  /// In en, this message translates to:
  /// **'Keep your pieces on your own side.'**
  String get outsideZone;

  /// No description provided for @invalidPosition.
  ///
  /// In en, this message translates to:
  /// **'This position isn\'t valid.'**
  String get invalidPosition;

  /// No description provided for @moveKing.
  ///
  /// In en, this message translates to:
  /// **'Move your king.'**
  String get moveKing;

  /// No description provided for @missingPieces.
  ///
  /// In en, this message translates to:
  /// **'{n} pieces still to place.'**
  String missingPieces(int n);

  /// No description provided for @timeUp.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up! We placed the rest for you.'**
  String get timeUp;

  /// No description provided for @dragHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a piece then a square, or drag it onto the board.'**
  String get dragHint;

  /// No description provided for @removePiece.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removePiece;

  /// No description provided for @passPhoneTo.
  ///
  /// In en, this message translates to:
  /// **'Hand the phone to {player}'**
  String passPhoneTo(String player);

  /// No description provided for @passPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'The other player looks away 😉'**
  String get passPhoneHint;

  /// No description provided for @imHere.
  ///
  /// In en, this message translates to:
  /// **'I\'m ready'**
  String get imHere;

  /// No description provided for @armiesReady.
  ///
  /// In en, this message translates to:
  /// **'Both armies are ready…'**
  String get armiesReady;

  /// No description provided for @revealWord.
  ///
  /// In en, this message translates to:
  /// **'REVEAL!'**
  String get revealWord;

  /// No description provided for @curtainRising.
  ///
  /// In en, this message translates to:
  /// **'The curtain is rising…'**
  String get curtainRising;

  /// No description provided for @battleBegins.
  ///
  /// In en, this message translates to:
  /// **'The battle begins!'**
  String get battleBegins;

  /// No description provided for @letsSee.
  ///
  /// In en, this message translates to:
  /// **'Now let\'s see who came prepared!'**
  String get letsSee;

  /// No description provided for @kingInDanger.
  ///
  /// In en, this message translates to:
  /// **'Your king is under fire! Move it.'**
  String get kingInDanger;

  /// No description provided for @opponentKingInDanger.
  ///
  /// In en, this message translates to:
  /// **'The opponent\'s king is under fire and is being moved…'**
  String get opponentKingInDanger;

  /// No description provided for @kingRescueHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a safe square (in gold).'**
  String get kingRescueHint;

  /// No description provided for @kingRescueFor.
  ///
  /// In en, this message translates to:
  /// **'{player}: your king is under fire! Move it.'**
  String kingRescueFor(String player);

  /// No description provided for @setupRedo.
  ///
  /// In en, this message translates to:
  /// **'These two armies can\'t start a game. Build them again.'**
  String get setupRedo;

  /// No description provided for @youWon.
  ///
  /// In en, this message translates to:
  /// **'You won!'**
  String get youWon;

  /// No description provided for @youLost.
  ///
  /// In en, this message translates to:
  /// **'You lost!'**
  String get youLost;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw!'**
  String get draw;

  /// No description provided for @whiteWins.
  ///
  /// In en, this message translates to:
  /// **'White wins!'**
  String get whiteWins;

  /// No description provided for @blackWins.
  ///
  /// In en, this message translates to:
  /// **'Black wins!'**
  String get blackWins;

  /// No description provided for @wonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Well played, champ!'**
  String get wonSubtitle;

  /// No description provided for @lostSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No worries, next time is yours.'**
  String get lostSubtitle;

  /// No description provided for @drawSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No winner, no loser.'**
  String get drawSubtitle;

  /// No description provided for @checkmateWin.
  ///
  /// In en, this message translates to:
  /// **'Boss move: that\'s checkmate!'**
  String get checkmateWin;

  /// No description provided for @reasonCheckmate.
  ///
  /// In en, this message translates to:
  /// **'Checkmate'**
  String get reasonCheckmate;

  /// No description provided for @reasonStalemate.
  ///
  /// In en, this message translates to:
  /// **'Stalemate'**
  String get reasonStalemate;

  /// No description provided for @reasonInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Not enough pieces to mate'**
  String get reasonInsufficient;

  /// No description provided for @reasonRepetition.
  ///
  /// In en, this message translates to:
  /// **'Same position three times'**
  String get reasonRepetition;

  /// No description provided for @reasonFifty.
  ///
  /// In en, this message translates to:
  /// **'Fifty moves without progress'**
  String get reasonFifty;

  /// No description provided for @reasonResign.
  ///
  /// In en, this message translates to:
  /// **'Resignation'**
  String get reasonResign;

  /// No description provided for @reasonDrawAgreed.
  ///
  /// In en, this message translates to:
  /// **'Draw by agreement'**
  String get reasonDrawAgreed;

  /// No description provided for @reasonAbandon.
  ///
  /// In en, this message translates to:
  /// **'Opponent left'**
  String get reasonAbandon;

  /// No description provided for @statMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get statMode;

  /// No description provided for @statMoves.
  ///
  /// In en, this message translates to:
  /// **'Moves'**
  String get statMoves;

  /// No description provided for @statDuration.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get statDuration;

  /// No description provided for @statCaptured.
  ///
  /// In en, this message translates to:
  /// **'Captured'**
  String get statCaptured;

  /// No description provided for @yourArmy.
  ///
  /// In en, this message translates to:
  /// **'Your army'**
  String get yourArmy;

  /// No description provided for @opponentArmy.
  ///
  /// In en, this message translates to:
  /// **'Opponent\'s army'**
  String get opponentArmy;

  /// No description provided for @whiteArmy.
  ///
  /// In en, this message translates to:
  /// **'White\'s army'**
  String get whiteArmy;

  /// No description provided for @blackArmy.
  ///
  /// In en, this message translates to:
  /// **'Black\'s army'**
  String get blackArmy;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgain;

  /// No description provided for @rematchRequested.
  ///
  /// In en, this message translates to:
  /// **'Rematch requested. Waiting for your friend…'**
  String get rematchRequested;

  /// No description provided for @rematchOffered.
  ///
  /// In en, this message translates to:
  /// **'Your friend wants a rematch!'**
  String get rematchOffered;

  /// No description provided for @viewBoard.
  ///
  /// In en, this message translates to:
  /// **'See the board'**
  String get viewBoard;

  /// No description provided for @engineLabel.
  ///
  /// In en, this message translates to:
  /// **'Engine: {name}'**
  String engineLabel(String name);

  /// No description provided for @languageShort.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get languageShort;

  /// No description provided for @errInvalidIp.
  ///
  /// In en, this message translates to:
  /// **'That IP address isn\'t valid.'**
  String get errInvalidIp;

  /// No description provided for @pieceThemeTunisian.
  ///
  /// In en, this message translates to:
  /// **'Tunisian'**
  String get pieceThemeTunisian;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About {app}'**
  String aboutTitle(String app);

  /// No description provided for @aboutSlogan.
  ///
  /// In en, this message translates to:
  /// **'Classic chess.\nTunisian identity.\nA different way to play.'**
  String get aboutSlogan;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'A Tunisian chess game with classic chess and a unique hidden-army Special Mode.'**
  String get aboutDescription;

  /// No description provided for @aboutSpecialTitle.
  ///
  /// In en, this message translates to:
  /// **'SPECIAL MODE'**
  String get aboutSpecialTitle;

  /// No description provided for @aboutSpecialBody.
  ///
  /// In en, this message translates to:
  /// **'Build your army without letting your opponent see it.'**
  String get aboutSpecialBody;

  /// No description provided for @aboutDeveloperTitle.
  ///
  /// In en, this message translates to:
  /// **'DEVELOPER'**
  String get aboutDeveloperTitle;

  /// No description provided for @developedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed by {name}'**
  String developedBy(String name);

  /// No description provided for @madeInTunisia.
  ///
  /// In en, this message translates to:
  /// **'Made in Tunisia'**
  String get madeInTunisia;

  /// No description provided for @madeInTunisiaFlag.
  ///
  /// In en, this message translates to:
  /// **'Made in Tunisia 🇹🇳'**
  String get madeInTunisiaFlag;

  /// No description provided for @contactTitle.
  ///
  /// In en, this message translates to:
  /// **'CONTACT & FEEDBACK'**
  String get contactTitle;

  /// No description provided for @contactQuestion.
  ///
  /// In en, this message translates to:
  /// **'Found a bug? Have an idea or a suggestion?'**
  String get contactQuestion;

  /// No description provided for @contactBody.
  ///
  /// In en, this message translates to:
  /// **'Contact me for bugs, suggestions or feedback.'**
  String get contactBody;

  /// No description provided for @contactDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Contact Developer'**
  String get contactDeveloper;

  /// No description provided for @reportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a Bug'**
  String get reportBug;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @sendSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggest an idea'**
  String get sendSuggestion;

  /// No description provided for @followDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Follow the Developer'**
  String get followDeveloper;

  /// No description provided for @linkGithub.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get linkGithub;

  /// No description provided for @linkLinkedin.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn'**
  String get linkLinkedin;

  /// No description provided for @linkInstagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get linkInstagram;

  /// No description provided for @linkFacebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get linkFacebook;

  /// No description provided for @linkEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get linkEmail;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @linkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open it. The address was copied instead.'**
  String get linkOpenFailed;

  /// No description provided for @bugWhatWentWrong.
  ///
  /// In en, this message translates to:
  /// **'What went wrong?'**
  String get bugWhatWentWrong;

  /// No description provided for @bugDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what happened and what you expected.'**
  String get bugDescriptionHint;

  /// No description provided for @bugGameMode.
  ///
  /// In en, this message translates to:
  /// **'Game mode (optional)'**
  String get bugGameMode;

  /// No description provided for @bugIncludeDevice.
  ///
  /// In en, this message translates to:
  /// **'Include device information'**
  String get bugIncludeDevice;

  /// No description provided for @bugPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'This opens your email app with the report ready. Nothing is sent until you press send.'**
  String get bugPrivacyNote;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
