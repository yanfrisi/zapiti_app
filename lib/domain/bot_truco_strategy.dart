import 'difficulty_profile.dart';

class BotTrucoStrategy {
  const BotTrucoStrategy._();

  static bool shouldCall({
    required int difficulty,
    required int teamScore,
    required int ownMaxStrength,
    required int cardsOnTable,
    required int teamRoundWins,
    required int opponentRoundWins,
    required bool teamHasStrongSignal,
    required bool opponentHasStrongSignal,
    required bool isCompanion,
    required bool needsPoints,
  }) {
    final profile = DifficultyProfiles.byLevel(difficulty);
    final canCloseHand = teamRoundWins > 0;
    final mustSaveHand = opponentRoundWins > 0;
    final readsOpponentSignals = profile.readsOpponentSignals;

    if (readsOpponentSignals && opponentHasStrongSignal && !canCloseHand) {
      return false;
    }
    if (mustSaveHand && teamScore < _threshold(profile, 95)) {
      return false;
    }

    final hasTableInformation = cardsOnTable >= 2;
    final hasSomeTableInformation = cardsOnTable > 0;
    final startsRound = cardsOnTable == 0;
    final plansVeryStrongLead = startsRound && ownMaxStrength >= 112;

    if (teamHasStrongSignal) {
      return hasSomeTableInformation ||
          canCloseHand ||
          teamScore >= _threshold(profile, 130);
    }

    if (plansVeryStrongLead && teamScore >= _threshold(profile, 132)) {
      return true;
    }

    if (startsRound && !canCloseHand) {
      return teamScore >= _threshold(profile, 165);
    }

    final tableDiscount = hasTableInformation ? 14 : 6;
    if (canCloseHand && teamScore >= _threshold(profile, 94) - tableDiscount) {
      return true;
    }
    if (isCompanion &&
        hasSomeTableInformation &&
        teamScore >= _threshold(profile, 122) - tableDiscount) {
      return true;
    }
    if (needsPoints &&
        hasSomeTableInformation &&
        teamScore >= _threshold(profile, 132) - tableDiscount) {
      return true;
    }

    return teamScore >= _threshold(profile, 145) - tableDiscount;
  }

  static int _threshold(DifficultyProfile profile, int base) {
    return base + profile.callThresholdModifier;
  }
}
