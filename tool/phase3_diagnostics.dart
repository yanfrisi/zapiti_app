import 'dart:math';

import 'package:zapiti_app/domain/ai_match_simulator.dart';
import 'package:zapiti_app/domain/bet_state.dart';
import 'package:zapiti_app/domain/bot_belief_state.dart';
import 'package:zapiti_app/domain/bot_bet_value_evaluator.dart';
import 'package:zapiti_app/domain/bot_strategy.dart';
import 'package:zapiti_app/domain/bot_truco_strategy.dart';
import 'package:zapiti_app/domain/hand_rules.dart';
import 'package:zapiti_app/domain/monte_carlo_card_selector.dart';
import 'package:zapiti_app/domain/monte_carlo_difficulty_config.dart';
import 'package:zapiti_app/domain/observable_game_state.dart';
import 'package:zapiti_app/domain/played_card.dart';
import 'package:zapiti_app/domain/possible_deal_sampler.dart';
import 'package:zapiti_app/domain/round_result.dart';
import 'package:zapiti_app/domain/round_rules.dart';
import 'package:zapiti_app/domain/signal_context.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/team_rules.dart';
import 'package:zapiti_app/domain/suit.dart';
import 'package:zapiti_app/domain/zapiti_deck.dart';
import 'package:zapiti_app/domain/zapiti_players.dart';

const _emptyBet = BetState(
  acceptedLevel: BetLevel.none,
  proposedLevel: null,
  proposingTeam: null,
  respondingTeam: null,
  lastRaisingTeam: null,
  responsePending: false,
);

void main(List<String> args) {
  final mode = args.isEmpty ? 'calibration' : args.first.replaceFirst('--', '');
  switch (mode) {
    case 'calibration':
      runCalibration();
    case 'benchmark':
      runBenchmarks();
    case 'self-play':
      runSelfPlay(args.length > 1 ? int.parse(args[1]) : 500);
    default:
      throw ArgumentError('Use --calibration, --benchmark or --self-play.');
  }
}

void runCalibration() {
  const samples = 2000;
  final random = Random(88219);
  final evaluator = const BotBetValueEvaluator();
  final wins = List<int>.filled(10, 0);
  final counts = List<int>.filled(10, 0);
  final predictions = List<double>.filled(10, 0);
  var rawBrier = 0.0;
  var calibratedBrier = 0.0;
  var calibrationError = 0.0;
  for (var sample = 0; sample < samples; sample++) {
    final deck = ZapitiDeck.shuffled(random: random);
    final hands = <String, List<SpanishCard>>{
      for (var i = 0; i < ZapitiPlayers.tableOrder.length; i++)
        ZapitiPlayers.tableOrder[i].id: deck.skip(i * 3).take(3).toList(),
    };
    final hand = hands['p1']!;
    final rawProbability =
        (0.12 + BotTrucoStrategy.evaluateHandStrength(hand) * 0.76)
            .clamp(0.05, 0.95)
            .toDouble();
    final probability = evaluator
        .evaluateHand(
          ownHand: hand,
          cardsOnTable: 0,
          teamRoundWins: 0,
          opponentRoundWins: 0,
        )
        .winProbability;
    final bucket = min(9, (probability * 10).floor());
    counts[bucket]++;
    predictions[bucket] += probability;
    final outcome = _playHand(hands) == TeamRules.teamOne ? 1.0 : 0.0;
    if (outcome == 1) wins[bucket]++;
    rawBrier += (rawProbability - outcome) * (rawProbability - outcome);
    calibratedBrier += (probability - outcome) * (probability - outcome);
  }
  print('Calibration: $samples random complete deals; BotBetValueEvaluator.');
  print('| Prediction mean | Observed win rate | Samples |');
  print('|---:|---:|---:|');
  for (var bucket = 0; bucket < 10; bucket++) {
    if (counts[bucket] == 0) continue;
    calibrationError +=
        (predictions[bucket] / counts[bucket] - wins[bucket] / counts[bucket])
                .abs() *
            counts[bucket];
    print('| ${(predictions[bucket] / counts[bucket]).toStringAsFixed(3)} | '
        '${(wins[bucket] / counts[bucket]).toStringAsFixed(3)} | ${counts[bucket]} |');
  }
  print('ECE=${(calibrationError / samples).toStringAsFixed(4)} '
      'Brier raw=${(rawBrier / samples).toStringAsFixed(4)} '
      'calibrated=${(calibratedBrier / samples).toStringAsFixed(4)}');
  print('Outcome policy: BotStrategy greedy continuation, no truco/seignals.');
}

int? _playHand(Map<String, List<SpanishCard>> hands) {
  var leaderIndex = 0;
  final tricks = <RoundResult>[];
  var progress = HandRules.resolve(tricks);
  for (var trickNumber = 0; trickNumber < 3; trickNumber++) {
    final table = <PlayedCard>[];
    for (var offset = 0; offset < ZapitiPlayers.tableOrder.length; offset++) {
      final player = ZapitiPlayers.tableOrder[(leaderIndex + offset) % 4];
      final own = hands[player.id]!;
      final card = BotStrategy.chooseCard(
        player: player,
        hand: own,
        playedCards: table,
        teamRoundWins: progress.roundWinsFor(player.teamId),
        opponentRoundWins:
            progress.roundWinsFor(TeamRules.opponentOf(player.teamId)),
        teammateStillToPlay: offset < 2,
        opponentStillToPlay: offset < 3,
      );
      own.remove(card);
      table.add(PlayedCard(player: player, card: card));
    }
    final result = RoundRules.resolveRound(table);
    tricks.add(result);
    progress = HandRules.resolve(tricks);
    if (result.winner != null) {
      leaderIndex = ZapitiPlayers.tableOrder.indexWhere(
        (player) => player.id == result.winner!.player.id,
      );
    }
    if (progress.isFinished) return progress.winningTeamId;
  }
  return progress.winningTeamId;
}

ObservableGameState _benchmarkState() => const ObservableGameState(
      botPlayerId: 'p1',
      players: ZapitiPlayers.tableOrder,
      botHand: [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 7, suit: Suit.copas),
        SpanishCard(value: 3, suit: Suit.oros),
      ],
      playedCards: [],
      cardsRemainingByPlayerId: {'p1': 3, 'p2': 3, 'p3': 3, 'p4': 3},
      publiclyKnownCardsByPlayerId: {},
      currentPlayerId: 'p1',
      trickLeaderId: 'p1',
      betState: _emptyBet,
      score: {1: 0, 2: 0},
      roundWins: {1: 0, 2: 0},
      visibleSignals: [],
      signalContext: SignalContext.empty,
    );

void runBenchmarks() {
  final state = _benchmarkState();
  const sampler = InferenceBiasedPossibleDealSampler(
    useActionInference: true,
    usePartnerModel: true,
    useOpponentProfiles: true,
    useSignalInference: true,
    useBetInference: true,
  );
  final beliefTimes = <int>[];
  final dealTimes = <int>[];
  for (var i = 0; i < 1000; i++) {
    var watch = Stopwatch()..start();
    BotBeliefState.fromObservable(state);
    watch.stop();
    beliefTimes.add(watch.elapsedMicroseconds);
    watch = Stopwatch()..start();
    sampler.sample(state, Random(i));
    watch.stop();
    dealTimes.add(watch.elapsedMicroseconds);
  }
  _printTiming('belief build', beliefTimes);
  _printTiming('determinization', dealTimes);
  for (final entry in [
    ('Hard', MonteCarloDifficultyConfigs.hard),
    ('Expert', MonteCarloDifficultyConfigs.expert),
  ]) {
    final times = <int>[];
    final selector = MonteCarloCardSelector(sampler: sampler);
    for (var seed = 0; seed < 2; seed++) {
      selector.selectCard(botPlayerId: 'p1', state: state, config: entry.$2);
    }
    for (var seed = 0; seed < 20; seed++) {
      final watch = Stopwatch()..start();
      selector.selectCard(botPlayerId: 'p1', state: state, config: entry.$2);
      watch.stop();
      times.add(watch.elapsedMicroseconds);
    }
    _printTiming('${entry.$1} complete card decision', times);
  }
}

void _printTiming(String label, List<int> values) {
  final sorted = [...values]..sort();
  int at(double percentile) =>
      sorted[((sorted.length - 1) * percentile).round()];
  final mean = values.fold<int>(0, (sum, value) => sum + value) / values.length;
  print('$label: n=${values.length} mean=${mean.toStringAsFixed(1)}us '
      'p50=${at(0.50)}us p95=${at(0.95)}us max=${sorted.last}us');
}

void runSelfPlay(int matches) {
  const simulator = AiMatchSimulator();
  for (final matchup in [
    ('Hard-Hard', 4, 4),
    ('Expert-Expert', 5, 5),
    ('Hard-Expert', 4, 5),
  ]) {
    print('Starting ${matchup.$1} diagnostic match.');
    var lastProgress = DateTime.now();
    final watch = Stopwatch()..start();
    final summary = simulator.run(AiSimulationConfig(
      matches: matches,
      seed: 309,
      teamOneDifficulty: matchup.$2,
      teamTwoDifficulty: matchup.$3,
      maxHandsPerMatch: 120,
      onProgress: (hand, round, turn) {
        if (DateTime.now().difference(lastProgress).inSeconds >= 5) {
          lastProgress = DateTime.now();
          print(
            '${matchup.$1}: progress hand=$hand round=$round turn=$turn '
            'elapsed=${watch.elapsed.inSeconds}s',
          );
        }
      },
    ));
    watch.stop();
    print('${matchup.$1}: complete=${summary.completedMatches} '
        'aborted=${summary.abortedMatches} '
        'wins=${summary.teamOneWins}-${summary.teamTwoWins} '
        'hands=${summary.totalHands} avgHands=${summary.averageHandsPerMatch.toStringAsFixed(1)} '
        'calls=${summary.totalTrucoCalls} raises=${summary.totalTrucoRaises} '
        'accept=${summary.totalTrucoAccepts} noQuiero=${summary.totalTrucoPasses} '
        'noQuieroRate=${(summary.trucoPassRate * 100).toStringAsFixed(1)}% '
        'AlVer-played=${summary.totalAlVerPlayed} invalid=0 '
        'decisionMean=${summary.averageDecisionMicros.toStringAsFixed(0)}us '
        'decisionP50=${summary.p50DecisionMicros}us '
        'decisionP95=${summary.p95DecisionMicros}us '
        'elapsed=${watch.elapsedMilliseconds}ms '
        'meanMatch=${(watch.elapsedMilliseconds / matches).toStringAsFixed(1)}ms '
        'betLevels=${summary.betCallsByValue} '
        'handsByMaxBet=${_orderedBetLevelCounts(summary.handsByMaxBetValue)} '
        'openingTrucoProbabilityBuckets='
        '${_probabilityBuckets(summary.openingTrucoWinProbabilities)}');
  }
}

Map<String, int> _orderedBetLevelCounts(Map<int, int> counts) => {
      'none': counts[0] ?? 0,
      for (final value in [3, 6, 9, 12, 15, 30]) '$value': counts[value] ?? 0,
    };

Map<String, int> _probabilityBuckets(List<double> probabilities) {
  final counts = <String, int>{};
  for (final probability in probabilities) {
    final lower = (probability * 10).floor().clamp(0, 9);
    final label = '$lower-${lower + 1}';
    counts.update(label, (count) => count + 1, ifAbsent: () => 1);
  }
  return counts;
}
// ignore_for_file: avoid_print
