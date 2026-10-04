// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'chess.tn';

  @override
  String get tagline => 'Monte ton armée en cachette… puis on lève le rideau.';

  @override
  String get normalChess => 'Échecs classiques';

  @override
  String get normalChessSubtitle => 'Jouez aux échecs classiques';

  @override
  String get specialChess => 'Échecs spéciaux';

  @override
  String get specialBadge => 'SPÉCIAL';

  @override
  String get specialChessSubtitle => 'Monte ton armée sans qu\'il te voie !';

  @override
  String get vsAi => 'Contre l\'IA';

  @override
  String get vsFriend => 'Contre un ami';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get back => 'Retour';

  @override
  String get cancel => 'Annuler';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Fermer';

  @override
  String get languageDarija => 'العربية التونسية';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get sectionGame => 'Jeu';

  @override
  String get sectionAudio => 'Son';

  @override
  String get sectionAppearance => 'Apparence';

  @override
  String get sound => 'Effets sonores';

  @override
  String get music => 'Musique';

  @override
  String get vibration => 'Vibration';

  @override
  String get boardTheme => 'Thème de l\'échiquier';

  @override
  String get pieceTheme => 'Style des pièces';

  @override
  String get showLegalMoves => 'Afficher les coups possibles';

  @override
  String get animations => 'Animations';

  @override
  String get defaultAiLevel => 'Niveau de l\'IA par défaut';

  @override
  String get aboutOffline => 'Sans compte et sans internet : ouvrez et jouez.';

  @override
  String get boardThemeTunisian => 'Tunisien';

  @override
  String get boardThemeClassic => 'Classique';

  @override
  String get boardThemeDark => 'Sombre';

  @override
  String get boardThemeWood => 'Bois';

  @override
  String get pieceThemeClassic => 'Classique';

  @override
  String get level1 => 'Très facile';

  @override
  String get level2 => 'Facile';

  @override
  String get level3 => 'Moyen';

  @override
  String get level4 => 'Difficile';

  @override
  String get level5 => 'Expert';

  @override
  String levelNumber(int n) {
    return 'Niveau $n';
  }

  @override
  String get chooseLevel => 'Choisis le niveau';

  @override
  String get chooseColor => 'Tu joues avec quelle couleur ?';

  @override
  String get colorWhite => 'Blancs';

  @override
  String get colorBlack => 'Noirs';

  @override
  String get colorRandom => 'Au hasard';

  @override
  String get startGame => 'Lancer la partie';

  @override
  String get friendTitle => 'Jouer avec un ami';

  @override
  String get createGame => 'Créer une partie';

  @override
  String get createGameHint =>
      'Tu ouvres la partie, ton ami entre avec le code';

  @override
  String get joinGame => 'Rejoindre une partie';

  @override
  String get joinGameHint => 'Tu as un code ? Entre';

  @override
  String get samePhone => 'Sur ce téléphone';

  @override
  String get samePhoneHint => 'Deux joueurs, un seul téléphone';

  @override
  String get roomCode => 'Code de la partie';

  @override
  String get shareCodeHint => 'Donne ce code à ton ami';

  @override
  String get waitingFriend => 'En attente de ton ami…';

  @override
  String get sameWifiHint =>
      'Vérifiez que les deux téléphones sont sur le même Wi-Fi.';

  @override
  String yourIp(String ip) {
    return 'Ton IP : $ip';
  }

  @override
  String get enterCode => 'Saisis le code';

  @override
  String get join => 'Rejoindre';

  @override
  String get joining => 'Connexion…';

  @override
  String get nearbyGames => 'Parties sur ce réseau';

  @override
  String get gameOnNetwork => 'Cette partie est sur ton réseau';

  @override
  String get noGamesFound => 'Aucune partie trouvée. Essaie avec le code.';

  @override
  String get searchAgain => 'Rechercher à nouveau';

  @override
  String get joinByIp => 'Rejoindre par IP';

  @override
  String get hostIpLabel => 'IP de ton ami';

  @override
  String get connected => 'Connecté !';

  @override
  String get playersReady => 'Les joueurs sont prêts ?';

  @override
  String get imReady => 'Je suis prêt';

  @override
  String get youAreReady => 'Tu es prêt';

  @override
  String get friendReady => 'Ton ami est prêt';

  @override
  String get friendNotReady => 'Ton ami n\'est pas encore prêt…';

  @override
  String get friendChoseSpecial => 'Ton ami a choisi les Échecs spéciaux';

  @override
  String get friendChoseNormal => 'Ton ami a choisi les Échecs classiques';

  @override
  String get youPlayWhite => 'Tu joues les Blancs';

  @override
  String get youPlayBlack => 'Tu joues les Noirs';

  @override
  String get errNoNetwork =>
      'Pas de réseau local. Active le Wi-Fi et réessaie.';

  @override
  String get errInvalidCode => 'Ce code n\'est pas valide.';

  @override
  String get errHostNotFound =>
      'Partie introuvable. Vérifiez que les deux téléphones sont sur le même Wi-Fi.';

  @override
  String get errRoomFull =>
      'Cette partie est complète : elle a déjà deux joueurs.';

  @override
  String get errWrongCode => 'Mauvais code. Vérifie-le avec ton ami.';

  @override
  String get errVersion =>
      'Les deux téléphones doivent avoir la même version du jeu.';

  @override
  String get errCannotHost => 'Impossible d\'ouvrir la partie. Réessaie.';

  @override
  String get errUnknown => 'Un problème est survenu. Réessaie.';

  @override
  String get connectionLost => 'Connexion perdue.';

  @override
  String get reconnecting => 'Tentative de reconnexion…';

  @override
  String get friendLeft => 'Ton ami a quitté la partie.';

  @override
  String get friendDisconnected =>
      'Ton ami a perdu la connexion. On l\'attend…';

  @override
  String get friendBack => 'Ton ami est de retour !';

  @override
  String get protocolError => 'Un problème de connexion a mis fin à la partie.';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get goHome => 'Accueil';

  @override
  String get yourTurn => 'À toi de jouer.';

  @override
  String get opponentTurn => 'Au tour de l\'adversaire.';

  @override
  String get aiThinking => 'Réfléchit…';

  @override
  String get check => 'Échec !';

  @override
  String get whiteToMove => 'Trait aux Blancs';

  @override
  String get blackToMove => 'Trait aux Noirs';

  @override
  String get you => 'Toi';

  @override
  String get opponent => 'Adversaire';

  @override
  String get friend => 'Ton ami';

  @override
  String get ai => 'IA';

  @override
  String get white => 'Blancs';

  @override
  String get black => 'Noirs';

  @override
  String get resign => 'Abandonner';

  @override
  String get resignConfirm => 'Tu veux vraiment abandonner ?';

  @override
  String get offerDraw => 'Proposer la nulle';

  @override
  String get drawOffered => 'Ton ami propose la nulle.';

  @override
  String get drawOfferSent => 'Proposition de nulle envoyée…';

  @override
  String get accept => 'Accepter';

  @override
  String get decline => 'Refuser';

  @override
  String get drawDeclined => 'Ton ami a refusé la nulle.';

  @override
  String get undo => 'Reprendre le coup';

  @override
  String get leaveGame => 'Quitter la partie ?';

  @override
  String get leaveGameBody => 'La partie sera terminée.';

  @override
  String get stay => 'Continuer';

  @override
  String get leave => 'Quitter';

  @override
  String get illegalMove => 'Oula, c\'était quoi ça ? 😂';

  @override
  String get promoteTitle => 'Promouvoir le pion en…';

  @override
  String get gameStartToast => 'La guerre est déclarée.';

  @override
  String get holdTight => 'Tiens bon !';

  @override
  String get pieceKing => 'Roi';

  @override
  String get pieceQueen => 'Dame';

  @override
  String get pieceRook => 'Tour';

  @override
  String get pieceBishop => 'Fou';

  @override
  String get pieceKnight => 'Cavalier';

  @override
  String get piecePawn => 'Pion';

  @override
  String get buildYourArmy => 'Monte ton armée';

  @override
  String get buildYourArmyHint => 'Place tes pièces comme tu veux.';

  @override
  String get remainingPieces => 'Pièces restantes';

  @override
  String get allPlaced => 'Toute ton armée est sur l\'échiquier.';

  @override
  String get reset => 'Recommencer';

  @override
  String get autoPlace => 'Placer pour moi';

  @override
  String get done => 'Prêt';

  @override
  String get editArmy => 'Modifier mon armée';

  @override
  String get opponentHidden => 'L\'armée adverse est cachée';

  @override
  String opponentPlacing(int n, int total) {
    return 'L\'adversaire place : $n/$total';
  }

  @override
  String get opponentArmyReady => 'L\'adversaire est prêt';

  @override
  String get waitingOpponentArmy =>
      'Ton armée est prête. On attend l\'adversaire…';

  @override
  String get lockedIn => 'Verrouillé ! Plus personne ne peut rien changer.';

  @override
  String get pawnBackRank => 'Les pions ne vont pas sur ta dernière rangée.';

  @override
  String get outsideZone => 'Garde tes pièces dans ton camp.';

  @override
  String get invalidPosition => 'Cette position n\'est pas valide.';

  @override
  String get moveKing => 'Déplace ton roi.';

  @override
  String missingPieces(int n) {
    return 'Encore $n pièces à placer.';
  }

  @override
  String get timeUp => 'Temps écoulé ! On a placé le reste pour toi.';

  @override
  String get dragHint =>
      'Touche une pièce puis une case, ou fais-la glisser sur l\'échiquier.';

  @override
  String get removePiece => 'Retirer';

  @override
  String passPhoneTo(String player) {
    return 'Passe le téléphone à $player';
  }

  @override
  String get passPhoneHint => 'L\'autre joueur regarde ailleurs 😉';

  @override
  String get imHere => 'Je suis prêt';

  @override
  String get armiesReady => 'Les deux armées sont prêtes…';

  @override
  String get revealWord => 'RÉVÉLATION !';

  @override
  String get curtainRising => 'Le rideau se lève…';

  @override
  String get battleBegins => 'La bataille commence !';

  @override
  String get letsSee => 'Voyons qui s\'est bien préparé !';

  @override
  String get kingInDanger => 'Ton roi est en danger ! Déplace-le.';

  @override
  String get opponentKingInDanger =>
      'Le roi adverse est en danger, il se déplace…';

  @override
  String get kingRescueHint => 'Choisis une case sûre (en doré).';

  @override
  String kingRescueFor(String player) {
    return '$player : ton roi est en danger ! Déplace-le.';
  }

  @override
  String get setupRedo =>
      'Ces deux armées ne peuvent pas démarrer une partie. Refaites-les.';

  @override
  String get youWon => 'Gagné !';

  @override
  String get youLost => 'Perdu !';

  @override
  String get draw => 'Match nul !';

  @override
  String get whiteWins => 'Les Blancs gagnent !';

  @override
  String get blackWins => 'Les Noirs gagnent !';

  @override
  String get wonSubtitle => 'Bravo, chef !';

  @override
  String get lostSubtitle => 'Pas grave, la prochaine sera la bonne.';

  @override
  String get drawSubtitle => 'Ni vainqueur ni vaincu.';

  @override
  String get checkmateWin => 'Chef, ça c\'est un échec et mat !';

  @override
  String get reasonCheckmate => 'Échec et mat';

  @override
  String get reasonStalemate => 'Pat';

  @override
  String get reasonInsufficient => 'Matériel insuffisant pour mater';

  @override
  String get reasonRepetition => 'Triple répétition';

  @override
  String get reasonFifty => 'Règle des cinquante coups';

  @override
  String get reasonResign => 'Abandon';

  @override
  String get reasonDrawAgreed => 'Nulle par accord';

  @override
  String get reasonAbandon => 'L\'adversaire est parti';

  @override
  String get statMode => 'Mode';

  @override
  String get statMoves => 'Coups';

  @override
  String get statDuration => 'Durée';

  @override
  String get statCaptured => 'Prises';

  @override
  String get yourArmy => 'Ton armée';

  @override
  String get opponentArmy => 'Armée adverse';

  @override
  String get whiteArmy => 'Armée des Blancs';

  @override
  String get blackArmy => 'Armée des Noirs';

  @override
  String get playAgain => 'Rejouer';

  @override
  String get rematchRequested => 'Revanche demandée. On attend ton ami…';

  @override
  String get rematchOffered => 'Ton ami veut une revanche !';

  @override
  String get viewBoard => 'Voir l\'échiquier';

  @override
  String engineLabel(String name) {
    return 'Moteur : $name';
  }

  @override
  String get languageShort => 'FR';

  @override
  String get errInvalidIp => 'Cette adresse IP n\'est pas valide.';

  @override
  String get pieceThemeTunisian => 'Tunisien';

  @override
  String aboutTitle(String app) {
    return 'À propos de $app';
  }

  @override
  String get aboutSlogan =>
      'Les échecs classiques.\nUne identité tunisienne.\nUne autre façon de jouer.';

  @override
  String get aboutDescription =>
      'Un jeu d\'échecs tunisien : les échecs classiques et un mode Spécial unique où l\'on monte son armée en cachette.';

  @override
  String get aboutSpecialTitle => 'MODE SPÉCIAL';

  @override
  String get aboutSpecialBody =>
      'Monte ton armée sans que ton adversaire la voie.';

  @override
  String get aboutDeveloperTitle => 'DÉVELOPPEUR';

  @override
  String developedBy(String name) {
    return 'Développé par $name';
  }

  @override
  String get madeInTunisia => 'Créé en Tunisie';

  @override
  String get madeInTunisiaFlag => 'Créé en Tunisie 🇹🇳';

  @override
  String get contactTitle => 'CONTACT ET RETOURS';

  @override
  String get contactQuestion => 'Un bug ? Une idée ou une suggestion ?';

  @override
  String get contactBody =>
      'Contacte-moi pour un bug, une suggestion ou un retour.';

  @override
  String get contactDeveloper => 'Contacter le développeur';

  @override
  String get reportBug => 'Signaler un bug';

  @override
  String get sendFeedback => 'Envoyer un retour';

  @override
  String get sendSuggestion => 'Proposer une idée';

  @override
  String get followDeveloper => 'Suivre le développeur';

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
      'Impossible de l\'ouvrir. L\'adresse a été copiée.';

  @override
  String get bugWhatWentWrong => 'Quel est le problème ?';

  @override
  String get bugDescriptionHint =>
      'Décris ce qui s\'est passé et ce que tu attendais.';

  @override
  String get bugGameMode => 'Mode de jeu (facultatif)';

  @override
  String get bugIncludeDevice => 'Inclure les infos de l\'appareil';

  @override
  String get bugPrivacyNote =>
      'Cela ouvre ton application e-mail avec le rapport prêt. Rien n\'est envoyé tant que tu n\'appuies pas sur Envoyer.';

  @override
  String get sectionAbout => 'À propos';
}
