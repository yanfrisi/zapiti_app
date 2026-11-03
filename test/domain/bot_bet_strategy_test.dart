import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bot_bet_strategy.dart';

void main() {
  group('BotBetStrategy', () {
    test('normal y hard apuestan en una posicion claramente favorable', () {
      final easy = BotBetStrategy.chooseBetValue(
        difficulty: 2,
        nextValue: 3,
        maxAllowedValue: 18,
        strengths: const [100, 90, 80],
        teamScore: 150,
        ownMaxStrength: 100,
        handStrength: 0.92,
        cardsOnTable: 0,
        teamRoundWins: 1,
        opponentRoundWins: 1,
        teamHasStrongSignal: false,
        opponentHasStrongSignal: false,
        isCompanion: false,
        needsPoints: false,
        scoreGap: 0,
        opponentsSpentPower: false,
        teamSpentPower: false,
        isWinningReparto: false,
        canCloseHand: true,
        mustSaveHand: true,
        sawOpponentStrongSignal: false,
        roll: 0.21,
      );
      final normal = BotBetStrategy.chooseBetValue(
        difficulty: 3,
        nextValue: 3,
        maxAllowedValue: 18,
        strengths: const [100, 90, 80],
        teamScore: 150,
        ownMaxStrength: 100,
        handStrength: 0.92,
        cardsOnTable: 0,
        teamRoundWins: 1,
        opponentRoundWins: 1,
        teamHasStrongSignal: false,
        opponentHasStrongSignal: false,
        isCompanion: false,
        needsPoints: false,
        scoreGap: 0,
        opponentsSpentPower: false,
        teamSpentPower: false,
        isWinningReparto: false,
        canCloseHand: true,
        mustSaveHand: true,
        sawOpponentStrongSignal: false,
        roll: 0.21,
      );
      final hard = BotBetStrategy.chooseBetValue(
        difficulty: 4,
        nextValue: 3,
        maxAllowedValue: 18,
        strengths: const [100, 90, 80],
        teamScore: 150,
        ownMaxStrength: 100,
        handStrength: 0.92,
        cardsOnTable: 0,
        teamRoundWins: 1,
        opponentRoundWins: 1,
        teamHasStrongSignal: false,
        opponentHasStrongSignal: false,
        isCompanion: false,
        needsPoints: false,
        scoreGap: 0,
        opponentsSpentPower: false,
        teamSpentPower: false,
        isWinningReparto: false,
        canCloseHand: true,
        mustSaveHand: true,
        sawOpponentStrongSignal: false,
        roll: 0.21,
      );

      expect(easy, isNull);
      expect(normal, 3);
      expect(hard, 3);
    });

    test('tener Zapiti por si solo no fuerza Truco en contexto desfavorable', () {
      final chosen = BotBetStrategy.chooseBetValue(
        difficulty: 4,
        nextValue: 3,
        maxAllowedValue: 18,
        strengths: const [100, 10, 5],
        teamScore: 95,
        ownMaxStrength: 100,
        handStrength: 0.48,
        cardsOnTable: 0,
        teamRoundWins: 0,
        opponentRoundWins: 0,
        teamHasStrongSignal: false,
        opponentHasStrongSignal: false,
        isCompanion: false,
        needsPoints: false,
        scoreGap: 0,
        opponentsSpentPower: false,
        teamSpentPower: false,
        isWinningReparto: false,
        canCloseHand: false,
        mustSaveHand: false,
        sawOpponentStrongSignal: false,
        roll: 0,
      );

      expect(chosen, isNull);
    });

    test('si el siguiente escalon legal es Seis evalua Seis y no Truco', () {
      final chosen = BotBetStrategy.chooseBetValue(
        difficulty: 4,
        nextValue: 6,
        maxAllowedValue: 18,
        strengths: const [100, 90, 80],
        teamScore: 170,
        ownMaxStrength: 100,
        handStrength: 0.91,
        cardsOnTable: 0,
        teamRoundWins: 1,
        opponentRoundWins: 1,
        teamHasStrongSignal: false,
        opponentHasStrongSignal: false,
        isCompanion: false,
        needsPoints: false,
        scoreGap: 0,
        opponentsSpentPower: false,
        teamSpentPower: false,
        isWinningReparto: false,
        canCloseHand: true,
        mustSaveHand: true,
        sawOpponentStrongSignal: false,
        roll: 0,
      );

      expect(chosen, 6);
    });
  });
}
