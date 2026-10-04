import 'dart:math';

import 'package:chess_tn/features/ai/data/adaptive_engine.dart';
import 'package:chess_tn/features/ai/data/minimax_engine.dart';
import 'package:chess_tn/features/ai/data/minimax_search.dart';
import 'package:chess_tn/features/ai/domain/ai_level.dart';
import 'package:chess_tn/features/ai/domain/ai_setup_generator.dart';
import 'package:chess_tn/features/ai/domain/chess_engine.dart';
import 'package:chess_tn/features/ai/domain/setup_evaluator.dart';
import 'package:chess_tn/features/chess/domain/chess_game.dart';
import 'package:chess_tn/features/special_mode/domain/army_placement.dart';
import 'package:chess_tn/features/special_mode/domain/special_position_validator.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowingEngine implements ChessEngine {
  int calls = 0;

  @override
  String get name => 'broken';

  @override
  Future<NormalMove?> bestMove(ChessGame game, AiLevel level) {
    calls++;
    throw UnsupportedError('no native engine here');
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  group('AI levels', () {
    test('there are five, each stronger than the previous', () {
      expect(AiLevel.values.map((l) => l.number), [1, 2, 3, 4, 5]);
      for (var i = 1; i < AiLevel.values.length; i++) {
        final weaker = AiLevel.values[i - 1];
        final stronger = AiLevel.values[i];
        expect(stronger.depth, greaterThan(weaker.depth));
        expect(stronger.moveTimeMs, greaterThan(weaker.moveTimeMs));
        expect(stronger.skillLevel, greaterThanOrEqualTo(weaker.skillLevel));
        expect(stronger.blunderChance, lessThanOrEqualTo(weaker.blunderChance));
        expect(stronger.setupCandidates, greaterThan(weaker.setupCandidates));
      }
    });
  });

  group('Built-in engine', () {
    test('finds mate in one', () {
      final uci = searchBestMove(
        const SearchRequest(
          fen: '6k1/5ppp/8/8/8/8/8/R3K3 w - - 0 1',
          maxDepth: 2,
          maxTimeMs: 5000,
          seed: 1,
        ),
      );
      expect(uci, 'a1a8');
    });

    test('takes a hanging queen', () {
      final uci = searchBestMove(
        const SearchRequest(
          fen: '4k3/8/8/3q4/4P3/8/8/4K3 w - - 0 1',
          maxDepth: 2,
          maxTimeMs: 5000,
          seed: 1,
        ),
      );
      expect(uci, 'e4d5');
    });

    test('returns null when there is no legal move', () {
      expect(
        searchBestMove(
          const SearchRequest(
            fen: '7k/5K2/6Q1/8/8/8/8/8 b - - 0 1',
            maxDepth: 2,
            maxTimeMs: 1000,
            seed: 1,
          ),
        ),
        isNull,
      );
    });

    test('always answers with a legal move at every level', () async {
      final engine = MinimaxEngine(random: Random(7), useIsolate: false);
      final game = ChessGame.standard();
      for (final level in AiLevel.values) {
        final move = await engine.bestMove(game, level);
        expect(move, isNotNull);
        expect(game.isLegal(move!), isTrue, reason: 'level ${level.number}');
      }
    });

    test('a stronger level beats level 1', () async {
      // Built-in engine on both sides (Stockfish needs a phone): level 3
      // settings against level 1 settings.
      final strong = MinimaxEngine(random: Random(11), useIsolate: false);
      final weak = MinimaxEngine(random: Random(12), useIsolate: false);
      var game = ChessGame.standard();
      while (game.outcome == null && game.ply < 120) {
        final white = game.turn == Side.white;
        final move = white
            ? await strong.bestMove(game, AiLevel.medium)
            : await weak.bestMove(game, AiLevel.veryEasy);
        game = game.play(move!);
      }
      final material = evaluateBoard(game.position.board);
      final won = game.outcome?.winner == Side.white;
      expect(
        won || material > 500,
        isTrue,
        reason: 'outcome ${game.outcome}, material $material',
      );
    }, timeout: const Timeout(Duration(minutes: 3)));
  });

  group('AdaptiveEngine', () {
    test(
      'falls back to the built-in engine when Stockfish is unavailable',
      () async {
        final broken = _ThrowingEngine();
        final engine = AdaptiveEngine(
          strong: broken,
          builtIn: MinimaxEngine(random: Random(3), useIsolate: false),
        );
        final game = ChessGame.standard();
        final move = await engine.bestMove(game, AiLevel.hard);
        expect(move, isNotNull);
        expect(game.isLegal(move!), isTrue);
        expect(broken.calls, 1);

        // It does not keep hammering a broken engine.
        await engine.bestMove(game, AiLevel.expert);
        expect(broken.calls, 1);
      },
    );

    test('levels 1 and 2 never use Stockfish', () async {
      final broken = _ThrowingEngine();
      final engine = AdaptiveEngine(
        strong: broken,
        builtIn: MinimaxEngine(random: Random(3), useIsolate: false),
      );
      await engine.bestMove(ChessGame.standard(), AiLevel.veryEasy);
      await engine.bestMove(ChessGame.standard(), AiLevel.easy);
      expect(broken.calls, 0);
    });
  });

  group('AI special setup', () {
    const validator = SpecialPositionValidator();

    test('contains exactly 1 K, 1 Q, 2 R, 2 B, 2 N, 8 P at every level', () {
      for (final level in AiLevel.values) {
        for (final side in Side.values) {
          final generator = AiSetupGenerator(random: Random(level.number));
          final army = generator.generate(side: side, level: level);
          expect(army.side, side);
          expect(army.countOf(Role.king), 1);
          expect(army.countOf(Role.queen), 1);
          expect(army.countOf(Role.rook), 2);
          expect(army.countOf(Role.bishop), 2);
          expect(army.countOf(Role.knight), 2);
          expect(army.countOf(Role.pawn), 8);
          expect(army.total, 16);
          expect(
            validator.validateArmy(army),
            isEmpty,
            reason: 'level ${level.number} ${side.name}',
          );
        }
      }
    });

    test('every strategy builds a valid army', () {
      final generator = AiSetupGenerator(random: Random(5));
      for (final strategy in SetupStrategy.values) {
        for (var i = 0; i < 20; i++) {
          final army = generator.build(Side.black, strategy);
          expect(validator.validateArmy(army), isEmpty, reason: strategy.name);
        }
      }
    });

    test('is not just the classical starting position', () {
      final generator = AiSetupGenerator(random: Random(9));
      for (final level in AiLevel.values) {
        expect(
          generator.generate(side: Side.black, level: level),
          isNot(ArmyPlacement.standard(Side.black)),
        );
      }
    });

    test('higher levels choose stronger setups', () {
      const evaluator = SetupEvaluator();
      double average(AiLevel level) {
        var total = 0.0;
        for (var seed = 0; seed < 12; seed++) {
          final generator = AiSetupGenerator(random: Random(seed));
          total += evaluator.score(
            generator.generate(side: Side.white, level: level),
          );
        }
        return total / 12;
      }

      final scores = [for (final level in AiLevel.values) average(level)];
      expect(scores[4], greaterThan(scores[2]));
      expect(scores[2], greaterThan(scores[0]));
      expect(scores[4], greaterThan(scores[0] + 100));
    });

    test('the evaluator scores a black army like its white mirror', () {
      const evaluator = SetupEvaluator();
      final white = ArmyPlacement.standard(Side.white);
      final black = ArmyPlacement.standard(Side.black);
      expect(evaluator.score(black), evaluator.score(white));
    });

    test('strong setups keep the king at home', () {
      for (var seed = 0; seed < 8; seed++) {
        final army = AiSetupGenerator(random: Random(seed))
            .generate(side: Side.black, level: AiLevel.expert);
        expect(army.kingSquare!.rank, Rank.eighth);
      }
    });
  });
}
