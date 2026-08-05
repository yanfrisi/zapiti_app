import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/difficulty_profile.dart';

void main() {
  group('DifficultyProfiles', () {
    test('mantiene cinco niveles ordenados y acotados', () {
      expect(DifficultyProfiles.values.keys, [1, 2, 3, 4, 5]);
      expect(DifficultyProfiles.byLevel(0).level, 1);
      expect(DifficultyProfiles.byLevel(6).level, 5);
    });

    test('reduce errores y endurece umbral de truco progresivamente', () {
      final profiles = [
        for (var level = 1; level <= 5; level++)
          DifficultyProfiles.byLevel(level),
      ];

      for (var index = 0; index < profiles.length - 1; index++) {
        expect(
          profiles[index].cardMistakeChance,
          greaterThanOrEqualTo(profiles[index + 1].cardMistakeChance),
        );
        expect(
          profiles[index].callThresholdModifier,
          lessThanOrEqualTo(profiles[index + 1].callThresholdModifier),
        );
      }
    });

    test('solo los niveles medios-altos leen senas rivales', () {
      expect(DifficultyProfiles.byLevel(1).readsOpponentSignals, isFalse);
      expect(DifficultyProfiles.byLevel(2).readsOpponentSignals, isFalse);
      expect(DifficultyProfiles.byLevel(3).readsOpponentSignals, isTrue);
      expect(DifficultyProfiles.byLevel(5).allowsPerfectCardPlay, isTrue);
    });

    test('acelera y elimina senas rivales en experto', () {
      expect(DifficultyProfiles.byLevel(1).rivalsGiveSignals, isTrue);
      expect(
        DifficultyProfiles.byLevel(1).rivalSignalRevealMilliseconds,
        greaterThan(DifficultyProfiles.byLevel(4).rivalSignalRevealMilliseconds),
      );
      expect(DifficultyProfiles.byLevel(5).rivalsGiveSignals, isFalse);
      expect(DifficultyProfiles.byLevel(5).rivalSignalRevealMilliseconds, 0);
    });
  });
}
