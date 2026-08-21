class MonteCarloDifficultyConfig {
  final int simulationsPerMove;
  final int rolloutDepth;
  final double mistakeProbability;
  final int topCandidateCount;
  final bool useActionInference;
  final bool usePartnerModel;
  final bool useOpponentProfiles;

  const MonteCarloDifficultyConfig({
    required this.simulationsPerMove,
    required this.rolloutDepth,
    required this.mistakeProbability,
    required this.topCandidateCount,
    required this.useActionInference,
    required this.usePartnerModel,
    required this.useOpponentProfiles,
  });
}

class MonteCarloDifficultyConfigs {
  const MonteCarloDifficultyConfigs._();

  static const easy = MonteCarloDifficultyConfig(
    simulationsPerMove: 10,
    rolloutDepth: 1,
    mistakeProbability: 0.20,
    topCandidateCount: 3,
    useActionInference: false,
    usePartnerModel: false,
    useOpponentProfiles: false,
  );

  static const normal = MonteCarloDifficultyConfig(
    simulationsPerMove: 75,
    rolloutDepth: 2,
    mistakeProbability: 0.07,
    topCandidateCount: 2,
    useActionInference: true,
    usePartnerModel: false,
    useOpponentProfiles: false,
  );

  static const hard = MonteCarloDifficultyConfig(
    simulationsPerMove: 80,
    rolloutDepth: 3,
    mistakeProbability: 0.01,
    topCandidateCount: 1,
    useActionInference: true,
    usePartnerModel: true,
    useOpponentProfiles: false,
  );

  static const expert = MonteCarloDifficultyConfig(
    simulationsPerMove: 120,
    rolloutDepth: 3,
    mistakeProbability: 0,
    topCandidateCount: 1,
    useActionInference: true,
    usePartnerModel: true,
    useOpponentProfiles: true,
  );

  static MonteCarloDifficultyConfig forDifficulty(int difficulty) {
    return switch (difficulty.clamp(1, 5)) {
      1 || 2 => easy,
      3 => normal,
      4 => hard,
      _ => expert,
    };
  }
}
