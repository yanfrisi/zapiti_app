import 'difficulty_profile.dart';

class BotTrucoResponseStrategy {
  const BotTrucoResponseStrategy._();

  static bool shouldAccept({
    required int difficulty,
    required int pendingValue,
    required int maxAllowedValue,
    required int teamScoreEstimate,
    required double handStrength,
    required int cardsOnTable,
    required bool canCloseHand,
    required bool mustSaveHand,
    required bool hasStrongSignal,
    required bool opponentHasStrongSignal,
    required bool needsPoints,
    required int scoreGap,
    required bool currentRoundUnsavable,
    double roll = 1,
  }) {
    if (pendingValue > maxAllowedValue || currentRoundUnsavable) return false;

    final profile = DifficultyProfiles.byLevel(difficulty);
    if (profile.impulsiveTrucoChance > 0 &&
        pendingValue <= 5 &&
        roll < profile.impulsiveTrucoChance * 0.45) {
      return true;
    }

    if (pendingValue >= 6 &&
        !canCloseHand &&
        !hasStrongSignal &&
        handStrength < 0.82) {
      return false;
    }
    if (pendingValue >= 8 &&
        !canCloseHand &&
        !hasStrongSignal &&
        handStrength < 0.90) {
      return false;
    }
    if (opponentHasStrongSignal &&
        pendingValue >= 6 &&
        !canCloseHand &&
        handStrength < 0.84) {
      return false;
    }
    if (pendingValue >= 8 &&
        !canCloseHand &&
        !mustSaveHand &&
        !needsPoints) {
      return false;
    }

    var confidence = handStrength * 100;
    confidence += switch (profile.level) {
      1 => -14,
      2 => -8,
      3 => 0,
      4 => 6,
      _ => 10,
    };

    if (canCloseHand) confidence += 12;
    if (mustSaveHand) confidence += pendingValue <= 5 ? 8 : 2;
    if (hasStrongSignal) confidence += 8;
    if (needsPoints) confidence += 6;
    if (cardsOnTable >= 2) {
      confidence += 4;
    } else if (cardsOnTable == 1) {
      confidence += 2;
    }
    if (teamScoreEstimate >= 140) {
      confidence += 8;
    } else if (teamScoreEstimate >= 120) {
      confidence += 4;
    }

    if (opponentHasStrongSignal) {
      confidence -= canCloseHand ? 4 : 12;
    }
    if (scoreGap >= 6) confidence -= 6;
    if (scoreGap <= -6) confidence += 4;
    if (teamScoreEstimate < 90 && pendingValue >= 6) confidence -= 8;
    if (pendingValue >= 6) confidence -= 5;
    if (pendingValue >= 8) confidence -= 7;
    if (!canCloseHand && pendingValue >= 6) confidence -= 4;
    if (!hasStrongSignal && pendingValue >= 8) confidence -= 4;

    final requiredConfidence = switch (pendingValue) {
      <= 3 => 46.0,
      <= 5 => 60.0,
      <= 6 => 76.0,
      <= 8 => 88.0,
      _ => 94.0,
    };

    return confidence >= requiredConfidence;
  }
}
