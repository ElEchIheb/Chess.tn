import 'package:dartchess/dartchess.dart';

import 'army_placement.dart';
import 'special_position_composer.dart';
import 'special_rules.dart';

enum SetupIssue {
  /// Not all pieces of the army are on the board yet.
  missingPieces,

  /// The army contains more or fewer pieces of a type than allowed.
  wrongPieceCount,

  /// There is not exactly one king.
  kingCount,

  /// A piece stands outside the player's setup zone.
  outsideZone,

  /// A pawn stands on the player's back rank.
  pawnOnBackRank,
}

/// Result of checking both armies together, after the reveal.
class CombinedValidation {
  const CombinedValidation({
    required this.kingsInCheck,
    required this.playable,
  });

  /// Sides whose king is attacked in the starting position.
  final Set<Side> kingsInCheck;

  /// False when the side to move would have no legal move at all.
  final bool playable;

  bool get isValid => kingsInCheck.isEmpty && playable;
}

/// All Special mode setup rules live here, away from the widgets.
class SpecialPositionValidator {
  const SpecialPositionValidator([this.rules = const SpecialRules()]);

  final SpecialRules rules;

  static const _composer = SpecialPositionComposer();

  /// Whether [role] may be put on [square] in [army] (occupancy is the
  /// caller's concern: the UI swaps or replaces).
  bool canPlace(ArmyPlacement army, Role role, Square square) =>
      rules.allows(army.side, role, square);

  /// Pieces of [role] the player still has to place.
  int remaining(ArmyPlacement army, Role role) =>
      (rules.army[role] ?? 0) - army.countOf(role);

  bool isComplete(ArmyPlacement army) => validateArmy(army).isEmpty;

  /// Validates one army in isolation. An empty list means it is ready.
  List<SetupIssue> validateArmy(ArmyPlacement army) {
    final issues = <SetupIssue>{};
    var missing = false;
    for (final role in Role.values) {
      final expected = rules.army[role] ?? 0;
      final actual = army.countOf(role);
      if (role == Role.king && actual != expected) {
        issues.add(SetupIssue.kingCount);
      }
      if (actual > expected) issues.add(SetupIssue.wrongPieceCount);
      if (actual < expected) missing = true;
    }
    if (missing) issues.add(SetupIssue.missingPieces);
    for (final entry in army.pieces.entries) {
      if (!rules.inZone(army.side, entry.key)) {
        issues.add(SetupIssue.outsideZone);
      } else if (entry.value == Role.pawn &&
          !rules.allowPawnsOnBackRank &&
          rules.isBackRank(army.side, entry.key)) {
        issues.add(SetupIssue.pawnOnBackRank);
      }
    }
    return issues.toList();
  }

  /// Sides whose king is attacked when both armies are put together.
  Set<Side> kingsInCheck(ArmyPlacement white, ArmyPlacement black) {
    final board = _composer.board(white, black);
    return {
      for (final side in Side.values)
        if (_isAttacked(board, side)) side,
    };
  }

  CombinedValidation validateCombined(
    ArmyPlacement white,
    ArmyPlacement black,
  ) {
    final checks = kingsInCheck(white, black);
    var playable = false;
    if (checks.isEmpty) {
      try {
        final position = _composer.position(white, black);
        playable =
            position.hasSomeLegalMoves && !position.isInsufficientMaterial;
      } on PositionSetupException {
        playable = false;
      }
    }
    return CombinedValidation(kingsInCheck: checks, playable: playable);
  }

  static bool _isAttacked(Board board, Side side) {
    final king = board.kingOf(side);
    return king != null && board.attacksTo(king, side.opposite).isNotEmpty;
  }
}
