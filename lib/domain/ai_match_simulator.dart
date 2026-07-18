import 'dart:math';

import 'bot_al_ver_strategy.dart';
import 'bot_bluff_strategy.dart';
import 'bot_memory_context.dart';
import 'bot_strategy.dart';
import 'bot_table_read.dart';
import 'bot_truco_raise_strategy.dart';
import 'bot_truco_strategy.dart';
import 'difficulty_profile.dart';
import 'difficulty_strategy.dart';
import 'player.dart';
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

    _startNewSimulatedHand(controller, random);
    metrics.hands += 1;

    while (!controller.isGameFinished &&
        metrics.hands <= config.maxHandsPerMatch) {
      _playCurrentHand(controller, config, random, metrics);
      if (!controller.isGameFinished) {
        _startNewSimulatedHand(controller, random);
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

      final card = _chooseCard(controller, config, random, player);
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
    final teamScore = _teamHandScore(controller, teamId);
    final canCloseHand = controller.roundWins[teamId]! > 0;
    final mustSaveHand = controller.roundWins[opponentTeamId]! > 0;
    final scorePressure =
        controller.score[teamId]! < controller.score[opponentTeamId]!;
    final tableDiscount = controller.playedCards.length >= 2 ? 14 : 6;
    final closingThreshold =
        _callThreshold(profileDifficulty, 94) - tableDiscount;

    if (canCloseHand && teamScore >= closingThreshold) return true;
    if (profile.impulsiveTrucoChance > 0 &&
        random.nextDouble() < profile.impulsiveTrucoChance) {
      return pendingValue <= 5;
    }
    if (canCloseHand &&
        teamScore >= _callThreshold(profileDifficulty, 86) &&
        pendingValue <= 6) {
      return true;
    }
    if (mustSaveHand &&
        teamScore >= _callThreshold(profileDifficulty, 85) &&
        pendingValue <= 5) {
      return true;
    }
    if (scorePressure &&
        teamScore >= _callThreshold(profileDifficulty, 105) &&
        pendingValue <= 6) {
      return true;
    }
    if (teamScore >= _callThreshold(profileDifficulty, 148)) {
      return pendingValue <= 8;
    }
    if (teamScore >= _callThreshold(profileDifficulty, 122)) {
      return pendingValue <= 5;
    }
    return teamScore >= _callThreshold(profileDifficulty, 100) &&
        pendingValue <= 3;
  }

  SpanishCard _chooseCard(
    ZapitiGameController controller,
    AiSimulationConfig config,
    Random random,
    Player player,
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
    final forceWinIfPossible = controller.handValue >= 6 ||
        controller.roundWins[opponentTeamId]! >
            controller.roundWins[player.teamId]!;

    final strategicCard = BotStrategy.chooseCard(
      player: player,
      hand: controller.hands[player.id] ?? const <SpanishCard>[],
      playedCards: controller.playedCards,
      teamRoundWins: controller.roundWins[player.teamId]!,
      opponentRoundWins: controller.roundWins[opponentTeamId]!,
      preserveStrongCards: controller.handValue < 6 ||
          memory.teammateWonLastRound ||
          memory.opponentsSpentPower,
      forceWinIfPossible: forceWinIfPossible,
      teammateStillToPlay: teammateStillToPlay && !memory.opponentsWonAnyRound,
      opponentStillToPlay: opponentStillToPlay,
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
  ) {
    final deck = ZapitiDeck.shuffled(random: random);
    controller.startNewHand(
      fixedHands: {
        for (var i = 0; i < controller.players.length; i++)
          controller.players[i].id: deck.skip(i * 3).take(3).toList(),
      },
    );
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

  int _callThreshold(int difficulty, int base) {
    return base + DifficultyProfiles.byLevel(difficulty).callThresholdModifier;
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
  });
}
