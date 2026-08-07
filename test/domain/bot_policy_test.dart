import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bot_decision_context.dart';
import 'package:zapiti_app/domain/bot_policy.dart';
import 'package:zapiti_app/domain/played_card.dart';
import 'package:zapiti_app/domain/player.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';

void main() {
  group('BotPolicySelector', () {
    test('usa heuristica en dificultades bajas', () {
      expect(BotPolicySelector.forDifficulty(2), isA<HeuristicBotPolicy>());
    });

    test('usa Monte Carlo en dificultad alta y experto', () {
      expect(BotPolicySelector.forDifficulty(4), isA<MonteCarloBotPolicy>());
      expect(BotPolicySelector.forDifficulty(5), isA<MonteCarloBotPolicy>());
    });
  });

  group('Bot policies', () {
    const bot = Player(id: 'bot', name: 'Bot', teamId: 2);
    const rival = Player(id: 'rival', name: 'Rival', teamId: 1);
    const teammate = Player(id: 'mate', name: 'Mate', teamId: 2);
    const rearRival = Player(id: 'rear', name: 'Rear', teamId: 1);
    const hand = [
      SpanishCard(value: 2, suit: Suit.copas),
      SpanishCard(value: 12, suit: Suit.oros),
    ];
    const playedCards = [
      PlayedCard(
        player: rival,
        card: SpanishCard(value: 1, suit: Suit.oros),
      ),
    ];
    const players = [rival, teammate, bot, rearRival];

    test('la heuristica elige una carta legal', () {
      final card = const HeuristicBotPolicy().chooseCard(
        const BotDecisionContext(
          difficulty: 2,
          bot: bot,
          players: players,
          hand: hand,
          hands: {'bot': hand},
          playedCards: playedCards,
          teamRoundWins: 0,
          opponentRoundWins: 0,
          preserveStrongCards: false,
          teammateHasStrongSignal: false,
          opponentHasStrongSignal: false,
          forceWinIfPossible: false,
          teammateStillToPlay: false,
          opponentStillToPlay: false,
        ),
      );

      expect(hand, contains(card));
    });

    test('ismcts inicial elige una carta legal', () {
      final card = const IsmctsBotPolicy(iterations: 8).chooseCard(
        const BotDecisionContext(
          difficulty: 5,
          bot: bot,
          players: players,
          hand: hand,
          hands: {
            'bot': hand,
            'rival': [
              SpanishCard(value: 1, suit: Suit.oros),
              SpanishCard(value: 6, suit: Suit.oros),
              SpanishCard(value: 5, suit: Suit.espadas),
            ],
            'mate': [
              SpanishCard(value: 2, suit: Suit.bastos),
              SpanishCard(value: 11, suit: Suit.copas),
              SpanishCard(value: 4, suit: Suit.copas),
            ],
            'rear': [
              SpanishCard(value: 7, suit: Suit.copas),
              SpanishCard(value: 4, suit: Suit.bastos),
              SpanishCard(value: 6, suit: Suit.espadas),
            ],
          },
          playedCards: playedCards,
          teamRoundWins: 0,
          opponentRoundWins: 0,
          preserveStrongCards: false,
          teammateHasStrongSignal: false,
          opponentHasStrongSignal: false,
          forceWinIfPossible: false,
          teammateStillToPlay: true,
          opponentStillToPlay: true,
        ),
      );

      expect(hand, contains(card));
    });
  });
}
