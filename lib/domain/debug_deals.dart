import 'spanish_card.dart';
import 'suit.dart';

class DebugDeals {
  const DebugDeals._();

  /// Presets de manos para reproducir escenarios de desarrollo.
  ///
  /// La UI solo los expone en `kDebugMode`, por lo que no forman parte de la
  /// experiencia final de usuario. Cada mapa usa ids de `ZapitiPlayers`.
  static const presets = [
    {
      'p1': [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 5, suit: Suit.copas),
      ],
      'p2': [
        SpanishCard(value: 7, suit: Suit.copas),
        SpanishCard(value: 1, suit: Suit.oros),
        SpanishCard(value: 6, suit: Suit.espadas),
      ],
      'p3': [
        SpanishCard(value: 3, suit: Suit.oros),
        SpanishCard(value: 10, suit: Suit.bastos),
        SpanishCard(value: 5, suit: Suit.espadas),
      ],
      'p4': [
        SpanishCard(value: 2, suit: Suit.copas),
        SpanishCard(value: 11, suit: Suit.oros),
        SpanishCard(value: 4, suit: Suit.espadas),
      ],
    },
    {
      'p1': [
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 11, suit: Suit.copas),
        SpanishCard(value: 5, suit: Suit.bastos),
      ],
      'p2': [
        SpanishCard(value: 3, suit: Suit.oros),
        SpanishCard(value: 2, suit: Suit.espadas),
        SpanishCard(value: 1, suit: Suit.copas),
      ],
      'p3': [
        SpanishCard(value: 7, suit: Suit.oros),
        SpanishCard(value: 6, suit: Suit.copas),
        SpanishCard(value: 4, suit: Suit.oros),
      ],
      'p4': [
        SpanishCard(value: 3, suit: Suit.bastos),
        SpanishCard(value: 10, suit: Suit.espadas),
        SpanishCard(value: 5, suit: Suit.oros),
      ],
    },
  ];
}
