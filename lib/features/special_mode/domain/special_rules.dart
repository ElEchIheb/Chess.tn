import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

/// Configurable rules of the Special ("hidden army") mode.
@immutable
class SpecialRules {
  const SpecialRules({
    this.zoneRanks = 4,
    this.army = standardArmy,
    this.setupTime = const Duration(seconds: 120),
    this.allowPawnsOnBackRank = false,
  });

  static const Map<Role, int> standardArmy = {
    Role.king: 1,
    Role.queen: 1,
    Role.rook: 2,
    Role.bishop: 2,
    Role.knight: 2,
    Role.pawn: 8,
  };

  /// Order used by the piece tray and by automatic placement.
  static const List<Role> trayOrder = [
    Role.king,
    Role.queen,
    Role.rook,
    Role.bishop,
    Role.knight,
    Role.pawn,
  ];

  /// How many ranks, counted from a player's own back rank, form their
  /// private setup zone.
  final int zoneRanks;

  /// Exact composition every army must have.
  final Map<Role, int> army;

  final Duration setupTime;

  /// Pawns on the back rank make an illegal chess position, so this is off
  /// by default.
  final bool allowPawnsOnBackRank;

  int get armySize => army.values.fold(0, (a, b) => a + b);

  /// Rank index (0..zoneRanks-1) of [square] counted from [side]'s back rank.
  int relativeRank(Side side, Square square) =>
      side == Side.white ? square.rank.value : 7 - square.rank.value;

  bool inZone(Side side, Square square) =>
      relativeRank(side, square) < zoneRanks;

  bool isBackRank(Side side, Square square) => relativeRank(side, square) == 0;

  /// Whether [role] may stand on [square] for [side] (ignores occupancy).
  bool allows(Side side, Role role, Square square) {
    if (!inZone(side, square)) return false;
    if (role == Role.pawn &&
        !allowPawnsOnBackRank &&
        isBackRank(side, square)) {
      return false;
    }
    return true;
  }

  Iterable<Square> zoneSquares(Side side) sync* {
    for (var i = 0; i < 64; i++) {
      final square = Square(i);
      if (inZone(side, square)) yield square;
    }
  }
}
