import 'dart:async';

import 'package:chess_tn/features/ai/domain/ai_level.dart';
import 'package:chess_tn/features/ai/domain/chess_engine.dart';
import 'package:chess_tn/features/chess/application/game_session.dart';
import 'package:chess_tn/features/chess/domain/chess_game.dart';
import 'package:chess_tn/features/chess/domain/game_phase.dart';
import 'package:chess_tn/features/chess/domain/game_state.dart';
import 'package:dartchess/dartchess.dart';

/// Engine that plays the first legal move, instantly.
class FirstMoveEngine implements ChessEngine {
  int calls = 0;

  @override
  String get name => 'first-move';

  @override
  Future<NormalMove?> bestMove(ChessGame game, AiLevel level) async {
    calls++;
    final position = game.position;
    for (final entry in position.legalMoves.entries) {
      final to = entry.value.first;
      if (to == null) continue;
      final promotes =
          position.board.roleAt(entry.key) == Role.pawn &&
          (to.rank == Rank.first || to.rank == Rank.eighth);
      return NormalMove(
        from: entry.key,
        to: to,
        promotion: promotes ? Role.queen : null,
      );
    }
    return null;
  }

  @override
  Future<void> dispose() async {}
}

/// Waits until [session] reaches [phase] (or fails after [timeout]).
Future<GameState> waitForPhase(
  GameSession session,
  GamePhase phase, {
  Duration timeout = const Duration(seconds: 5),
}) => waitForState(
  session,
  (s) => s.phase == phase,
  timeout: timeout,
  description: 'phase ${phase.name}',
);

Future<GameState> waitForState(
  GameSession session,
  bool Function(GameState state) test, {
  Duration timeout = const Duration(seconds: 5),
  String description = 'condition',
}) {
  if (test(session.current)) return Future.value(session.current);
  final completer = Completer<GameState>();
  void listener() {
    if (!completer.isCompleted && test(session.current)) {
      completer.complete(session.current);
    }
  }

  session.state.addListener(listener);
  return completer.future
      .timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'Timed out waiting for $description; phase is '
            '${session.current.phase.name}',
          );
        },
      )
      .whenComplete(() => session.state.removeListener(listener));
}

/// Lets queued microtasks and zero-delay timers run.
Future<void> settle([int rounds = 4]) async {
  for (var i = 0; i < rounds; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
