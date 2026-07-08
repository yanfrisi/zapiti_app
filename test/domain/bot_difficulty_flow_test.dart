import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bot_strategy.dart';
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
  group('Bot difficulty flow', () {
    const bot = Player(id: 'bot', name: 'Bot', teamId: 2);
    const rival = Player(id: 'rival', name: 'Rival', teamId: 1);
    const hand = [
      SpanishCard(value: 2, suit: Suit.copas),
      SpanishCard(value: 12, suit: Suit.oros),
    ];
    const table = [
      PlayedCard(
        player: rival,
        card: SpanishCard(value: 1, suit: Suit.oros),
      ),
    ];

    test('nivel facil puede romper una buena decision estrategica', () {
      final strategicCard = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: table,
        forceWinIfPossible: true,
      );

      final chosen = DifficultyStrategy.applyCardMistake(
        difficulty: 1,
        random: _FixedRandom(nextDoubleValue: 0, nextBoolValue: true),
        player: bot,
        hand: hand,
        strategicCard: strategicCard,
        playedCards: table,
      );

      expect(strategicCard, const SpanishCard(value: 2, suit: Suit.copas));
      expect(chosen, const SpanishCard(value: 12, suit: Suit.oros));
    });

    test('nivel experto conserva la decision estrategica', () {
      final strategicCard = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: table,
        forceWinIfPossible: true,
      );

      final chosen = DifficultyStrategy.applyCardMistake(
        difficulty: 5,
        random: _FixedRandom(nextDoubleValue: 0, nextBoolValue: true),
        player: bot,
        hand: hand,
        strategicCard: strategicCard,
        playedCards: table,
      );

      expect(chosen, strategicCard);
    });
  });
}
