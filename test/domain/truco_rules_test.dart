import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/truco_rules.dart';

void main() {
  group('TrucoRules', () {
    test('usa Ahorrisi como techo oficial de la escalera', () {
      final maxValue = TrucoRules.maxAllowedValue(
        scoreTeamOne: 21,
        scoreTeamTwo: 26,
        targetScore: 30,
        currentAcceptedValue: 3,
      );

      expect(maxValue, 18);
    });

    test('el marcador no recorta el techo oficial de apuesta', () {
      final maxValue = TrucoRules.maxAllowedValue(
        scoreTeamOne: 19,
        scoreTeamTwo: 27,
        targetScore: 30,
        currentAcceptedValue: 1,
      );

      expect(maxValue, 18);
    });

    test('el limite por equipo no inventa escalones por marcador', () {
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

      expect(teamWithMargin, 18);
      expect(teamNearEnd, 18);
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

    test('no ajusta una subida a valores fuera de la escalera oficial', () {
      final options = TrucoRules.raiseOptions(
        pendingValue: 3,
        maxAllowedValue: 5,
      );

      expect(options, isEmpty);
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
