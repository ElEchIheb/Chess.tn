// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'chess.tn';

  @override
  String get tagline => 'Build your army in secret… then we lift the curtain.';

  @override
  String get normalChess => 'Classic Chess';

  @override
  String get normalChessSubtitle => 'Play chess the classic way';

  @override
  String get specialChess => 'Special Chess';

  @override
  String get specialBadge => 'SPECIAL';

  @override
  String get specialChessSubtitle =>
      'Build your army where they can\'t see it!';

  @override
  String get vsAi => 'vs AI';

  @override
  String get vsFriend => 'vs a friend';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Close';

  @override
  String get languageDarija => 'العربية التونسية';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get sectionGame => 'Game';

  @override
  String get sectionAudio => 'Sound';

  @override
  String get sectionAppearance => 'Look';

  @override
  String get sound => 'Sound effects';

  @override
  String get music => 'Music';

  @override
  String get vibration => 'Vibration';

  @override
  String get boardTheme => 'Board theme';

  @override
  String get pieceTheme => 'Piece style';

  @override
  String get showLegalMoves => 'Show legal moves';

  @override
  String get animations => 'Animations';

  @override
  String get defaultAiLevel => 'Default AI level';

  @override
  String get aboutOffline => 'No account, no internet: just open and play.';

  @override
  String get boardThemeTunisian => 'Tunisian';

  @override
  String get boardThemeClassic => 'Classic';

  @override
  String get boardThemeDark => 'Dark';

  @override
  String get boardThemeWood => 'Wood';

  @override
  String get pieceThemeClassic => 'Classic';

  @override
  String get level1 => 'Very easy';

  @override
  String get level2 => 'Easy';

  @override
  String get level3 => 'Medium';

  @override
  String get level4 => 'Hard';

  @override
  String get level5 => 'Expert';

  @override
  String levelNumber(int n) {
    return 'Level $n';
  }

  @override
  String get chooseLevel => 'Pick a level';

  @override
  String get chooseColor => 'Which colour do you play?';

  @override
  String get colorWhite => 'White';

  @override
  String get colorBlack => 'Black';

  @override
  String get colorRandom => 'Surprise me';

  @override
  String get startGame => 'Start the game';

  @override
  String get friendTitle => 'Play with a friend';

  @override
  String get createGame => 'Create a game';

  @override
  String get createGameHint =>
      'You open the game, your friend joins with the code';

  @override
  String get joinGame => 'Join a game';

  @override
  String get joinGameHint => 'Got a code? Come in';

  @override
  String get samePhone => 'On this phone';

  @override
  String get samePhoneHint => 'Two players, one phone';

  @override
  String get roomCode => 'Game code';

  @override
  String get shareCodeHint => 'Give this code to your friend';

  @override
  String get waitingFriend => 'Waiting for your friend to join…';

  @override
  String get sameWifiHint => 'Make sure both phones are on the same Wi-Fi.';

  @override
  String yourIp(String ip) {
    return 'Your IP: $ip';
  }

  @override
  String get enterCode => 'Type the code';

  @override
  String get join => 'Join';

  @override
  String get joining => 'Connecting…';

  @override
  String get nearbyGames => 'Games on this network';

  @override
  String get gameOnNetwork => 'This game is on your network';

  @override
  String get noGamesFound => 'No game found nearby. Try the code.';

  @override
  String get searchAgain => 'Search again';

  @override
  String get joinByIp => 'Join by IP';

  @override
  String get hostIpLabel => 'Your friend\'s IP';

  @override
  String get connected => 'Connected!';

  @override
  String get playersReady => 'Players ready?';

  @override
  String get imReady => 'I\'m ready';

  @override
  String get youAreReady => 'You\'re ready';

  @override
  String get friendReady => 'Your friend is ready';

  @override
  String get friendNotReady => 'Your friend isn\'t ready yet…';

  @override
  String get friendChoseSpecial => 'Your friend picked Special Chess';

  @override
  String get friendChoseNormal => 'Your friend picked Classic Chess';

  @override
  String get youPlayWhite => 'You play White';

  @override
  String get youPlayBlack => 'You play Black';

  @override
  String get errNoNetwork => 'No local network. Turn on Wi-Fi and try again.';

  @override
  String get errInvalidCode => 'That code doesn\'t look right.';

  @override
  String get errHostNotFound =>
      'Game not found. Make sure both phones are on the same Wi-Fi.';

  @override
  String get errRoomFull => 'That game is full: it already has two players.';

  @override
  String get errWrongCode => 'Wrong code. Check it with your friend.';

  @override
  String get errVersion => 'Both phones need the same version of the game.';

  @override
  String get errCannotHost => 'Couldn\'t open the game. Try again.';

  @override
  String get errUnknown => 'Something went wrong. Try again.';

  @override
  String get connectionLost => 'Connection lost.';

  @override
  String get reconnecting => 'Trying to reconnect…';

  @override
  String get friendLeft => 'Your friend left the game.';

  @override
  String get friendDisconnected =>
      'Your friend lost the connection. Waiting for them…';

  @override
  String get friendBack => 'Your friend is back!';

  @override
  String get protocolError => 'A connection problem ended the game.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get goHome => 'Home';

  @override
  String get yourTurn => 'Your move.';

  @override
  String get opponentTurn => 'Opponent\'s move.';

  @override
  String get aiThinking => 'Thinking…';

  @override
  String get check => 'Check!';

  @override
  String get whiteToMove => 'White to move';

  @override
  String get blackToMove => 'Black to move';

  @override
  String get you => 'You';

  @override
  String get opponent => 'Opponent';

  @override
  String get friend => 'Your friend';

  @override
  String get ai => 'AI';

  @override
  String get white => 'White';

  @override
  String get black => 'Black';

  @override
  String get resign => 'Resign';

  @override
  String get resignConfirm => 'Sure you want to resign?';

  @override
  String get offerDraw => 'Offer a draw';

  @override
  String get drawOffered => 'Your friend offers a draw.';

  @override
  String get drawOfferSent => 'Draw offer sent…';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get drawDeclined => 'Your friend declined the draw.';

  @override
  String get undo => 'Take back';

  @override
  String get leaveGame => 'Leave the game?';

  @override
  String get leaveGameBody => 'The game will end.';

  @override
  String get stay => 'Keep playing';

  @override
  String get leave => 'Leave';

  @override
  String get illegalMove => 'Whoa, what was that? 😂';

  @override
  String get promoteTitle => 'Promote the pawn to…';

  @override
  String get gameStartToast => 'And the war begins.';

  @override
  String get holdTight => 'Hold tight!';

  @override
  String get pieceKing => 'King';

  @override
  String get pieceQueen => 'Queen';

  @override
  String get pieceRook => 'Rook';

  @override
  String get pieceBishop => 'Bishop';

  @override
  String get pieceKnight => 'Knight';

  @override
  String get piecePawn => 'Pawn';

  @override
  String get buildYourArmy => 'Build your army';

  @override
  String get buildYourArmyHint => 'Arrange your pieces any way you like.';

  @override
  String get remainingPieces => 'Pieces left';

  @override
  String get allPlaced => 'Your whole army is on the board.';

  @override
  String get reset => 'Start over';

  @override
  String get autoPlace => 'Place for me';

  @override
  String get done => 'Done';

  @override
  String get editArmy => 'Change my setup';

  @override
  String get opponentHidden => 'Opponent\'s army is hidden';

  @override
  String opponentPlacing(int n, int total) {
    return 'Opponent placing: $n/$total';
  }

  @override
  String get opponentArmyReady => 'Opponent is ready';

  @override
  String get waitingOpponentArmy =>
      'Your army is ready. Waiting for the opponent…';

  @override
  String get lockedIn => 'Locked! Nobody can change anything now.';

  @override
  String get pawnBackRank => 'Pawns can\'t stand on your back rank.';

  @override
  String get outsideZone => 'Keep your pieces on your own side.';

  @override
  String get invalidPosition => 'This position isn\'t valid.';

  @override
  String get moveKing => 'Move your king.';

  @override
  String missingPieces(int n) {
    return '$n pieces still to place.';
  }

  @override
  String get timeUp => 'Time\'s up! We placed the rest for you.';

  @override
  String get dragHint =>
      'Tap a piece then a square, or drag it onto the board.';

  @override
  String get removePiece => 'Remove';

  @override
  String passPhoneTo(String player) {
    return 'Hand the phone to $player';
  }

  @override
  String get passPhoneHint => 'The other player looks away 😉';

  @override
  String get imHere => 'I\'m ready';

  @override
  String get armiesReady => 'Both armies are ready…';

  @override
  String get revealWord => 'REVEAL!';

  @override
  String get curtainRising => 'The curtain is rising…';

  @override
  String get battleBegins => 'The battle begins!';

  @override
  String get letsSee => 'Now let\'s see who came prepared!';

  @override
  String get kingInDanger => 'Your king is under fire! Move it.';

  @override
  String get opponentKingInDanger =>
      'The opponent\'s king is under fire and is being moved…';

  @override
  String get kingRescueHint => 'Pick a safe square (in gold).';

  @override
  String kingRescueFor(String player) {
    return '$player: your king is under fire! Move it.';
  }

  @override
  String get setupRedo =>
      'These two armies can\'t start a game. Build them again.';

  @override
  String get youWon => 'You won!';

  @override
  String get youLost => 'You lost!';

  @override
  String get draw => 'Draw!';

  @override
  String get whiteWins => 'White wins!';

  @override
  String get blackWins => 'Black wins!';

  @override
  String get wonSubtitle => 'Well played, champ!';

  @override
  String get lostSubtitle => 'No worries, next time is yours.';

  @override
  String get drawSubtitle => 'No winner, no loser.';

  @override
  String get checkmateWin => 'Boss move: that\'s checkmate!';

  @override
  String get reasonCheckmate => 'Checkmate';

  @override
  String get reasonStalemate => 'Stalemate';

  @override
  String get reasonInsufficient => 'Not enough pieces to mate';

  @override
  String get reasonRepetition => 'Same position three times';

  @override
  String get reasonFifty => 'Fifty moves without progress';

  @override
  String get reasonResign => 'Resignation';

  @override
  String get reasonDrawAgreed => 'Draw by agreement';

  @override
  String get reasonAbandon => 'Opponent left';

  @override
  String get statMode => 'Mode';

  @override
  String get statMoves => 'Moves';

  @override
  String get statDuration => 'Time';

  @override
  String get statCaptured => 'Captured';

  @override
  String get yourArmy => 'Your army';

  @override
  String get opponentArmy => 'Opponent\'s army';

  @override
  String get whiteArmy => 'White\'s army';

  @override
  String get blackArmy => 'Black\'s army';

  @override
  String get playAgain => 'Play again';

  @override
  String get rematchRequested => 'Rematch requested. Waiting for your friend…';

  @override
  String get rematchOffered => 'Your friend wants a rematch!';

  @override
  String get viewBoard => 'See the board';

  @override
  String engineLabel(String name) {
    return 'Engine: $name';
  }

  @override
  String get languageShort => 'EN';

  @override
  String get errInvalidIp => 'That IP address isn\'t valid.';

  @override
  String get pieceThemeTunisian => 'Tunisian';

  @override
  String aboutTitle(String app) {
    return 'About $app';
  }

  @override
  String get aboutSlogan =>
      'Classic chess.\nTunisian identity.\nA different way to play.';

  @override
  String get aboutDescription =>
      'A Tunisian chess game with classic chess and a unique hidden-army Special Mode.';

  @override
  String get aboutSpecialTitle => 'SPECIAL MODE';

  @override
  String get aboutSpecialBody =>
      'Build your army without letting your opponent see it.';

  @override
  String get aboutDeveloperTitle => 'DEVELOPER';

  @override
  String developedBy(String name) {
    return 'Developed by $name';
  }

  @override
  String get madeInTunisia => 'Made in Tunisia';

  @override
  String get madeInTunisiaFlag => 'Made in Tunisia 🇹🇳';

  @override
  String get contactTitle => 'CONTACT & FEEDBACK';

  @override
  String get contactQuestion => 'Found a bug? Have an idea or a suggestion?';

  @override
  String get contactBody => 'Contact me for bugs, suggestions or feedback.';

  @override
  String get contactDeveloper => 'Contact Developer';

  @override
  String get reportBug => 'Report a Bug';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get sendSuggestion => 'Suggest an idea';

  @override
  String get followDeveloper => 'Follow the Developer';

  @override
  String get linkGithub => 'GitHub';

  @override
  String get linkLinkedin => 'LinkedIn';

  @override
  String get linkInstagram => 'Instagram';

  @override
  String get linkFacebook => 'Facebook';

  @override
  String get linkEmail => 'Email';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get linkOpenFailed =>
      'Couldn\'t open it. The address was copied instead.';

  @override
  String get bugWhatWentWrong => 'What went wrong?';

  @override
  String get bugDescriptionHint =>
      'Describe what happened and what you expected.';

  @override
  String get bugGameMode => 'Game mode (optional)';

  @override
  String get bugIncludeDevice => 'Include device information';

  @override
  String get bugPrivacyNote =>
      'This opens your email app with the report ready. Nothing is sent until you press send.';

  @override
  String get sectionAbout => 'About';
}
