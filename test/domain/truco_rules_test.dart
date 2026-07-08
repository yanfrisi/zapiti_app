import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/truco_rules.dart';

void main() {
  group('TrucoRules', () {
    test('limita la subida para no llegar al objetivo de partida', () {
      final maxValue = TrucoRules.maxAllowedValue(
        scoreTeamOne: 21,
        scoreTeamTwo: 26,
        targetScore: 30,
        currentAcceptedValue: 3,
      );

      expect(maxValue, 3);
    });

    test('permite el truco base aunque un equipo este a 27', () {
      final maxValue = TrucoRules.maxAllowedValue(
        scoreTeamOne: 19,
        scoreTeamTwo: 27,
        targetScore: 30,
        currentAcceptedValue: 1,
      );

      expect(maxValue, 3);
    });

    test('el limite por equipo bloquea abrir truco si ya esta a 27', () {
      final teamWithMargin = TrucoRules.maxAllowedValueForTeam(
        teamScore: 19,
        targetScore: 30,
        currentAcceptedValue: 1,
      );
      final teamNearEnd = TrucoRules.maxAllowedValueForTeam(
        teamScore: 27,
        targetScore: 30,
        currentAcceptedValue: 1,
      );

      expect(teamWithMargin, greaterThanOrEqualTo(3));
      expect(teamNearEnd, lessThan(3));
    });

    test('no ofrece subida si el final de partida solo permite truco base', () {
      final options = TrucoRules.raiseOptions(
        pendingValue: 3,
        maxAllowedValue: 3,
      );

      expect(options, isEmpty);
    });

    test('ofrece solo el siguiente nivel de subida', () {
      final options = TrucoRules.raiseOptions(
        pendingValue: 3,
        maxAllowedValue: 12,
      );

      expect(options, [6]);
    });

    test('rechaza contra-subidas que no caen en escalones de tres', () {
      expect(
        TrucoRules.isRaiseValue(
          currentAcceptedValue: 3,
          value: 5,
          maxAllowedValue: 12,
        ),
        isFalse,
      );
      expect(
        TrucoRules.isRaiseValue(
          currentAcceptedValue: 3,
          value: 9,
          maxAllowedValue: 12,
        ),
        isFalse,
      );
      expect(
        TrucoRules.isRaiseValue(
          currentAcceptedValue: 3,
          value: 6,
          maxAllowedValue: 12,
        ),
        isTrue,
      );
    });

    test('pasar una subida paga el valor previamente aceptado', () {
      final points = TrucoRules.passPoints(currentAcceptedValue: 6);

      expect(points, 6);
    });
  });
}
