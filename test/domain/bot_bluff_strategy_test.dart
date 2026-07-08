import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bot_bluff_strategy.dart';

void main() {
  group('BotBluffStrategy', () {
    test('puede cantar farol con presion y mano media-baja', () {
      final shouldBluff = BotBluffStrategy.shouldBluffCall(
        difficulty: 3,
        roll: 0.02,
        teamScore: 96,
        ownMaxStrength: 70,
        cardsOnTable: 1,
        teamRoundWins: 0,
        opponentRoundWins: 0,
        teamHasStrongSignal: false,
        opponentHasStrongSignal: false,
        needsPoints: true,
      );

      expect(shouldBluff, isTrue);
    });

    test('no farolea si realmente tiene senya o carta fuerte', () {
      final withStrongSignal = BotBluffStrategy.shouldBluffCall(
        difficulty: 3,
        roll: 0,
        teamScore: 96,
        ownMaxStrength: 70,
        cardsOnTable: 1,
        teamRoundWins: 0,
        opponentRoundWins: 0,
        teamHasStrongSignal: true,
        opponentHasStrongSignal: false,
        needsPoints: true,
      );
      final withStrongCard = BotBluffStrategy.shouldBluffCall(
        difficulty: 3,
        roll: 0,
        teamScore: 96,
        ownMaxStrength: 95,
        cardsOnTable: 1,
        teamRoundWins: 0,
        opponentRoundWins: 0,
        teamHasStrongSignal: false,
        opponentHasStrongSignal: false,
        needsPoints: true,
      );

      expect(withStrongSignal, isFalse);
      expect(withStrongCard, isFalse);
    });

    test('no farolea en nivel alto si vio senya fuerte rival', () {
      final shouldBluff = BotBluffStrategy.shouldBluffCall(
        difficulty: 4,
        roll: 0,
        teamScore: 92,
        ownMaxStrength: 70,
        cardsOnTable: 2,
        teamRoundWins: 0,
        opponentRoundWins: 0,
        teamHasStrongSignal: false,
        opponentHasStrongSignal: true,
        needsPoints: true,
      );

      expect(shouldBluff, isFalse);
    });

    test('puede subir de farol solo valores moderados', () {
      final raiseValue = BotBluffStrategy.bluffRaiseValue(
        difficulty: 3,
        roll: 0.01,
        pendingValue: 3,
        maxAllowedValue: 8,
        teamScore: 98,
        hasStrongSignal: false,
        sawOpponentStrongSignal: false,
        needsPoints: true,
        isWinningReparto: false,
      );
      final tooHigh = BotBluffStrategy.bluffRaiseValue(
        difficulty: 3,
        roll: 0,
        pendingValue: 6,
        maxAllowedValue: 8,
        teamScore: 98,
        hasStrongSignal: false,
        sawOpponentStrongSignal: false,
        needsPoints: true,
        isWinningReparto: false,
      );

      expect(raiseValue, 6);
      expect(tooHigh, isNull);
    });
  });
}
