import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bot_ven_a_mi_strategy.dart';
import 'package:zapiti_app/domain/played_card.dart';
import 'package:zapiti_app/domain/player.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';

void main() {
  group('BotVenAMiStrategy', () {
    const human = Player(id: 'p1', name: 'Humano', teamId: 1);
    const rivalRight = Player(id: 'p2', name: 'Rival 1', teamId: 2);
    const companion = Player(id: 'p3', name: 'Compa', teamId: 1);
    const rivalLeft = Player(id: 'p4', name: 'Rival 2', teamId: 2);

    test('con Zapiti, carta media y baja tira la legal mas baja', () {
      const players = [human, rivalRight, companion, rivalLeft];
      const hand = [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 5, suit: Suit.espadas),
      ];
      const playedCards = [
        PlayedCard(
          player: human,
          card: SpanishCard(value: 3, suit: Suit.oros),
        ),
        PlayedCard(
          player: rivalRight,
          card: SpanishCard(value: 1, suit: Suit.oros),
        ),
      ];

      final chosen = BotVenAMiStrategy.chooseCard(
        bot: companion,
        hand: hand,
        playedCards: playedCards,
        players: players,
        hands: const {
          'p3': hand,
          'p4': [SpanishCard(value: 5, suit: Suit.espadas)],
        },
      );

      expect(chosen, const SpanishCard(value: 5, suit: Suit.espadas));
    });

    test('elige la menor entre las cartas legales, no de toda la mano', () {
      const players = [human, rivalRight, companion, rivalLeft];
      const hand = [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 5, suit: Suit.espadas),
      ];
      const playedCards = [
        PlayedCard(
          player: human,
          card: SpanishCard(value: 1, suit: Suit.oros),
        ),
        PlayedCard(
          player: rivalRight,
          card: SpanishCard(value: 12, suit: Suit.copas),
        ),
      ];

      final chosen = BotVenAMiStrategy.chooseCard(
        bot: companion,
        hand: hand,
        playedCards: playedCards,
        players: players,
        hands: const {'p3': hand},
        legalCards: const [
          SpanishCard(value: 4, suit: Suit.bastos),
          SpanishCard(value: 12, suit: Suit.oros),
        ],
      );

      expect(chosen, const SpanishCard(value: 12, suit: Suit.oros));
    });
  });
}
