import 'dart:math';
import 'dart:io';

import 'package:zapiti_app/domain/ai_match_simulator.dart';

void main(List<String> args) {
  final matches = args.isEmpty ? 12 : int.tryParse(args.first) ?? 12;
  const simulator = AiMatchSimulator();
  const scenarios = [
    ('Normal vs Easy', 3, 1),
    ('Hard vs Easy', 4, 1),
    ('Hard vs Normal', 4, 3),
    ('Expert vs Hard', 5, 4),
  ];

  for (final scenario in scenarios) {
    final forward = simulator.run(
      AiSimulationConfig(
        matches: matches,
        seed: 20260809,
        targetScore: 6,
        teamOneDifficulty: scenario.$2,
        teamTwoDifficulty: scenario.$3,
        maxHandsPerMatch: 12,
      ),
    );
    final reverse = simulator.run(
      AiSimulationConfig(
        matches: matches,
        seed: 20260809 + matches,
        targetScore: 6,
        teamOneDifficulty: scenario.$3,
        teamTwoDifficulty: scenario.$2,
        maxHandsPerMatch: 12,
      ),
    );
    final strongerWins = forward.teamOneWins + reverse.teamTwoWins;
    final weakerWins = forward.teamTwoWins + reverse.teamOneWins;
    final played = max(1, strongerWins + weakerWins);
    final combined = AiSimulationSummary.combine(
      forward.config,
      [forward, reverse],
    );
    final strongerRate = strongerWins / played;
    stdout.writeln(
      '${scenario.$1}: strongerWinRate=${_pct(strongerRate)} '
      'strongerWins=$strongerWins weakerWins=$weakerWins '
      'avgScore=${combined.averageFinalScoreTeamOne.toStringAsFixed(1)}/'
      '${combined.averageFinalScoreTeamTwo.toStringAsFixed(1)} '
      'decisionAvgMs=${_ms(combined.averageDecisionMicros)} '
      'p50Ms=${_ms(combined.p50DecisionMicros.toDouble())} '
      'p95Ms=${_ms(combined.p95DecisionMicros.toDouble())} '
      'p99Ms=${_ms(combined.p99DecisionMicros.toDouble())}',
    );
  }
}

String _pct(double value) => '${(value * 100).toStringAsFixed(1)}%';

String _ms(double micros) => (micros / 1000).toStringAsFixed(2);
