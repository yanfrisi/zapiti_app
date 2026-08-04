import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/ai_benchmark_report.dart';
import 'package:zapiti_app/domain/ai_match_simulator.dart';

void main() {
  test('AiBenchmarkRunner genera resultados reproducibles y formateables', () {
    const runner = AiBenchmarkRunner(simulator: AiMatchSimulator());
    const scenarios = [
      AiBenchmarkScenario(
        label: 'IA 2 vs IA 2',
        teamOneDifficulty: 2,
        teamTwoDifficulty: 2,
      ),
      AiBenchmarkScenario(
        label: 'IA 5 vs IA 3',
        teamOneDifficulty: 5,
        teamTwoDifficulty: 3,
      ),
    ];
    const seeds = [101, 202];

    final first = runner.run(
      scenarios: scenarios,
      seeds: seeds,
      matchesPerSeed: 4,
      maxHandsPerMatch: 40,
    );
    final second = runner.run(
      scenarios: scenarios,
      seeds: seeds,
      matchesPerSeed: 4,
      maxHandsPerMatch: 40,
    );

    expect(first.results.length, 2);
    expect(second.formatLines(), first.formatLines());
    expect(first.formatLines().first, contains('IA 2 vs IA 2'));
    expect(first.formatLines().last, contains('IA 5 vs IA 3'));
  });
}
