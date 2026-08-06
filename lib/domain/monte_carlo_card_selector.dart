import 'dart:math';

import 'bot_strategy.dart';
import 'monte_carlo_difficulty_config.dart';
import 'observable_game_state.dart';
import 'possible_deal_sampler.dart';
import 'simulation_evaluator.dart';
import 'simulation_game_engine.dart';
import 'simulation_game_state.dart';
import 'simulation_state_factory.dart';
import 'spanish_card.dart';
import 'team_rules.dart';

class ScoredCard {
  final SpanishCard card;
  final double score;
  const ScoredCard(this.card, this.score);
}

class MonteCarloCardSelector {
  final Random random;
  final PossibleDealSampler sampler;
  final SimulationStateFactory stateFactory;
  final SimulationGameEngine engine;
  final SimulationEvaluator evaluator;

  MonteCarloCardSelector({
    Random? random,
    this.sampler = const UniformPossibleDealSampler(),
    this.stateFactory = const DefaultSimulationStateFactory(),
    this.engine = const DefaultSimulationGameEngine(),
    this.evaluator = const TeamSimulationEvaluator(),
  }) : random = random ?? Random();

  SpanishCard selectCard({
    required String botPlayerId,
    required ObservableGameState state,
    required MonteCarloDifficultyConfig config,
  }) {
    final legalCards = state.botHand.toList();
    if (legalCards.isEmpty) {
      return state.botHand.first;
    }
    if (legalCards.length == 1 || config.simulationsPerMove <= 0) {
      return legalCards.first;
    }

    final scored = <ScoredCard>[];
    for (final card in legalCards) {
      var total = 0.0;
      for (var i = 0; i < config.simulationsPerMove; i++) {
        final deal = sampler.sample(state, random);
        final simState = stateFactory.create(
          observableState: state,
          possibleDeal: deal,
        );
        final after = _simulateToEnd(simState, botPlayerId, card, config.rolloutDepth);
        total += evaluator.evaluate(after, botPlayerId);
      }
      scored.add(ScoredCard(card, total / config.simulationsPerMove));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final top = scored.take(config.topCandidateCount).toList();
    return top[random.nextInt(top.length)].card;
  }

  SimulationGameState _simulateToEnd(
    SimulationGameState state,
    String botPlayerId,
    SpanishCard initialCard,
    int rolloutDepth,
  ) {
    var current = engine.playCard(state, botPlayerId, initialCard).nextState;
    var depth = 0;
    while (!engine.isTerminal(current) && depth < max(1, rolloutDepth)) {
      final playerId = current.currentPlayerId;
      final hand = current.playerState(playerId).hand;
      if (hand.isEmpty) break;
      final chosen = _rolloutChoose(current, playerId);
      current = engine.playCard(current, playerId, chosen).nextState;
      depth++;
    }
    return current;
  }

  SpanishCard _rolloutChoose(SimulationGameState state, String playerId) {
    final hand = state.playerState(playerId).hand;
    final playedCards = state.playedCards;
    final players = [for (final p in state.players) p.player];
    final player = players.firstWhere((p) => p.id == playerId);
    final teamId = player.teamId;
    return BotStrategy.chooseCard(
      player: player,
      hand: hand,
      playedCards: playedCards,
      teamRoundWins: state.roundWins[teamId] ?? 0,
      opponentRoundWins: state.roundWins[TeamRules.opponentOf(teamId)] ?? 0,
      preserveStrongCards: true,
      teammateStillToPlay: true,
      opponentStillToPlay: true,
    );
  }
}
