import 'dart:math';

import 'spanish_card.dart';
import 'suit.dart';

class ZapitiDeck {
  const ZapitiDeck._();

  static List<SpanishCard> fullDeck() {
    const values = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12];

    return [
      for (final suit in Suit.values)
        for (final value in values) SpanishCard(value: value, suit: suit),
    ];
  }

  static List<SpanishCard> shuffled({Random? random}) {
    final deck = fullDeck();
    deck.shuffle(random);
    return deck;
  }
}
