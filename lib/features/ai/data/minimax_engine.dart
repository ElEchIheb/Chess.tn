import 'dart:isolate';
import 'dart:math';

import 'package:dartchess/dartchess.dart';

import '../../chess/domain/chess_game.dart';
import '../domain/ai_level.dart';
import '../domain/chess_engine.dart';
import 'minimax_search.dart';

/// Built-in pure Dart engine (alpha-beta + piece-square tables).
///
/// Plays levels 1 and 2 on purpose — it can be made genuinely weak — and
/// replaces Stockfish on platforms where the native engine is unavailable.
class MinimaxEngine implements ChessEngine {
  MinimaxEngine({Random? random, this.useIsolate = true})
    : _random = random ?? Random();

  final Random _random;

  /// Tests run the search inline to stay deterministic and fast.
  final bool useIsolate;

  @override
  String get name => 'chess.tn engine';

  @override
  Future<NormalMove?> bestMove(ChessGame game, AiLevel level) async {
    final request = SearchRequest(
      fen: game.fen,
      maxDepth: level.useStockfish ? level.fallbackDepth : level.depth,
      maxTimeMs: max(level.moveTimeMs, 250),
      blunderChance: level.blunderChance,
      evalNoise: level.evalNoise,
      seed: _random.nextInt(1 << 31),
    );
    final uci = useIsolate
        ? await Isolate.run(() => searchBestMove(request))
        : searchBestMove(request);
    final move = uci == null ? null : Move.parse(uci);
    return move is NormalMove ? move : null;
  }

  @override
  Future<void> dispose() async {}
}
