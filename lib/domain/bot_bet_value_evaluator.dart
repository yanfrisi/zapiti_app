import 'bot_truco_strategy.dart';
import 'legal_actions.dart';
import 'spanish_card.dart';
import 'truco_rules.dart';

class HandEvaluation {
  final double winProbability;
  final double expectedHandValue;
  final double confidence;

  const HandEvaluation({
    required this.winProbability,
    required this.expectedHandValue,
    required this.confidence,
  });
}

class BotBetValueEvaluator {
  const BotBetValueEvaluator();

  static double openingMarginForDifficulty(int difficulty) =>
      switch (difficulty) {
        >= 5 => 2.1,
        4 => 1.25,
        3 => 1.0,
        _ => 1.0,
      };

  // Empirical monotonic calibration against complete, greedy-played hands.
  static const _calibration = <(double, double)>[
    (0.0, 0.02),
    (0.25, 0.04),
    (0.35, 0.19),
    (0.45, 0.236),
    (0.55, 0.331),
    (0.65, 0.473),
    (0.74, 0.584),
    (0.825, 0.817),
    (1.0, 0.98),
  ];

  static double calibrateWinProbability(double probability) {
    final p = probability.clamp(0.0, 1.0);
    for (var i = 1; i < _calibration.length; i++) {
      final (x1, y1) = _calibration[i];
      if (p <= x1) {
        final (x0, y0) = _calibration[i - 1];
        return y0 + (p - x0) / (x1 - x0) * (y1 - y0);
      }
    }
    return _calibration.last.$2;
  }

  HandEvaluation evaluateHand({
    required Iterable<SpanishCard> ownHand,
    required int cardsOnTable,
    required int teamRoundWins,
    required int opponentRoundWins,
    bool hasStrongSignal = false,
    bool opponentHasStrongSignal = false,
  }) {
    var probability = 0.12 +
        BotTrucoStrategy.evaluateHandStrength(ownHand) * 0.76 +
        (teamRoundWins - opponentRoundWins) * 0.12 +
        (cardsOnTable.clamp(0, 3) * 0.025) +
        (hasStrongSignal ? 0.06 : 0) -
        (opponentHasStrongSignal ? 0.07 : 0);
    probability = calibrateWinProbability(
      probability.clamp(0.05, 0.95).toDouble(),
    );
    return HandEvaluation(
      winProbability: probability,
      expectedHandValue: probability * 3 - (1 - probability),
      confidence: (0.35 + cardsOnTable * 0.12).clamp(0.35, 0.71).toDouble(),
    );
  }

  double actionValue({
    required BetAction action,
    required HandEvaluation hand,
    required int teamScore,
    required int opponentScore,
    required int targetScore,
    required int acceptedValue,
    required int pendingValue,
    required int proposedValue,
    required int difficulty,
  }) {
    int points(int score, int nominal) => TrucoRules.awardedPointsForTeam(
          teamScore: score,
          targetScore: targetScore,
          nominalValue: nominal,
        );

    double utility(int score, int award) {
      final resultingScore = score + award;
      final progress = (resultingScore - score).toDouble();
      final terminal = resultingScore >= targetScore ? targetScore * 1.5 : 0.0;
      return progress + terminal;
    }

    final p = hand.winProbability;
    switch (action.type) {
      case BetActionType.pass:
        return -utility(opponentScore, points(opponentScore, acceptedValue));
      case BetActionType.accept:
        final riskAversion = switch (difficulty) {
          >= 5 => 0.85,
          4 => 0.75,
          3 => 0.45,
          _ => 0.2,
        };
        final exposure = pendingValue * pendingValue / targetScore;
        return p * utility(teamScore, points(teamScore, pendingValue)) -
            (1 - p) *
                utility(opponentScore, points(opponentScore, pendingValue)) -
            riskAversion * (1 - p) * exposure;
      case BetActionType.call:
        final value = action.value ?? proposedValue;
        final current = p *
                utility(teamScore, points(teamScore, acceptedValue)) -
            (1 - p) *
                utility(opponentScore, points(opponentScore, acceptedValue));
        final raised = p * utility(teamScore, points(teamScore, value)) -
            (1 - p) * utility(opponentScore, points(opponentScore, value));
        final foldProbability = (0.12 + (p - 0.5) * 0.25).clamp(0.02, 0.24);
        final raiseValue = foldProbability *
                utility(teamScore, points(teamScore, acceptedValue)) +
            (1 - foldProbability) * raised;
        final riskAversion = difficulty >= 5
            ? 0.18
            : difficulty == 4
                ? 0.12
                : difficulty == 3
                    ? 0.06
                    : 0.0;
        if (value > pendingValue) {
          return raiseValue -
              (difficulty >= 5
                      ? 2.2
                      : difficulty == 4
                          ? 2.0
                          : 1.2) *
                  (1 - p) *
                  value *
                  value /
                  targetScore;
        }
        return (raiseValue - current) - riskAversion * (value - acceptedValue);
    }
  }

  BetAction? chooseAction({
    required List<BetAction> legalActions,
    required HandEvaluation hand,
    required int teamScore,
    required int opponentScore,
    required int targetScore,
    required int acceptedValue,
    required int pendingValue,
    required int difficulty,
  }) {
    if (legalActions.isEmpty) return null;
    final hasResponse = legalActions.any((a) => a.type == BetActionType.accept);
    if (!hasResponse) {
      final call =
          legalActions.where((a) => a.type == BetActionType.call).firstOrNull;
      if (call == null) return null;
      final value = actionValue(
        action: call,
        hand: hand,
        teamScore: teamScore,
        opponentScore: opponentScore,
        targetScore: targetScore,
        acceptedValue: acceptedValue,
        pendingValue: pendingValue,
        proposedValue: call.value!,
        difficulty: difficulty,
      );
      final isOpening =
          pendingValue == 1 && acceptedValue == 1 && call.value == 3;
      if (isOpening) {
        final uncertaintyMargin = (1 - hand.confidence).clamp(0.0, 1.0) * 0.5;
        final difficultyMargin = difficulty >= 5 ? 0.15 : 0.05;
        final openingMargin = openingMarginForDifficulty(difficulty);
        final requiredMargin =
            openingMargin + uncertaintyMargin + difficultyMargin;
        return value > requiredMargin ? call : null;
      }
      return value > 0.0 ? call : null;
    }

    final pass = legalActions.firstWhere((a) => a.type == BetActionType.pass);
    final accept =
        legalActions.firstWhere((a) => a.type == BetActionType.accept);
    final acceptValue = actionValue(
      action: accept,
      hand: hand,
      teamScore: teamScore,
      opponentScore: opponentScore,
      targetScore: targetScore,
      acceptedValue: acceptedValue,
      pendingValue: pendingValue,
      proposedValue: pendingValue,
      difficulty: difficulty,
    );
    final passValue = actionValue(
      action: pass,
      hand: hand,
      teamScore: teamScore,
      opponentScore: opponentScore,
      targetScore: targetScore,
      acceptedValue: acceptedValue,
      pendingValue: pendingValue,
      proposedValue: pendingValue,
      difficulty: difficulty,
    );
    final raise =
        legalActions.where((a) => a.type == BetActionType.call).firstOrNull;
    if (raise != null &&
        actionValue(
              action: raise,
              hand: hand,
              teamScore: teamScore,
              opponentScore: opponentScore,
              targetScore: targetScore,
              acceptedValue: pendingValue,
              pendingValue: pendingValue,
              proposedValue: raise.value!,
              difficulty: difficulty,
            ) >
            acceptValue + 0.5 + (raise.value! - pendingValue) * 0.1) {
      return raise;
    }
    return acceptValue > passValue ? accept : pass;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
