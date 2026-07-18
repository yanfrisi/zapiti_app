import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bot_al_ver_strategy.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';

void main() {
  group('BotAlVerStrategy', () {
    test('una mano mala puede hacer que la IA se vaya a casa en facil', () {
      final play = BotAlVerStrategy.shouldPlay(
        cards: _badHand(),
        difficulty: 1,
        teamScore: 29,
        opponentScore: 28,
        targetScore: 30,
      );

      expect(play, isFalse);
    });

    test('una mano fuerte hace que la IA juegue', () {
      final play = BotAlVerStrategy.shouldPlay(
        cards: _strongHand(),
        difficulty: 3,
        teamScore: 29,
        opponentScore: 28,
        targetScore: 30,
      );

      expect(play, isTrue);
    });

    test('dificil juega con mas facilidad que facil', () {
      final easy = BotAlVerStrategy.shouldPlay(
        cards: _mediumHand(),
        difficulty: 1,
        teamScore: 29,
        opponentScore: 28,
        targetScore: 30,
      );
      final hard = BotAlVerStrategy.shouldPlay(
        cards: _mediumHand(),
        difficulty: 5,
        teamScore: 29,
        opponentScore: 28,
        targetScore: 30,
      );

      expect(easy, isFalse);
      expect(hard, isTrue);
    });
  });
}

List<SpanishCard> _badHand() {
  return const [
    SpanishCard(value: 5, suit: Suit.oros),
    SpanishCard(value: 6, suit: Suit.copas),
    SpanishCard(value: 4, suit: Suit.espadas),
  ];
}

List<SpanishCard> _mediumHand() {
  return const [
    SpanishCard(value: 10, suit: Suit.oros),
    SpanishCard(value: 11, suit: Suit.copas),
    SpanishCard(value: 12, suit: Suit.bastos),
  ];
}

List<SpanishCard> _strongHand() {
  return const [
    SpanishCard(value: 4, suit: Suit.bastos),
    SpanishCard(value: 7, suit: Suit.copas),
    SpanishCard(value: 1, suit: Suit.espadas),
  ];
}
