import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/ai_benchmark_report.dart';
import 'package:zapiti_app/domain/ai_match_simulator.dart';

void main() {
  test(
      'bateria alpha de IA profesional completa partidas y cubre eventos clave',
      () {
    const scenarios = [
      AiBenchmarkScenario(
        label: 'IA 3 vs IA 3',
        teamOneDifficulty: 3,
        teamTwoDifficulty: 3,
      ),
      AiBenchmarkScenario(
        label: 'IA 5 vs IA 5',
        teamOneDifficulty: 5,
        teamTwoDifficulty: 5,
      ),
      AiBenchmarkScenario(
        label: 'IA 5 vs IA 2',
        teamOneDifficulty: 5,
        teamTwoDifficulty: 2,
      ),
      AiBenchmarkScenario(
        label: 'IA 2 vs IA 5',
        teamOneDifficulty: 2,
        teamTwoDifficulty: 5,
      ),
      AiBenchmarkScenario(
        label: 'IA 4 vs IA 3',
        teamOneDifficulty: 4,
        teamTwoDifficulty: 3,
      ),
      AiBenchmarkScenario(
        label: 'IA 3 vs IA 4',
        teamOneDifficulty: 3,
        teamTwoDifficulty: 4,
      ),
      AiBenchmarkScenario(
        label: 'IA 5 vs IA 4',
        teamOneDifficulty: 5,
        teamTwoDifficulty: 4,
      ),
      AiBenchmarkScenario(
        label: 'IA 4 vs IA 5',
        teamOneDifficulty: 4,
        teamTwoDifficulty: 5,
      ),
    ];
    const seeds = [20260805, 20260806, 20260807, 20260808, 20260809];
    const matchesPerSeed = 20;
    final expectedMatches = seeds.length * matchesPerSeed;
    const runner = AiBenchmarkRunner(simulator: AiMatchSimulator());

    final report = runner.run(
      scenarios: scenarios,
      seeds: seeds,
      matchesPerSeed: matchesPerSeed,
      maxHandsPerMatch: 80,
    );

    var totalAlVerDecisions = 0;
    var totalSignalOpportunities = 0;
    var totalSignalsGiven = 0;
    var totalVoyATiRequests = 0;
    var totalVenAMiOrders = 0;
    var totalVenAMiProtectedRounds = 0;
    for (final result in report.results) {
      final summary = result.summary;
      // ignore: avoid_print
      print(result.formatLine());

      expect(
        summary.playedMatches,
        expectedMatches,
        reason: '${result.scenario.label} dejo partidas sin terminar',
      );
      expect(
        summary.averageHandsPerMatch,
        lessThan(80),
        reason: '${result.scenario.label} se acerca al limite de manos',
      );
      expect(
        summary.totalRounds,
        greaterThan(summary.playedMatches),
        reason: '${result.scenario.label} no esta jugando rondas suficientes',
      );
      expect(
        summary.totalTrucoCalls,
        greaterThan(0),
        reason: '${result.scenario.label} no cubre llamadas de truco',
      );
      expect(
        summary.totalTrucoResponses,
        greaterThan(0),
        reason: '${result.scenario.label} no cubre respuestas de truco',
      );
      expect(summary.teamOneWinRate, inInclusiveRange(0.15, 0.85));
      totalAlVerDecisions +=
          summary.totalAlVerPlayed + summary.totalAlVerConceded;
      totalSignalOpportunities += summary.totalSignalOpportunities;
      totalSignalsGiven += summary.totalSignalsGiven;
      totalVoyATiRequests += summary.totalVoyATiRequests;
      totalVenAMiOrders += summary.totalVenAMiOrders;
      totalVenAMiProtectedRounds += summary.totalVenAMiProtectedRounds;
    }

    expect(
      totalAlVerDecisions,
      greaterThan(0),
      reason: 'La bateria no ha cubierto decisiones de Al ver',
    );
    expect(
      totalSignalOpportunities,
      greaterThan(0),
      reason: 'La bateria no ha visto manos con senas posibles',
    );
    expect(
      totalSignalsGiven,
      greaterThan(0),
      reason: 'La bateria no ha cubierto senas visibles',
    );
    expect(
      totalVoyATiRequests,
      greaterThan(0),
      reason: 'La bateria no ha cubierto solicitudes de voy a ti',
    );
    expect(
      totalVenAMiOrders,
      greaterThan(0),
      reason: 'La bateria no ha cubierto ordenes de ven a mi',
    );
    expect(
      totalVenAMiProtectedRounds,
      greaterThan(0),
      reason: 'La bateria no ha confirmado ven a mi protegiendo rondas',
    );
  });
}
