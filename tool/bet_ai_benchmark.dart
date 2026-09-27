import 'dart:io';

import 'package:zapiti_app/domain/bot_bet_value_evaluator.dart';
import 'package:zapiti_app/domain/legal_actions.dart';

void main() {
  const evaluator = BotBetValueEvaluator();
  const legal = [
    BetAction.accept(),
    BetAction.pass(),
    BetAction.call(6),
  ];
  const hand = HandEvaluation(
    winProbability: 0.91,
    expectedHandValue: 2.64,
    confidence: 0.7,
  );

  for (final difficulty in [4, 5]) {
    BetAction? decide() => evaluator.chooseAction(
          legalActions: legal,
          hand: hand,
          teamScore: 12,
          opponentScore: 9,
          targetScore: 30,
          acceptedValue: 1,
          pendingValue: 3,
          difficulty: difficulty,
        );

    for (var warmup = 0; warmup < 20; warmup++) {
      decide();
    }
    final times = <int>[];
    for (var sample = 0; sample < 1000; sample++) {
      final watch = Stopwatch()..start();
      decide();
      watch.stop();
      times.add(watch.elapsedMicroseconds);
    }
    times.sort();
    final mean = times.reduce((a, b) => a + b) / times.length;
    stdout.writeln(
      '${difficulty == 4 ? 'Hard' : 'Expert'} bets: '
      'mean=${mean.toStringAsFixed(2)}us '
      'p50=${percentile(times, 0.50)}us '
      'p95=${percentile(times, 0.95)}us '
      'max=${times.last}us n=${times.length}',
    );
  }
}

int percentile(List<int> sorted, double quantile) =>
    sorted[((sorted.length - 1) * quantile).round()];
