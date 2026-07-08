import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bot_memory_context.dart';
import 'package:zapiti_app/domain/played_card.dart';
import 'package:zapiti_app/domain/player.dart';
import 'package:zapiti_app/domain/round_result.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';

void main() {
  group('BotMemoryContext', () {
    const bot = Player(id: 'bot', name: 'Bot', teamId: 1);
    const mate = Player(id: 'mate', name: 'Mate', teamId: 1);
    const rival = Player(id: 'rival', name: 'Rival', teamId: 2);

    test('recuerda cartas fuertes gastadas por rivales', () {
      final memory = BotMemoryContext.from(
        bot: bot,
        playedCards: const [
          PlayedCard(
            player: rival,
            card: SpanishCard(value: 4, suit: Suit.bastos),
          ),
          PlayedCard(
            player: bot,
            card: SpanishCard(value: 12, suit: Suit.oros),
          ),
        ],
        roundHistory: const [],
      );

      expect(memory.strongCardsPlayed, 1);
      expect(memory.strongCardsPlayedByOpponents, 1);
      expect(memory.opponentsSpentPower, isTrue);
    });

    test('recuerda quien gano rondas previas', () {
      const mateWinner = PlayedCard(
        player: mate,
        card: SpanishCard(value: 2, suit: Suit.copas),
      );
      final memory = BotMemoryContext.from(
        bot: bot,
        playedCards: const [],
        roundHistory: [
          const RoundResult(
            winner: PlayedCard(
              player: rival,
              card: SpanishCard(value: 1, suit: Suit.espadas),
            ),
            playedCards: [],
          ),
          const RoundResult(
            winner: mateWinner,
            playedCards: [],
          ),
        ],
      );

      expect(memory.teamWonAnyRound, isTrue);
      expect(memory.opponentsWonAnyRound, isTrue);
      expect(memory.teammateWonLastRound, isTrue);
    });
  });
}
