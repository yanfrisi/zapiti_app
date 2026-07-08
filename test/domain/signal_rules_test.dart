import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/signal_rules.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';

void main() {
  group('SignalRules', () {
    test('prioriza el 4 de Bastos', () {
      final signal = SignalRules.signalForHand(const [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 7, suit: Suit.copas),
      ]);

      expect(signal, '4 Bastos');
    });

    test('marca mala cuando la mano no tiene fuerza', () {
      final signal = SignalRules.signalForHand(const [
        SpanishCard(value: 5, suit: Suit.oros),
        SpanishCard(value: 4, suit: Suit.espadas),
      ]);

      expect(signal, 'Mala');
      expect(SignalRules.isStrongSignal(signal), isFalse);
    });

    test('marca treses antes que doses', () {
      final signal = SignalRules.signalForHand(const [
        SpanishCard(value: 3, suit: Suit.oros),
        SpanishCard(value: 2, suit: Suit.espadas),
      ]);

      expect(signal, 'Treses');
      expect(SignalRules.isStrongSignal(signal), isTrue);
    });

    test('marca doses cuando no hay senya superior', () {
      final signal = SignalRules.signalForHand(const [
        SpanishCard(value: 2, suit: Suit.copas),
        SpanishCard(value: 1, suit: Suit.oros),
      ]);

      expect(signal, 'Doses');
      expect(SignalRules.isStrongSignal(signal), isTrue);
    });

    test('no inventa senya con mano media sin especial', () {
      final signal = SignalRules.signalForHand(const [
        SpanishCard(value: 1, suit: Suit.oros),
        SpanishCard(value: 6, suit: Suit.espadas),
      ]);

      expect(signal, isNull);
    });
  });
}
