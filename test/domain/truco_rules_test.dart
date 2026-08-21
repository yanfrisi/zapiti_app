import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/truco_rules.dart';

void main() {
  group('TrucoRules', () {
    test('usa Ahorrisi como techo oficial de la escalera con marcador normal',
        () {
      final maxValue = TrucoRules.maxAllowedValue(
        scoreTeamOne: 21,
        scoreTeamTwo: 26,
        targetScore: 30,
        currentAcceptedValue: 3,
      );

      expect(maxValue, 18);
    });

    test(
        'el tope global sigue siendo Ahorrisi si el otro equipo todavia tiene margen',
        () {
      final maxValue = TrucoRules.maxAllowedValue(
        scoreTeamOne: 19,
        scoreTeamTwo: 27,
        targetScore: 30,
        currentAcceptedValue: 1,
      );

      expect(maxValue, 18);
    });

    test('a 27 y 28 se permite truco pero se bloquean subidas mayores', () {
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

      final teamAt28 = TrucoRules.maxAllowedValueForTeam(
        teamScore: 28,
        targetScore: 30,
        currentAcceptedValue: 1,
      );

      expect(teamWithMargin, 18);
      expect(teamNearEnd, 3);
      expect(teamAt28, 3);
    });

    test('a 29 ya no hay truco legal para ese equipo', () {
      final teamAt29 = TrucoRules.maxAllowedValueForTeam(
        teamScore: 29,
        targetScore: 30,
        currentAcceptedValue: 1,
      );

      expect(teamAt29, 0);
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

    test('al resolver truco cerca de 30 solo se cobra hasta 29', () {
      expect(
        TrucoRules.awardedPointsForTeam(
          teamScore: 27,
          targetScore: 30,
          nominalValue: 3,
        ),
        2,
      );
      expect(
        TrucoRules.awardedPointsForTeam(
          teamScore: 28,
          targetScore: 30,
          nominalValue: 3,
        ),
        1,
      );
      expect(
        TrucoRules.awardedPointsForTeam(
          teamScore: 10,
          targetScore: 30,
          nominalValue: 6,
        ),
        6,
      );
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
