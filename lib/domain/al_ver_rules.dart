class AlVerRules {
  const AlVerRules._();

  static const int triggerScore = 29;
  static const int playPoints = 2;
  static const int concedePoints = 2;

  static bool requiresDecision(Set<int> teamIds) => teamIds.length == 1;

  static bool forcesPlayAtScore({
    required int alVerTeamScore,
    required int opponentScore,
    required int targetScore,
  }) {
    return alVerTeamScore == triggerScore && opponentScore == targetScore - 2;
  }
}
