// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'chess.tn';

  @override
  String get tagline => 'إبني جيشك من غير ما يشوفك... وبعد نرفعو الستار.';

  @override
  String get normalChess => 'لعب عادي';

  @override
  String get normalChessSubtitle => 'إلعب بالشطرنج الكلاسيكي';

  @override
  String get specialChess => 'اللعبة الخاصة';

  @override
  String get specialBadge => 'SPECIAL';

  @override
  String get specialChessSubtitle => 'ابني جيشك من غير ما يشوفك!';

  @override
  String get vsAi => 'ضد AI';

  @override
  String get vsFriend => 'ضد صاحبك';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get back => 'أرجع';

  @override
  String get cancel => 'بطّل';

  @override
  String get ok => 'باهي';

  @override
  String get close => 'سكّر';

  @override
  String get languageDarija => 'العربية التونسية';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get sectionGame => 'اللعب';

  @override
  String get sectionAudio => 'الصوت';

  @override
  String get sectionAppearance => 'المظهر';

  @override
  String get sound => 'أصوات اللعبة';

  @override
  String get music => 'الموسيقى';

  @override
  String get vibration => 'الاهتزاز';

  @override
  String get boardTheme => 'شكل الرقعة';

  @override
  String get pieceTheme => 'شكل القطع';

  @override
  String get showLegalMoves => 'ورّيني النقلات الممكنة';

  @override
  String get animations => 'الحركات';

  @override
  String get defaultAiLevel => 'مستوى الـAI';

  @override
  String get aboutOffline => 'من غير حساب ومن غير أنترنات: حل وإلعب.';

  @override
  String get boardThemeTunisian => 'تونسي';

  @override
  String get boardThemeClassic => 'كلاسيكي';

  @override
  String get boardThemeDark => 'داكن';

  @override
  String get boardThemeWood => 'خشب';

  @override
  String get pieceThemeClassic => 'كلاسيكي';

  @override
  String get level1 => 'ساهل برشا';

  @override
  String get level2 => 'ساهل';

  @override
  String get level3 => 'متوسط';

  @override
  String get level4 => 'صعيب';

  @override
  String get level5 => 'محترف';

  @override
  String levelNumber(int n) {
    return 'مستوى $n';
  }

  @override
  String get chooseLevel => 'إختار المستوى';

  @override
  String get chooseColor => 'بأنا لون تلعب؟';

  @override
  String get colorWhite => 'أبيض';

  @override
  String get colorBlack => 'أسود';

  @override
  String get colorRandom => 'كيف ما يجي';

  @override
  String get startGame => 'إبدا اللعبة';

  @override
  String get friendTitle => 'إلعب مع صاحبك';

  @override
  String get createGame => 'إنشاء لعبة';

  @override
  String get createGameHint => 'إنت تحل اللعبة وصاحبك يدخل بالكود';

  @override
  String get joinGame => 'إنضم للعبة';

  @override
  String get joinGameHint => 'عندك كود؟ أدخل بيه';

  @override
  String get samePhone => 'على نفس التلفون';

  @override
  String get samePhoneHint => 'تلعبو الزوز بتلفون واحد';

  @override
  String get roomCode => 'كود اللعبة';

  @override
  String get shareCodeHint => 'أعطي الكود هذا لصاحبك';

  @override
  String get waitingFriend => 'إستنى صاحبك يدخل...';

  @override
  String get sameWifiHint => 'تأكد اللي الزوز تلفونات مربوطين بنفس الـWi-Fi.';

  @override
  String yourIp(String ip) {
    return 'الـIP متاعك: $ip';
  }

  @override
  String get enterCode => 'أكتب الكود';

  @override
  String get join => 'أدخل';

  @override
  String get joining => 'قاعد يربط...';

  @override
  String get nearbyGames => 'ألعاب على نفس الشبكة';

  @override
  String get gameOnNetwork => 'اللعبة موجودة على نفس الشبكة';

  @override
  String get noGamesFound => 'ما لقينا حتى لعبة. جرّب بالكود.';

  @override
  String get searchAgain => 'عاود لوّج';

  @override
  String get joinByIp => 'إنضم بالـIP';

  @override
  String get hostIpLabel => 'الـIP متاع صاحبك';

  @override
  String get connected => 'تم الربط!';

  @override
  String get playersReady => 'اللاعبين واجدين؟';

  @override
  String get imReady => 'أنا واجد';

  @override
  String get youAreReady => 'إنت واجد';

  @override
  String get friendReady => 'صاحبك واجد';

  @override
  String get friendNotReady => 'صاحبك مازال...';

  @override
  String get friendChoseSpecial => 'صاحبك اختار اللعبة الخاصة';

  @override
  String get friendChoseNormal => 'صاحبك اختار اللعب العادي';

  @override
  String get youPlayWhite => 'إنت تلعب بالأبيض';

  @override
  String get youPlayBlack => 'إنت تلعب بالأسود';

  @override
  String get errNoNetwork => 'ما فماش شبكة. حل الـWi-Fi وعاود حاول.';

  @override
  String get errInvalidCode => 'الكود هذا موش صحيح.';

  @override
  String get errHostNotFound =>
      'ما لقيناش اللعبة. تأكد اللي الزوز تلفونات مربوطين بنفس الـWi-Fi.';

  @override
  String get errRoomFull => 'اللعبة معبّية: فيها زوز لاعبين.';

  @override
  String get errWrongCode => 'الكود غالط. ثبّت فيه مع صاحبك.';

  @override
  String get errVersion => 'لازم الزوز يكون عندكم نفس نسخة اللعبة.';

  @override
  String get errCannotHost => 'ما نجّمناش نحلّو اللعبة. عاود حاول.';

  @override
  String get errUnknown => 'صار مشكل. عاود حاول.';

  @override
  String get connectionLost => 'الاتصال تقطع.';

  @override
  String get reconnecting => 'نحاولو نرجّعو الربط...';

  @override
  String get friendLeft => 'صاحبك خرج من اللعبة.';

  @override
  String get friendDisconnected => 'صاحبك تقطع عليه الربط. نستنّاو فيه...';

  @override
  String get friendBack => 'صاحبك رجع!';

  @override
  String get protocolError => 'صار مشكل في الاتصال واللعبة وفات.';

  @override
  String get tryAgain => 'عاود حاول';

  @override
  String get goHome => 'للرئيسية';

  @override
  String get yourTurn => 'هاو جاك الدور.';

  @override
  String get opponentTurn => 'الدور على الخصم.';

  @override
  String get aiThinking => 'يخمّم...';

  @override
  String get check => 'كش ملك!';

  @override
  String get whiteToMove => 'الدور على الأبيض';

  @override
  String get blackToMove => 'الدور على الأسود';

  @override
  String get you => 'إنت';

  @override
  String get opponent => 'الخصم';

  @override
  String get friend => 'صاحبك';

  @override
  String get ai => 'الذكاء الاصطناعي';

  @override
  String get white => 'الأبيض';

  @override
  String get black => 'الأسود';

  @override
  String get resign => 'إستسلم';

  @override
  String get resignConfirm => 'متأكد تحب تستسلم؟';

  @override
  String get offerDraw => 'أطلب تعادل';

  @override
  String get drawOffered => 'صاحبك يطلب في تعادل.';

  @override
  String get drawOfferSent => 'بعثت طلب تعادل...';

  @override
  String get accept => 'أقبل';

  @override
  String get decline => 'أرفض';

  @override
  String get drawDeclined => 'صاحبك رفض التعادل.';

  @override
  String get undo => 'رجّع النقلة';

  @override
  String get leaveGame => 'تخرج من اللعبة؟';

  @override
  String get leaveGameBody => 'اللعبة باش توفى.';

  @override
  String get stay => 'نكمّل';

  @override
  String get leave => 'إخرج';

  @override
  String get illegalMove => 'ياخي شعملت؟ 😂';

  @override
  String get promoteTitle => 'بدّل البيدق بـ...';

  @override
  String get gameStartToast => 'هاك بديت الحرب.';

  @override
  String get holdTight => 'شد صحيح!';

  @override
  String get pieceKing => 'الملك';

  @override
  String get pieceQueen => 'الوزير';

  @override
  String get pieceRook => 'الرخ';

  @override
  String get pieceBishop => 'الفيل';

  @override
  String get pieceKnight => 'الحصان';

  @override
  String get piecePawn => 'البيدق';

  @override
  String get buildYourArmy => 'إبني جيشك';

  @override
  String get buildYourArmyHint => 'رتّب قطعك كيف ما تحب.';

  @override
  String get remainingPieces => 'القطع الباقية';

  @override
  String get allPlaced => 'جيشك الكل في الرقعة.';

  @override
  String get reset => 'عاود من الأول';

  @override
  String get autoPlace => 'رتّب وحدك';

  @override
  String get done => 'جاهز';

  @override
  String get editArmy => 'بدّل الترتيب';

  @override
  String get opponentHidden => 'جيش الخصم مخبّي';

  @override
  String opponentPlacing(int n, int total) {
    return 'الخصم يرتّب: $n/$total';
  }

  @override
  String get opponentArmyReady => 'الخصم واجد';

  @override
  String get waitingOpponentArmy => 'جيشك واجد. نستنّاو في الخصم...';

  @override
  String get lockedIn => 'تسكّرت! حتى حد ما عاد ينجّم يبدّل.';

  @override
  String get pawnBackRank => 'البيادق ما يتحطّوش في الصف اللخراني.';

  @override
  String get outsideZone => 'خلّي قطعك في جيهتك.';

  @override
  String get invalidPosition => 'الوضعية هاذي موش صالحة.';

  @override
  String get moveKing => 'بدّل مكان الملك.';

  @override
  String missingPieces(int n) {
    return 'مازالو $n قطع ما تحطّوش.';
  }

  @override
  String get timeUp => 'الوقت وفى! رتّبنالك الباقي.';

  @override
  String get dragHint => 'أنقر على القطعة وبعد على البلاصة، ولا جرّها للرقعة.';

  @override
  String get removePiece => 'نحّيها';

  @override
  String passPhoneTo(String player) {
    return 'أعطي التلفون لـ$player';
  }

  @override
  String get passPhoneHint => 'اللاعب الآخر يدوّر وجهو 😉';

  @override
  String get imHere => 'أنا واجد';

  @override
  String get armiesReady => 'الجيشين واجدين...';

  @override
  String get revealWord => 'كشــــــــف!';

  @override
  String get curtainRising => 'الستار يترفع...';

  @override
  String get battleBegins => 'المعركة تبدأ!';

  @override
  String get letsSee => 'توا نشوفو شكون حضّر روحو!';

  @override
  String get kingInDanger => 'ملكك في خطر! بدّل مكانو.';

  @override
  String get opponentKingInDanger => 'ملك الخصم في خطر، قاعد يبدّل فيه...';

  @override
  String get kingRescueHint => 'إختار بلاصة آمنة (بالذهبي).';

  @override
  String kingRescueFor(String player) {
    return '$player: ملكك في خطر! بدّل مكانو.';
  }

  @override
  String get setupRedo => 'الجيشين هاذم ما ينجّموش يبداو لعبة. عاودو ابنيوهم.';

  @override
  String get youWon => 'ربحت!';

  @override
  String get youLost => 'خسرت!';

  @override
  String get draw => 'تعادل!';

  @override
  String get whiteWins => 'الأبيض ربح!';

  @override
  String get blackWins => 'الأسود ربح!';

  @override
  String get wonSubtitle => 'مبروك يا معلم!';

  @override
  String get lostSubtitle => 'ما عليش، المرة الجاية خير.';

  @override
  String get drawSubtitle => 'لا غالب لا مغلوب.';

  @override
  String get checkmateWin => 'يا معلم، هاذي كش مات!';

  @override
  String get reasonCheckmate => 'كش مات';

  @override
  String get reasonStalemate => 'الملك محصور (بات)';

  @override
  String get reasonInsufficient => 'القطع ما تكفيش للكش مات';

  @override
  String get reasonRepetition => 'نفس الوضعية ثلاثة مرات';

  @override
  String get reasonFifty => 'خمسين نقلة بلاش حتى شي';

  @override
  String get reasonResign => 'استسلام';

  @override
  String get reasonDrawAgreed => 'تعادل بالاتفاق';

  @override
  String get reasonAbandon => 'الخصم خرج';

  @override
  String get statMode => 'نوع اللعبة';

  @override
  String get statMoves => 'النقلات';

  @override
  String get statDuration => 'الوقت';

  @override
  String get statCaptured => 'المأكولة';

  @override
  String get yourArmy => 'جيشك';

  @override
  String get opponentArmy => 'جيش الخصم';

  @override
  String get whiteArmy => 'جيش الأبيض';

  @override
  String get blackArmy => 'جيش الأسود';

  @override
  String get playAgain => 'عاود اللعب';

  @override
  String get rematchRequested => 'طلبت تعاودو. نستنّاو في صاحبك...';

  @override
  String get rematchOffered => 'صاحبك يحب يعاود!';

  @override
  String get viewBoard => 'شوف الرقعة';

  @override
  String engineLabel(String name) {
    return 'المحرّك: $name';
  }

  @override
  String get languageShort => 'تونسي';

  @override
  String get errInvalidIp => 'الـIP هذا موش صحيح.';

  @override
  String get pieceThemeTunisian => 'تونسي';

  @override
  String aboutTitle(String app) {
    return 'حول $app';
  }

  @override
  String get aboutSlogan => 'شطرنج كلاسيكي.\nروح تونسية.\nطريقة أخرى للعب.';

  @override
  String get aboutDescription =>
      'لعبة شطرنج تونسية: الشطرنج الكلاسيكي، ومعاه لعبة خاصة تبني فيها جيشك بالمخبّي.';

  @override
  String get aboutSpecialTitle => 'اللعبة الخاصة';

  @override
  String get aboutSpecialBody => 'إبني جيشك من غير ما يشوفو خصمك.';

  @override
  String get aboutDeveloperTitle => 'المطوّر';

  @override
  String developedBy(String name) {
    return 'طوّرها $name';
  }

  @override
  String get madeInTunisia => 'مصنوعة في تونس';

  @override
  String get madeInTunisiaFlag => 'مصنوعة في تونس 🇹🇳';

  @override
  String get contactTitle => 'تواصل وآراء';

  @override
  String get contactQuestion => 'لقيت Bug؟ عندك فكرة ولا اقتراح؟';

  @override
  String get contactBody => 'كلّمني على أي Bug، اقتراح ولا رأي.';

  @override
  String get contactDeveloper => 'تواصل مع المطوّر';

  @override
  String get reportBug => 'بلّغ على Bug';

  @override
  String get sendFeedback => 'ابعث Feedback';

  @override
  String get sendSuggestion => 'اقترح فكرة';

  @override
  String get followDeveloper => 'تابع المطوّر';

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
    return 'النسخة $version';
  }

  @override
  String get linkOpenFailed => 'ما نجّمناش نحلّوه. نسخنالك العنوان.';

  @override
  String get bugWhatWentWrong => 'شنوة المشكلة؟';

  @override
  String get bugDescriptionHint => 'أحكيلنا شنوة صار وشنوة كنت تستنّى.';

  @override
  String get bugGameMode => 'نوع اللعبة (كان تحب)';

  @override
  String get bugIncludeDevice => 'زيد معلومات التلفون';

  @override
  String get bugPrivacyNote =>
      'هذا يحلّلك تطبيق الـEmail والتقرير واجد. ما يتبعث شي كان ما تنزل إنت على «إبعث».';

  @override
  String get sectionAbout => 'حول';
}
