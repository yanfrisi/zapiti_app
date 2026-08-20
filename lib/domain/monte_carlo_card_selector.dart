import 'dart:math';

import 'bot_strategy.dart';
import 'bot_table_read.dart';
import 'monte_carlo_difficulty_config.dart';
import 'observable_game_state.dart';
import 'played_card.dart';
import 'round_rules.dart';
import 'player.dart';
import 'possible_deal_sampler.dart';
import 'signal_context.dart';
import 'simulation_evaluator.dart';
import 'simulation_game_engine.dart';
import 'simulation_game_state.dart';
import 'simulation_state_factory.dart';
import 'spanish_card.dart';
import 'team_rules.dart';
import 'zapiti_rules.dart';

class ScoredCard {
  final SpanishCard card;
  final double score;
  const ScoredCard(this.card, this.score);
}

class MonteCarloCardSelector {
  static const _expectedValueWeight = 1.0;
  static const _robustnessWeight = 0.24;
  static const _riskPenaltyWeight = 0.18;
  static const _opportunityCostWeight = 0.12;

  final PossibleDealSampler sampler;
  final SimulationStateFactory stateFactory;
  final SimulationGameEngine engine;
  final SimulationEvaluator evaluator;

  MonteCarloCardSelector({
    this.sampler = const UniformPossibleDealSampler(),
    this.stateFactory = const DefaultSimulationStateFactory(),
    this.engine = const DefaultSimulationGameEngine(),
    this.evaluator = const TeamSimulationEvaluator(),
  });

  SpanishCard selectCard({
    required String botPlayerId,
    required ObservableGameState state,
    required MonteCarloDifficultyConfig config,
  }) {
    final baseSeed = _stableSeed(
      botPlayerId: botPlayerId,
      state: state,
      config: config,
    );
    final random = Random(baseSeed);
    final legalCards = [...state.botHand];
    if (legalCards.isEmpty) {
      return state.botHand.first;
    }
    if (legalCards.length == 1 || config.simulationsPerMove <= 0) {
      return legalCards.first;
    }

    final currentWinningTeam = BotTableRead.currentWinningTeamOnTable(
      state.playedCards,
    );
    final bot = state.players.firstWhere((player) => player.id == botPlayerId);
    if (currentWinningTeam == bot.teamId &&
        state.playedCards.length == state.players.length - 1) {
      final sorted = [...legalCards]..sort(BotStrategy.compareByStrength);
      return sorted.first;
    }

    final preservationChoice = _knownThirdTrickPreservationChoice(
      state: state,
      bot: bot,
      legalCards: legalCards,
    );
    if (preservationChoice != null) {
      return preservationChoice;
    }

    final rolloutProfiles = _buildRolloutProfiles(
      state: state,
      botPlayerId: botPlayerId,
      config: config,
    );
    final samplerToUse = _samplerForConfig(config);
    final stageOneSamples = min(
      config.simulationsPerMove,
      max(8, legalCards.length * 6),
    );
    final stageOneDeals = List.generate(
      stageOneSamples,
      (index) => samplerToUse.sample(
        state,
        Random(_mixSeed(baseSeed, index)),
      ),
      growable: false,
    );
    final valueCache = <int, double>{};

    final aggregates = <SpanishCard, _CardAggregate>{
      for (final card in legalCards)
        card: _CardAggregate(
          card: card,
          prior: _staticCardPrior(
            botPlayerId: botPlayerId,
            state: state,
            card: card,
          ),
        ),
    };
    _evaluateDeals(
      deals: stageOneDeals,
      cards: legalCards,
      botPlayerId: botPlayerId,
      state: state,
      config: config,
      valueCache: valueCache,
      rolloutProfiles: rolloutProfiles,
      aggregates: aggregates,
    );

    final orderedAfterStageOne = aggregates.values.toList()
      ..sort((a, b) => b.meanScore.compareTo(a.meanScore));
    final survivorCount = min(
      legalCards.length,
      max(config.topCandidateCount, min(legalCards.length, 2)),
    );
    final survivors = orderedAfterStageOne.take(survivorCount).toList();
    final remainingSamples = config.simulationsPerMove - stageOneSamples;

    if (remainingSamples > 0 && survivors.isNotEmpty) {
      final survivorCards = [for (final aggregate in survivors) aggregate.card];
      final stageTwoDeals = List.generate(
        remainingSamples,
        (index) => samplerToUse.sample(
          state,
          Random(_mixSeed(baseSeed, stageOneSamples + index)),
        ),
        growable: false,
      );
      _evaluateDeals(
        deals: stageTwoDeals,
        cards: survivorCards,
        botPlayerId: botPlayerId,
        state: state,
        config: config,
        valueCache: valueCache,
        rolloutProfiles: rolloutProfiles,
        aggregates: aggregates,
      );
    }

    final scored = aggregates.values
        .map((entry) => ScoredCard(entry.card, entry.meanScore))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final orderAware = _orderAwareChoice(
      botPlayerId: botPlayerId,
      state: state,
      scored: scored,
    );
    if (orderAware != null) return orderAware;
    final top = scored.take(config.topCandidateCount).toList();
    return top[random.nextInt(top.length)].card;
  }

  SpanishCard? _knownThirdTrickPreservationChoice({
    required ObservableGameState state,
    required Player bot,
    required List<SpanishCard> legalCards,
  }) {
    final opponentTeamId = TeamRules.opponentOf(bot.teamId);
    if ((state.roundWins[bot.teamId] ?? 0) <=
        (state.roundWins[opponentTeamId] ?? 0)) {
      return null;
    }
    if (state.playedCards.length != state.players.length - 1) {
      return null;
    }
    if (legalCards.length <= 1) return null;
    for (final player in state.players) {
      if (player.id == bot.id) continue;
      final known = state.publiclyKnownCardsByPlayerId[player.id];
      final expected = state.cardsRemainingByPlayerId[player.id] ?? 0;
      if (known == null || known.length != expected) {
        return null;
      }
    }

    final sorted = [...legalCards]..sort(BotStrategy.compareByStrength);
    final weakest = sorted.first;
    final result = RoundRules.resolveRound([
      ...state.playedCards,
      PlayedCard(player: bot, card: weakest),
    ]);
    if (result.winningTeamId == bot.teamId) {
      return null;
    }

    SpanishCard? strongestRemaining;
    int? strongestTeamId;
    for (final player in state.players) {
      final cards = player.id == bot.id
          ? sorted.skip(1)
          : (state.publiclyKnownCardsByPlayerId[player.id] ?? const <SpanishCard>[]);
      for (final card in cards) {
        if (strongestRemaining == null ||
            ZapitiRules.strength(card) > ZapitiRules.strength(strongestRemaining)) {
          strongestRemaining = card;
          strongestTeamId = player.teamId;
        }
      }
    }
    if (strongestRemaining == null || strongestTeamId != bot.teamId) {
      return null;
    }
    return weakest;
  }

  SpanishCard? _orderAwareChoice({
    required String botPlayerId,
    required ObservableGameState state,
    required List<ScoredCard> scored,
  }) {
    if (scored.isEmpty) return null;
    final bot = state.players.firstWhere((player) => player.id == botPlayerId);
    final signalBias = _observableSignalBiasForPlayer(state, bot);
    final bestScore = scored.first.score;
    final tableStrength = BotTableRead.bestTableStrength(state.playedCards) ?? -1;

    if (signalBias.mustWin) {
      final winning = scored
          .where((entry) => ZapitiRules.strength(entry.card) > tableStrength)
          .toList()
        ..sort((a, b) => BotStrategy.compareByStrength(a.card, b.card));
      if (winning.isNotEmpty && winning.first.score >= bestScore - 60) {
        return winning.first.card;
      }
    }

    if (signalBias.conserveResources) {
      final conservative = [...scored]
        ..sort((a, b) => BotStrategy.compareByStrength(a.card, b.card));
      if (conservative.first.score >= bestScore - 70) {
        return conservative.first.card;
      }
    }

    return null;
  }

  PossibleDealSampler _samplerForConfig(MonteCarloDifficultyConfig config) {
    if (!config.useActionInference &&
        !config.usePartnerModel &&
        !config.useOpponentProfiles) {
      return sampler;
    }
    return InferenceBiasedPossibleDealSampler(
      useActionInference: config.useActionInference,
      usePartnerModel: config.usePartnerModel,
      useOpponentProfiles: config.useOpponentProfiles,
    );
  }

  void _evaluateDeals({
    required List<PossibleDeal> deals,
    required List<SpanishCard> cards,
    required String botPlayerId,
    required ObservableGameState state,
    required MonteCarloDifficultyConfig config,
    required Map<int, double> valueCache,
    required Map<String, _RolloutProfile> rolloutProfiles,
    required Map<SpanishCard, _CardAggregate> aggregates,
  }) {
    for (final card in cards) {
      final aggregate = aggregates[card]!;
      for (final deal in deals) {
        final simState = stateFactory.create(
          observableState: state,
          possibleDeal: deal,
        );
        final afterInitial = engine.playCard(simState, botPlayerId, card).nextState;
        final value = _evaluateState(
          state: afterInitial,
          botPlayerId: botPlayerId,
          remainingDepth: max(1, config.rolloutDepth) - 1,
          valueCache: valueCache,
          rolloutProfiles: rolloutProfiles,
        );
        aggregate.record(value);
      }
    }
  }

  double _evaluateState({
    required SimulationGameState state,
    required String botPlayerId,
    required int remainingDepth,
    required Map<int, double> valueCache,
    required Map<String, _RolloutProfile> rolloutProfiles,
  }) {
    final cacheKey = _stateCacheKey(
      state: state,
      botPlayerId: botPlayerId,
      remainingDepth: remainingDepth,
    );
    final cached = valueCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    if (engine.isTerminal(state) || remainingDepth <= 0) {
      final score = evaluator.evaluate(state, botPlayerId);
      valueCache[cacheKey] = score;
      return score;
    }

    final playerId = state.currentPlayerId;
    final hand = state.playerState(playerId).hand;
    if (hand.isEmpty) {
      final score = evaluator.evaluate(state, botPlayerId);
      valueCache[cacheKey] = score;
      return score;
    }

    final chosen = _rolloutChoose(
      state,
      playerId,
      rolloutProfiles[playerId] ?? const _RolloutProfile(),
    );
    final nextState = engine.playCard(state, playerId, chosen).nextState;
    final score = _evaluateState(
      state: nextState,
      botPlayerId: botPlayerId,
      remainingDepth: remainingDepth - 1,
      valueCache: valueCache,
      rolloutProfiles: rolloutProfiles,
    );
    valueCache[cacheKey] = score;
    return score;
  }

  SpanishCard _rolloutChoose(
    SimulationGameState state,
    String playerId,
    _RolloutProfile profile,
  ) {
    final hand = state.playerState(playerId).hand;
    final playedCards = state.playedCards;
    final players = [for (final p in state.players) p.player];
    final player = players.firstWhere((p) => p.id == playerId);
    final teamId = player.teamId;
    final opponentTeamId = TeamRules.opponentOf(teamId);
    final currentWinningTeam = BotTableRead.currentWinningTeamOnTable(playedCards);
    final teammateHasStrongSignal = state.signalContext
        .visibleToTeam(teamId)
        .teamHasObservedStrongCardSignal(teamId);
    final opponentHasStrongSignal = state.signalContext
        .visibleToTeam(teamId)
        .teamHasObservedStrongCardSignal(opponentTeamId);
    final signalBias = _signalBiasForPlayer(state, player);
    final preserveStrongCards =
        currentWinningTeam == teamId ||
        teammateHasStrongSignal ||
        signalBias.conserveResources ||
        (state.roundWins[teamId] ?? 0) > (state.roundWins[opponentTeamId] ?? 0) ||
        profile.conservation >= 0.65;
    final forceWinIfPossible =
        (state.roundWins[opponentTeamId] ?? 0) > (state.roundWins[teamId] ?? 0) &&
        (!teammateHasStrongSignal || profile.aggression >= 0.7) ||
        signalBias.mustWin;

    final baseline = BotStrategy.chooseCard(
      player: player,
      hand: hand,
      playedCards: playedCards,
      teamRoundWins: state.roundWins[teamId] ?? 0,
      opponentRoundWins: state.roundWins[opponentTeamId] ?? 0,
      preserveStrongCards: preserveStrongCards,
      teammateHasStrongSignal: teammateHasStrongSignal,
      opponentHasStrongSignal: opponentHasStrongSignal,
      forceWinIfPossible: forceWinIfPossible,
      teammateStillToPlay: _teammateStillToPlay(state, player),
      opponentStillToPlay: _opponentStillToPlay(state, player),
    );
    if (hand.length <= 1) {
      return baseline;
    }

    final sorted = [...hand]..sort(BotStrategy.compareByStrength);
    final bestStrength = BotTableRead.bestTableStrength(playedCards) ?? -1;
    final winningCards = sorted
        .where((card) => ZapitiRules.strength(card) > bestStrength)
        .toList(growable: false);
    final tyingCards = sorted
        .where((card) => ZapitiRules.strength(card) == bestStrength)
        .toList(growable: false);

    if (signalBias.conserveResources && currentWinningTeam == teamId) {
      return sorted.first;
    }
    if (signalBias.mustWin && winningCards.isNotEmpty) {
      return winningCards.first;
    }
    if (profile.cooperation >= 0.75 &&
        currentWinningTeam == teamId &&
        sorted.isNotEmpty) {
      return sorted.first;
    }
    if (profile.aggression >= 0.72 && winningCards.isNotEmpty) {
      return winningCards.last;
    }
    if (profile.conservation >= 0.72) {
      if (currentWinningTeam == teamId) {
        return sorted.first;
      }
      if (winningCards.isNotEmpty) {
        return winningCards.first;
      }
      if (tyingCards.isNotEmpty) {
        return tyingCards.first;
      }
    }
    return baseline;
  }

  Map<String, _RolloutProfile> _buildRolloutProfiles({
    required ObservableGameState state,
    required String botPlayerId,
    required MonteCarloDifficultyConfig config,
  }) {
    final botTeamId =
        state.players.firstWhere((player) => player.id == botPlayerId).teamId;
    final profiles = <String, _RolloutProfile>{};

    for (final player in state.players) {
      var aggression = 0.52;
      var conservation = 0.52;
      var cooperation = player.teamId == botTeamId ? 0.55 : 0.40;

      final playedByPlayer =
          state.playedCards.where((played) => played.player.id == player.id).toList();
      if (config.useActionInference && playedByPlayer.isNotEmpty) {
        final averageStrength = playedByPlayer
                .map((entry) => ZapitiRules.strength(entry.card))
                .fold<int>(0, (sum, value) => sum + value) /
            playedByPlayer.length;
        if (averageStrength >= 80) {
          aggression += 0.18;
          conservation -= 0.12;
        } else if (averageStrength <= 35) {
          aggression -= 0.10;
          conservation += 0.16;
        }
      }

      if (config.usePartnerModel && player.teamId == botTeamId) {
        cooperation += 0.20;
        conservation += 0.06;
      }

      if (config.useOpponentProfiles && player.teamId != botTeamId) {
        final seatIndex = state.players.indexWhere((entry) => entry.id == player.id);
        if (seatIndex.isEven) {
          aggression += 0.06;
        } else {
          conservation += 0.06;
        }
      }

      profiles[player.id] = _RolloutProfile(
        aggression: aggression.clamp(0.2, 0.9),
        conservation: conservation.clamp(0.2, 0.9),
        cooperation: cooperation.clamp(0.2, 0.95),
      );
    }

    return profiles;
  }

  int _stableSeed({
    required String botPlayerId,
    required ObservableGameState state,
    required MonteCarloDifficultyConfig config,
  }) {
    var hash = 0x1fffffff;
    int mix(int value) {
      hash = 0x1fffffff & (hash + value);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      return hash ^ (hash >> 6);
    }

    mix(botPlayerId.hashCode);
    mix(config.simulationsPerMove);
    mix(config.rolloutDepth);
    mix((config.mistakeProbability * 1000).round());
    mix(config.topCandidateCount);
    mix(config.useActionInference ? 1 : 0);
    mix(config.usePartnerModel ? 1 : 0);
    mix(config.useOpponentProfiles ? 1 : 0);
    mix(state.currentPlayerId.hashCode);
    mix(state.trickLeaderId.hashCode);
    mix(state.botHand.length);
    for (final card in state.botHand) {
      mix(card.value);
      mix(card.suit.index);
    }
    mix(state.playedCards.length);
    for (final played in state.playedCards) {
      mix(played.player.id.hashCode);
      mix(played.player.teamId);
      mix(played.card.value);
      mix(played.card.suit.index);
    }
    for (final player in state.players) {
      mix(player.id.hashCode);
      mix(player.teamId);
      mix(state.cardsRemainingByPlayerId[player.id] ?? 0);
      mix(state.roundWins[player.teamId] ?? 0);
    }
    mix(state.trickIndex);
    for (final signal in state.signalContext.signals) {
      mix(signal.type.index);
      mix(signal.issuerPlayerId.hashCode);
      mix(signal.targetPlayerId?.hashCode ?? 0);
      mix(signal.teamId);
      mix(signal.trickIndex);
      mix(signal.active ? 1 : 0);
    }
    return hash & 0x3fffffff;
  }

  int _mixSeed(int baseSeed, int index) {
    var hash = baseSeed ^ (index + 1);
    hash = 0x1fffffff & (hash + ((hash & 0x0007ffff) << 10));
    hash ^= hash >> 6;
    hash = 0x1fffffff & (hash + ((hash & 0x03ffffff) << 3));
    hash ^= hash >> 11;
    return hash & 0x3fffffff;
  }

  int _stateCacheKey({
    required SimulationGameState state,
    required String botPlayerId,
    required int remainingDepth,
  }) {
    var hash = 0x1fffffff;
    void mix(int value) {
      hash = 0x1fffffff & (hash + value);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }

    mix(botPlayerId.hashCode);
    mix(remainingDepth);
    mix(state.currentPlayerId.hashCode);
    mix(state.trickLeaderId.hashCode);
    mix(state.roundNumber);
    mix(state.trickIndex);
    mix(state.isHandFinished ? 1 : 0);
    for (final signal in state.signalContext.signals) {
      mix(signal.type.index);
      mix(signal.issuerPlayerId.hashCode);
      mix(signal.targetPlayerId?.hashCode ?? 0);
      mix(signal.teamId);
      mix(signal.trickIndex);
      mix(signal.active ? 1 : 0);
    }
    for (final player in state.players) {
      mix(player.player.id.hashCode);
      for (final card in player.hand) {
        mix(card.value);
        mix(card.suit.index);
      }
    }
    for (final played in state.playedCards) {
      mix(played.player.id.hashCode);
      mix(played.card.value);
      mix(played.card.suit.index);
    }
    for (final completed in state.completedTricks) {
      mix(completed.winningTeamId ?? 0);
      mix(completed.isTie ? 1 : 0);
    }
    return hash & 0x3fffffff;
  }

  double _staticCardPrior({
    required String botPlayerId,
    required ObservableGameState state,
    required SpanishCard card,
  }) {
    return _teamCoordinationBonus(
          botPlayerId: botPlayerId,
          state: state,
          card: card,
        ) +
        _tacticalLeadBonus(
          botPlayerId: botPlayerId,
          state: state,
          card: card,
        );
  }

  double _teamCoordinationBonus({
    required String botPlayerId,
    required ObservableGameState state,
    required SpanishCard card,
  }) {
    final bot = state.players.firstWhere((player) => player.id == botPlayerId);
    final teamId = bot.teamId;
    final opponentTeamId = TeamRules.opponentOf(teamId);
    final currentWinningTeam = BotTableRead.currentWinningTeamOnTable(
      state.playedCards,
    );
    final bestStrength = BotTableRead.bestTableStrength(state.playedCards) ?? 0;
    final cardStrength = BotStrategy.strengthOf(card);
    final teammateStillToPlay = _teammateStillToPlayObservable(state, bot);
    final opponentStillToPlay = _opponentStillToPlayObservable(state, bot);
    final isLastToPlay = state.playedCards.length == state.players.length - 1;
    final canBeatTable = cardStrength > bestStrength;
    final canTieTable = cardStrength == bestStrength;
    final signalBias = _observableSignalBiasForPlayer(state, bot);

    if (currentWinningTeam == teamId) {
      var bonus = 48 - cardStrength * 0.55;
      if (isLastToPlay) bonus += 10;
      if (teammateStillToPlay) bonus += 4;
      if (signalBias.conserveResources) bonus += 34 - cardStrength * 0.35;
      if ((state.roundWins[teamId] ?? 0) > (state.roundWins[opponentTeamId] ?? 0) &&
          state.completedTricks.isNotEmpty) {
        bonus += 24 - cardStrength * 0.28;
      }
      return bonus;
    }

    if (currentWinningTeam == opponentTeamId) {
      var bonus = (canBeatTable || canTieTable)
          ? 24 - cardStrength * 0.18
          : 34 - cardStrength * 0.42;
      if (isLastToPlay) bonus += 8;
      if (teammateStillToPlay) bonus += 5;
      if (signalBias.mustWin && canBeatTable) {
        bonus += 116 - cardStrength * 0.72;
      } else if (signalBias.conserveResources) {
        bonus += canBeatTable ? -cardStrength * 0.34 : 22;
      }
      if ((state.roundWins[teamId] ?? 0) > (state.roundWins[opponentTeamId] ?? 0) &&
          state.completedTricks.isNotEmpty &&
          isLastToPlay) {
        bonus += canBeatTable ? -cardStrength * 0.40 : 42 - cardStrength * 0.08;
      }
      return bonus;
    }

    var bonus = 0.0;
    if (signalBias.conserveResources) {
      bonus += 22 - cardStrength * 0.24;
    }
    if ((state.roundWins[teamId] ?? 0) > (state.roundWins[opponentTeamId] ?? 0) &&
        state.completedTricks.isNotEmpty &&
        state.playedCards.isEmpty) {
      bonus += 18 - cardStrength * 0.20;
    }
    if (signalBias.mustWin && canBeatTable) {
      bonus += 80 - cardStrength * 0.48;
    }
    if (teammateStillToPlay) {
      bonus += 10 - cardStrength * 0.08;
    }
    if (opponentStillToPlay) {
      bonus += 4 - cardStrength * 0.04;
    }
    return bonus;
  }

  double _tacticalLeadBonus({
    required String botPlayerId,
    required ObservableGameState state,
    required SpanishCard card,
  }) {
    final bot = state.players.firstWhere((player) => player.id == botPlayerId);
    final teamId = bot.teamId;
    final opponentTeamId = TeamRules.opponentOf(teamId);
    final cardStrength = ZapitiRules.strength(card);
    final tableStrength = BotTableRead.bestTableStrength(state.playedCards) ?? -1;
    final canBeat = cardStrength > tableStrength;
    final canTie = cardStrength == tableStrength;

    var bonus = 0.0;
    if ((state.roundWins[opponentTeamId] ?? 0) > (state.roundWins[teamId] ?? 0) &&
        canBeat) {
      bonus += 18;
    }
    if ((state.roundWins[teamId] ?? 0) > (state.roundWins[opponentTeamId] ?? 0) &&
        !canBeat &&
        !canTie) {
      bonus += 12;
    }
    if (state.playedCards.isEmpty) {
      bonus += max(0, 14 - cardStrength * 0.10);
    }
    return bonus;
  }

  bool _teammateStillToPlay(SimulationGameState state, Player player) {
    final teammateIndex = state.players.indexWhere(
      (entry) =>
          entry.player.teamId == player.teamId && entry.player.id != player.id,
    );
    if (teammateIndex < 0) return false;

    final teammateId = state.players[teammateIndex].player.id;
    if (state.playedCards.any((played) => played.player.id == teammateId)) {
      return false;
    }

    final playerIndex = state.players.indexWhere(
      (entry) => entry.player.id == player.id,
    );
    final remainingTurnsAfterPlayer =
        state.players.length - state.playedCards.length - 1;
    final turnsUntilTeammate =
        (teammateIndex - playerIndex) % state.players.length;
    return turnsUntilTeammate > 0 &&
        turnsUntilTeammate <= remainingTurnsAfterPlayer;
  }

  bool _teammateStillToPlayObservable(ObservableGameState state, Player player) {
    final teammateIndex = state.players.indexWhere(
      (entry) => entry.teamId == player.teamId && entry.id != player.id,
    );
    if (teammateIndex < 0) return false;

    final teammateId = state.players[teammateIndex].id;
    if (state.playedCards.any((played) => played.player.id == teammateId)) {
      return false;
    }

    final playerIndex = state.players.indexWhere(
      (entry) => entry.id == player.id,
    );
    final remainingTurnsAfterPlayer =
        state.players.length - state.playedCards.length - 1;
    final turnsUntilTeammate =
        (teammateIndex - playerIndex) % state.players.length;
    return turnsUntilTeammate > 0 &&
        turnsUntilTeammate <= remainingTurnsAfterPlayer;
  }

  bool _opponentStillToPlay(SimulationGameState state, Player player) {
    final playerIndex = state.players.indexWhere(
      (entry) => entry.player.id == player.id,
    );
    final remainingTurnsAfterPlayer =
        state.players.length - state.playedCards.length - 1;
    if (remainingTurnsAfterPlayer <= 0) return false;

    for (final opponent in state.players.where(
      (entry) => entry.player.teamId != player.teamId,
    )) {
      final opponentId = opponent.player.id;
      if (state.playedCards.any((played) => played.player.id == opponentId)) {
        continue;
      }
      final opponentIndex = state.players.indexWhere(
        (entry) => entry.player.id == opponentId,
      );
      final turnsUntilOpponent =
          (opponentIndex - playerIndex) % state.players.length;
      if (turnsUntilOpponent > 0 &&
          turnsUntilOpponent <= remainingTurnsAfterPlayer) {
        return true;
      }
    }

    return false;
  }

  bool _opponentStillToPlayObservable(ObservableGameState state, Player player) {
    final playerIndex = state.players.indexWhere(
      (entry) => entry.id == player.id,
    );
    final remainingTurnsAfterPlayer =
        state.players.length - state.playedCards.length - 1;
    if (remainingTurnsAfterPlayer <= 0) return false;

    for (final opponent in state.players.where(
      (entry) => entry.teamId != player.teamId,
    )) {
      final opponentId = opponent.id;
      if (state.playedCards.any((played) => played.player.id == opponentId)) {
        continue;
      }
      final opponentIndex = state.players.indexWhere(
        (entry) => entry.id == opponentId,
      );
      final turnsUntilOpponent =
          (opponentIndex - playerIndex) % state.players.length;
      if (turnsUntilOpponent > 0 &&
          turnsUntilOpponent <= remainingTurnsAfterPlayer) {
        return true;
      }
    }
    return false;
  }

  _SignalBias _signalBiasForPlayer(SimulationGameState state, Player player) {
    return _signalBiasFromContext(
      state.signalContext,
      player: player,
      trickIndex: state.trickIndex,
    );
  }

  _SignalBias _observableSignalBiasForPlayer(
    ObservableGameState state,
    Player player,
  ) {
    return _signalBiasFromContext(
      state.signalContext,
      player: player,
      trickIndex: state.trickIndex,
    );
  }

  _SignalBias _signalBiasFromContext(
    SignalContext signalContext, {
    required Player player,
    required int trickIndex,
  }) {
    var conserve = false;
    var mustWin = false;
    for (final signal in signalContext.activeForPlayer(
      playerId: player.id,
      playerTeamId: player.teamId,
      trickIndex: trickIndex,
    )) {
      switch (signal.type) {
        case StrategicSignalType.venAMi:
        case StrategicSignalType.voyATi:
          conserve = true;
          break;
        case StrategicSignalType.mata:
          mustWin = true;
          break;
        case StrategicSignalType.cardSignal:
          break;
      }
    }
    return _SignalBias(
      conserveResources: conserve,
      mustWin: mustWin,
    );
  }
}

class _CardAggregate {
  final SpanishCard card;
  final double prior;
  double rolloutTotal = 0;
  int rolloutCount = 0;

  _CardAggregate({
    required this.card,
    required this.prior,
  });

  void record(double value) {
    rolloutTotal += value;
    rolloutCount += 1;
    if (value < worstScore) worstScore = value;
    if (value > bestScore) bestScore = value;
    values.add(value);
  }

  double get meanScore {
    if (rolloutCount == 0) return prior;
    final mean = rolloutTotal / rolloutCount;
    final variance = values.fold<double>(
          0,
          (sum, value) => sum + (value - mean) * (value - mean),
        ) /
        rolloutCount;
    final robustFloor = percentile(0.25);
    final opportunityCost = BotStrategy.strengthOf(card).toDouble();
    return prior +
        mean * MonteCarloCardSelector._expectedValueWeight +
        robustFloor * MonteCarloCardSelector._robustnessWeight -
        variance.sqrt() * MonteCarloCardSelector._riskPenaltyWeight -
        opportunityCost * MonteCarloCardSelector._opportunityCostWeight;
  }

  double worstScore = double.infinity;
  double bestScore = double.negativeInfinity;
  final List<double> values = [];

  double percentile(double ratio) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final index = ((sorted.length - 1) * ratio).round();
    return sorted[index];
  }
}

class _RolloutProfile {
  final double aggression;
  final double conservation;
  final double cooperation;

  const _RolloutProfile({
    this.aggression = 0.5,
    this.conservation = 0.5,
    this.cooperation = 0.5,
  });
}

extension on double {
  double sqrt() => sqrtValue(this);
}

double sqrtValue(double value) => value <= 0 ? 0 : sqrt(value);

class _SignalBias {
  final bool conserveResources;
  final bool mustWin;

  const _SignalBias({
    required this.conserveResources,
    required this.mustWin,
  });
}
