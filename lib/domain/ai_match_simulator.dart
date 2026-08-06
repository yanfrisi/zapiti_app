import 'dart:math';

import 'bot_al_ver_strategy.dart';
import 'bot_bluff_strategy.dart';
import 'bot_decision_context.dart';
import 'bot_policy.dart';
import 'bot_memory_context.dart';
import 'bot_table_read.dart';
import 'bot_truco_raise_strategy.dart';
import 'bot_truco_response_strategy.dart';
import 'bot_truco_strategy.dart';
import 'bot_ven_a_mi_strategy.dart';
import 'bot_voy_a_ti_strategy.dart';
import 'difficulty_profile.dart';
import 'difficulty_strategy.dart';
import 'monte_carlo_difficulty_config.dart';
import 'played_card.dart';
import 'player.dart';
import 'signal_rules.dart';
import 'spanish_card.dart';
import 'team_rules.dart';
import 'truco_rules.dart';
import 'zapiti_deck.dart';
import 'zapiti_game_controller.dart';
import 'zapiti_players.dart';
import 'zapiti_rules.dart';

class AiSimulationConfig {
  final int matches;
  final int seed;
  final int targetScore;
  final int teamOneDifficulty;
  final int teamTwoDifficulty;
  final int maxHandsPerMatch;
  final bool rotateStartingPlayerPerMatch;

  const AiSimulationConfig({
    this.matches = 100,
    this.seed = 1,
    this.targetScore = ZapitiGameController.defaultTargetScore,
    int difficulty = 3,
    int? teamOneDifficulty,
    int? teamTwoDifficulty,
    this.maxHandsPerMatch = 120,
    this.rotateStartingPlayerPerMatch = true,
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
  final int totalHands;
  final int totalRounds;
  final int totalTrucoCalls;
  final int totalTrucoRaises;
  final int totalTrucoAccepts;
  final int totalTrucoPasses;
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

  const AiSimulationSummary({
    required this.config,
    required this.teamOneWins,
    required this.teamTwoWins,
    required this.totalHands,
    required this.totalRounds,
    required this.totalTrucoCalls,
    required this.totalTrucoRaises,
    required this.totalTrucoAccepts,
    required this.totalTrucoPasses,
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
  });

  int get playedMatches => teamOneWins + teamTwoWins;
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
  double get signalGiveRate => totalSignalOpportunities == 0
      ? 0
      : totalSignalsGiven / totalSignalOpportunities;
  double get strongSignalRate =>
      totalSignalsGiven == 0 ? 0 : totalStrongSignalsGiven / totalSignalsGiven;
  double get venAMiProtectionRate => totalVenAMiOrders == 0
      ? 0
      : totalVenAMiProtectedRounds / totalVenAMiOrders;

  static AiSimulationSummary combine(
    AiSimulationConfig config,
    Iterable<AiSimulationSummary> summaries,
  ) {
    var teamOneWins = 0;
    var teamTwoWins = 0;
    var totalHands = 0;
    var totalRounds = 0;
    var totalTrucoCalls = 0;
    var totalTrucoRaises = 0;
    var totalTrucoAccepts = 0;
    var totalTrucoPasses = 0;
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

    for (final summary in summaries) {
      teamOneWins += summary.teamOneWins;
      teamTwoWins += summary.teamTwoWins;
      totalHands += summary.totalHands;
      totalRounds += summary.totalRounds;
      totalTrucoCalls += summary.totalTrucoCalls;
      totalTrucoRaises += summary.totalTrucoRaises;
      totalTrucoAccepts += summary.totalTrucoAccepts;
      totalTrucoPasses += summary.totalTrucoPasses;
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
    }

    return AiSimulationSummary(
      config: config,
      teamOneWins: teamOneWins,
      teamTwoWins: teamTwoWins,
      totalHands: totalHands,
      totalRounds: totalRounds,
      totalTrucoCalls: totalTrucoCalls,
      totalTrucoRaises: totalTrucoRaises,
      totalTrucoAccepts: totalTrucoAccepts,
      totalTrucoPasses: totalTrucoPasses,
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
    );
  }
}

class AiMatchSimulator {
  const AiMatchSimulator();

  AiSimulationSummary run(AiSimulationConfig config) {
    var teamOneWins = 0;
    var teamTwoWins = 0;
    var totalHands = 0;
    var totalRounds = 0;
    var totalTrucoCalls = 0;
    var totalTrucoRaises = 0;
    var totalTrucoAccepts = 0;
    var totalTrucoPasses = 0;
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
      }
      totalHands += result.hands;
      totalRounds += result.rounds;
      totalTrucoCalls += result.trucoCalls;
      totalTrucoRaises += result.trucoRaises;
      totalTrucoAccepts += result.trucoAccepts;
      totalTrucoPasses += result.trucoPasses;
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
    }

    return AiSimulationSummary(
      config: config,
      teamOneWins: teamOneWins,
      teamTwoWins: teamTwoWins,
      totalHands: totalHands,
      totalRounds: totalRounds,
      totalTrucoCalls: totalTrucoCalls,
      totalTrucoRaises: totalTrucoRaises,
      totalTrucoAccepts: totalTrucoAccepts,
      totalTrucoPasses: totalTrucoPasses,
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
      if (!controller.isGameFinished) {
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
      alVerPlayed: metrics.alVerPlayed,
      alVerConceded: metrics.alVerConceded,
      signalOpportunities: metrics.signalOpportunities,
      signalsGiven: metrics.signalsGiven,
      strongSignalsGiven: metrics.strongSignalsGiven,
      voyATiRequests: metrics.voyATiRequests,
      venAMiOrders: metrics.venAMiOrders,
      venAMiProtectedRounds: metrics.venAMiProtectedRounds,
    );
  }

  void _playCurrentHand(
    ZapitiGameController controller,
    AiSimulationConfig config,
    Random random,
    _SimulationMetrics metrics,
  ) {
    final teamsThatConsideredTruco = <int>{};

    while (!controller.handFinished && !controller.isGameFinished) {
      _resolveAlVerIfNeeded(controller, config, metrics);
      if (controller.handFinished || controller.isGameFinished) return;

      if (controller.pendingTrucoValue != null) {
        _respondToTruco(controller, config, random, metrics);
        continue;
      }

      final player = controller.currentPlayer;
      if (_maybeCallTruco(
        controller,
        config,
        random,
        player,
        teamsThatConsideredTruco,
        metrics,
      )) {
        continue;
      }

      final card = _chooseCard(controller, config, random, player, metrics);
      final roundCompleted = controller.playCard(player, card);
      if (roundCompleted) {
        controller.resolveRound();
        metrics.rounds += 1;
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
    Set<int> teamsThatConsideredTruco,
    _SimulationMetrics metrics,
  ) {
    if (controller.roundHistory.length >= 2 ||
        controller.trucoState != TrucoNegotiationState.notStarted ||
        teamsThatConsideredTruco.contains(player.teamId) ||
        !controller.canCallTruco(
          player,
          value: TrucoRules.firstTrucoValue,
          actorPlayerId: player.id,
        )) {
      return false;
    }

    teamsThatConsideredTruco.add(player.teamId);
    final hand = controller.hands[player.id] ?? const <SpanishCard>[];
    if (hand.isEmpty) return false;

    final teamId = player.teamId;
    final opponentTeamId = TeamRules.opponentOf(teamId);
    final teamCards = _teamCards(controller, teamId);
    final memory = BotMemoryContext.from(
      bot: player,
      playedCards: controller.playedCards,
      roundHistory: controller.roundHistory,
    );
    final ownMaxStrength = hand
        .map(ZapitiRules.strength)
        .reduce((best, current) => current > best ? current : best);
    final needsPoints =
        controller.score[teamId]! < controller.score[opponentTeamId]! ||
            memory.teamIsUnderRoundPressure;
    final shouldCall = BotTrucoStrategy.shouldCallWithRoll(
      difficulty: _difficultyFor(config, teamId),
      roll: random.nextDouble(),
      teamScore: _teamHandScore(controller, teamId),
      ownMaxStrength: ownMaxStrength,
      handStrength: BotTrucoStrategy.evaluateHandStrength(teamCards),
      cardsOnTable: controller.playedCards.length,
      teamRoundWins: controller.roundWins[teamId]!,
      opponentRoundWins: controller.roundWins[opponentTeamId]!,
      teamHasStrongSignal: false,
      opponentHasStrongSignal: false,
      isCompanion: false,
      needsPoints: needsPoints,
      scoreGap: controller.score[teamId]! - controller.score[opponentTeamId]!,
      opponentsSpentPower: memory.opponentsSpentPower,
      teamSpentPower: memory.teamSpentPower,
    );
    final shouldBluff = shouldCall
        ? false
        : BotBluffStrategy.shouldBluffCall(
            difficulty: _difficultyFor(config, teamId),
            roll: random.nextDouble(),
            teamScore: _teamHandScore(controller, teamId),
            ownMaxStrength: ownMaxStrength,
            cardsOnTable: controller.playedCards.length,
            teamRoundWins: controller.roundWins[teamId]!,
            opponentRoundWins: controller.roundWins[opponentTeamId]!,
            teamHasStrongSignal: false,
            opponentHasStrongSignal: false,
            needsPoints: needsPoints,
            opponentsSpentPower: memory.opponentsSpentPower,
            teamSpentPower: memory.teamSpentPower,
            teamIsUnderRoundPressure: memory.teamIsUnderRoundPressure,
            scoreGap:
                controller.score[teamId]! - controller.score[opponentTeamId]!,
          );

    if (!shouldCall && !shouldBluff) return false;

    controller.callTruco(
      player,
      value: TrucoRules.firstTrucoValue,
      actorPlayerId: player.id,
    );
    metrics.trucoCalls += 1;
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
    final raiseValue = _chooseRaiseValue(
      controller,
      config,
      random,
      teamId,
      responder,
      pendingValue,
    );
    if (raiseValue != null) {
      controller.raiseTruco(
        responder,
        value: raiseValue,
        actorPlayerId: responder.id,
      );
      metrics.trucoRaises += 1;
      return;
    }

    if (_shouldAcceptTruco(controller, config, random, teamId, pendingValue)) {
      controller.acceptTruco(teamId: teamId, actorPlayerId: responder.id);
      metrics.trucoAccepts += 1;
    } else {
      controller.passTruco(passingTeamId: teamId, actorPlayerId: responder.id);
      metrics.trucoPasses += 1;
    }
  }

  int? _chooseRaiseValue(
    ZapitiGameController controller,
    AiSimulationConfig config,
    Random random,
    int teamId,
    Player responder,
    int pendingValue,
  ) {
    final strengths = _teamCards(controller, teamId)
        .map(ZapitiRules.strength)
        .toList()
      ..sort();
    final opponentTeamId = TeamRules.opponentOf(teamId);
    final memory = BotMemoryContext.from(
      bot: responder,
      playedCards: controller.playedCards,
      roundHistory: controller.roundHistory,
    );
    final isWinningReparto =
        controller.roundWins[teamId]! > controller.roundWins[opponentTeamId]!;
    final raiseValue = BotTrucoRaiseStrategy.chooseRaiseValue(
      difficulty: _difficultyFor(config, teamId),
      pendingValue: pendingValue,
      maxAllowedValue: controller.maxAllowedTrucoValueForTeam(teamId),
      strengths: strengths,
      teamScore: _teamHandScore(controller, teamId),
      hasStrongSignal: false,
      isWinningReparto: isWinningReparto,
      sawOpponentStrongSignal: false,
      canCloseHand: controller.roundWins[teamId]! > 0,
      mustSaveHand: controller.roundWins[opponentTeamId]! > 0,
      needsPoints:
          controller.score[teamId]! < controller.score[opponentTeamId]! ||
              memory.teamIsUnderRoundPressure,
      scoreGap: controller.score[teamId]! - controller.score[opponentTeamId]!,
      roll: random.nextDouble(),
    );
    if (controller.raiseOptions.contains(raiseValue)) return raiseValue;

    final bluffValue = BotBluffStrategy.bluffRaiseValue(
      difficulty: _difficultyFor(config, teamId),
      roll: random.nextDouble(),
      pendingValue: pendingValue,
      maxAllowedValue: controller.maxAllowedTrucoValueForTeam(teamId),
      teamScore: _teamHandScore(controller, teamId),
      hasStrongSignal: false,
      sawOpponentStrongSignal: false,
      needsPoints:
          controller.score[teamId]! < controller.score[opponentTeamId]! ||
              memory.teamIsUnderRoundPressure,
      isWinningReparto: isWinningReparto,
      opponentsSpentPower: memory.opponentsSpentPower,
      teamSpentPower: memory.teamSpentPower,
      scoreGap: controller.score[teamId]! - controller.score[opponentTeamId]!,
    );
    return controller.raiseOptions.contains(bluffValue) ? bluffValue : null;
  }

  bool _shouldAcceptTruco(
    ZapitiGameController controller,
    AiSimulationConfig config,
    Random random,
    int teamId,
    int pendingValue,
  ) {
    if (pendingValue > controller.maxAllowedTrucoValue) return false;
    if (BotTableRead.currentRoundIsUnsavableForTeam(
      teamId: teamId,
      players: controller.players,
      hands: controller.hands,
      playedCards: controller.playedCards,
    )) {
      return false;
    }

    final profileDifficulty = _difficultyFor(config, teamId);
    final profile = DifficultyProfiles.byLevel(profileDifficulty);
    final opponentTeamId = TeamRules.opponentOf(teamId);
    final responder = _responderFor(controller, teamId);
    final memory = BotMemoryContext.from(
      bot: responder,
      playedCards: controller.playedCards,
      roundHistory: controller.roundHistory,
    );
    return BotTrucoResponseStrategy.shouldAccept(
      difficulty: profileDifficulty,
      pendingValue: pendingValue,
      maxAllowedValue: controller.maxAllowedTrucoValue,
      teamScoreEstimate: _teamHandScore(controller, teamId),
      handStrength: BotTrucoStrategy.evaluateHandStrength(
        _teamCards(controller, teamId),
      ),
      cardsOnTable: controller.playedCards.length,
      canCloseHand: controller.roundWins[teamId]! > 0,
      mustSaveHand: controller.roundWins[opponentTeamId]! > 0,
      hasStrongSignal: false,
      opponentHasStrongSignal: profile.readsOpponentSignals && false,
      needsPoints:
          controller.score[teamId]! < controller.score[opponentTeamId]! ||
              memory.teamIsUnderRoundPressure,
      scoreGap: controller.score[teamId]! - controller.score[opponentTeamId]!,
      currentRoundUnsavable: false,
      roll: random.nextDouble(),
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
    _trackSignals(controller, config, metrics);
  }

  List<SpanishCard> _teamCards(ZapitiGameController controller, int teamId) {
    return controller.players
        .where((player) => player.teamId == teamId)
        .expand(
            (player) => controller.hands[player.id] ?? const <SpanishCard>[])
        .toList();
  }

  int _teamHandScore(ZapitiGameController controller, int teamId) {
    final strengths = _teamCards(controller, teamId)
        .map(ZapitiRules.strength)
        .toList()
      ..sort();
    if (strengths.isEmpty) return 0;

    final strongest = strengths.last;
    final second = strengths.length > 1 ? strengths[strengths.length - 2] : 0;
    final third = strengths.length > 2 ? strengths[strengths.length - 3] : 0;
    return strongest + (second ~/ 2) + (third ~/ 3);
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
  int alVerPlayed = 0;
  int alVerConceded = 0;
  int signalOpportunities = 0;
  int signalsGiven = 0;
  int strongSignalsGiven = 0;
  int voyATiRequests = 0;
  int venAMiOrders = 0;
  int venAMiProtectedRounds = 0;
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
  final int alVerPlayed;
  final int alVerConceded;
  final int signalOpportunities;
  final int signalsGiven;
  final int strongSignalsGiven;
  final int voyATiRequests;
  final int venAMiOrders;
  final int venAMiProtectedRounds;

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
    required this.alVerPlayed,
    required this.alVerConceded,
    required this.signalOpportunities,
    required this.signalsGiven,
    required this.strongSignalsGiven,
    required this.voyATiRequests,
    required this.venAMiOrders,
    required this.venAMiProtectedRounds,
  });
}
