import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bot_truco_response_strategy.dart';

void main() {
  group('BotTrucoResponseStrategy', () {
    test('rechaza un truco alto con mano floja y sin cierre', () {
      final accepts = BotTrucoResponseStrategy.shouldAccept(
        difficulty: 5,
        pendingValue: 6,
        maxAllowedValue: 9,
        teamScoreEstimate: 84,
        handStrength: 0.46,
        cardsOnTable: 0,
        canCloseHand: false,
        mustSaveHand: false,
        hasStrongSignal: false,
        opponentHasStrongSignal: false,
        needsPoints: false,
        scoreGap: 0,
        currentRoundUnsavable: false,
      );

      expect(accepts, isFalse);
    });

    test('acepta con mano fuerte cuando puede cerrar el reparto', () {
      final accepts = BotTrucoResponseStrategy.shouldAccept(
        difficulty: 5,
        pendingValue: 6,
        maxAllowedValue: 9,
        teamScoreEstimate: 146,
        handStrength: 0.83,
        cardsOnTable: 2,
        canCloseHand: true,
        mustSaveHand: false,
        hasStrongSignal: true,
        opponentHasStrongSignal: false,
        needsPoints: false,
        scoreGap: 3,
        currentRoundUnsavable: false,
      );

      expect(accepts, isTrue);
    });

    test('si la ronda es insalvable rechaza aunque necesite puntos', () {
      final accepts = BotTrucoResponseStrategy.shouldAccept(
        difficulty: 4,
        pendingValue: 5,
        maxAllowedValue: 9,
        teamScoreEstimate: 140,
        handStrength: 0.78,
        cardsOnTable: 2,
        canCloseHand: false,
        mustSaveHand: true,
        hasStrongSignal: false,
        opponentHasStrongSignal: false,
        needsPoints: true,
        scoreGap: -8,
        currentRoundUnsavable: true,
      );

      expect(accepts, isFalse);
    });

    test('rechaza un seis con mano media si no cierra ni tiene senya', () {
      final accepts = BotTrucoResponseStrategy.shouldAccept(
        difficulty: 5,
        pendingValue: 6,
        maxAllowedValue: 9,
        teamScoreEstimate: 126,
        handStrength: 0.74,
        cardsOnTable: 1,
        canCloseHand: false,
        mustSaveHand: false,
        hasStrongSignal: false,
        opponentHasStrongSignal: false,
        needsPoints: false,
        scoreGap: 0,
        currentRoundUnsavable: false,
      );

      expect(accepts, isFalse);
    });

    test('acepta un seis con cierre y respaldo fuerte', () {
      final accepts = BotTrucoResponseStrategy.shouldAccept(
        difficulty: 5,
        pendingValue: 6,
        maxAllowedValue: 9,
        teamScoreEstimate: 150,
        handStrength: 0.86,
        cardsOnTable: 2,
        canCloseHand: true,
        mustSaveHand: false,
        hasStrongSignal: true,
        opponentHasStrongSignal: false,
        needsPoints: false,
        scoreGap: 2,
        currentRoundUnsavable: false,
      );

      expect(accepts, isTrue);
    });

    test('rechaza un ocho sin cierre ni necesidad aunque la mano sea decente', () {
      final accepts = BotTrucoResponseStrategy.shouldAccept(
        difficulty: 5,
        pendingValue: 8,
        maxAllowedValue: 9,
        teamScoreEstimate: 148,
        handStrength: 0.88,
        cardsOnTable: 2,
        canCloseHand: false,
        mustSaveHand: false,
        hasStrongSignal: false,
        opponentHasStrongSignal: false,
        needsPoints: false,
        scoreGap: 1,
        currentRoundUnsavable: false,
      );

      expect(accepts, isFalse);
    });

    test('acepta un ocho con cierre y mucha fuerza real', () {
      final accepts = BotTrucoResponseStrategy.shouldAccept(
        difficulty: 5,
        pendingValue: 8,
        maxAllowedValue: 9,
        teamScoreEstimate: 164,
        handStrength: 0.94,
        cardsOnTable: 2,
        canCloseHand: true,
        mustSaveHand: false,
        hasStrongSignal: true,
        opponentHasStrongSignal: false,
        needsPoints: false,
        scoreGap: 4,
        currentRoundUnsavable: false,
      );

      expect(accepts, isTrue);
    });
  });
}
