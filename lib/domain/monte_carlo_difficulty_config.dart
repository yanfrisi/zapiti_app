class MonteCarloDifficultyConfig {
  final int simulationsPerMove;
  final int rolloutDepth;
  final double mistakeProbability;
  final int topCandidateCount;
  final bool useActionInference;
  final bool usePartnerModel;
  final bool useOpponentProfiles;
  final bool useSignalInference;
  final bool useBetInference;

  const MonteCarloDifficultyConfig({
    required this.simulationsPerMove,
    required this.rolloutDepth,
    required this.mistakeProbability,
    required this.topCandidateCount,
    required this.useActionInference,
    required this.usePartnerModel,
    required this.useOpponentProfiles,
    this.useSignalInference = false,
    this.useBetInference = false,
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
    useSignalInference: false,
    useBetInference: false,
  );

  static const normal = MonteCarloDifficultyConfig(
    simulationsPerMove: 75,
    rolloutDepth: 2,
    mistakeProbability: 0.07,
    topCandidateCount: 2,
    useActionInference: true,
    usePartnerModel: false,
    useOpponentProfiles: false,
    useSignalInference: true,
    useBetInference: false,
  );

  static const hard = MonteCarloDifficultyConfig(
    simulationsPerMove: 240,
    rolloutDepth: 3,
    mistakeProbability: 0.01,
    topCandidateCount: 1,
    useActionInference: true,
    usePartnerModel: true,
    useOpponentProfiles: false,
    useSignalInference: true,
    useBetInference: true,
  );

  static const expert = MonteCarloDifficultyConfig(
    simulationsPerMove: 600,
    rolloutDepth: 4,
    mistakeProbability: 0,
    topCandidateCount: 1,
    useActionInference: true,
    usePartnerModel: true,
    useOpponentProfiles: true,
    useSignalInference: true,
    useBetInference: true,
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
