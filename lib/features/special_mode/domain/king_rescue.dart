import 'package:dartchess/dartchess.dart';

import 'army_placement.dart';
import 'special_position_validator.dart';
import 'special_rules.dart';

/// "No king starts under fire" rule.
///
/// Armies are built blind, so a king can be attacked the moment the curtain
/// opens. That is not a legal chess start, so the owner must move the king
/// to a safe square of their zone before the battle begins. This happens
/// after the reveal, when everything is public, so nothing leaks.
class KingRescueResolver {
  const KingRescueResolver([this.rules = const SpecialRules()]);

  final SpecialRules rules;

  SpecialPositionValidator get _validator => SpecialPositionValidator(rules);

  /// The side that has to relocate next, white first. `null` when no king is
  /// in check.
  Side? nextToRescue(ArmyPlacement white, ArmyPlacement black) {
    final checks = _validator.kingsInCheck(white, black);
    if (checks.contains(Side.white)) return Side.white;
    if (checks.contains(Side.black)) return Side.black;
    return null;
  }

  /// Empty squares of [side]'s zone where its king is safe and where the
  /// relocation does not put the other king in a (new) check.
  Set<Square> safeSquares(Side side, ArmyPlacement white, ArmyPlacement black) {
    final own = side == Side.white ? white : black;
    final before = _validator.kingsInCheck(white, black);
    final result = <Square>{};
    for (final square in rules.zoneSquares(side)) {
      if (white.roleAt(square) != null || black.roleAt(square) != null) {
        continue;
      }
      final moved = own.withKingAt(square);
      final after = side == Side.white
          ? _validator.kingsInCheck(moved, black)
          : _validator.kingsInCheck(white, moved);
      if (after.contains(side)) continue;
      if (after.contains(side.opposite) && !before.contains(side.opposite)) {
        continue;
      }
      result.add(square);
    }
    return result;
  }
}
