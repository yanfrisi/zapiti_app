import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';
import 'package:zapiti_app/domain/zapiti_rules.dart';

void main() {
  group('ZapitiRules', () {
    test('4 de Bastos es más fuerte que 7 de Copas', () {
      const fourBastos = SpanishCard(value: 4, suit: Suit.bastos);
      const sevenCopas = SpanishCard(value: 7, suit: Suit.copas);

      expect(
        ZapitiRules.strength(fourBastos),
        greaterThan(ZapitiRules.strength(sevenCopas)),
      );
    });

    test('winnerCard devuelve la carta más fuerte', () {
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
