import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/ai_match_simulator.dart';

void main() {
  test(
    'informe manual de balance de IA',
    () {
      const scenarios = [
        (
          label: 'IA 1 vs IA 1',
          teamOneDifficulty: 1,
          teamTwoDifficulty: 1,
        ),
        (
          label: 'IA 3 vs IA 3',
          teamOneDifficulty: 3,
          teamTwoDifficulty: 3,
        ),
        (
          label: 'IA 5 vs IA 5',
          teamOneDifficulty: 5,
          teamTwoDifficulty: 5,
        ),
        (
          label: 'IA 5 vs IA 1',
          teamOneDifficulty: 5,
          teamTwoDifficulty: 1,
        ),
        (
          label: 'IA 1 vs IA 5',
          teamOneDifficulty: 1,
          teamTwoDifficulty: 5,
        ),
        (
          label: 'IA 3 vs IA 1',
          teamOneDifficulty: 3,
          teamTwoDifficulty: 1,
        ),
        (
          label: 'IA 1 vs IA 3',
          teamOneDifficulty: 1,
          teamTwoDifficulty: 3,
        ),
        (
          label: 'IA 5 vs IA 3',
          teamOneDifficulty: 5,
          teamTwoDifficulty: 3,
        ),
        (
          label: 'IA 3 vs IA 5',
          teamOneDifficulty: 3,
          teamTwoDifficulty: 5,
        ),
      ];

      const simulator = AiMatchSimulator();
      const seeds = [
        20260718,
        20260719,
        20260720,
        20260721,
        20260722,
        20260723,
        20260724,
        20260725,
        20260726,
        20260727,
      ];
      const matchesPerSeed = 50;
      for (final scenario in scenarios) {
        final config = AiSimulationConfig(
          matches: seeds.length * matchesPerSeed,
          seed: seeds.first,
          teamOneDifficulty: scenario.teamOneDifficulty,
          teamTwoDifficulty: scenario.teamTwoDifficulty,
          maxHandsPerMatch: 60,
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
                  maxHandsPerMatch: config.maxHandsPerMatch,
                ),
              ),
          ],
        );

        // ignore: avoid_print
        print([
          scenario.label,
          'partidas=${summary.playedMatches}',
          'semillas=${seeds.length}',
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
        ].join(' | '));
      }
    },
    skip: !const bool.fromEnvironment('AI_BALANCE_REPORT') &&
            Platform.environment['AI_BALANCE_REPORT'] != '1'
        ? 'Lanzar con --dart-define=AI_BALANCE_REPORT=true para imprimir el informe.'
        : false,
  );
}

String _percent(double value) => '${(value * 100).toStringAsFixed(1)}%';
