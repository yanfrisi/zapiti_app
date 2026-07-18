import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bot_table_read.dart';
import 'package:zapiti_app/domain/played_card.dart';
import 'package:zapiti_app/domain/player.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';

void main() {
  group('BotTableRead', () {
    const human = Player(id: 'p1', name: 'Humano', teamId: 1);
    const rivalRight = Player(id: 'p2', name: 'Rival 1', teamId: 2);
    const companion = Player(id: 'p3', name: 'Compa', teamId: 1);
    const rivalLeft = Player(id: 'p4', name: 'Rival 2', teamId: 2);
    const players = [human, rivalRight, companion, rivalLeft];

    test('detecta ronda insalvable si rival domina y no quedan respuestas', () {
      const playedCards = [
        PlayedCard(
          player: rivalRight,
          card: SpanishCard(value: 4, suit: Suit.bastos),
        ),
        PlayedCard(
          player: human,
          card: SpanishCard(value: 12, suit: Suit.oros),
        ),
      ];

      final unsavable = BotTableRead.currentRoundIsUnsavableForTeam(
        teamId: 1,
        players: players,
        hands: const {
          'p3': [SpanishCard(value: 1, suit: Suit.copas)],
        },
        playedCards: playedCards,
      );

      expect(unsavable, isTrue);
    });

    test('no marca insalvable si queda una carta que empata o gana', () {
      const playedCards = [
        PlayedCard(
          player: rivalRight,
          card: SpanishCard(value: 3, suit: Suit.oros),
        ),
      ];

      final unsavable = BotTableRead.currentRoundIsUnsavableForTeam(
        teamId: 1,
        players: players,
        hands: const {
          'p1': [SpanishCard(value: 3, suit: Suit.copas)],
          'p3': [SpanishCard(value: 12, suit: Suit.oros)],
        },
        playedCards: playedCards,
      );

      expect(unsavable, isFalse);
    });
  });
}
