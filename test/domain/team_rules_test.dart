import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/team_rules.dart';

void main() {
  group('TeamRules', () {
    test('devuelve el equipo rival', () {
      expect(TeamRules.opponentOf(1), 2);
      expect(TeamRules.opponentOf(2), 1);
    });

    test('rechaza equipos desconocidos', () {
      expect(() => TeamRules.opponentOf(3), throwsArgumentError);
    });
  });
}
