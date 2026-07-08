import 'difficulty_profile.dart';

class BotBluffStrategy {
  const BotBluffStrategy._();

  static bool shouldBluffCall({
    required int difficulty,
    required double roll,
    required int teamScore,
    required int ownMaxStrength,
    required int cardsOnTable,
    required int teamRoundWins,
    required int opponentRoundWins,
    required bool teamHasStrongSignal,
    required bool opponentHasStrongSignal,
    required bool needsPoints,
  }) {
    final profile = DifficultyProfiles.byLevel(difficulty);
    if (profile.bluffChance == 0) return false;
    if (teamHasStrongSignal || ownMaxStrength >= 90 || teamScore >= 126) {
      return false;
    }
    if (profile.readsOpponentSignals && opponentHasStrongSignal) return false;
    if (opponentRoundWins > 0 && !needsPoints) return false;

    final hasTableRead = cardsOnTable > 0;
    final hasPressure = needsPoints || opponentRoundWins > teamRoundWins;
    final canSellStory = hasTableRead || hasPressure || difficulty <= 2;
    if (!canSellStory) return false;

    return roll <
        _adjustedChance(
          profile,
          hasTableRead: hasTableRead,
          hasPressure: hasPressure,
          difficulty: difficulty,
        );
  }

  static int? bluffRaiseValue({
    required int difficulty,
    required double roll,
    required int pendingValue,
    required int maxAllowedValue,
    required int teamScore,
    required bool hasStrongSignal,
    required bool sawOpponentStrongSignal,
    required bool needsPoints,
    required bool isWinningReparto,
  }) {
    if (pendingValue >= maxAllowedValue || pendingValue >= 9) return null;

    final profile = DifficultyProfiles.byLevel(difficulty);
    if (hasStrongSignal || teamScore >= 130) return null;
    if (profile.readsOpponentSignals && sawOpponentStrongSignal) return null;
    if (!needsPoints && !isWinningReparto && difficulty >= 4) return null;

    final chance = _adjustedChance(
      profile,
      hasTableRead: true,
      hasPressure: needsPoints,
      difficulty: difficulty,
    );
    if (roll >= chance) return null;

    final value = pendingValue + 3;
    return value <= maxAllowedValue ? value : null;
  }

  static double _adjustedChance(
    DifficultyProfile profile, {
    required bool hasTableRead,
    required bool hasPressure,
    required int difficulty,
  }) {
    var chance = profile.bluffChance;
    if (hasTableRead) chance += 0.025;
    if (hasPressure) chance += 0.025;
    if (difficulty == 1) chance -= 0.02;
    return chance.clamp(0, 0.18);
  }
}
