import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

import '../../chess/domain/chess_game.dart';
import '../domain/ai_level.dart';
import '../domain/chess_engine.dart';
import 'minimax_engine.dart';
import 'stockfish_engine.dart';

/// Routes each request to the right engine for the level, and falls back to
/// the built-in engine whenever Stockfish cannot be used, so the AI always
/// answers with a legal move.
class AdaptiveEngine implements ChessEngine {
  AdaptiveEngine({ChessEngine? strong, ChessEngine? builtIn})
    : _strong = strong ?? StockfishEngine(),
      _builtIn = builtIn ?? MinimaxEngine();

  final ChessEngine _strong;
  final ChessEngine _builtIn;
  bool _strongBroken = false;

  /// Name of the engine that produced the last move.
  final ValueNotifier<String?> lastEngineName = ValueNotifier(null);

  @override
  String get name => lastEngineName.value ?? _builtIn.name;

  @override
  Future<NormalMove?> bestMove(ChessGame game, AiLevel level) async {
    if (level.useStockfish && !_strongBroken) {
      try {
        final move = await _strong.bestMove(game, level);
        if (move != null && game.isLegal(move)) {
          lastEngineName.value = _strong.name;
          return move;
        }
      } catch (error) {
        // Unsupported platform or a crashed engine: stop trying.
        _strongBroken = true;
        debugPrint('Stockfish unavailable, using built-in engine: $error');
      }
    }
    lastEngineName.value = _builtIn.name;
    return _builtIn.bestMove(game, level);
  }

  @override
  Future<void> dispose() async {
    await _strong.dispose();
    await _builtIn.dispose();
  }
}
