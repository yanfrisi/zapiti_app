import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/difficulty_strategy.dart';
import 'package:zapiti_app/domain/played_card.dart';
import 'package:zapiti_app/domain/player.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';

class _FixedRandom implements Random {
  final double nextDoubleValue;
  final bool nextBoolValue;

  _FixedRandom({
    required this.nextDoubleValue,
    required this.nextBoolValue,
  });

  @override
  bool nextBool() => nextBoolValue;

  @override
  double nextDouble() => nextDoubleValue;

  @override
  int nextInt(int max) => 0;
}

void main() {
  group('DifficultyStrategy', () {
    const bot = Player(id: 'bot', name: 'Bot', teamId: 2);
    const teammate = Player(id: 'mate', name: 'Mate', teamId: 2);
    const rival = Player(id: 'rival', name: 'Rival', teamId: 1);
    const hand = [
      SpanishCard(value: 12, suit: Suit.oros),
      SpanishCard(value: 2, suit: Suit.copas),
    ];

    test('reduce progresivamente la probabilidad de error', () {
      expect(DifficultyStrategy.cardMistakeChance(1), greaterThan(0.3));
      expect(
        DifficultyStrategy.cardMistakeChance(1),
        greaterThan(DifficultyStrategy.cardMistakeChance(2)),
      );
      expect(
        DifficultyStrategy.cardMistakeChance(2),
        greaterThan(DifficultyStrategy.cardMistakeChance(3)),
      );
      expect(
        DifficultyStrategy.cardMistakeChance(3),
        greaterThan(DifficultyStrategy.cardMistakeChance(4)),
      );
      expect(DifficultyStrategy.cardMistakeChance(5), 0);
    });

    test('nivel experto no altera la carta estrategica', () {
      final chosen = DifficultyStrategy.applyCardMistake(
        difficulty: 5,
        random: _FixedRandom(nextDoubleValue: 0, nextBoolValue: false),
        player: bot,
        hand: hand,
        strategicCard: const SpanishCard(value: 12, suit: Suit.oros),
        playedCards: const [
          PlayedCard(
            player: rival,
            card: SpanishCard(value: 1, suit: Suit.oros),
          ),
        ],
      );

      expect(chosen, const SpanishCard(value: 12, suit: Suit.oros));
    });

    test('nivel facil puede equivocarse si la ronda no esta ganada', () {
      final chosen = DifficultyStrategy.applyCardMistake(
        difficulty: 1,
        random: _FixedRandom(nextDoubleValue: 0, nextBoolValue: false),
        player: bot,
        hand: hand,
        strategicCard: const SpanishCard(value: 12, suit: Suit.oros),
        playedCards: const [
          PlayedCard(
            player: rival,
            card: SpanishCard(value: 1, suit: Suit.oros),
          ),
        ],
      );

      expect(chosen, const SpanishCard(value: 2, suit: Suit.copas));
    });

    test('no fuerza error si el equipo del bot ya gana la ronda', () {
      final chosen = DifficultyStrategy.applyCardMistake(
        difficulty: 1,
        random: _FixedRandom(nextDoubleValue: 0, nextBoolValue: true),
        player: bot,
        hand: hand,
        strategicCard: const SpanishCard(value: 12, suit: Suit.oros),
        playedCards: const [
          PlayedCard(
            player: teammate,
            card: SpanishCard(value: 4, suit: Suit.bastos),
          ),
          PlayedCard(
            player: rival,
            card: SpanishCard(value: 1, suit: Suit.espadas),
          ),
        ],
      );

      expect(chosen, const SpanishCard(value: 12, suit: Suit.oros));
    });
  });
}
