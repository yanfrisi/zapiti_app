import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bot_truco_raise_strategy.dart';

void main() {
  group('BotTrucoRaiseStrategy', () {
    test('el companero puede contra-subir un truco rival si tiene carta alta',
        () {
      final raiseValue = BotTrucoRaiseStrategy.chooseRaiseValue(
        difficulty: 3,
        pendingValue: 3,
        maxAllowedValue: 8,
        strengths: const [100, 60, 10],
        teamScore: 133,
        hasStrongSignal: false,
        isWinningReparto: false,
        sawOpponentStrongSignal: false,
        isCompanionProtectingHuman: true,
      );

      expect(raiseValue, 6);
    });

    test('el companero no secuestra la respuesta humana con mano floja', () {
      final raiseValue = BotTrucoRaiseStrategy.chooseRaiseValue(
        difficulty: 3,
        pendingValue: 3,
        maxAllowedValue: 8,
        strengths: const [60, 10, 10],
        teamScore: 68,
        hasStrongSignal: false,
        isWinningReparto: false,
        sawOpponentStrongSignal: false,
        isCompanionProtectingHuman: true,
      );

      expect(raiseValue, isNull);
    });

    test('si lee senya rival fuerte no contra-sube en dificultad alta', () {
      final raiseValue = BotTrucoRaiseStrategy.chooseRaiseValue(
        difficulty: 4,
        pendingValue: 3,
        maxAllowedValue: 8,
        strengths: const [100, 90, 60],
        teamScore: 165,
        hasStrongSignal: false,
        isWinningReparto: false,
        sawOpponentStrongSignal: true,
        isCompanionProtectingHuman: true,
      );

      expect(raiseValue, isNull);
    });

    test('una senya fuerte propia contra-sube al siguiente escalon legal', () {
      final raiseValue = BotTrucoRaiseStrategy.chooseRaiseValue(
        difficulty: 3,
        pendingValue: 3,
        maxAllowedValue: 8,
        strengths: const [80, 60, 10],
        teamScore: 120,
        hasStrongSignal: true,
        isWinningReparto: false,
        sawOpponentStrongSignal: false,
      );

      expect(raiseValue, 6);
    });
  });
}
