import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';
import 'package:zapiti_app/domain/zapiti_rules.dart';

void main() {
  group('ZapitiRules', () {
    test('4 de Bastos es mas fuerte que 7 de Copas', () {
      const fourBastos = SpanishCard(value: 4, suit: Suit.bastos);
      const sevenCopas = SpanishCard(value: 7, suit: Suit.copas);

      expect(
        ZapitiRules.strength(fourBastos),
        greaterThan(ZapitiRules.strength(sevenCopas)),
      );
    });

    test('7 de Oros es mas fuerte que 3', () {
      const sevenOros = SpanishCard(value: 7, suit: Suit.oros);
      const threeBastos = SpanishCard(value: 3, suit: Suit.bastos);

      expect(
        ZapitiRules.strength(sevenOros),
        greaterThan(ZapitiRules.strength(threeBastos)),
      );
    });

    test('winnerCard devuelve la carta mas fuerte', () {
      const cards = [
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 1, suit: Suit.espadas),
        SpanishCard(value: 7, suit: Suit.oros),
      ];

      final winner = ZapitiRules.winnerCard(cards);

      expect(winner, const SpanishCard(value: 7, suit: Suit.oros));
    });
  });
}
