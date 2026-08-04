import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/ai_benchmark_report.dart';
import 'package:zapiti_app/domain/ai_match_simulator.dart';

void main() {
  test(
    'informe compacto de progreso de IA',
    () {
      const scenarios = [
        AiBenchmarkScenario(
          label: 'IA 5 vs IA 1',
          teamOneDifficulty: 5,
          teamTwoDifficulty: 1,
        ),
        AiBenchmarkScenario(
          label: 'IA 1 vs IA 5',
          teamOneDifficulty: 1,
          teamTwoDifficulty: 5,
        ),
        AiBenchmarkScenario(
          label: 'IA 5 vs IA 3',
          teamOneDifficulty: 5,
          teamTwoDifficulty: 3,
        ),
        AiBenchmarkScenario(
          label: 'IA 3 vs IA 5',
          teamOneDifficulty: 3,
          teamTwoDifficulty: 5,
        ),
        AiBenchmarkScenario(
          label: 'IA 3 vs IA 1',
          teamOneDifficulty: 3,
          teamTwoDifficulty: 1,
        ),
        AiBenchmarkScenario(
          label: 'IA 1 vs IA 3',
          teamOneDifficulty: 1,
          teamTwoDifficulty: 3,
        ),
        AiBenchmarkScenario(
          label: 'IA 5 vs IA 5',
          teamOneDifficulty: 5,
          teamTwoDifficulty: 5,
        ),
      ];

      const runner = AiBenchmarkRunner(simulator: AiMatchSimulator());
      const seeds = [
        20260804,
        20260805,
        20260806,
        20260807,
        20260808,
        20260809,
      ];
      const matchesPerSeed = 10;

      final report = runner.run(
        scenarios: scenarios,
        seeds: seeds,
        matchesPerSeed: matchesPerSeed,
        maxHandsPerMatch: 60,
      );

      for (final line in report.formatLines()) {
        // ignore: avoid_print
        print(line);
      }
    },
    skip: !const bool.fromEnvironment('AI_PROGRESS_REPORT') &&
            Platform.environment['AI_PROGRESS_REPORT'] != '1'
        ? 'Lanzar con --dart-define=AI_PROGRESS_REPORT=true para imprimir el informe.'
        : false,
  );
}
