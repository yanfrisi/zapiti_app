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

    test('Monte Carlo conserva la carta baja si la mesa ya esta ganada', () {
      final card = MonteCarloBotPolicy().chooseCard(
        const BotDecisionContext(
          difficulty: 5,
          bot: bot,
          players: players,
          hand: hand,
          hands: {
            'bot': hand,
            'rival': [
              SpanishCard(value: 1, suit: Suit.oros),
            ],
            'mate': [
              SpanishCard(value: 4, suit: Suit.bastos),
            ],
            'rear': [
              SpanishCard(value: 3, suit: Suit.espadas),
            ],
          },
          playedCards: [
            PlayedCard(
              player: rival,
              card: SpanishCard(value: 1, suit: Suit.oros),
            ),
            PlayedCard(
              player: teammate,
              card: SpanishCard(value: 4, suit: Suit.bastos),
            ),
            PlayedCard(
              player: rearRival,
              card: SpanishCard(value: 3, suit: Suit.espadas),
            ),
          ],
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

      expect(card, const SpanishCard(value: 12, suit: Suit.oros));
    });

    test('Monte Carlo descarta la baja si no puede ganar la baza', () {
      final card = MonteCarloBotPolicy().chooseCard(
        const BotDecisionContext(
          difficulty: 5,
          bot: bot,
          players: players,
          hand: hand,
          hands: {
            'bot': hand,
            'rival': [
              SpanishCard(value: 4, suit: Suit.bastos),
            ],
            'mate': [
              SpanishCard(value: 5, suit: Suit.copas),
            ],
            'rear': [
              SpanishCard(value: 6, suit: Suit.espadas),
            ],
          },
          playedCards: [
            PlayedCard(
              player: rival,
              card: SpanishCard(value: 4, suit: Suit.bastos),
            ),
            PlayedCard(
              player: teammate,
              card: SpanishCard(value: 5, suit: Suit.copas),
            ),
            PlayedCard(
              player: rearRival,
              card: SpanishCard(value: 6, suit: Suit.espadas),
            ),
          ],
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

      expect(card, const SpanishCard(value: 12, suit: Suit.oros));
    });

    test('Monte Carlo sigue siendo legal cuando el bot es equipo 1', () {
      const teamOneBot = Player(id: 'bot1', name: 'Bot1', teamId: 1);
      const teamOneMate = Player(id: 'mate1', name: 'Mate1', teamId: 1);
      const teamTwoA = Player(id: 'r1', name: 'R1', teamId: 2);
      const teamTwoB = Player(id: 'r2', name: 'R2', teamId: 2);
      const teamOneHand = [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 12, suit: Suit.oros),
      ];

      final card = MonteCarloBotPolicy().chooseCard(
        const BotDecisionContext(
          difficulty: 5,
          bot: teamOneBot,
          players: [teamOneBot, teamTwoA, teamOneMate, teamTwoB],
          hand: teamOneHand,
          hands: {
            'bot1': teamOneHand,
            'r1': [
              SpanishCard(value: 3, suit: Suit.copas),
              SpanishCard(value: 6, suit: Suit.oros),
            ],
            'mate1': [
              SpanishCard(value: 2, suit: Suit.bastos),
              SpanishCard(value: 5, suit: Suit.copas),
            ],
            'r2': [
              SpanishCard(value: 7, suit: Suit.copas),
              SpanishCard(value: 4, suit: Suit.espadas),
            ],
          },
          playedCards: [],
          teamRoundWins: 1,
          opponentRoundWins: 0,
          preserveStrongCards: false,
          teammateHasStrongSignal: false,
          opponentHasStrongSignal: false,
          forceWinIfPossible: false,
          teammateStillToPlay: true,
          opponentStillToPlay: true,
        ),
      );

      expect(teamOneHand, contains(card));
    });
  });
}
