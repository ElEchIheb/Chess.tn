/// The five AI difficulty levels and everything they control.
enum AiLevel {
  veryEasy(
    number: 1,
    useStockfish: false,
    skillLevel: 0,
    depth: 1,
    moveTimeMs: 150,
    fallbackDepth: 1,
    blunderChance: 0.45,
    evalNoise: 120,
    setupCandidates: 1,
    setupRefinements: 0,
  ),
  easy(
    number: 2,
    useStockfish: false,
    skillLevel: 0,
    depth: 2,
    moveTimeMs: 300,
    fallbackDepth: 2,
    blunderChance: 0.15,
    evalNoise: 60,
    setupCandidates: 4,
    setupRefinements: 0,
  ),
  medium(
    number: 3,
    useStockfish: true,
    skillLevel: 3,
    depth: 5,
    moveTimeMs: 400,
    fallbackDepth: 3,
    blunderChance: 0.03,
    evalNoise: 15,
    setupCandidates: 24,
    setupRefinements: 0,
  ),
  hard(
    number: 4,
    useStockfish: true,
    skillLevel: 10,
    depth: 10,
    moveTimeMs: 900,
    fallbackDepth: 4,
    blunderChance: 0,
    evalNoise: 0,
    setupCandidates: 120,
    setupRefinements: 120,
  ),
  expert(
    number: 5,
    useStockfish: true,
    skillLevel: 20,
    depth: 18,
    moveTimeMs: 1800,
    fallbackDepth: 5,
    blunderChance: 0,
    evalNoise: 0,
    setupCandidates: 300,
    setupRefinements: 500,
  );

  const AiLevel({
    required this.number,
    required this.useStockfish,
    required this.skillLevel,
    required this.depth,
    required this.moveTimeMs,
    required this.fallbackDepth,
    required this.blunderChance,
    required this.evalNoise,
    required this.setupCandidates,
    required this.setupRefinements,
  });

  /// 1..5, as shown to the player.
  final int number;

  /// Levels 3+ are played by Stockfish; 1 and 2 by the built-in engine,
  /// because even Stockfish's weakest setting is too strong for beginners.
  final bool useStockfish;

  /// Stockfish "Skill Level" option (0..20).
  final int skillLevel;

  /// Search depth limit.
  final int depth;

  /// Thinking time limit.
  final int moveTimeMs;

  /// Depth used by the built-in engine when Stockfish is unavailable.
  final int fallbackDepth;

  /// Probability of playing a random legal move (built-in engine).
  final double blunderChance;

  /// Random centipawn noise added to root move scores (built-in engine).
  final int evalNoise;

  /// Special mode: how many army arrangements are generated and compared.
  final int setupCandidates;

  /// Special mode: hill-climbing steps applied to the best arrangement.
  final int setupRefinements;

  static AiLevel fromNumber(int number) => values.firstWhere(
    (l) => l.number == number,
    orElse: () => AiLevel.medium,
  );
}
