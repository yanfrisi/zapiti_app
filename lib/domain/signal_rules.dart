import 'spanish_card.dart';
import 'suit.dart';
import 'zapiti_rules.dart';

class SignalRules {
  const SignalRules._();

  /// Devuelve la seña más informativa que describe una mano.
  ///
  /// Prioriza cartas especiales del Zápiti y usa `Mala` cuando no hay fuerza
  /// suficiente para comunicar algo útil al compañero.
  static String? signalForHand(List<SpanishCard> hand) {
    if (hand.contains(const SpanishCard(value: 4, suit: Suit.bastos))) {
      return '4 Bastos';
    }
    if (hand.contains(const SpanishCard(value: 7, suit: Suit.copas))) {
      return '7 Copas';
    }
    if (hand.contains(const SpanishCard(value: 7, suit: Suit.oros))) {
      return '7 Oros';
    }
    if (hand.contains(const SpanishCard(value: 1, suit: Suit.espadas))) {
      return 'As Espadas';
    }
    if (hand.any((card) => card.value == 3)) {
      return 'Treses';
    }
    if (hand.any((card) => card.value == 2)) {
      return 'Doses';
    }
    if (hand.any((card) =>
        card.value == 1 && card.suit != Suit.espadas)) {
      return 'Ases';
    }

    final strongest = hand.isEmpty
        ? 0
        : hand
            .map(ZapitiRules.strength)
            .reduce((best, current) => current > best ? current : best);
    if (strongest < 70) return 'Mala';
    return null;
  }

  /// Una seña fuerte es cualquier seña que no sea `Mala`.
  static bool isStrongSignal(String? signal) {
    return signal != null && signal != 'Mala';
  }

  /// Resolves signals that identify one exact card. Group signals such as
  /// "Treses" intentionally return null because they do not identify a
  /// unique card.
  static SpanishCard? exactCardForSignal(String? signal) {
    final normalized = signal?.replaceAll(' de ', ' ');
    return switch (normalized) {
      '4 Bastos' => const SpanishCard(value: 4, suit: Suit.bastos),
      '7 Copas' => const SpanishCard(value: 7, suit: Suit.copas),
      '7 Oros' => const SpanishCard(value: 7, suit: Suit.oros),
      'As Espadas' => const SpanishCard(value: 1, suit: Suit.espadas),
      _ => null,
    };
  }
}
