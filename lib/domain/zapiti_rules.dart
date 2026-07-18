import 'spanish_card.dart';
import 'suit.dart';

class ZapitiRules {
  const ZapitiRules._();

  /// Jerarquía de cartas usada por todas las modalidades de Zápiti.
  ///
  /// Importante:
  /// La UI y los bots deben consultar o reflejar esta misma jerarquía.
  static int strength(SpanishCard card) {
    if (card.value == 4 && card.suit == Suit.bastos) return 100;
    if (card.value == 7 && card.suit == Suit.copas) return 99;
    if (card.value == 7 && card.suit == Suit.oros) return 98;
    if (card.value == 1 && card.suit == Suit.espadas) return 97;

    if (card.value == 3) return 90;
    if (card.value == 2) return 80;
    if (card.value == 1) return 70;

    if (card.value == 12) return 60;
    if (card.value == 11) return 50;
    if (card.value == 10) return 40;

    if (card.value == 7) return 30;
    if (card.value == 6) return 20;
    if (card.value == 5) return 10;
    if (card.value == 4) return 5;

    return 0;
  }

  static SpanishCard winnerCard(List<SpanishCard> cards) {
    if (cards.isEmpty) {
      throw ArgumentError('No se puede calcular ganadora sin cartas jugadas.');
    }

    return cards.reduce((best, current) {
      return strength(current) > strength(best) ? current : best;
    });
  }
}
