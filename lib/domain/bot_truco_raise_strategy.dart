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

    final value = pendingValue + 3;
    return value <= maxAllowedValue ? value : null;
  }

  static int _threshold(DifficultyProfile profile, int base) {
    return base + profile.callThresholdModifier;
  }
}
