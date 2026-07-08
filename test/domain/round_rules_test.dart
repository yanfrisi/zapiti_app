import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/played_card.dart';
import 'package:zapiti_app/domain/player.dart';
import 'package:zapiti_app/domain/round_rules.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';

void main() {
  group('RoundRules', () {
    test('maxima unica en Equipo 2 gana el chico', () {
      const playerA = Player(id: 'p1', name: 'Jugador A', teamId: 1);
      const playerB = Player(id: 'p2', name: 'Jugador B', teamId: 2);

      const playedCards = [
        PlayedCard(
            player: playerA, card: SpanishCard(value: 12, suit: Suit.oros)),
        PlayedCard(
            player: playerB, card: SpanishCard(value: 4, suit: Suit.bastos)),
      ];

      final result = RoundRules.resolveRound(playedCards);

      expect(result.winner?.player, playerB);
      expect(result.winningTeamId, 2);
      expect(result.isTie, isFalse);
    });

    test('maxima empatada y cartas secundarias diferentes no desempatan', () {
      const playerA = Player(id: 'p1', name: 'Jugador A', teamId: 1);
      const playerB = Player(id: 'p2', name: 'Jugador B', teamId: 2);
      const playerC = Player(id: 'p3', name: 'Jugador C', teamId: 1);
      const playerD = Player(id: 'p4', name: 'Jugador D', teamId: 2);

      const playedCards = [
        PlayedCard(
          player: playerA,
          card: SpanishCard(value: 3, suit: Suit.oros),
        ),
        PlayedCard(
          player: playerB,
          card: SpanishCard(value: 3, suit: Suit.bastos),
        ),
        PlayedCard(
          player: playerC,
          card: SpanishCard(value: 12, suit: Suit.oros),
        ),
        PlayedCard(
          player: playerD,
          card: SpanishCard(value: 2, suit: Suit.copas),
        ),
      ];

      final result = RoundRules.resolveRound(playedCards);

      expect(result.winner, isNull);
      expect(result.winningTeamId, isNull);
      expect(result.isTie, isTrue);
    });

    test('maxima empatada y cartas secundarias iguales empatan', () {
      const playerA = Player(id: 'p1', name: 'Jugador A', teamId: 1);
      const playerB = Player(id: 'p2', name: 'Jugador B', teamId: 2);
      const playerC = Player(id: 'p3', name: 'Jugador C', teamId: 1);
      const playerD = Player(id: 'p4', name: 'Jugador D', teamId: 2);

      const playedCards = [
        PlayedCard(
          player: playerA,
          card: SpanishCard(value: 3, suit: Suit.oros),
        ),
        PlayedCard(
          player: playerB,
          card: SpanishCard(value: 3, suit: Suit.bastos),
        ),
        PlayedCard(
          player: playerC,
          card: SpanishCard(value: 12, suit: Suit.oros),
        ),
        PlayedCard(
          player: playerD,
          card: SpanishCard(value: 12, suit: Suit.copas),
        ),
      ];

      final result = RoundRules.resolveRound(playedCards);

      expect(result.winner, isNull);
      expect(result.winningTeamId, isNull);
      expect(result.isTie, isTrue);
    });

    test('maxima unica en Equipo 1 gana el chico', () {
      const playerA = Player(id: 'p1', name: 'Jugador A', teamId: 1);
      const playerB = Player(id: 'p2', name: 'Jugador B', teamId: 2);
      const playerC = Player(id: 'p3', name: 'Jugador C', teamId: 1);
      const playerD = Player(id: 'p4', name: 'Jugador D', teamId: 2);

      const playedCards = [
        PlayedCard(
          player: playerA,
          card: SpanishCard(value: 4, suit: Suit.bastos),
        ),
        PlayedCard(
          player: playerB,
          card: SpanishCard(value: 7, suit: Suit.copas),
        ),
        PlayedCard(
          player: playerC,
          card: SpanishCard(value: 12, suit: Suit.oros),
        ),
        PlayedCard(
          player: playerD,
          card: SpanishCard(value: 2, suit: Suit.copas),
        ),
      ];

      final result = RoundRules.resolveRound(playedCards);

      expect(result.winner?.player, playerA);
      expect(result.winningTeamId, 1);
      expect(result.isTie, isFalse);
    });
  });
}
