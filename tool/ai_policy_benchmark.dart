import 'dart:io';

import 'package:zapiti_app/domain/bet_state.dart';
import 'package:zapiti_app/domain/bot_bet_value_evaluator.dart';
import 'package:zapiti_app/domain/legal_actions.dart';
import 'package:zapiti_app/domain/monte_carlo_card_selector.dart';
import 'package:zapiti_app/domain/monte_carlo_difficulty_config.dart';
import 'package:zapiti_app/domain/observable_game_state.dart';
import 'package:zapiti_app/domain/player.dart';
import 'package:zapiti_app/domain/signal_context.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';

void main() {
  const players = [
    Player(id: 'bot', name: 'Bot', teamId: 1),
    Player(id: 'rival-a', name: 'Rival A', teamId: 2),
    Player(id: 'mate', name: 'Mate', teamId: 1),
    Player(id: 'rival-b', name: 'Rival B', teamId: 2),
  ];
  const state = ObservableGameState(
    botPlayerId: 'bot',
    players: players,
    botHand: [
      SpanishCard(value: 4, suit: Suit.bastos),
      SpanishCard(value: 2, suit: Suit.copas),
      SpanishCard(value: 12, suit: Suit.oros),
    ],
    playedCards: [],
    cardsRemainingByPlayerId: {'bot': 3, 'rival-a': 3, 'mate': 3, 'rival-b': 3},
    publiclyKnownCardsByPlayerId: {},
    currentPlayerId: 'bot',
    trickLeaderId: 'bot',
    betState: BetState(
      acceptedLevel: BetLevel.none,
      proposedLevel: null,
      proposingTeam: null,
      respondingTeam: null,
      lastRaisingTeam: null,
      responsePending: false,
    ),
    score: {1: 0, 2: 0},
    roundWins: {1: 0, 2: 0},
    visibleSignals: [],
    signalContext: SignalContext.empty,
  );
  final selector = MonteCarloCardSelector();
  const betEvaluator = BotBetValueEvaluator();

  for (final entry in [
    ('Hard', MonteCarloDifficultyConfigs.hard),
    ('Expert', MonteCarloDifficultyConfigs.expert),
  ]) {
    for (var warmup = 0; warmup < 2; warmup++) {
      selector.selectCard(
        botPlayerId: state.botPlayerId,
        state: state,
        config: entry.$2,
      );
    }

    final times = <int>[];
    for (var sample = 0; sample < 20; sample++) {
      final watch = Stopwatch()..start();
      selector.selectCard(
        botPlayerId: state.botPlayerId,
        state: state,
        config: entry.$2,
      );
      watch.stop();
      times.add(watch.elapsedMicroseconds);
    }
    times.sort();
    final mean = times.reduce((a, b) => a + b) / times.length;
    final median = percentile(times, 0.50);
    stdout.writeln(
      '${entry.$1} cards: mean=${mean.round()}us p50=${median}us '
      'p95=${percentile(times, 0.95)}us max=${times.last}us n=${times.length}',
    );

    const hand = HandEvaluation(
      winProbability: 0.91,
      expectedHandValue: 2.64,
      confidence: 0.7,
    );
    const legalBetActions = [
      BetAction.accept(),
      BetAction.pass(),
      BetAction.call(6),
    ];
    for (var warmup = 0; warmup < 10; warmup++) {
      betEvaluator.chooseAction(
        legalActions: legalBetActions,
        hand: hand,
        teamScore: 12,
        opponentScore: 9,
        targetScore: 30,
        acceptedValue: 1,
        pendingValue: 3,
        difficulty: entry.$1 == 'Hard' ? 4 : 5,
      );
    }
    final betTimes = <int>[];
    for (var sample = 0; sample < 100; sample++) {
      final watch = Stopwatch()..start();
      betEvaluator.chooseAction(
        legalActions: legalBetActions,
        hand: hand,
        teamScore: 12,
        opponentScore: 9,
        targetScore: 30,
        acceptedValue: 1,
        pendingValue: 3,
        difficulty: entry.$1 == 'Hard' ? 4 : 5,
      );
      watch.stop();
      betTimes.add(watch.elapsedMicroseconds);
    }
    betTimes.sort();
    final betMean = betTimes.reduce((a, b) => a + b) / betTimes.length;
    stdout.writeln(
      '${entry.$1} bets: mean=${betMean.round()}us '
      'p50=${percentile(betTimes, 0.50)}us '
      'p95=${percentile(betTimes, 0.95)}us '
      'max=${betTimes.last}us n=${betTimes.length}',
    );
  }
}

int percentile(List<int> sorted, double quantile) =>
    sorted[((sorted.length - 1) * quantile).round()];

