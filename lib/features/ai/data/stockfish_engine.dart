import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:multistockfish/multistockfish.dart';

import '../../chess/domain/chess_game.dart';
import '../domain/ai_level.dart';
import '../domain/chess_engine.dart';

/// Stockfish 19 running natively on the device (no network involved).
class StockfishEngine implements ChessEngine {
  Stockfish? _engine;
  StreamSubscription<String>? _output;
  Completer<String>? _pending;
  Future<void>? _starting;

  @override
  String get name => 'Stockfish 19';

  Future<void> _ensureStarted() => _starting ??= _start();

  Future<void> _start() async {
    try {
      final engine = await Stockfish.create();
      _engine = engine;
      _output = engine.stdout.listen(_onLine);
      engine.stdin = 'setoption name Threads value 1';
      engine.stdin = 'setoption name Hash value 16';
    } catch (_) {
      _starting = null;
      rethrow;
    }
  }

  void _onLine(String line) {
    if (line.startsWith('bestmove')) {
      final pending = _pending;
      _pending = null;
      pending?.complete(line);
    }
  }

  @override
  Future<NormalMove?> bestMove(ChessGame game, AiLevel level) async {
    await _ensureStarted();
    final engine = _engine!;
    if (_pending != null) {
      // A previous search was abandoned: stop it and drop its answer.
      engine.stdin = 'stop';
      await _pending!.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => '',
      );
    }
    final completer = _pending = Completer<String>();
    final moves = game.uciMoves;
    engine.stdin = 'setoption name Skill Level value ${level.skillLevel}';
    engine.stdin = moves.isEmpty
        ? 'position fen ${game.initialFen}'
        : 'position fen ${game.initialFen} moves ${moves.join(' ')}';
    engine.stdin = 'go depth ${level.depth} movetime ${level.moveTimeMs}';

    final line = await completer.future.timeout(
      Duration(milliseconds: level.moveTimeMs + 6000),
      onTimeout: () {
        engine.stdin = 'stop';
        throw TimeoutException('Stockfish did not answer');
      },
    );
    final parts = line.split(' ');
    if (parts.length < 2) return null;
    final move = Move.parse(parts[1]);
    return move is NormalMove ? move : null;
  }

  @override
  Future<void> dispose() async {
    await _output?.cancel();
    _output = null;
    final engine = _engine;
    _engine = null;
    _starting = null;
    if (_pending != null && !_pending!.isCompleted) {
      _pending!.complete('');
    }
    _pending = null;
    await engine?.dispose();
  }
}
