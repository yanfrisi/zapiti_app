import 'package:zapiti_app/domain/bet_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bot_decision_context.dart';
import 'package:zapiti_app/domain/bot_policy.dart';
import 'package:zapiti_app/domain/monte_carlo_card_selector.dart';
import 'package:zapiti_app/domain/monte_carlo_difficulty_config.dart';
import 'package:zapiti_app/domain/observable_game_state.dart';
import 'package:zapiti_app/domain/played_card.dart';
import 'package:zapiti_app/domain/player.dart';
import 'package:zapiti_app/domain/round_result.dart';
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

  group('Bot policies with prior trick history', () {
    const bot = Player(id: 'bot', name: 'Bot', teamId: 2);
    const rival = Player(id: 'rival', name: 'Rival', teamId: 1);
    const teammate = Player(id: 'mate', name: 'Mate', teamId: 2);
    const rearRival = Player(id: 'rear', name: 'Rear', teamId: 1);
    const players = [rival, teammate, rearRival, bot];
    const hardTestConfig = MonteCarloDifficultyConfig(
      simulationsPerMove: 48,
      rolloutDepth: 8,
      mistakeProbability: 0,
      topCandidateCount: 1,
      useActionInference: true,
      usePartnerModel: true,
      useOpponentProfiles: false,
    );

    RoundResult firstTrickWonBy(Player winner, SpanishCard card) {
      return RoundResult(
        winner: PlayedCard(player: winner, card: card),
        playedCards: [
          PlayedCard(
            player: bot,
            card: winner.id == bot.id
                ? card
                : const SpanishCard(value: 12, suit: Suit.oros),
          ),
          const PlayedCard(
            player: rival,
            card: SpanishCard(value: 6, suit: Suit.copas),
          ),
          PlayedCard(
            player: teammate,
            card: winner.id == teammate.id
                ? card
                : const SpanishCard(value: 5, suit: Suit.bastos),
          ),
          const PlayedCard(
            player: rearRival,
            card: SpanishCard(value: 7, suit: Suit.espadas),
          ),
        ],
      );
    }

    ObservableGameState hardState({
      required List<SpanishCard> botHand,
      required Map<String, List<SpanishCard>> knownHands,
      required List<PlayedCard> playedCards,
      required List<RoundResult> roundHistory,
      required Map<int, int> roundWins,
    }) {
      return ObservableGameState(
        botPlayerId: bot.id,
        players: players,
        botHand: botHand,
        playedCards: playedCards,
        cardsRemainingByPlayerId: {
          for (final player in players) player.id: knownHands[player.id]!.length,
        },
        publiclyKnownCardsByPlayerId: {
          for (final entry in knownHands.entries)
            if (entry.key != bot.id) entry.key: entry.value,
        },
        betState: const BetState(
          acceptedLevel: BetLevel.none,
          proposedLevel: null,
          proposingTeam: null,
          respondingTeam: null,
          lastRaisingTeam: null,
          responsePending: false,
        ),
        score: const {1: 0, 2: 0},
        roundWins: roundWins,
        completedTricks: roundHistory,
        visibleSignals: const [],
        currentPlayerId: bot.id,
        trickLeaderId: rival.id,
      );
    }

    test('normal conserva una carta extrema en segunda si su equipo gano la primera', () {
      const botHand = [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 12, suit: Suit.oros),
      ];
      const secondTrick = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.oros),
        ),
        PlayedCard(
          player: teammate,
          card: SpanishCard(value: 12, suit: Suit.copas),
        ),
        PlayedCard(
          player: rearRival,
          card: SpanishCard(value: 2, suit: Suit.copas),
        ),
      ];
      const hands = {
        'bot': botHand,
        'rival': [
          SpanishCard(value: 5, suit: Suit.oros),
        ],
        'mate': [
          SpanishCard(value: 7, suit: Suit.oros),
        ],
        'rear': [
          SpanishCard(value: 3, suit: Suit.copas),
        ],
      };

      final card = const RolloutBotPolicy(rolloutCount: 24).chooseCard(
        BotDecisionContext(
          difficulty: 3,
          bot: bot,
          players: players,
          hand: botHand,
          hands: hands,
          playedCards: secondTrick,
          teamRoundWins: 1,
          opponentRoundWins: 0,
          preserveStrongCards: true,
          teammateHasStrongSignal: false,
          opponentHasStrongSignal: false,
          forceWinIfPossible: false,
          teammateStillToPlay: false,
          opponentStillToPlay: false,
          roundHistory: [
            firstTrickWonBy(
              bot,
              const SpanishCard(value: 2, suit: Suit.copas),
            ),
          ],
        ),
      );

      expect(card, const SpanishCard(value: 12, suit: Suit.oros));
    });

    test('normal usa carta fuerte si no hacerlo deja la mano perdida', () {
      const botHand = [
        SpanishCard(value: 1, suit: Suit.espadas),
        SpanishCard(value: 12, suit: Suit.oros),
      ];
      const secondTrick = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.oros),
        ),
        PlayedCard(
          player: teammate,
          card: SpanishCard(value: 12, suit: Suit.copas),
        ),
        PlayedCard(
          player: rearRival,
          card: SpanishCard(value: 3, suit: Suit.oros),
        ),
      ];
      const hands = {
        'bot': botHand,
        'rival': [
          SpanishCard(value: 5, suit: Suit.oros),
        ],
        'mate': [
          SpanishCard(value: 7, suit: Suit.oros),
        ],
        'rear': [
          SpanishCard(value: 4, suit: Suit.bastos),
        ],
      };

      final card = const RolloutBotPolicy(rolloutCount: 24).chooseCard(
        BotDecisionContext(
          difficulty: 3,
          bot: bot,
          players: players,
          hand: botHand,
          hands: hands,
          playedCards: secondTrick,
          teamRoundWins: 1,
          opponentRoundWins: 0,
          preserveStrongCards: true,
          teammateHasStrongSignal: false,
          opponentHasStrongSignal: false,
          forceWinIfPossible: false,
          teammateStillToPlay: false,
          opponentStillToPlay: false,
          roundHistory: [
            firstTrickWonBy(
              teammate,
              const SpanishCard(value: 2, suit: Suit.copas),
            ),
          ],
        ),
      );

      expect(card, const SpanishCard(value: 1, suit: Suit.espadas));
    });

    test('cambiar solo el ganador de primera baza altera la evaluacion de segunda', () {
      const botHand = [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 12, suit: Suit.oros),
      ];
      const secondTrick = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.oros),
        ),
        PlayedCard(
          player: teammate,
          card: SpanishCard(value: 12, suit: Suit.copas),
        ),
        PlayedCard(
          player: rearRival,
          card: SpanishCard(value: 2, suit: Suit.copas),
        ),
      ];
      const hands = {
        'bot': botHand,
        'rival': [
          SpanishCard(value: 5, suit: Suit.oros),
        ],
        'mate': [
          SpanishCard(value: 7, suit: Suit.oros),
        ],
        'rear': [
          SpanishCard(value: 3, suit: Suit.copas),
        ],
      };

      final chosenWhenWinning = const RolloutBotPolicy(rolloutCount: 24).chooseCard(
        BotDecisionContext(
          difficulty: 3,
          bot: bot,
          players: players,
          hand: botHand,
          hands: hands,
          playedCards: secondTrick,
          teamRoundWins: 1,
          opponentRoundWins: 0,
          preserveStrongCards: true,
          teammateHasStrongSignal: false,
          opponentHasStrongSignal: false,
          forceWinIfPossible: false,
          teammateStillToPlay: false,
          opponentStillToPlay: false,
          roundHistory: [
            firstTrickWonBy(
              teammate,
              const SpanishCard(value: 2, suit: Suit.copas),
            ),
          ],
        ),
      );

      final chosenWhenLosing = const RolloutBotPolicy(rolloutCount: 24).chooseCard(
        BotDecisionContext(
          difficulty: 3,
          bot: bot,
          players: players,
          hand: botHand,
          hands: hands,
          playedCards: secondTrick,
          teamRoundWins: 0,
          opponentRoundWins: 1,
          preserveStrongCards: true,
          teammateHasStrongSignal: false,
          opponentHasStrongSignal: false,
          forceWinIfPossible: false,
          teammateStillToPlay: false,
          opponentStillToPlay: false,
          roundHistory: [
            firstTrickWonBy(
              rival,
              const SpanishCard(value: 3, suit: Suit.espadas),
            ),
          ],
        ),
      );

      expect(chosenWhenWinning, const SpanishCard(value: 12, suit: Suit.oros));
      expect(chosenWhenLosing, const SpanishCard(value: 4, suit: Suit.bastos));
    });

    test('hard conserva carta fuerte para una tercera baza favorable', () {
      const botHand = [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 12, suit: Suit.oros),
      ];
      const secondTrick = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.oros),
        ),
        PlayedCard(
          player: teammate,
          card: SpanishCard(value: 12, suit: Suit.copas),
        ),
        PlayedCard(
          player: rearRival,
          card: SpanishCard(value: 2, suit: Suit.copas),
        ),
      ];
      const hands = {
        'bot': botHand,
        'rival': [
          SpanishCard(value: 5, suit: Suit.oros),
        ],
        'mate': [
          SpanishCard(value: 7, suit: Suit.oros),
        ],
        'rear': [
          SpanishCard(value: 3, suit: Suit.copas),
        ],
      };

      final selector = MonteCarloCardSelector();
      final card = selector.selectCard(
        botPlayerId: bot.id,
        state: hardState(
          botHand: botHand,
          knownHands: hands,
          playedCards: secondTrick,
          roundHistory: [
            firstTrickWonBy(
              teammate,
              const SpanishCard(value: 2, suit: Suit.copas),
            ),
          ],
          roundWins: const {1: 0, 2: 1},
        ),
        config: hardTestConfig,
      );

      expect(card, const SpanishCard(value: 12, suit: Suit.oros));
    });

    test('hard distingue segunda baza segun quien gano la primera', () {
      const botHand = [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 12, suit: Suit.oros),
      ];
      const secondTrick = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.oros),
        ),
        PlayedCard(
          player: teammate,
          card: SpanishCard(value: 12, suit: Suit.copas),
        ),
        PlayedCard(
          player: rearRival,
          card: SpanishCard(value: 2, suit: Suit.copas),
        ),
      ];
      const hands = {
        'bot': botHand,
        'rival': [
          SpanishCard(value: 5, suit: Suit.oros),
        ],
        'mate': [
          SpanishCard(value: 7, suit: Suit.oros),
        ],
        'rear': [
          SpanishCard(value: 3, suit: Suit.copas),
        ],
      };
      final selector = MonteCarloCardSelector();

      final conserving = selector.selectCard(
        botPlayerId: bot.id,
        state: hardState(
          botHand: botHand,
          knownHands: hands,
          playedCards: secondTrick,
          roundHistory: [
            firstTrickWonBy(
              teammate,
              const SpanishCard(value: 2, suit: Suit.copas),
            ),
          ],
          roundWins: const {1: 0, 2: 1},
        ),
        config: hardTestConfig,
      );
      final forcing = selector.selectCard(
        botPlayerId: bot.id,
        state: hardState(
          botHand: botHand,
          knownHands: hands,
          playedCards: secondTrick,
          roundHistory: [
            firstTrickWonBy(
              rival,
              const SpanishCard(value: 3, suit: Suit.espadas),
            ),
          ],
          roundWins: const {1: 1, 2: 0},
        ),
        config: hardTestConfig,
      );

      expect(conserving, const SpanishCard(value: 12, suit: Suit.oros));
      expect(forcing, const SpanishCard(value: 4, suit: Suit.bastos));
    });

    test('easy sigue siendo legal; normal y hard conservan con la historia correcta', () {
      const botHand = [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 12, suit: Suit.oros),
      ];
      const secondTrick = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.oros),
        ),
        PlayedCard(
          player: teammate,
          card: SpanishCard(value: 12, suit: Suit.copas),
        ),
        PlayedCard(
          player: rearRival,
          card: SpanishCard(value: 2, suit: Suit.copas),
        ),
      ];
      const hands = {
        'bot': botHand,
        'rival': [
          SpanishCard(value: 5, suit: Suit.oros),
        ],
        'mate': [
          SpanishCard(value: 7, suit: Suit.oros),
        ],
        'rear': [
          SpanishCard(value: 3, suit: Suit.copas),
        ],
      };
      final roundHistory = [
        firstTrickWonBy(
          teammate,
          const SpanishCard(value: 2, suit: Suit.copas),
        ),
      ];

      final easy = const HeuristicBotPolicy().chooseCard(
        BotDecisionContext(
          difficulty: 2,
          bot: bot,
          players: players,
          hand: botHand,
          hands: hands,
          playedCards: secondTrick,
          teamRoundWins: 1,
          opponentRoundWins: 0,
          preserveStrongCards: true,
          teammateHasStrongSignal: false,
          opponentHasStrongSignal: false,
          forceWinIfPossible: false,
          teammateStillToPlay: false,
          opponentStillToPlay: false,
          roundHistory: roundHistory,
        ),
      );
      final normal = const RolloutBotPolicy(rolloutCount: 24).chooseCard(
        BotDecisionContext(
          difficulty: 3,
          bot: bot,
          players: players,
          hand: botHand,
          hands: hands,
          playedCards: secondTrick,
          teamRoundWins: 1,
          opponentRoundWins: 0,
          preserveStrongCards: true,
          teammateHasStrongSignal: false,
          opponentHasStrongSignal: false,
          forceWinIfPossible: false,
          teammateStillToPlay: true,
          opponentStillToPlay: true,
          roundHistory: roundHistory,
        ),
      );
      final hard = MonteCarloCardSelector().selectCard(
        botPlayerId: bot.id,
        state: hardState(
          botHand: botHand,
          knownHands: hands,
          playedCards: secondTrick,
          roundHistory: roundHistory,
          roundWins: const {1: 0, 2: 1},
        ),
        config: hardTestConfig,
      );

      expect(botHand, contains(easy));
      expect(normal, const SpanishCard(value: 12, suit: Suit.oros));
      expect(hard, const SpanishCard(value: 12, suit: Suit.oros));
    });
  });
}
