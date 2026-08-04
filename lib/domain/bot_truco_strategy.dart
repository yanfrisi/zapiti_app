import 'difficulty_profile.dart';
import 'spanish_card.dart';
import 'zapiti_rules.dart';

class BotTrucoStrategy {
  const BotTrucoStrategy._();

  static bool shouldCall({
    required int difficulty,
    required int teamScore,
    required int ownMaxStrength,
    double handStrength = 0.70,
    required int cardsOnTable,
    required int teamRoundWins,
    required int opponentRoundWins,
    required bool teamHasStrongSignal,
    required bool opponentHasStrongSignal,
    required bool isCompanion,
    required bool needsPoints,
    int scoreGap = 0,
    bool opponentsSpentPower = false,
    bool teamSpentPower = false,
  }) {
    final profile = DifficultyProfiles.byLevel(difficulty);
    final canCloseHand = teamRoundWins > 0;
    final mustSaveHand = opponentRoundWins > 0;
    final readsOpponentSignals = profile.readsOpponentSignals;
    final startsRound = cardsOnTable == 0;
    final hasSomeTableInformation = cardsOnTable > 0;
    final hasTableInformation = cardsOnTable >= 2;
    final plansVeryStrongLead = startsRound && ownMaxStrength >= 112;
    final plansStrongLead = startsRound && ownMaxStrength >= 97;

    if (handStrength < 0.40) return false;
    if (readsOpponentSignals && opponentHasStrongSignal && !canCloseHand) {
      return false;
    }
    if (mustSaveHand &&
        handStrength < 0.65 &&
        teamScore < _threshold(profile, 95)) {
      return false;
    }
    if (startsRound &&
        !teamHasStrongSignal &&
        !plansVeryStrongLead &&
        handStrength < 0.84) {
      return false;
    }
    if (startsRound &&
        profile.level >= 4 &&
        !teamHasStrongSignal &&
        !plansStrongLead &&
        handStrength < 0.90) {
      return false;
    }
    if (scoreGap >= 6 &&
        startsRound &&
        !teamHasStrongSignal &&
        !plansVeryStrongLead) {
      return false;
    }

    if (teamHasStrongSignal) {
      return handStrength >= 0.50 ||
          hasSomeTableInformation ||
          canCloseHand ||
          teamScore >= _threshold(profile, 130);
    }

    if (plansVeryStrongLead &&
        handStrength >= 0.75 &&
        teamScore >= _threshold(profile, 132)) {
      return true;
    }

    if (startsRound && !canCloseHand) {
      return handStrength >= 0.80 && teamScore >= _threshold(profile, 165);
    }

    final tableDiscount = hasTableInformation ? 14 : 6;
    final pressureBonus = needsPoints || scoreGap <= -6 ? 6 : 0;
    final drainedBonus = opponentsSpentPower ? 14 : 0;
    final spentPenalty = teamSpentPower && !opponentsSpentPower ? 8 : 0;
    if (canCloseHand &&
        handStrength >= 0.55 &&
        teamScore >=
            _threshold(profile, 94) - tableDiscount - pressureBonus) {
      return true;
    }
    if (isCompanion &&
        hasSomeTableInformation &&
        handStrength >= 0.65 &&
        teamScore >=
            _threshold(profile, 122) - tableDiscount - pressureBonus) {
      return true;
    }
    if (needsPoints &&
        hasSomeTableInformation &&
        handStrength >= 0.65 &&
        teamScore >=
            _threshold(profile, 132) - tableDiscount - pressureBonus) {
      return true;
    }

    return handStrength >= 0.65 &&
        teamScore >=
            _threshold(profile, 145) -
                tableDiscount -
                pressureBonus -
                drainedBonus +
                spentPenalty;
  }

  static bool shouldCallWithRoll({
    required int difficulty,
    required double roll,
    required int teamScore,
    required int ownMaxStrength,
    double handStrength = 0.70,
    required int cardsOnTable,
    required int teamRoundWins,
    required int opponentRoundWins,
    required bool teamHasStrongSignal,
    required bool opponentHasStrongSignal,
    required bool isCompanion,
    required bool needsPoints,
    int scoreGap = 0,
    bool opponentsSpentPower = false,
    bool teamSpentPower = false,
  }) {
    if (!shouldCall(
      difficulty: difficulty,
      teamScore: teamScore,
      ownMaxStrength: ownMaxStrength,
      handStrength: handStrength,
      cardsOnTable: cardsOnTable,
      teamRoundWins: teamRoundWins,
      opponentRoundWins: opponentRoundWins,
      teamHasStrongSignal: teamHasStrongSignal,
      opponentHasStrongSignal: opponentHasStrongSignal,
      isCompanion: isCompanion,
      needsPoints: needsPoints,
      scoreGap: scoreGap,
      opponentsSpentPower: opponentsSpentPower,
      teamSpentPower: teamSpentPower,
    )) {
      return false;
    }

    final profile = DifficultyProfiles.byLevel(difficulty);
    final chance = callChance(
      profile,
      handStrength: handStrength,
      teamScore: teamScore,
      ownMaxStrength: ownMaxStrength,
      cardsOnTable: cardsOnTable,
      teamRoundWins: teamRoundWins,
      needsPoints: needsPoints,
      teamHasStrongSignal: teamHasStrongSignal,
      isCompanion: isCompanion,
      scoreGap: scoreGap,
      opponentsSpentPower: opponentsSpentPower,
      teamSpentPower: teamSpentPower,
    );
    return roll < chance;
  }

  static double callChance(
    DifficultyProfile profile, {
    required double handStrength,
    required int teamScore,
    required int ownMaxStrength,
    required int cardsOnTable,
    required int teamRoundWins,
    required bool needsPoints,
    required bool teamHasStrongSignal,
    required bool isCompanion,
    required int scoreGap,
    required bool opponentsSpentPower,
    required bool teamSpentPower,
  }) {
    var chance = switch (profile.level) {
      <= 2 => switch (handStrength) {
          < 0.40 => 0.005,
          < 0.65 => 0.025,
          < 0.80 => 0.09,
          _ => 0.16,
        },
      3 => switch (handStrength) {
          < 0.40 => 0.01,
          < 0.65 => 0.045,
          < 0.80 => 0.135,
          _ => 0.24,
        },
      _ => switch (handStrength) {
          < 0.40 => 0.015,
          < 0.65 => 0.07,
          < 0.80 => 0.22,
          _ => 0.36,
        },
    };

    if (cardsOnTable > 0) chance += 0.01;
    if (cardsOnTable >= 2) chance += 0.01;
    if (teamRoundWins > 0) chance += 0.02;
    if (teamHasStrongSignal) chance += 0.025;
    if (needsPoints) chance += 0.015;
    if (ownMaxStrength >= 97) chance += 0.015;
    if (teamScore >= 140) chance += 0.01;
    if (scoreGap <= -6) chance += 0.025;
    if (scoreGap >= 6) chance -= 0.03;
    if (opponentsSpentPower) chance += 0.03;
    if (teamSpentPower && !opponentsSpentPower) chance -= 0.03;
    if (isCompanion) chance -= 0.02;

    return chance.clamp(0, 0.48);
  }

  static double evaluateHandStrength(Iterable<SpanishCard> hand) {
    final strengths = hand.map(ZapitiRules.strength).toList()..sort();
    if (strengths.isEmpty) return 0;

    final strongest = strengths.last / 100;
    final second =
        strengths.length > 1 ? strengths[strengths.length - 2] / 100 : 0;
    final third =
        strengths.length > 2 ? strengths[strengths.length - 3] / 100 : 0;
    return (strongest * 0.55 + second * 0.30 + third * 0.15).clamp(0, 1);
  }

  static int _threshold(DifficultyProfile profile, int base) {
    return base + profile.callThresholdModifier;
  }
}
