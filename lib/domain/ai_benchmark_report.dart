import 'ai_match_simulator.dart';

class AiBenchmarkScenario {
  final String label;
  final int teamOneDifficulty;
  final int teamTwoDifficulty;

  const AiBenchmarkScenario({
    required this.label,
    required this.teamOneDifficulty,
    required this.teamTwoDifficulty,
  });
}

class AiBenchmarkResult {
  final AiBenchmarkScenario scenario;
  final AiSimulationSummary summary;

  const AiBenchmarkResult({
    required this.scenario,
    required this.summary,
  });

  String formatLine() {
    return [
      scenario.label,
      'partidas=${summary.playedMatches}',
      'eq1=${summary.teamOneWins} (${_percent(summary.teamOneWinRate)})',
      'eq2=${summary.teamTwoWins} (${_percent(summary.teamTwoWinRate)})',
      'marcadorMedio=${summary.averageFinalScoreTeamOne.toStringAsFixed(1)}-${summary.averageFinalScoreTeamTwo.toStringAsFixed(1)}',
      'manosMedias=${summary.averageHandsPerMatch.toStringAsFixed(1)}',
      'rondasMedias=${summary.averageRoundsPerMatch.toStringAsFixed(1)}',
      'trucos=${summary.totalTrucoCalls}',
      'subidas=${summary.totalTrucoRaises}',
      'aceptados=${summary.totalTrucoAccepts}',
      'rechazados=${summary.totalTrucoPasses}',
      'rechazo=${_percent(summary.trucoPassRate)}',
      'subida=${_percent(summary.trucoRaiseRate)}',
      'alVerJuega=${summary.totalAlVerPlayed}',
      'alVerCasa=${summary.totalAlVerConceded}',
      'senas=${summary.totalSignalsGiven}/${summary.totalSignalOpportunities}',
      'senasFuertes=${summary.totalStrongSignalsGiven}',
      'voyATi=${summary.totalVoyATiRequests}',
      'venAMi=${summary.totalVenAMiOrders}',
      'venProtege=${_percent(summary.venAMiProtectionRate)}',
    ].join(' | ');
  }

  static String _percent(double value) =>
      '${(value * 100).toStringAsFixed(1)}%';
}

class AiBenchmarkReport {
  final List<AiBenchmarkResult> results;

  const AiBenchmarkReport({required this.results});

  List<String> formatLines() {
    return [
      for (final result in results) result.formatLine(),
    ];
  }
}

class AiBenchmarkRunner {
  final AiMatchSimulator simulator;

  const AiBenchmarkRunner({this.simulator = const AiMatchSimulator()});

  AiBenchmarkReport run({
    required List<AiBenchmarkScenario> scenarios,
    required List<int> seeds,
    int matchesPerSeed = 50,
    int maxHandsPerMatch = 60,
  }) {
    final results = <AiBenchmarkResult>[];
    for (final scenario in scenarios) {
      final config = AiSimulationConfig(
        matches: seeds.length * matchesPerSeed,
        seed: seeds.first,
        teamOneDifficulty: scenario.teamOneDifficulty,
        teamTwoDifficulty: scenario.teamTwoDifficulty,
        maxHandsPerMatch: maxHandsPerMatch,
      );
      final summary = AiSimulationSummary.combine(
        config,
        [
          for (final seed in seeds)
            simulator.run(
              AiSimulationConfig(
                matches: matchesPerSeed,
                seed: seed,
                teamOneDifficulty: scenario.teamOneDifficulty,
                teamTwoDifficulty: scenario.teamTwoDifficulty,
                maxHandsPerMatch: maxHandsPerMatch,
              ),
            ),
        ],
      );
      results.add(AiBenchmarkResult(scenario: scenario, summary: summary));
    }
    return AiBenchmarkReport(results: results);
  }
}
