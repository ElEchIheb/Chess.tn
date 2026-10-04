import 'dart:math';

import 'package:dartchess/dartchess.dart';

import '../../special_mode/domain/army_placement.dart';
import '../../special_mode/domain/special_position_validator.dart';
import '../../special_mode/domain/special_rules.dart';
import 'ai_level.dart';
import 'setup_evaluator.dart';

/// Army building styles the AI can choose from in Special mode.
enum SetupStrategy { random, defensive, balanced, aggressive, tricky }

/// Builds the AI's hidden army.
///
/// The generator is deliberately blind: its only inputs are the AI's own
/// side, the difficulty level and a random source. The human's arrangement
/// is never passed in, so the AI cannot cheat during the setup phase.
class AiSetupGenerator {
  AiSetupGenerator({
    this.rules = const SpecialRules(),
    this.evaluator = const SetupEvaluator(),
    Random? random,
  }) : _random = random ?? Random();

  final SpecialRules rules;
  final SetupEvaluator evaluator;
  final Random _random;

  /// Strategies available per level: stronger levels may use bolder plans
  /// because they can tell which arrangements actually hold together.
  static List<SetupStrategy> strategiesFor(AiLevel level) => switch (level) {
    AiLevel.veryEasy => const [SetupStrategy.random],
    AiLevel.easy => const [SetupStrategy.defensive, SetupStrategy.balanced],
    AiLevel.medium => const [
      SetupStrategy.balanced,
      SetupStrategy.defensive,
      SetupStrategy.aggressive,
    ],
    AiLevel.hard || AiLevel.expert => const [
      SetupStrategy.balanced,
      SetupStrategy.aggressive,
      SetupStrategy.defensive,
      SetupStrategy.tricky,
    ],
  };

  ArmyPlacement generate({required Side side, required AiLevel level}) {
    final strategies = strategiesFor(level);
    if (level == AiLevel.veryEasy) {
      return build(side, SetupStrategy.random);
    }
    ArmyPlacement? best;
    var bestScore = double.negativeInfinity;
    for (var i = 0; i < level.setupCandidates; i++) {
      final candidate = build(side, strategies[i % strategies.length]);
      final score = evaluator.score(candidate);
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }
    return _refine(best!, bestScore, level.setupRefinements);
  }

  /// One arrangement in the style of [strategy]. Always valid.
  ArmyPlacement build(Side side, SetupStrategy strategy) {
    final free = <(int, int)>[
      for (var rank = 0; rank < rules.zoneRanks; rank++)
        for (var file = 0; file < 8; file++) (file, rank),
    ];
    final placed = <(int, int), Role>{};
    (int, int)? king;

    for (final role in SpecialRules.trayOrder) {
      for (var n = 0; n < (rules.army[role] ?? 0); n++) {
        final options = [
          for (final cell in free)
            if (role != Role.pawn || rules.allowPawnsOnBackRank || cell.$2 > 0)
              cell,
        ];
        final weights = [
          for (final cell in options)
            _weight(strategy, role, cell.$1, cell.$2, king, placed),
        ];
        final choice = options[_sample(weights)];
        placed[choice] = role;
        free.remove(choice);
        if (role == Role.king) king = choice;
      }
    }

    return ArmyPlacement(side, {
      for (final entry in placed.entries)
        Square.fromCoords(
          File(entry.key.$1),
          Rank(side == Side.white ? entry.key.$2 : 7 - entry.key.$2),
        ): entry.value,
    });
  }

  /// Preference (log-weight) of putting [role] on (file, rank), where rank 0
  /// is the AI's own back rank.
  double _weight(
    SetupStrategy strategy,
    Role role,
    int file,
    int rank,
    (int, int)? king,
    Map<(int, int), Role> placed,
  ) {
    if (strategy == SetupStrategy.random) return 0;
    final edge = (file - 3.5).abs(); // 0.5 centre .. 3.5 rim
    final nearKing = king == null
        ? 0.0
        : (3 - (file - king.$1).abs()).toDouble();
    final kingFlank = king == null ? 0 : (king.$1 < 4 ? -1 : 1);
    final sameFlank = kingFlank == 0 ? false : (file < 4 ? -1 : 1) == kingFlank;

    switch (strategy) {
      case SetupStrategy.random:
        return 0;

      case SetupStrategy.balanced:
        return switch (role) {
          Role.king => (rank == 0 ? 6 : -4.0 * rank) + 0.8 * edge,
          Role.pawn =>
            (rank == 1
                    ? 2.5
                    : rank == 2
                    ? 1.8
                    : -1.0) +
                (king != null && rank == king.$2 + 1 ? 0.9 * nearKing : 0),
          Role.queen =>
            (rank == 0
                    ? 3
                    : rank == 1
                    ? 1.5
                    : -3) -
                0.4 * edge,
          Role.rook => (rank == 0 ? 3 : 0.0) - 0.3 * edge,
          Role.bishop => (rank <= 1 ? 2.5 : -1.5) - 0.2 * edge,
          Role.knight =>
            (rank == 1
                    ? 2.5
                    : rank == 0
                    ? 1.5
                    : -1.0) -
                0.6 * edge,
        };

      case SetupStrategy.defensive:
        return switch (role) {
          Role.king => (rank == 0 ? 8 : -6.0 * rank) + 1.6 * edge,
          Role.pawn =>
            (rank == 1
                    ? 3.5
                    : rank == 2
                    ? 0.5
                    : -3.0) +
                (king != null && rank == king.$2 + 1 ? 1.5 * nearKing : 0),
          Role.queen => (rank == 0 ? 4 : -2.0 * rank) + 0.4 * nearKing,
          Role.rook => (rank == 0 ? 4 : -2.0 * rank) + 0.5 * nearKing,
          Role.bishop =>
            (rank == 0
                    ? 3
                    : rank == 1
                    ? 1.0
                    : -3) +
                0.3 * nearKing,
          Role.knight => (rank <= 1 ? 2.5 : -3) + 0.6 * nearKing,
        };

      case SetupStrategy.aggressive:
        return switch (role) {
          Role.king => (rank == 0 ? 6 : -5.0 * rank) + 1.4 * edge,
          Role.pawn =>
            (rank == 3
                    ? 2.2
                    : rank == 2
                    ? 2.6
                    : 0.0) -
                0.5 * edge +
                (king != null && rank == 1 ? 0.8 * nearKing : 0),
          Role.queen =>
            (rank == 1
                    ? 3
                    : rank == 0
                    ? 1.5
                    : -1.5) -
                0.8 * edge,
          Role.rook =>
            (rank == 1
                    ? 2.5
                    : rank == 0
                    ? 2.0
                    : -2) -
                0.7 * edge,
          Role.bishop =>
            (rank == 1
                    ? 2.5
                    : rank == 2
                    ? 1.0
                    : 0.0) -
                0.3 * edge,
          Role.knight =>
            (rank == 2
                    ? 3
                    : rank == 1
                    ? 2.0
                    : -1.0) -
                0.8 * edge,
        };

      case SetupStrategy.tricky:
        // King tucked on one wing, the heavy pieces massed on the other.
        return switch (role) {
          Role.king => (rank == 0 ? 6 : -5.0 * rank) + 1.8 * edge,
          Role.pawn =>
            (rank == 1 && sameFlank ? 3.0 : 0.0) +
                (rank == 2 && !sameFlank ? 2.6 : 0.0) +
                (rank == 3 ? -1.5 : 0.0),
          Role.queen => (sameFlank ? -3.0 : 3.0) + (rank <= 1 ? 2.0 : -2.0),
          Role.rook => (sameFlank ? -2.0 : 3.0) + (rank <= 1 ? 2.0 : -2.0),
          Role.bishop =>
            (rank == 1 && (file == 1 || file == 6) ? 3.5 : 0.0) +
                (rank <= 1 ? 1.0 : -2.0),
          Role.knight =>
            (rank == 1
                    ? 2.0
                    : rank == 2
                    ? 1.0
                    : 0.0) +
                (sameFlank ? 1.2 : 0.0) -
                0.4 * edge,
        };
    }
  }

  /// Softmax sampling over log-weights.
  int _sample(List<double> weights) {
    final top = weights.reduce(max);
    final probabilities = [for (final w in weights) exp(w - top)];
    var roll = _random.nextDouble() * probabilities.fold(0.0, (a, b) => a + b);
    for (var i = 0; i < probabilities.length; i++) {
      roll -= probabilities[i];
      if (roll <= 0) return i;
    }
    return probabilities.length - 1;
  }

  /// Hill climbing: try moving a piece to a free square or swapping two
  /// pieces, keep the change when the arrangement scores better.
  ArmyPlacement _refine(ArmyPlacement start, double startScore, int steps) {
    if (steps <= 0) return start;
    final validator = SpecialPositionValidator(rules);
    final zone = rules.zoneSquares(start.side).toList();
    var best = start;
    var bestScore = startScore;
    for (var i = 0; i < steps; i++) {
      final occupied = best.pieces.keys.toList();
      final from = occupied[_random.nextInt(occupied.length)];
      final to = zone[_random.nextInt(zone.length)];
      if (from == to) continue;
      final candidate = best.move(from, to);
      if (validator.validateArmy(candidate).isNotEmpty) continue;
      final score = evaluator.score(candidate);
      if (score > bestScore) {
        best = candidate;
        bestScore = score;
      }
    }
    return best;
  }
}
