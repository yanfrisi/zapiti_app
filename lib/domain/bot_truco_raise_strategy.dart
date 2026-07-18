import 'difficulty_profile.dart';

class BotTrucoRaiseStrategy {
  const BotTrucoRaiseStrategy._();

  static int? chooseRaiseValue({
    required int difficulty,
    required int pendingValue,
    required int maxAllowedValue,
    required Iterable<int> strengths,
    required int teamScore,
    required bool hasStrongSignal,
    required bool isWinningReparto,
    required bool sawOpponentStrongSignal,
    bool isCompanionProtectingHuman = false,
    double roll = 0,
  }) {
    if (pendingValue >= maxAllowedValue || pendingValue >= 9) return null;

    final profile = DifficultyProfiles.byLevel(difficulty);
    if (profile.readsOpponentSignals && sawOpponentStrongSignal) return null;

    final sortedStrengths = strengths.toList()..sort();
    if (sortedStrengths.isEmpty) return null;

    final strongest = sortedStrengths.last;
    final hasTwoGoodCards =
        sortedStrengths.where((strength) => strength >= 80).length >= 2;
    final thresholdDiscount = isCompanionProtectingHuman ? 14 : 0;

    if (strongest < 90 && !hasTwoGoodCards && !hasStrongSignal) return null;
    if (!isWinningReparto &&
        pendingValue >= 6 &&
        !hasTwoGoodCards &&
        !hasStrongSignal) {
      return null;
    }
    if (pendingValue == 3 &&
        isCompanionProtectingHuman &&
        strongest < 97 &&
        !hasTwoGoodCards &&
        !hasStrongSignal) {
      return null;
    }
    if (teamScore <
            _threshold(profile, isCompanionProtectingHuman ? 105 : 115) -
                thresholdDiscount &&
        pendingValue >= 6) {
      return null;
    }

    final shouldRaise = teamScore >=
            _threshold(profile, isCompanionProtectingHuman ? 132 : 145) ||
        hasStrongSignal ||
        (isCompanionProtectingHuman && strongest >= 97);
    if (!shouldRaise && pendingValue >= 6) return null;

    final handStrength = _normalizedStrength(sortedStrengths);
    final chance = _raiseChance(
      profile.level,
      handStrength: handStrength,
      hasStrongSignal: hasStrongSignal,
      isWinningReparto: isWinningReparto,
      pendingValue: pendingValue,
      isCompanionProtectingHuman: isCompanionProtectingHuman,
    );
    if (roll >= chance) return null;

    final value = pendingValue + 3;
    return value <= maxAllowedValue ? value : null;
  }

  static double _normalizedStrength(List<int> sortedStrengths) {
    final strongest = sortedStrengths.last / 100;
    final second = sortedStrengths.length > 1
        ? sortedStrengths[sortedStrengths.length - 2] / 100
        : 0;
    final third = sortedStrengths.length > 2
        ? sortedStrengths[sortedStrengths.length - 3] / 100
        : 0;
    return (strongest * 0.55 + second * 0.30 + third * 0.15).clamp(0, 1);
  }

  static double _raiseChance(
    int difficulty, {
    required double handStrength,
    required bool hasStrongSignal,
    required bool isWinningReparto,
    required int pendingValue,
    required bool isCompanionProtectingHuman,
  }) {
    var chance = switch (difficulty) {
      <= 2 => handStrength >= 0.80 ? 0.10 : 0.05,
      3 => handStrength >= 0.80 ? 0.17 : 0.09,
      _ => handStrength >= 0.80 ? 0.27 : 0.15,
    };
    if (hasStrongSignal) chance += 0.04;
    if (isWinningReparto) chance += 0.025;
    if (pendingValue >= 6) chance *= 0.45;
    if (isCompanionProtectingHuman) chance *= 0.75;
    return chance.clamp(0, 0.32);
  }

  static int _threshold(DifficultyProfile profile, int base) {
    return base + profile.callThresholdModifier;
  }
}
