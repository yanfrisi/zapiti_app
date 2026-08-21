class AlVerRules {
  const AlVerRules._();

  static const int triggerScore = 29;
  static const int playPoints = 3;
  static const int concedePoints = 2;

  static bool requiresDecision(Set<int> teamIds) => teamIds.length == 1;
}
