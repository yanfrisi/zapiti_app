import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/ai_match_simulator.dart';

void main() {
  test('torneo IA smoke con tiempos de decision', () {
    const simulator = AiMatchSimulator();
    const scenarios = [
      ('Normal vs Easy', 3, 1),
      ('Hard vs Normal', 4, 3),
      ('Expert vs Hard', 5, 4),
    ];

    for (final scenario in scenarios) {
      final forward = simulator.run(
        AiSimulationConfig(
          matches: 2,
          seed: 20260809,
          targetScore: 1,
          teamOneDifficulty: scenario.$2,
          teamTwoDifficulty: scenario.$3,
          maxHandsPerMatch: 3,
        ),
      );
      final reverse = simulator.run(
        AiSimulationConfig(
          matches: 2,
          seed: 20260819,
          targetScore: 1,
          teamOneDifficulty: scenario.$3,
          teamTwoDifficulty: scenario.$2,
          maxHandsPerMatch: 3,
        ),
      );
      final summary = AiSimulationSummary.combine(
        forward.config,
        [forward, reverse],
      );
      final strongerWins = forward.teamOneWins + reverse.teamTwoWins;
      final weakerWins = forward.teamTwoWins + reverse.teamOneWins;
      final played = strongerWins + weakerWins;
      final strongerWinRate = played == 0 ? 0 : strongerWins / played;
      // ignore: avoid_print
      print(
        '${scenario.$1}: strongerWinRate='
        '${strongerWinRate.toStringAsFixed(2)} '
        'strongerWins=$strongerWins weakerWins=$weakerWins '
        'avgDecisionMs='
        '${(summary.averageDecisionMicros / 1000).toStringAsFixed(2)} '
        'p95Ms=${(summary.p95DecisionMicros / 1000).toStringAsFixed(2)}',
      );
      expect(summary.decisionMicros, isNotEmpty);
    }
  });
}
