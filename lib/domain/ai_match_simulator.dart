import 'dart:math';

import 'bot_al_ver_strategy.dart';
import 'bot_bet_value_evaluator.dart';
import 'bot_decision_context.dart';
import 'bot_policy.dart';
import 'bot_memory_context.dart';
import 'bot_table_read.dart';
import 'bot_ven_a_mi_strategy.dart';
import 'bot_voy_a_ti_strategy.dart';
import 'difficulty_profile.dart';
import 'difficulty_strategy.dart';
import 'monte_carlo_difficulty_config.dart';
import 'played_card.dart';
import 'legal_actions.dart';
import 'player.dart';
import 'signal_rules.dart';
import 'spanish_card.dart';
import 'team_rules.dart';
import 'truco_rules.dart';
import 'zapiti_deck.dart';
import 'zapiti_game_controller.dart';
import 'zapiti_players.dart';

class AiSimulationConfig {
  final int matches;
  final int seed;
  final int targetScore;
  final int teamOneDifficulty;
  final int teamTwoDifficulty;
  final int maxHandsPerMatch;
  final bool rotateStartingPlayerPerMatch;
  final void Function(int hand, int round, int turn)? onProgress;

  const AiSimulationConfig({
    this.matches = 100,
    this.seed = 1,
    this.targetScore = ZapitiGameController.defaultTargetScore,
    int difficulty = 3,
    int? teamOneDifficulty,
    int? teamTwoDifficulty,
    this.maxHandsPerMatch = 120,
    this.rotateStartingPlayerPerMatch = true,
    this.onProgress,
  })  : teamOneDifficulty = teamOneDifficulty ?? difficulty,
        teamTwoDifficulty = teamTwoDifficulty ?? difficulty;
}

class DifficultyConfigAdapter {
  const DifficultyConfigAdapter._();

  static MonteCarloDifficultyConfig forDifficulty(int difficulty) {
    return MonteCarloDifficultyConfigs.forDifficulty(difficulty);
  }
}

class AiSimulationSummary {
  final AiSimulationConfig config;
  final int teamOneWins;
  final int teamTwoWins;
  final int abortedMatches;
  final int totalHands;
  final int totalRounds;
  final int totalTrucoCalls;
  final int totalTrucoRaises;
  final int totalTrucoAccepts;
  final int totalTrucoPasses;
  final Map<int, int> betCallsByValue;
  final Map<int, int> handsByMaxBetValue;
  final List<double> openingTrucoWinProbabilities;
  final int totalAlVerPlayed;
  final int totalAlVerConceded;
  final int totalSignalOpportunities;
  final int totalSignalsGiven;
  final int totalStrongSignalsGiven;
  final int totalVoyATiRequests;
  final int totalVenAMiOrders;
  final int totalVenAMiProtectedRounds;
  final int totalTeamOneScore;
  final int totalTeamTwoScore;
  final List<int> decisionMicros;

  const AiSimulationSummary({
    required this.config,
    required this.teamOneWins,
    required this.teamTwoWins,
    required this.abortedMatches,
    required this.totalHands,
    required this.totalRounds,
    required this.totalTrucoCalls,
    required this.totalTrucoRaises,
    required this.totalTrucoAccepts,
    required this.totalTrucoPasses,
    required this.betCallsByValue,
    required this.handsByMaxBetValue,
    required this.openingTrucoWinProbabilities,
    required this.totalAlVerPlayed,
    required this.totalAlVerConceded,
    required this.totalSignalOpportunities,
    required this.totalSignalsGiven,
    required this.totalStrongSignalsGiven,
    required this.totalVoyATiRequests,
    required this.totalVenAMiOrders,
    required this.totalVenAMiProtectedRounds,
    required this.totalTeamOneScore,
    required this.totalTeamTwoScore,
    this.decisionMicros = const [],
  });

  int get playedMatches => teamOneWins + teamTwoWins;
  int get completedMatches => playedMatches;
  double get teamOneWinRate =>
      playedMatches == 0 ? 0 : teamOneWins / playedMatches;
  double get teamTwoWinRate =>
      playedMatches == 0 ? 0 : teamTwoWins / playedMatches;
  double get averageHandsPerMatch =>
      playedMatches == 0 ? 0 : totalHands / playedMatches;
  double get averageRoundsPerMatch =>
      playedMatches == 0 ? 0 : totalRounds / playedMatches;
  double get averageTrucoCallsPerMatch =>
      playedMatches == 0 ? 0 : totalTrucoCalls / playedMatches;
  int get totalTrucoResponses => totalTrucoAccepts + totalTrucoPasses;
  double get trucoPassRate =>
      totalTrucoResponses == 0 ? 0 : totalTrucoPasses / totalTrucoResponses;
  double get trucoRaiseRate => totalTrucoResponses == 0
      ? 0
      : totalTrucoRaises / (totalTrucoResponses + totalTrucoRaises);
  double get averageFinalScoreTeamOne =>
      playedMatches == 0 ? 0 : totalTeamOneScore / playedMatches;
  double get averageFinalScoreTeamTwo =>
      playedMatches == 0 ? 0 : totalTeamTwoScore / playedMatches;
  double get averageDecisionMicros => decisionMicros.isEmpty
      ? 0
      : decisionMicros.fold<int>(0, (sum, value) => sum + value) /
          decisionMicros.length;
  int get p50DecisionMicros => _percentileDecisionMicros(0.50);
  int get p95DecisionMicros => _percentileDecisionMicros(0.95);
  int get p99DecisionMicros => _percentileDecisionMicros(0.99);
  double get signalGiveRate => totalSignalOpportunities == 0
      ? 0
      : totalSignalsGiven / totalSignalOpportunities;
  double get strongSignalRate =>
      totalSignalsGiven == 0 ? 0 : totalStrongSignalsGiven / totalSignalsGiven;
  double get venAMiProtectionRate => totalVenAMiOrders == 0
      ? 0
      : totalVenAMiProtectedRounds / totalVenAMiOrders;

  int _percentileDecisionMicros(double ratio) {
    if (decisionMicros.isEmpty) return 0;
    final sorted = [...decisionMicros]..sort();
    final index = ((sorted.length - 1) * ratio).round();
    return sorted[index];
  }

  static AiSimulationSummary combine(
    AiSimulationConfig config,
    Iterable<AiSimulationSummary> summaries,
  ) {
    var teamOneWins = 0;
    var teamTwoWins = 0;
    var abortedMatches = 0;
    var totalHands = 0;
    var totalRounds = 0;
    var totalTrucoCalls = 0;
    var totalTrucoRaises = 0;
    var totalTrucoAccepts = 0;
    var totalTrucoPasses = 0;
    final betCallsByValue = <int, int>{};
    final handsByMaxBetValue = <int, int>{};
    final openingTrucoWinProbabilities = <double>[];
    var totalAlVerPlayed = 0;
    var totalAlVerConceded = 0;
    var totalSignalOpportunities = 0;
    var totalSignalsGiven = 0;
    var totalStrongSignalsGiven = 0;
    var totalVoyATiRequests = 0;
    var totalVenAMiOrders = 0;
    var totalVenAMiProtectedRounds = 0;
    var totalTeamOneScore = 0;
    var totalTeamTwoScore = 0;
    final decisionMicros = <int>[];

    for (final summary in summaries) {
      teamOneWins += summary.teamOneWins;
      teamTwoWins += summary.teamTwoWins;
      abortedMatches += summary.abortedMatches;
      totalHands += summary.totalHands;
      totalRounds += summary.totalRounds;
      totalTrucoCalls += summary.totalTrucoCalls;
      totalTrucoRaises += summary.totalTrucoRaises;
      totalTrucoAccepts += summary.totalTrucoAccepts;
      totalTrucoPasses += summary.totalTrucoPasses;
      for (final entry in summary.betCallsByValue.entries) {
        betCallsByValue.update(
          entry.key,
          (count) => count + entry.value,
          ifAbsent: () => entry.value,
        );
      }
      for (final entry in summary.handsByMaxBetValue.entries) {
        handsByMaxBetValue.update(
          entry.key,
          (count) => count + entry.value,
          ifAbsent: () => entry.value,
        );
      }
      openingTrucoWinProbabilities.addAll(summary.openingTrucoWinProbabilities);
      totalAlVerPlayed += summary.totalAlVerPlayed;
      totalAlVerConceded += summary.totalAlVerConceded;
      totalSignalOpportunities += summary.totalSignalOpportunities;
      totalSignalsGiven += summary.totalSignalsGiven;
      totalStrongSignalsGiven += summary.totalStrongSignalsGiven;
      totalVoyATiRequests += summary.totalVoyATiRequests;
      totalVenAMiOrders += summary.totalVenAMiOrders;
      totalVenAMiProtectedRounds += summary.totalVenAMiProtectedRounds;
      totalTeamOneScore += summary.totalTeamOneScore;
      totalTeamTwoScore += summary.totalTeamTwoScore;
      decisionMicros.addAll(summary.decisionMicros);
    }

    return AiSimulationSummary(
      config: config,
      teamOneWins: teamOneWins,
      teamTwoWins: teamTwoWins,
      abortedMatches: abortedMatches,
      totalHands: totalHands,
      totalRounds: totalRounds,
      totalTrucoCalls: totalTrucoCalls,
      totalTrucoRaises: totalTrucoRaises,
      totalTrucoAccepts: totalTrucoAccepts,
      totalTrucoPasses: totalTrucoPasses,
      betCallsByValue: Map.unmodifiable(betCallsByValue),
      handsByMaxBetValue: Map.unmodifiable(handsByMaxBetValue),
      openingTrucoWinProbabilities:
          List.unmodifiable(openingTrucoWinProbabilities),
      totalAlVerPlayed: totalAlVerPlayed,
      totalAlVerConceded: totalAlVerConceded,
      totalSignalOpportunities: totalSignalOpportunities,
      totalSignalsGiven: totalSignalsGiven,
      totalStrongSignalsGiven: totalStrongSignalsGiven,
      totalVoyATiRequests: totalVoyATiRequests,
      totalVenAMiOrders: totalVenAMiOrders,
      totalVenAMiProtectedRounds: totalVenAMiProtectedRounds,
      totalTeamOneScore: totalTeamOneScore,
      totalTeamTwoScore: totalTeamTwoScore,
      decisionMicros: List.unmodifiable(decisionMicros),
    );
  }
}

class AiMatchSimulator {
  const AiMatchSimulator();
  static const _betEvaluator = BotBetValueEvaluator();

  AiSimulationSummary run(AiSimulationConfig config) {
    var teamOneWins = 0;
    var teamTwoWins = 0;
    var abortedMatches = 0;
    var totalHands = 0;
    var totalRounds = 0;
    var totalTrucoCalls = 0;
    var totalTrucoRaises = 0;
    var totalTrucoAccepts = 0;
    var totalTrucoPasses = 0;
    final betCallsByValue = <int, int>{};
    final handsByMaxBetValue = <int, int>{};
    final openingTrucoWinProbabilities = <double>[];
    var totalAlVerPlayed = 0;
    var totalAlVerConceded = 0;
    var totalSignalOpportunities = 0;
    var totalSignalsGiven = 0;
    var totalStrongSignalsGiven = 0;
    var totalVoyATiRequests = 0;
    var totalVenAMiOrders = 0;
    var totalVenAMiProtectedRounds = 0;
    var totalTeamOneScore = 0;
    var totalTeamTwoScore = 0;
    final decisionMicros = <int>[];

    for (var index = 0; index < config.matches; index++) {
      final result = _runMatch(
        config,
        Random(config.seed + index),
        startingPlayerIndex: config.rotateStartingPlayerPerMatch
            ? index % ZapitiPlayers.tableOrder.length
            : 0,
      );
      if (result.winningTeamId == TeamRules.teamOne) {
        teamOneWins += 1;
      } else if (result.winningTeamId == TeamRules.teamTwo) {
        teamTwoWins += 1;
      } else {
        abortedMatches += 1;
      }
      totalHands += result.hands;
      totalRounds += result.rounds;
      totalTrucoCalls += result.trucoCalls;
      totalTrucoRaises += result.trucoRaises;
      totalTrucoAccepts += result.trucoAccepts;
      totalTrucoPasses += result.trucoPasses;
      for (final entry in result.betCallsByValue.entries) {
        betCallsByValue.update(
          entry.key,
          (count) => count + entry.value,
          ifAbsent: () => entry.value,
        );
      }
      for (final entry in result.handsByMaxBetValue.entries) {
        handsByMaxBetValue.update(
          entry.key,
          (count) => count + entry.value,
          ifAbsent: () => entry.value,
        );
      }
      openingTrucoWinProbabilities.addAll(result.openingTrucoWinProbabilities);
      totalAlVerPlayed += result.alVerPlayed;
      totalAlVerConceded += result.alVerConceded;
      totalSignalOpportunities += result.signalOpportunities;
      totalSignalsGiven += result.signalsGiven;
      totalStrongSignalsGiven += result.strongSignalsGiven;
      totalVoyATiRequests += result.voyATiRequests;
      totalVenAMiOrders += result.venAMiOrders;
      totalVenAMiProtectedRounds += result.venAMiProtectedRounds;
      totalTeamOneScore += result.finalScoreTeamOne;
      totalTeamTwoScore += result.finalScoreTeamTwo;
      decisionMicros.addAll(result.decisionMicros);
    }

    return AiSimulationSummary(
      config: config,
      teamOneWins: teamOneWins,
      teamTwoWins: teamTwoWins,
      abortedMatches: abortedMatches,
      totalHands: totalHands,
      totalRounds: totalRounds,
      totalTrucoCalls: totalTrucoCalls,
      totalTrucoRaises: totalTrucoRaises,
      totalTrucoAccepts: totalTrucoAccepts,
      totalTrucoPasses: totalTrucoPasses,
      betCallsByValue: Map.unmodifiable(betCallsByValue),
      handsByMaxBetValue: Map.unmodifiable(handsByMaxBetValue),
      openingTrucoWinProbabilities:
          List.unmodifiable(openingTrucoWinProbabilities),
      totalAlVerPlayed: totalAlVerPlayed,
      totalAlVerConceded: totalAlVerConceded,
      totalSignalOpportunities: totalSignalOpportunities,
      totalSignalsGiven: totalSignalsGiven,
      totalStrongSignalsGiven: totalStrongSignalsGiven,
      totalVoyATiRequests: totalVoyATiRequests,
      totalVenAMiOrders: totalVenAMiOrders,
      totalVenAMiProtectedRounds: totalVenAMiProtectedRounds,
      totalTeamOneScore: totalTeamOneScore,
      totalTeamTwoScore: totalTeamTwoScore,
      decisionMicros: List.unmodifiable(decisionMicros),
    );
  }

  _SimulatedMatchResult _runMatch(
    AiSimulationConfig config,
    Random random, {
    required int startingPlayerIndex,
  }) {
    final controller = ZapitiGameController(
      targetScore: config.targetScore,
      players: ZapitiPlayers.tableOrder,
      humanPlayerId: ZapitiPlayers.human.id,
      authorizedTrucoPlayerIds: ZapitiPlayers.tableOrder.map(
        (player) => player.id,
      ),
      autoStart: false,
    );
    controller.nextLeadIndex = startingPlayerIndex % controller.players.length;
    final metrics = _SimulationMetrics();

    _startNewSimulatedHand(controller, random, config, metrics);
    metrics.hands += 1;

    while (!controller.isGameFinished &&
        metrics.hands <= config.maxHandsPerMatch) {
      _playCurrentHand(controller, config, random, metrics);
      metrics.handsByMaxBetValue.update(
        metrics.currentHandMaxBetValue,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      if (!controller.isGameFinished &&
          metrics.hands < config.maxHandsPerMatch) {
        _startNewSimulatedHand(controller, random, config, metrics);
        metrics.hands += 1;
      }
    }

    return _SimulatedMatchResult(
      winningTeamId: controller.winningTeamId,
      finalScoreTeamOne: controller.score[TeamRules.teamOne]!,
      finalScoreTeamTwo: controller.score[TeamRules.teamTwo]!,
      hands: metrics.hands,
      rounds: metrics.rounds,
      trucoCalls: metrics.trucoCalls,
      trucoRaises: metrics.trucoRaises,
      trucoAccepts: metrics.trucoAccepts,
      trucoPasses: metrics.trucoPasses,
      betCallsByValue: Map.unmodifiable(metrics.betCallsByValue),
      handsByMaxBetValue: Map.unmodifiable(metrics.handsByMaxBetValue),
      openingTrucoWinProbabilities:
          List.unmodifiable(metrics.openingTrucoWinProbabilities),
      alVerPlayed: metrics.alVerPlayed,
      alVerConceded: metrics.alVerConceded,
      signalOpportunities: metrics.signalOpportunities,
      signalsGiven: metrics.signalsGiven,
      strongSignalsGiven: metrics.strongSignalsGiven,
      voyATiRequests: metrics.voyATiRequests,
      venAMiOrders: metrics.venAMiOrders,
      venAMiProtectedRounds: metrics.venAMiProtectedRounds,
      decisionMicros: List.unmodifiable(metrics.decisionMicros),
    );
  }

  void _playCurrentHand(
    ZapitiGameController controller,
    AiSimulationConfig config,
    Random random,
    _SimulationMetrics metrics,
  ) {
    var stagnantIterations = 0;
    String? previousSignature;
    while (!controller.handFinished && !controller.isGameFinished) {
      if (metrics.turnsInHand >= 128) {
        throw StateError(
          'AI simulation exceeded 128 transitions in hand ${metrics.hands}; '
          'round=${controller.roundHistory.length}, turn=${controller.turnIndex}, '
          'pending=${controller.pendingTrucoValue}, played=${controller.playedCards.length}',
        );
      }
      metrics.turnsInHand += 1;
      final signature = [
        controller.turnIndex,
        controller.leadIndex,
        controller.handValue,
        controller.pendingTrucoValue,
        controller.trucoState.name,
        controller.playedCards.length,
        controller.roundHistory.length,
        controller.roundWins[TeamRules.teamOne],
        controller.roundWins[TeamRules.teamTwo],
        controller.score[TeamRules.teamOne],
        controller.score[TeamRules.teamTwo],
        for (final player in controller.players)
          '${player.id}:${controller.hands[player.id]?.length ?? 0}',
      ].join('|');
      if (signature == previousSignature) {
        stagnantIterations += 1;
        if (stagnantIterations >= 64) {
          throw StateError('AI simulation stalled at $signature');
        }
      } else {
        previousSignature = signature;
        stagnantIterations = 0;
      }

      _resolveAlVerIfNeeded(controller, config, metrics);
      if (controller.handFinished || controller.isGameFinished) return;

      if (controller.pendingTrucoValue != null) {
        _respondToTruco(controller, config, random, metrics);
        config.onProgress?.call(
          metrics.hands,
          controller.roundHistory.length + 1,
          controller.turnIndex,
        );
        continue;
      }

      final player = controller.currentPlayer;
      if (_maybeCallTruco(
        controller,
        config,
        random,
        player,
        metrics,
      )) {
        config.onProgress?.call(
          metrics.hands,
          controller.roundHistory.length + 1,
          controller.turnIndex,
        );
        continue;
      }

      final watch = Stopwatch()..start();
      final card = _chooseCard(controller, config, random, player, metrics);
      watch.stop();
      metrics.decisionMicros.add(watch.elapsedMicroseconds);
      final roundCompleted = controller.playCard(player, card);
      config.onProgress?.call(
        metrics.hands,
        controller.roundHistory.length + 1,
        controller.turnIndex,
      );
      if (roundCompleted) {
        controller.resolveRound();
        metrics.rounds += 1;
        metrics.turnsInHand = 0;
        if (controller.isRoundAwaitingContinue) {
          controller.continueRound();
        }
      }
    }
  }

  void _resolveAlVerIfNeeded(
    ZapitiGameController controller,
    AiSimulationConfig config,
    _SimulationMetrics metrics,
  ) {
    if (controller.alVerState != AlVerState.awaitingDecision) return;

    if (controller.alVerTeamIds.length != 1) {
      controller.alVerState = AlVerState.playing;
      metrics.alVerPlayed += controller.alVerTeamIds.length;
      return;
    }

    final teamId = controller.alVerTeamIds.first;
    final play = BotAlVerStrategy.shouldPlay(
      cards: _teamCards(controller, teamId),
      difficulty: _difficultyFor(config, teamId),
      teamScore: controller.score[teamId]!,
      opponentScore: controller.score[TeamRules.opponentOf(teamId)]!,
      targetScore: controller.targetScore,
    );
    controller.chooseAlVerDecision(teamId: teamId, play: play);
    if (play) {
      metrics.alVerPlayed += 1;
    } else {
      metrics.alVerConceded += 1;
    }
  }

  bool _maybeCallTruco(
    ZapitiGameController controller,
    AiSimulationConfig config,
    Random random,
    Player player,
    _SimulationMetrics metrics,
  ) {
    if (controller.roundHistory.length >= 2 ||
        controller.trucoState == TrucoNegotiationState.awaitingResponse) {
      return false;
    }
    final hand = controller.hands[player.id] ?? const <SpanishCard>[];
    if (hand.isEmpty) return false;
    final nextValue = controller.nextTrucoValueForPlayer(player);
    if (nextValue == null ||
        !controller.canCallTruco(
          player,
          value: nextValue,
          actorPlayerId: player.id,
        )) {
      return false;
    }

    final teamId = player.teamId;
    final action =
        _chooseBetAction(controller, player, _difficultyFor(config, teamId));
    if (action?.type != BetActionType.call) return false;

    controller.callTruco(
      player,
      value: action!.value!,
      actorPlayerId: player.id,
    );
    if (action.value == TrucoRules.firstTrucoValue) {
      metrics.trucoCalls += 1;
      final evaluation = _betEvaluator.evaluateHand(
        ownHand: hand,
        cardsOnTable: controller.playedCards.length,
        teamRoundWins: controller.roundWins[teamId]!,
        opponentRoundWins: controller.roundWins[TeamRules.opponentOf(teamId)]!,
      );
      metrics.openingTrucoWinProbabilities
          .add(evaluation.winProbability);
    } else {
      metrics.trucoRaises += 1;
    }
    metrics.betCallsByValue.update(
      action.value!,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    metrics.currentHandMaxBetValue =
        max(metrics.currentHandMaxBetValue, action.value!);
    return true;
  }

  void _respondToTruco(
    ZapitiGameController controller,
    AiSimulationConfig config,
    Random random,
    _SimulationMetrics metrics,
  ) {
    final teamId = controller.respondingTrucoTeamId;
    final pendingValue = controller.pendingTrucoValue;
    if (teamId == null || pendingValue == null) return;

    final responder = _responderFor(controller, teamId);
    final action =
        _chooseBetAction(controller, responder, _difficultyFor(config, teamId));
    if (action?.type == BetActionType.call) {
      controller.raiseTruco(
        responder,
        value: action!.value!,
        actorPlayerId: responder.id,
      );
      metrics.trucoRaises += 1;
      metrics.currentHandMaxBetValue =
          max(metrics.currentHandMaxBetValue, action.value!);
      metrics.betCallsByValue.update(
        action.value!,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      return;
    }

    if (action?.type == BetActionType.accept) {
      controller.acceptTruco(teamId: teamId, actorPlayerId: responder.id);
      metrics.trucoAccepts += 1;
    } else {
      controller.passTruco(passingTeamId: teamId, actorPlayerId: responder.id);
      metrics.trucoPasses += 1;
    }
  }

  BetAction? _chooseBetAction(
    ZapitiGameController controller,
    Player player,
    int difficulty,
  ) {
    final opponent = TeamRules.opponentOf(player.teamId);
    final hand = _betEvaluator.evaluateHand(
      ownHand: controller.hands[player.id] ?? const <SpanishCard>[],
      cardsOnTable: controller.playedCards.length,
      teamRoundWins: controller.roundWins[player.teamId]!,
      opponentRoundWins: controller.roundWins[opponent]!,
    );
    return _betEvaluator.chooseAction(
      legalActions: controller.legalBetActionsForPlayer(player),
      hand: hand,
      teamScore: controller.score[player.teamId]!,
      opponentScore: controller.score[opponent]!,
      targetScore: controller.targetScore,
      acceptedValue: controller.handValue,
      pendingValue: controller.pendingTrucoValue ?? controller.handValue,
      difficulty: difficulty,
    );
  }

  SpanishCard _chooseCard(
    ZapitiGameController controller,
    AiSimulationConfig config,
    Random random,
    Player player,
    _SimulationMetrics metrics,
  ) {
    final playedPlayerIds = {
      for (final playedCard in controller.playedCards) playedCard.player.id,
    };
    final teammateStillToPlay = controller.players.any((candidate) {
      return candidate.id != player.id &&
          candidate.teamId == player.teamId &&
          !playedPlayerIds.contains(candidate.id) &&
          (controller.hands[candidate.id] ?? const <SpanishCard>[]).isNotEmpty;
    });
    final opponentStillToPlay = controller.players.any((candidate) {
      return candidate.teamId != player.teamId &&
          !playedPlayerIds.contains(candidate.id) &&
          (controller.hands[candidate.id] ?? const <SpanishCard>[]).isNotEmpty;
    });
    final opponentTeamId = TeamRules.opponentOf(player.teamId);
    final memory = BotMemoryContext.from(
      bot: player,
      playedCards: controller.playedCards,
      roundHistory: controller.roundHistory,
    );
    final venAMiCard = _tryVenAMiCard(controller, player, metrics);
    if (venAMiCard != null) {
      return DifficultyStrategy.applyCardMistake(
        difficulty: _difficultyFor(config, player.teamId),
        random: random,
        player: player,
        hand: controller.hands[player.id] ?? const <SpanishCard>[],
        strategicCard: venAMiCard,
        playedCards: controller.playedCards,
      );
    }
    _trackVoyATiOpportunity(controller, config, random, player, metrics);
    final forceWinIfPossible = controller.handValue >= 6 ||
        controller.roundWins[opponentTeamId]! >
            controller.roundWins[player.teamId]!;
    final policy = BotPolicySelector.forDifficulty(
      _difficultyFor(config, player.teamId),
    );
    final strategicCard = policy.chooseCard(
      BotDecisionContext(
        difficulty: _difficultyFor(config, player.teamId),
        bot: player,
        players: controller.players,
        hand: controller.hands[player.id] ?? const <SpanishCard>[],
        hands: controller.hands,
        playedCards: controller.playedCards,
        teamRoundWins: controller.roundWins[player.teamId]!,
        opponentRoundWins: controller.roundWins[opponentTeamId]!,
        preserveStrongCards: controller.handValue < 6 ||
            memory.teammateWonLastRound ||
            memory.opponentsSpentPower,
        teammateHasStrongSignal: false,
        opponentHasStrongSignal: false,
        forceWinIfPossible: forceWinIfPossible,
        teammateStillToPlay:
            teammateStillToPlay && !memory.opponentsWonAnyRound,
        opponentStillToPlay: opponentStillToPlay,
      ),
    );
    return DifficultyStrategy.applyCardMistake(
      difficulty: _difficultyFor(config, player.teamId),
      random: random,
      player: player,
      hand: controller.hands[player.id] ?? const <SpanishCard>[],
      strategicCard: strategicCard,
      playedCards: controller.playedCards,
    );
  }

  Player _responderFor(ZapitiGameController controller, int teamId) {
    return controller.players.firstWhere(
      (player) =>
          player.teamId == teamId &&
          (controller.hands[player.id] ?? const <SpanishCard>[]).isNotEmpty,
      orElse: () => controller.players.firstWhere(
        (player) => player.teamId == teamId,
      ),
    );
  }

  void _startNewSimulatedHand(
    ZapitiGameController controller,
    Random random,
    AiSimulationConfig config,
    _SimulationMetrics metrics,
  ) {
    final deck = ZapitiDeck.shuffled(random: random);
    controller.startNewHand(
      fixedHands: {
        for (var i = 0; i < controller.players.length; i++)
          controller.players[i].id: deck.skip(i * 3).take(3).toList(),
      },
    );
    metrics.currentHandMaxBetValue = 0;
    _trackSignals(controller, config, metrics);
  }

  List<SpanishCard> _teamCards(ZapitiGameController controller, int teamId) {
    return controller.players
        .where((player) => player.teamId == teamId)
        .expand(
            (player) => controller.hands[player.id] ?? const <SpanishCard>[])
        .toList();
  }

  int _difficultyFor(AiSimulationConfig config, int teamId) {
    return teamId == TeamRules.teamOne
        ? config.teamOneDifficulty
        : config.teamTwoDifficulty;
  }

  void _trackSignals(
    ZapitiGameController controller,
    AiSimulationConfig config,
    _SimulationMetrics metrics,
  ) {
    for (final player in controller.players) {
      final signal = SignalRules.signalForHand(
        controller.hands[player.id] ?? const <SpanishCard>[],
      );
      if (signal == null) continue;

      metrics.signalOpportunities += 1;
      final profile = DifficultyProfiles.byLevel(
        _difficultyFor(config, player.teamId),
      );
      if (!profile.rivalsGiveSignals) continue;

      metrics.signalsGiven += 1;
      if (SignalRules.isStrongSignal(signal)) {
        metrics.strongSignalsGiven += 1;
      }
    }
  }

  void _trackVoyATiOpportunity(
    ZapitiGameController controller,
    AiSimulationConfig config,
    Random random,
    Player player,
    _SimulationMetrics metrics,
  ) {
    final teammate = controller.players.cast<Player?>().firstWhere(
      (candidate) {
        if (candidate == null ||
            candidate.id == player.id ||
            candidate.teamId != player.teamId) {
          return false;
        }
        final alreadyPlayed = controller.playedCards.any(
          (playedCard) => playedCard.player.id == candidate.id,
        );
        return !alreadyPlayed &&
            (controller.hands[candidate.id] ?? const <SpanishCard>[])
                .isNotEmpty;
      },
      orElse: () => null,
    );
    if (teammate == null) return;

    final shouldAsk = BotVoyATiStrategy.shouldAskTeammateToWin(
      bot: player,
      teammate: teammate,
      players: controller.players,
      hands: controller.hands,
      playedCards: controller.playedCards,
      teamRoundWins: controller.roundWins[player.teamId]!,
      opponentRoundWins: controller.roundWins[TeamRules.opponentOf(
        player.teamId,
      )]!,
      handValue: controller.handValue,
      difficulty: _difficultyFor(config, player.teamId),
      roll: random.nextDouble(),
    );
    if (shouldAsk) {
      metrics.voyATiRequests += 1;
    }
  }

  SpanishCard? _tryVenAMiCard(
    ZapitiGameController controller,
    Player player,
    _SimulationMetrics metrics,
  ) {
    if (controller.playedCards.isEmpty) return null;
    final currentWinningTeam = BotTableRead.currentWinningTeamOnTable(
      controller.playedCards,
    );
    if (currentWinningTeam != player.teamId) return null;
    final teammateAlreadyWinning = controller.playedCards.any(
      (playedCard) =>
          playedCard.player.teamId == player.teamId &&
          playedCard.player.id != player.id,
    );
    if (!teammateAlreadyWinning) return null;

    final hand = controller.hands[player.id] ?? const <SpanishCard>[];
    if (hand.isEmpty) return null;

    metrics.venAMiOrders += 1;
    final chosen = BotVenAMiStrategy.chooseCard(
      bot: player,
      hand: hand,
      playedCards: controller.playedCards,
      players: controller.players,
      hands: controller.hands,
    );
    final simulated = [
      ...controller.playedCards,
      PlayedCard(player: player, card: chosen),
    ];
    if (BotTableRead.currentWinningTeamOnTable(simulated) == player.teamId) {
      metrics.venAMiProtectedRounds += 1;
    }
    return chosen;
  }
}

class _SimulationMetrics {
  int hands = 0;
  int rounds = 0;
  int trucoCalls = 0;
  int trucoRaises = 0;
  int trucoAccepts = 0;
  int trucoPasses = 0;
  final Map<int, int> betCallsByValue = {};
  final Map<int, int> handsByMaxBetValue = {};
  final List<double> openingTrucoWinProbabilities = [];
  int currentHandMaxBetValue = 0;
  int alVerPlayed = 0;
  int alVerConceded = 0;
  int signalOpportunities = 0;
  int signalsGiven = 0;
  int strongSignalsGiven = 0;
  int voyATiRequests = 0;
  int venAMiOrders = 0;
  int venAMiProtectedRounds = 0;
  int turnsInHand = 0;
  final List<int> decisionMicros = [];
}

class _SimulatedMatchResult {
  final int? winningTeamId;
  final int finalScoreTeamOne;
  final int finalScoreTeamTwo;
  final int hands;
  final int rounds;
  final int trucoCalls;
  final int trucoRaises;
  final int trucoAccepts;
  final int trucoPasses;
  final Map<int, int> betCallsByValue;
  final Map<int, int> handsByMaxBetValue;
  final List<double> openingTrucoWinProbabilities;
  final int alVerPlayed;
  final int alVerConceded;
  final int signalOpportunities;
  final int signalsGiven;
  final int strongSignalsGiven;
  final int voyATiRequests;
  final int venAMiOrders;
  final int venAMiProtectedRounds;
  final List<int> decisionMicros;

  const _SimulatedMatchResult({
    required this.winningTeamId,
    required this.finalScoreTeamOne,
    required this.finalScoreTeamTwo,
    required this.hands,
    required this.rounds,
    required this.trucoCalls,
    required this.trucoRaises,
    required this.trucoAccepts,
    required this.trucoPasses,
    required this.betCallsByValue,
    required this.handsByMaxBetValue,
    required this.openingTrucoWinProbabilities,
    required this.alVerPlayed,
    required this.alVerConceded,
    required this.signalOpportunities,
    required this.signalsGiven,
    required this.strongSignalsGiven,
    required this.voyATiRequests,
    required this.venAMiOrders,
    required this.venAMiProtectedRounds,
    required this.decisionMicros,
  });
}
