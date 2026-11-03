import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/hidden_card_determinizer.dart';
import 'package:zapiti_app/domain/played_card.dart';
import 'package:zapiti_app/domain/player.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';

void main() {
  group('HiddenCardDeterminizer', () {
    const bot = Player(id: 'p1', name: 'Bot', teamId: 1);
    const rivalRight = Player(id: 'p2', name: 'Rival 1', teamId: 2);
    const teammate = Player(id: 'p3', name: 'Mate', teamId: 1);
    const rivalLeft = Player(id: 'p4', name: 'Rival 2', teamId: 2);
    const players = [bot, rivalRight, teammate, rivalLeft];

    test('preserva la mano propia, las jugadas y el numero de cartas', () {
      const hands = {
        'p1': [
          SpanishCard(value: 4, suit: Suit.bastos),
          SpanishCard(value: 12, suit: Suit.oros),
        ],
        'p2': [SpanishCard(value: 3, suit: Suit.copas)],
        'p3': [
          SpanishCard(value: 2, suit: Suit.copas),
          SpanishCard(value: 11, suit: Suit.bastos),
        ],
        'p4': [SpanishCard(value: 1, suit: Suit.espadas)],
      };
      const playedCards = [
        PlayedCard(
          player: rivalRight,
          card: SpanishCard(value: 7, suit: Suit.oros),
        ),
      ];

      final determinized = HiddenCardDeterminizer.determinizeHands(
        bot: bot,
        players: players,
        hands: hands,
        playedCards: playedCards,
      );

      expect(determinized['p1'], hands['p1']);
      expect(determinized['p2']!.length, 1);
      expect(determinized['p3']!.length, 2);
      expect(determinized['p4']!.length, 1);
      expect(
        determinized.values.expand((cards) => cards).toSet().length,
        determinized.values.expand((cards) => cards).length,
      );
      expect(
        determinized.values.expand((cards) => cards),
        isNot(contains(const SpanishCard(value: 7, suit: Suit.oros))),
      );
    });

    test('es reproducible desde el mismo estado publico', () {
      const hands = {
        'p1': [SpanishCard(value: 4, suit: Suit.bastos)],
        'p2': [
          SpanishCard(value: 3, suit: Suit.copas),
          SpanishCard(value: 5, suit: Suit.oros),
        ],
        'p3': [SpanishCard(value: 2, suit: Suit.copas)],
        'p4': [
          SpanishCard(value: 1, suit: Suit.espadas),
          SpanishCard(value: 6, suit: Suit.bastos),
        ],
      };

      final first = HiddenCardDeterminizer.determinizeHands(
        bot: bot,
        players: players,
        hands: hands,
        playedCards: const [],
      );
      final second = HiddenCardDeterminizer.determinizeHands(
        bot: bot,
        players: players,
        hands: hands,
        playedCards: const [],
      );

      expect(first, second);
    });

    test('respeta cartas publicamente conocidas', () {
      const hands = {
        'p1': [SpanishCard(value: 4, suit: Suit.bastos)],
        'p2': [
          SpanishCard(value: 3, suit: Suit.copas),
          SpanishCard(value: 5, suit: Suit.oros),
        ],
        'p3': [SpanishCard(value: 2, suit: Suit.copas)],
        'p4': [
          SpanishCard(value: 1, suit: Suit.espadas),
          SpanishCard(value: 6, suit: Suit.bastos),
        ],
      };
      const knownCard = SpanishCard(value: 7, suit: Suit.copas);

      final determinized = HiddenCardDeterminizer.determinizeHands(
        bot: bot,
        players: players,
        hands: hands,
        playedCards: const [],
        publiclyKnownCardsByPlayer: const {
          'p3': [knownCard],
        },
      );

      expect(determinized['p3'], contains(knownCard));
      expect(determinized['p3']!.length, 1);
    });
  });
}
