import 'dart:io';

import 'package:zapiti_app/domain/ai_match_simulator.dart';

void main(List<String> args) {
  final matches = _intArg(args, '--matches', fallback: 100);
  final seed = _intArg(args, '--seed', fallback: 1);
  final difficulty = _intArg(args, '--difficulty', fallback: 3);
  final teamOneDifficulty = _intArg(
    args,
    '--team-one-difficulty',
    fallback: difficulty,
  );
  final teamTwoDifficulty = _intArg(
    args,
    '--team-two-difficulty',
    fallback: difficulty,
  );

  final summary = const AiMatchSimulator().run(
    AiSimulationConfig(
      matches: matches,
      seed: seed,
      teamOneDifficulty: teamOneDifficulty,
      teamTwoDifficulty: teamTwoDifficulty,
    ),
  );

  stdout.writeln('Zapiti IA simulator');
  stdout.writeln('Partidas: ${summary.playedMatches}');
  stdout.writeln('Semilla: $seed');
  stdout.writeln('Equipo 1 IA: $teamOneDifficulty');
  stdout.writeln('Equipo 2 IA: $teamTwoDifficulty');
  stdout.writeln('');
  stdout.writeln(
    'Victorias Equipo 1: ${summary.teamOneWins} '
    '(${_percent(summary.teamOneWinRate)})',
  );
  stdout.writeln(
    'Victorias Equipo 2: ${summary.teamTwoWins} '
    '(${_percent(summary.teamTwoWinRate)})',
  );
  stdout.writeln(
    'Marcador medio: '
    '${summary.averageFinalScoreTeamOne.toStringAsFixed(1)} - '
    '${summary.averageFinalScoreTeamTwo.toStringAsFixed(1)}',
  );
  stdout.writeln(
    'Manos medias: ${summary.averageHandsPerMatch.toStringAsFixed(1)}',
  );
  stdout.writeln(
    'Rondas medias: ${summary.averageRoundsPerMatch.toStringAsFixed(1)}',
  );
  stdout.writeln(
    'Trucos por partida: '
    '${summary.averageTrucoCallsPerMatch.toStringAsFixed(1)}',
  );
  stdout.writeln('Trucos cantados: ${summary.totalTrucoCalls}');
  stdout.writeln('Subidas: ${summary.totalTrucoRaises}');
  stdout.writeln('Aceptados: ${summary.totalTrucoAccepts}');
  stdout.writeln('Rechazados: ${summary.totalTrucoPasses}');
  stdout.writeln('Al ver jugados: ${summary.totalAlVerPlayed}');
  stdout.writeln('Al ver concedidos: ${summary.totalAlVerConceded}');
}

int _intArg(List<String> args, String name, {required int fallback}) {
  final index = args.indexOf(name);
  if (index < 0 || index + 1 >= args.length) return fallback;
  return int.tryParse(args[index + 1]) ?? fallback;
}

String _percent(double value) {
  return '${(value * 100).toStringAsFixed(1)}%';
}
