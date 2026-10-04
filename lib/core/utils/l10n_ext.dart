import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';

import '../../features/ai/domain/ai_level.dart';
import '../../features/chess/domain/chess_game.dart';
import '../../features/chess/domain/match_authority.dart';
import '../../features/multiplayer/domain/lan_error.dart';
import '../../features/special_mode/domain/special_position_validator.dart';
import '../../l10n/app_localizations.dart';
import '../theme/board_theme.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Localized names for domain values, kept in one place so no widget
/// hardcodes a string.
extension L10nNames on AppLocalizations {
  String levelName(AiLevel level) => switch (level) {
    AiLevel.veryEasy => level1,
    AiLevel.easy => level2,
    AiLevel.medium => level3,
    AiLevel.hard => level4,
    AiLevel.expert => level5,
  };

  String variantName(GameVariant variant) =>
      variant == GameVariant.special ? specialChess : normalChess;

  String sideName(Side side) => side == Side.white ? white : black;

  String roleName(Role role) => switch (role) {
    Role.king => pieceKing,
    Role.queen => pieceQueen,
    Role.rook => pieceRook,
    Role.bishop => pieceBishop,
    Role.knight => pieceKnight,
    Role.pawn => piecePawn,
  };

  String endReason(GameEndReason reason) => switch (reason) {
    GameEndReason.checkmate => reasonCheckmate,
    GameEndReason.stalemate => reasonStalemate,
    GameEndReason.insufficientMaterial => reasonInsufficient,
    GameEndReason.threefoldRepetition => reasonRepetition,
    GameEndReason.fiftyMoveRule => reasonFifty,
    GameEndReason.resignation => reasonResign,
    GameEndReason.drawAgreement => reasonDrawAgreed,
    GameEndReason.abandonment => reasonAbandon,
  };

  String lanError(LanError error) => switch (error) {
    LanError.noNetwork => errNoNetwork,
    LanError.invalidCode => errInvalidCode,
    LanError.hostNotFound => errHostNotFound,
    LanError.roomFull => errRoomFull,
    LanError.wrongCode => errWrongCode,
    LanError.versionMismatch => errVersion,
    LanError.cannotHost => errCannotHost,
    LanError.unknown => errUnknown,
  };

  /// The most useful message for a list of setup problems.
  String setupIssue(List<SetupIssue> issues, {int missing = 0}) {
    if (issues.contains(SetupIssue.pawnOnBackRank)) return pawnBackRank;
    if (issues.contains(SetupIssue.outsideZone)) return outsideZone;
    if (issues.contains(SetupIssue.kingCount) &&
        !issues.contains(SetupIssue.missingPieces)) {
      return '$invalidPosition $moveKing';
    }
    if (issues.contains(SetupIssue.missingPieces) && missing > 0) {
      return missingPieces(missing);
    }
    return invalidPosition;
  }

  String boardThemeName(BoardTheme theme) => switch (theme) {
    BoardTheme.tunisian => boardThemeTunisian,
    BoardTheme.classic => boardThemeClassic,
    BoardTheme.dark => boardThemeDark,
    BoardTheme.wood => boardThemeWood,
  };

  String pieceThemeName(PieceTheme theme) => switch (theme) {
    PieceTheme.tunisian => pieceThemeTunisian,
    PieceTheme.classic => pieceThemeClassic,
  };
}

String formatClock(Duration duration) {
  final total = duration.inSeconds.clamp(0, 359999);
  final minutes = (total ~/ 60).toString().padLeft(2, '0');
  final seconds = (total % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
