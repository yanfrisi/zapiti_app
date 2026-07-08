import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/hand_rules.dart';
import 'package:zapiti_app/domain/played_card.dart';
import 'package:zapiti_app/domain/player.dart';
import 'package:zapiti_app/domain/round_result.dart';
import 'package:zapiti_app/domain/round_rules.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';

void main() {
  group('HandRules', () {
    test('la primera ronda empatada da una chica a cada equipo', () {
      final progress = HandRules.resolve([
        _tiedRound(),
      ]);

      expect(progress.roundWinsFor(1), 1);
      expect(progress.roundWinsFor(2), 1);
      expect(progress.isFinished, isFalse);
    });

    test('la segunda ronda empatada da la mano al ganador de la primera', () {
      final progress = HandRules.resolve([
        _wonRoundByTeam(1),
        _tiedRound(),
      ]);

      expect(progress.roundWinsFor(1), 2);
      expect(progress.winningTeamId, 1);
      expect(progress.isFinished, isTrue);
      expect(progress.isNoPoints, isFalse);
    });

    test('primera y segunda empatadas dejan decidir a la tercera', () {
      final progress = HandRules.resolve([
        _tiedRound(),
        _tiedRound(),
      ]);

      expect(progress.roundWinsFor(1), 1);
      expect(progress.roundWinsFor(2), 1);
      expect(progress.isFinished, isFalse);
    });

    test('primera empatada y segunda ganada decide el reparto', () {
      final progress = HandRules.resolve([
        _tiedRound(),
        _wonRoundByTeam(2),
      ]);

      expect(progress.roundWinsFor(1), 1);
      expect(progress.roundWinsFor(2), 2);
      expect(progress.winningTeamId, 2);
      expect(progress.isFinished, isTrue);
      expect(progress.isNoPoints, isFalse);
    });

    test('una ronda para cada equipo deja decidir a la tercera', () {
      final progress = HandRules.resolve([
        _wonRoundByTeam(1),
        _wonRoundByTeam(2),
        _wonRoundByTeam(1),
      ]);

      expect(progress.roundWinsFor(1), 2);
      expect(progress.roundWinsFor(2), 1);
      expect(progress.winningTeamId, 1);
      expect(progress.isFinished, isTrue);
      expect(progress.isNoPoints, isFalse);
    });

    test('dos rondas ganadas por el mismo equipo cierran el reparto', () {
      final progress = HandRules.resolve([
        _wonRoundByTeam(1),
        _wonRoundByTeam(1),
        _wonRoundByTeam(2),
      ]);

      expect(progress.roundWinsFor(1), 2);
      expect(progress.roundWinsFor(2), 0);
      expect(progress.winningTeamId, 1);
      expect(progress.isFinished, isTrue);
      expect(progress.isNoPoints, isFalse);
    });

    test('tercera ronda empatada con 1-1 termina sin puntos', () {
      final progress = HandRules.resolve([
        _wonRoundByTeam(1),
        _wonRoundByTeam(2),
        _tiedRound(),
      ]);

      expect(progress.roundWinsFor(1), 1);
      expect(progress.roundWinsFor(2), 1);
      expect(progress.winningTeamId, isNull);
      expect(progress.isFinished, isTrue);
      expect(progress.isNoPoints, isTrue);
    });

    test('tres rondas empatadas terminan sin puntos', () {
      final progress = HandRules.resolve([
        _tiedRound(),
        _tiedRound(),
        _tiedRound(),
      ]);

      expect(progress.roundWinsFor(1), 1);
      expect(progress.roundWinsFor(2), 1);
      expect(progress.winningTeamId, isNull);
      expect(progress.isFinished, isTrue);
      expect(progress.isNoPoints, isTrue);
    });
  });
}

RoundResult _wonRoundByTeam(int teamId) {
  final winner = Player(id: 'winner-$teamId', name: 'Ganador', teamId: teamId);
  final loserTeam = teamId == 1 ? 2 : 1;
  final loser =
      Player(id: 'loser-$loserTeam', name: 'Perdedor', teamId: loserTeam);

  return RoundRules.resolveRound([
    PlayedCard(
        player: winner, card: const SpanishCard(value: 4, suit: Suit.bastos)),
    PlayedCard(
        player: loser, card: const SpanishCard(value: 12, suit: Suit.oros)),
  ]);
}

RoundResult _tiedRound() {
  const playerA = Player(id: 'p1', name: 'Jugador A', teamId: 1);
  const playerB = Player(id: 'p2', name: 'Jugador B', teamId: 2);

  return RoundRules.resolveRound([
    const PlayedCard(
      player: playerA,
      card: SpanishCard(value: 3, suit: Suit.oros),
    ),
    const PlayedCard(
      player: playerB,
      card: SpanishCard(value: 3, suit: Suit.bastos),
    ),
  ]);
}
