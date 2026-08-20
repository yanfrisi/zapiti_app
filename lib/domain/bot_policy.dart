import 'dart:math';

import 'bot_decision_context.dart';
import 'bot_rollout_evaluator.dart';
import 'bot_strategy.dart';
import 'difficulty_profile.dart';
import 'monte_carlo_card_selector.dart';
import 'monte_carlo_difficulty_config.dart';
import 'observable_game_state.dart';
import 'spanish_card.dart';

abstract interface class BotPolicy {
  SpanishCard chooseCard(BotDecisionContext context);
}

class HeuristicBotPolicy implements BotPolicy {
  const HeuristicBotPolicy();

  @override
  SpanishCard chooseCard(BotDecisionContext context) {
    return BotStrategy.chooseCard(
      player: context.bot,
      hand: context.hand,
      playedCards: context.playedCards,
      teamRoundWins: context.teamRoundWins,
      opponentRoundWins: context.opponentRoundWins,
      preserveStrongCards: context.preserveStrongCards,
      teammateHasStrongSignal: context.teammateHasStrongSignal,
      opponentHasStrongSignal: context.opponentHasStrongSignal,
      forceWinIfPossible: context.forceWinIfPossible,
      teammateStillToPlay: context.teammateStillToPlay,
      opponentStillToPlay: context.opponentStillToPlay,
    );
  }
}

class RolloutBotPolicy implements BotPolicy {
  final int handValueEstimate;
  final int rolloutCount;

  const RolloutBotPolicy({
    this.handValueEstimate = 1,
    this.rolloutCount = 12,
  });

  @override
  SpanishCard chooseCard(BotDecisionContext context) {
    return BotStrategy.chooseCardWithLookahead(
      difficulty: context.difficulty,
      player: context.bot,
      hand: context.hand,
      playedCards: context.playedCards,
      players: context.players,
      hands: context.hands,
      teamRoundWins: context.teamRoundWins,
      opponentRoundWins: context.opponentRoundWins,
      preserveStrongCards: context.preserveStrongCards,
      teammateHasStrongSignal: context.teammateHasStrongSignal,
      opponentHasStrongSignal: context.opponentHasStrongSignal,
      forceWinIfPossible: context.forceWinIfPossible,
      teammateStillToPlay: context.teammateStillToPlay,
      opponentStillToPlay: context.opponentStillToPlay,
      roundHistory: context.roundHistory,
      rolloutCount: rolloutCount,
    );
  }
}

class MonteCarloBotPolicy implements BotPolicy {
  final MonteCarloCardSelector selector;

  MonteCarloBotPolicy({
    MonteCarloCardSelector? selector,
  }) : selector = selector ?? MonteCarloCardSelector();

  @override
  SpanishCard chooseCard(BotDecisionContext context) {
    final observable = ObservableGameState(
      botPlayerId: context.bot.id,
      players: context.players,
      botHand: context.hand,
      playedCards: context.playedCards,
      cardsRemainingByPlayerId: {
        for (final player in context.players)
          player.id: context.hands[player.id]?.length ?? 0,
      },
      publiclyKnownCardsByPlayerId: const {},
      currentPlayerId: context.bot.id,
      trickLeaderId:
          context.playedCards.isEmpty ? context.bot.id : context.playedCards.first.player.id,
      betState: context.betState,
      score: context.score,
      roundWins: {
        context.bot.teamId: context.teamRoundWins,
        3 - context.bot.teamId: context.opponentRoundWins,
      },
      completedTricks: context.roundHistory,
      visibleSignals: const [],
      signalContext: context.signalContext.visibleToTeam(context.bot.teamId),
      handVersion: context.handVersion,
      trickIndex: context.trickIndex,
    );
    return selector.selectCard(
      botPlayerId: context.bot.id,
      state: observable,
      config: MonteCarloDifficultyConfigs.forDifficulty(context.difficulty),
    );
  }
}

class IsmctsBotPolicy implements BotPolicy {
  final int iterations;
  final int handValueEstimate;
  final double exploration;

  const IsmctsBotPolicy({
    this.iterations = 48,
    this.handValueEstimate = 1,
    this.exploration = 1.15,
  });

  @override
  SpanishCard chooseCard(BotDecisionContext context) {
    final sorted = [...context.hand]..sort(
      (a, b) => BotStrategy.compareByStrength(a, b),
    );
    final stats = {
      for (final candidate in sorted) candidate: _RootActionStats(),
    };

    for (var step = 0; step < iterations; step++) {
      final totalVisits = stats.values.fold<int>(0, (sum, stat) => sum + stat.visits);
      final candidate = _selectAction(sorted, stats, totalVisits);
      final reward = BotRolloutEvaluator.evaluateCardOnce(
        player: context.bot,
        candidate: candidate,
        hand: context.hand,
        playedCards: context.playedCards,
        players: context.players,
        hands: context.hands,
        teamRoundWins: context.teamRoundWins,
        opponentRoundWins: context.opponentRoundWins,
        roundHistory: context.roundHistory,
        handValue: handValueEstimate,
        rolloutIndex: step,
      );
      stats[candidate]!.record(reward);
    }

    return sorted.reduce((best, candidate) {
      final bestStats = stats[best]!;
      final candidateStats = stats[candidate]!;
      final bestValue = bestStats.meanValue - BotStrategy.strengthOf(best) / 1000;
      final candidateValue =
          candidateStats.meanValue - BotStrategy.strengthOf(candidate) / 1000;
      if (candidateStats.visits > bestStats.visits) return candidate;
      if (candidateStats.visits == bestStats.visits &&
          candidateValue > bestValue) {
        return candidate;
      }
      return best;
    });
  }

  SpanishCard _selectAction(
    List<SpanishCard> sorted,
    Map<SpanishCard, _RootActionStats> stats,
    int totalVisits,
  ) {
    for (final candidate in sorted) {
      if (stats[candidate]!.visits == 0) return candidate;
    }
    return sorted.reduce((best, candidate) {
      final bestScore = stats[best]!.uctScore(
        totalVisits: totalVisits,
        exploration: exploration,
      );
      final candidateScore = stats[candidate]!.uctScore(
        totalVisits: totalVisits,
        exploration: exploration,
      );
      if (candidateScore > bestScore) return candidate;
      return best;
    });
  }
}

class _RootActionStats {
  int visits = 0;
  double totalValue = 0;

  double get meanValue => visits == 0 ? 0 : totalValue / visits;

  void record(double value) {
    visits += 1;
    totalValue += value;
  }

  double uctScore({
    required int totalVisits,
    required double exploration,
  }) {
    if (visits == 0) return double.infinity;
    return meanValue + exploration * sqrt(log(totalVisits) / visits);
  }
}

class BotPolicySelector {
  const BotPolicySelector._();

  static BotPolicy forDifficulty(int difficulty) {
    final profile = DifficultyProfiles.byLevel(difficulty);
    if (profile.level >= 4) {
      return MonteCarloBotPolicy();
    }
    if (profile.level == 3) {
      return const RolloutBotPolicy();
    }
    return const HeuristicBotPolicy();
  }
}
