import 'package:chess_tn/features/special_mode/domain/army_placement.dart';
import 'package:dartchess/dartchess.dart';

/// Builds an army from rows written back rank first, files a..h.
/// `.` is an empty square; letters are k q r b n p.
ArmyPlacement armyFromRows(Side side, List<String> rows) {
  final pieces = <Square, Role>{};
  for (var r = 0; r < rows.length; r++) {
    for (var f = 0; f < 8; f++) {
      final char = rows[r][f];
      if (char == '.') continue;
      final rank = side == Side.white ? r : 7 - r;
      pieces[Square.fromCoords(File(f), Rank(rank))] = Role.fromChar(char)!;
    }
  }
  return ArmyPlacement(side, pieces);
}

/// A non-classical white army (ranks 1 to 4).
ArmyPlacement customWhite() =>
    armyFromRows(Side.white, ['..r.r.k.', '..bbqppp', 'ppp.nn..', '...pp...']);

/// A non-classical black army (ranks 8 down to 5).
ArmyPlacement customBlack() =>
    armyFromRows(Side.black, ['.k.r.r..', 'pppqbb..', '..nn.ppp', '....pp..']);
