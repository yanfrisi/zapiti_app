import 'bot_truco_raise_strategy.dart';
import 'bot_truco_strategy.dart';
import 'truco_rules.dart';

class BotBetStrategy {
  const BotBetStrategy._();

  static int? chooseBetValue({
    required int difficulty,
    required int nextValue,
    required int maxAllowedValue,
    required Iterable<int> strengths,
    required int teamScore,
    required int ownMaxStrength,
    required double handStrength,
    required int cardsOnTable,
    required int teamRoundWins,
    required int opponentRoundWins,
    required bool teamHasStrongSignal,
    required bool opponentHasStrongSignal,
    required bool isCompanion,
    required bool needsPoints,
    required int scoreGap,
    required bool opponentsSpentPower,
    required bool teamSpentPower,
    required bool isWinningReparto,
    required bool canCloseHand,
    required bool mustSaveHand,
    required bool sawOpponentStrongSignal,
    required double roll,
  }) {
    if (nextValue == TrucoRules.firstTrucoValue) {
      return BotTrucoStrategy.shouldCallWithRoll(
        difficulty: difficulty,
        roll: roll,
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
      )
          ? nextValue
          : null;
    }

    final pendingValue = nextValue - TrucoRules.raiseStep;
    if (pendingValue < TrucoRules.firstTrucoValue) return null;
    return BotTrucoRaiseStrategy.chooseRaiseValue(
      difficulty: difficulty,
      pendingValue: pendingValue,
      maxAllowedValue: maxAllowedValue,
      strengths: strengths,
      teamScore: teamScore,
      hasStrongSignal: teamHasStrongSignal,
      isWinningReparto: isWinningReparto,
      sawOpponentStrongSignal: sawOpponentStrongSignal,
      canCloseHand: canCloseHand,
      mustSaveHand: mustSaveHand,
      needsPoints: needsPoints,
      scoreGap: scoreGap,
      roll: roll,
    );
  }
}
