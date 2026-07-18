import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/ai_match_simulator.dart';

void main() {
  group('AiMatchSimulator', () {
    const simulator = AiMatchSimulator();

    test('simula partidas completas y recoge metricas de balance', () {
      final summary = simulator.run(
        const AiSimulationConfig(matches: 20, seed: 42, difficulty: 3),
      );

      expect(summary.playedMatches, 20);
      expect(summary.teamOneWins + summary.teamTwoWins, 20);
      expect(summary.totalHands, greaterThanOrEqualTo(20));
      expect(summary.totalRounds, greaterThan(0));
      expect(summary.averageHandsPerMatch, greaterThan(1));
      expect(summary.trucoPassRate, inInclusiveRange(0, 1));
      expect(summary.trucoRaiseRate, inInclusiveRange(0, 1));
      expect(summary.averageFinalScoreTeamOne, greaterThan(0));
      expect(summary.averageFinalScoreTeamTwo, greaterThan(0));
    });

    test('misma semilla produce el mismo resumen', () {
      const config = AiSimulationConfig(matches: 12, seed: 7, difficulty: 4);

      final first = simulator.run(config);
      final second = simulator.run(config);

      expect(second.teamOneWins, first.teamOneWins);
      expect(second.teamTwoWins, first.teamTwoWins);
      expect(second.totalHands, first.totalHands);
      expect(second.totalRounds, first.totalRounds);
      expect(second.totalTrucoCalls, first.totalTrucoCalls);
      expect(second.totalTrucoRaises, first.totalTrucoRaises);
      expect(second.totalTrucoAccepts, first.totalTrucoAccepts);
      expect(second.totalTrucoPasses, first.totalTrucoPasses);
      expect(second.totalAlVerPlayed, first.totalAlVerPlayed);
      expect(second.totalAlVerConceded, first.totalAlVerConceded);
      expect(second.totalTeamOneScore, first.totalTeamOneScore);
      expect(second.totalTeamTwoScore, first.totalTeamTwoScore);
    });

    test('combina resumenes de varias tandas', () {
      const config = AiSimulationConfig(matches: 20, seed: 1, difficulty: 3);
      final first = simulator.run(
        const AiSimulationConfig(matches: 10, seed: 1, difficulty: 3),
      );
      final second = simulator.run(
        const AiSimulationConfig(matches: 10, seed: 11, difficulty: 3),
      );

      final combined = AiSimulationSummary.combine(config, [first, second]);

      expect(
          combined.playedMatches, first.playedMatches + second.playedMatches);
      expect(combined.totalHands, first.totalHands + second.totalHands);
      expect(combined.totalRounds, first.totalRounds + second.totalRounds);
      expect(
        combined.totalTrucoCalls,
        first.totalTrucoCalls + second.totalTrucoCalls,
      );
    });

    test('permite comparar dificultades entre parejas', () {
      final summary = simulator.run(
        const AiSimulationConfig(
          matches: 30,
          seed: 11,
          teamOneDifficulty: 5,
          teamTwoDifficulty: 1,
        ),
      );

      expect(summary.playedMatches, 30);
      expect(summary.totalTrucoCalls, greaterThan(0));
      expect(summary.teamOneWinRate, greaterThan(0.35));
    });

    test('permite fijar el asiento inicial para reproducir partidas', () {
      const config = AiSimulationConfig(
        matches: 8,
        seed: 23,
        difficulty: 3,
        rotateStartingPlayerPerMatch: false,
      );

      final first = simulator.run(config);
      final second = simulator.run(config);

      expect(second.teamOneWins, first.teamOneWins);
      expect(second.teamTwoWins, first.teamTwoWins);
      expect(second.totalHands, first.totalHands);
    });
  });
}
