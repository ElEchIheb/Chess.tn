import 'package:dartchess/dartchess.dart';

import '../../chess/domain/chess_game.dart';
import 'ai_level.dart';

/// A chess opponent. Implementations run fully on the device.
abstract interface class ChessEngine {
  /// Short name for diagnostics, e.g. `Stockfish 19`.
  String get name;

  /// Best move for the side to move in [game], or `null` if there is none.
  Future<NormalMove?> bestMove(ChessGame game, AiLevel level);

  Future<void> dispose();
}
