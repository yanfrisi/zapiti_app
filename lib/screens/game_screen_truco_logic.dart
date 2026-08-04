part of 'game_screen.dart';

extension _GameScreenTrucoLogic on _GameScreenState {
  void _humanCallsTruco() {
    if (!_canHumanCallTruco || _isGameFinished) return;

    final value = _game.nextTrucoValueForPlayer(_humanPlayer);
    if (value == null) return;
    var didCall = false;

    _updateState(() {
      didCall = _callTruco(
        _humanPlayer,
        value: value,
        actorPlayerId: _humanPlayer.id,
      );
      if (!didCall) return;
      if (_isMultiplayerMatch) {
        _isAutoPlaying = false;
      } else {
        _isAutoPlaying = true;
        _isWaitingHumanTrucoResponse = false;
      }
    });
    if (!didCall) return;
    if (_isGuidedTutorialMatch) {
      final scenario = _guidedTutorialScenarios[_guidedTutorialScenarioIndex];
      final correct =
          scenario.expectedAction == _TutorialScenarioAction.callTruco;
      unawaited(_advanceGuidedTutorialAfterSuccess(correct: correct));
      return;
    }
    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        socket.callTruco(
          roomId: roomId,
          playerId: playerId,
          value: value,
          expectedStateVersion: _multiplayerStateVersion,
        );
      }
      if (_teamNeedsLocalBotTrucoResponse(_game.respondingTrucoTeamId)) {
        _resolveBotResponseToTruco();
      }
      return;
    }
    _resolveBotResponseToTruco();
  }

  void _humanAcceptsTruco() {
    if (!_isWaitingHumanTrucoResponse ||
        _isGameFinished ||
        _pendingTrucoValue == null) {
      return;
    }

    final respondingTeamId = _game.respondingTrucoTeamId;
    if (respondingTeamId == null) return;

    _updateState(() {
      _acceptTruco(teamId: respondingTeamId, actorPlayerId: _humanPlayer.id);
      _showTemporaryPlayerMessage(
        _humanPlayer.id,
        context.tr('acceptTrucoSpeech'),
      );
      if (_isMultiplayerMatch) {
        _isWaitingHumanTrucoResponse = false;
        _isAutoPlaying = false;
      } else {
        _isWaitingHumanTrucoResponse = false;
        _isAutoPlaying = true;
      }
    });
    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        socket.acceptTruco(
          roomId: roomId,
          playerId: playerId,
          expectedStateVersion: _multiplayerStateVersion,
        );
      }
      return;
    }
    _advanceBots();
  }

  void _humanPassesTruco() {
    if (_isGameFinished ||
        !_isWaitingHumanTrucoResponse ||
        _trucoCallerTeamId == null ||
        _pendingTrucoValue == null) {
      return;
    }

    final passingTeamId = _game.respondingTrucoTeamId;
    if (passingTeamId == null) {
      return;
    }
    _updateState(() {
      _showTemporaryPlayerMessage(_humanPlayer.id, context.tr('passSpeech'));
      _isWaitingHumanTrucoResponse = false;
      _passTruco(
        passingTeamId: passingTeamId,
        actorPlayerId: _humanPlayer.id,
      );
    });
    if (_isGuidedTutorialMatch) {
      final scenario = _guidedTutorialScenarios[_guidedTutorialScenarioIndex];
      final correct =
          scenario.expectedAction == _TutorialScenarioAction.passTruco;
      unawaited(_advanceGuidedTutorialAfterSuccess(correct: correct));
      return;
    }
    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        socket.passTruco(
          roomId: roomId,
          playerId: playerId,
          expectedStateVersion: _multiplayerStateVersion,
        );
      }
      return;
    }
  }

  void _humanRaisesTruco(int value) {
    if (!_isWaitingHumanTrucoResponse ||
        _pendingTrucoValue == null ||
        !_humanRaiseOptions.contains(value)) {
      return;
    }

    var didRaise = false;
    final raisingTeamId = _game.respondingTrucoTeamId;
    if (raisingTeamId == null) {
      return;
    }
    final raisingPlayer = _teamLeadPlayer(raisingTeamId);
    _updateState(() {
      didRaise = _raiseTruco(
        raisingPlayer,
        value: value,
        actorPlayerId: _humanPlayer.id,
      );
      if (!didRaise) return;
      if (_isMultiplayerMatch) {
        _isWaitingHumanTrucoResponse = false;
        _isAutoPlaying = false;
      } else {
        _isWaitingHumanTrucoResponse = false;
        _isAutoPlaying = true;
      }
    });
    if (!didRaise) return;
    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        socket.raiseTruco(
          roomId: roomId,
          playerId: playerId,
          value: value,
          expectedStateVersion: _multiplayerStateVersion,
        );
      }
      if (_teamNeedsLocalBotTrucoResponse(_game.respondingTrucoTeamId)) {
        _resolveBotResponseToTruco();
      }
      return;
    }
    _resolveBotResponseToTruco();
  }

  bool _callTruco(
    Player player, {
    required int value,
    String? actorPlayerId,
  }) {
    if (!_game.canCallTruco(
      player,
      value: value,
      actorPlayerId: actorPlayerId,
    )) {
      return false;
    }

    _game.callTruco(player, value: value, actorPlayerId: actorPlayerId);
    _showTemporaryPlayerMessage(player.id, _trucoSpeechFor(value));
    return true;
  }

  void _acceptTruco({required int teamId, String? actorPlayerId}) {
    if (!_game.canAcceptTruco(
      teamId: teamId,
      actorPlayerId: actorPlayerId,
    )) {
      return;
    }
    _game.acceptTruco(teamId: teamId, actorPlayerId: actorPlayerId);
  }

  bool _raiseTruco(
    Player player, {
    required int value,
    String? actorPlayerId,
  }) {
    if (!_game.canCallTruco(
      player,
      value: value,
      actorPlayerId: actorPlayerId,
    )) {
      return false;
    }
    _game.raiseTruco(player, value: value, actorPlayerId: actorPlayerId);
    _showTemporaryPlayerMessage(player.id, _trucoSpeechFor(value));
    return true;
  }

  void _passTruco({required int passingTeamId, String? actorPlayerId}) {
    if (!_game.canPassTruco(
      passingTeamId: passingTeamId,
      actorPlayerId: actorPlayerId,
    )) {
      return;
    }
    _game.passTruco(
      passingTeamId: passingTeamId,
      actorPlayerId: actorPlayerId,
    );
  }

  bool _isLegalTrucoCall(Player player, int value) {
    return _game.canCallTruco(player, value: value, actorPlayerId: player.id);
  }

  String _trucoSpeechFor(int value) {
    if (value == TrucoRules.firstTrucoValue) return context.tr('trucoSpeech');
    return context.tr('raiseSpeech', params: {'value': value});
  }

  Player _teamLeadPlayer(int teamId) {
    return _players.firstWhere((player) => player.teamId == teamId);
  }

  Player _teamBotResponderPlayer(int teamId) {
    if (_isMultiplayerMatch) {
      final localBots = _players.where(
        (player) => player.teamId == teamId && _isLocalBotPlayer(player),
      );
      if (localBots.isNotEmpty) return localBots.first;
    }
    return _teamLeadPlayer(teamId);
  }

  Future<void> _resolveBotResponseToTruco() async {
    final version = _handVersion;

    await _botDelay(900);
    if (!mounted ||
        version != _handVersion ||
        _handFinished ||
        _pendingTrucoValue == null ||
        _trucoCallerTeamId == null) {
      return;
    }

    final callerTeamId = _trucoCallerTeamId!;
    final pendingValue = _pendingTrucoValue!;
    final respondingTeamId = TeamRules.opponentOf(callerTeamId);
    if (_isMultiplayerMatch &&
        !_teamNeedsLocalBotTrucoResponse(respondingTeamId)) {
      return;
    }
    if (respondingTeamId == _humanPlayer.teamId) {
      _updateState(() {
        _isAutoPlaying = false;
        _isWaitingHumanTrucoResponse = true;
        _status = context.tr('answerYourTeam');
      });
      return;
    }

    final respondingPlayer = _teamBotResponderPlayer(respondingTeamId);
    final accepts = _shouldTeamAcceptTruco(
      respondingTeamId,
      pendingValue: pendingValue,
    );
    final raiseValue = accepts
        ? _botRaiseValue(respondingTeamId, pendingValue: pendingValue)
        : null;

    _updateState(() {
      if (raiseValue != null &&
          _raiseTruco(
            respondingPlayer,
            value: raiseValue,
            actorPlayerId: respondingPlayer.id,
          )) {
        _sendMultiplayerTrucoRaiseIfNeeded(respondingPlayer, raiseValue);
        _isAutoPlaying = false;
        _isWaitingHumanTrucoResponse =
            _teamNeedsLocalHumanTrucoResponse(_game.respondingTrucoTeamId);
        _status = _isWaitingHumanTrucoResponse
            ? context.tr(
                'teamRaisesAnswer',
                params: {'team': respondingTeamId, 'value': raiseValue},
              )
            : context.tr(
                'teamRaises',
                params: {'team': respondingTeamId, 'value': raiseValue},
              );
      } else if (accepts) {
        _acceptTruco(
            teamId: respondingTeamId, actorPlayerId: respondingPlayer.id);
        _sendMultiplayerTrucoAcceptIfNeeded(respondingPlayer);
        _showTemporaryPlayerMessage(
          respondingPlayer.id,
          context.tr('weAcceptSpeech'),
        );
      } else {
        _showTemporaryPlayerMessage(
          respondingPlayer.id,
          context.tr('wePassSpeech'),
        );
        _passTruco(
          passingTeamId: respondingTeamId,
          actorPlayerId: respondingPlayer.id,
        );
        _sendMultiplayerTrucoPassIfNeeded(respondingPlayer);
      }
    });

    if (!mounted ||
        version != _handVersion ||
        _handFinished ||
        _isWaitingHumanTrucoResponse) {
      return;
    }
    _advanceBots();
  }

  bool _shouldBotCallTruco(Player bot) {
    if (!_isLocalBotPlayer(bot) || bot.teamId == _humanPlayer.teamId) {
      return false;
    }
    if (_pendingTrucoValue != null ||
        _handFinished ||
        _roundHistory.length >= 2 ||
        _game.trucoState != TrucoNegotiationState.notStarted ||
        !_game.canCallTruco(
          bot,
          value: TrucoRules.firstTrucoValue,
          actorPlayerId: bot.id,
        )) {
      return false;
    }

    final hand = _hands[bot.id] ?? [];
    if (hand.isEmpty) return false;
    final alreadyConsidered =
        _aiTeamsConsideredTrucoThisHand.contains(bot.teamId);
    if (alreadyConsidered) return false;
    _aiTeamsConsideredTrucoThisHand.add(bot.teamId);

    final teamSignal = _teamSignalsByTeam[bot.teamId];
    final opponentSignal = _opponentSignalsSeenByTeam[bot.teamId];
    final teamScore = _teamHandScore(bot.teamId);
    final otherTeam = TeamRules.opponentOf(bot.teamId);
    final needsPoints = _score[bot.teamId]! < _score[otherTeam]!;
    final ownMaxStrength = hand
        .map(ZapitiRules.strength)
        .reduce((best, current) => current > best ? current : best);
    final memory = BotMemoryContext.from(
      bot: bot,
      playedCards: _playedCards,
      roundHistory: _roundHistory,
    );
    final pressuredByScoreOrRounds =
        needsPoints || memory.teamIsUnderRoundPressure;
    final teamCards = _teamCardsFor(bot.teamId);
    final handStrength = BotTrucoStrategy.evaluateHandStrength(teamCards);
    final profile = DifficultyProfiles.byLevel(_selectedDifficulty);
    final callChance = BotTrucoStrategy.callChance(
      profile,
      handStrength: handStrength,
      teamScore: teamScore,
      ownMaxStrength: ownMaxStrength,
      cardsOnTable: _playedCards.length,
      teamRoundWins: _roundWins[bot.teamId]!,
      needsPoints: pressuredByScoreOrRounds,
      teamHasStrongSignal: _isStrongSignal(teamSignal),
      isCompanion: false,
      scoreGap: _score[bot.teamId]! - _score[otherTeam]!,
      opponentsSpentPower: memory.opponentsSpentPower,
      teamSpentPower: memory.teamSpentPower,
    );
    final callRoll = _random.nextDouble();
    final shouldCall = BotTrucoStrategy.shouldCallWithRoll(
      difficulty: _selectedDifficulty,
      roll: callRoll,
      teamScore: teamScore,
      ownMaxStrength: ownMaxStrength,
      handStrength: handStrength,
      cardsOnTable: _playedCards.length,
      teamRoundWins: _roundWins[bot.teamId]!,
      opponentRoundWins: _roundWins[otherTeam]!,
      teamHasStrongSignal: _isStrongSignal(teamSignal),
      opponentHasStrongSignal: _isStrongSignal(opponentSignal),
      isCompanion: false,
      needsPoints: pressuredByScoreOrRounds,
      scoreGap: _score[bot.teamId]! - _score[otherTeam]!,
      opponentsSpentPower: memory.opponentsSpentPower,
      teamSpentPower: memory.teamSpentPower,
    );
    if (kDebugMode) {
      debugPrint(
        '[AI TRUCO] team=${bot.teamId} difficulty=$_selectedDifficulty '
        'handStrength=${handStrength.toStringAsFixed(2)} '
        'chance=${callChance.toStringAsFixed(3)} '
        'roll=${callRoll.toStringAsFixed(3)} result=$shouldCall '
        'pending=${_game.trucoState == TrucoNegotiationState.awaitingResponse} '
        'alreadyConsidered=$alreadyConsidered',
      );
    }
    if (shouldCall) {
      return true;
    }

    final bluffRoll = _random.nextDouble();
    final shouldBluff = BotBluffStrategy.shouldBluffCall(
      difficulty: _selectedDifficulty,
      roll: bluffRoll,
      teamScore: teamScore,
      ownMaxStrength: ownMaxStrength,
      cardsOnTable: _playedCards.length,
      teamRoundWins: _roundWins[bot.teamId]!,
      opponentRoundWins: _roundWins[otherTeam]!,
      teamHasStrongSignal: _isStrongSignal(teamSignal),
      opponentHasStrongSignal: _isStrongSignal(opponentSignal),
      needsPoints: pressuredByScoreOrRounds,
      opponentsSpentPower: memory.opponentsSpentPower,
      teamSpentPower: memory.teamSpentPower,
      teamIsUnderRoundPressure: memory.teamIsUnderRoundPressure,
      scoreGap: _score[bot.teamId]! - _score[otherTeam]!,
    );
    if (kDebugMode) {
      debugPrint(
        '[AI TRUCO] team=${bot.teamId} '
        'bluffRoll=${bluffRoll.toStringAsFixed(3)} '
        'bluff=$shouldBluff alreadyConsidered=true',
      );
    }
    return shouldBluff;
  }

  int? _botRaiseValue(int teamId, {required int pendingValue}) {
    final responder = _teamBotResponderPlayer(teamId);
    final memory = BotMemoryContext.from(
      bot: responder,
      playedCards: _playedCards,
      roundHistory: _roundHistory,
    );
    final teamCards = _players
        .where((player) => player.teamId == teamId)
        .expand((player) => _hands[player.id] ?? <SpanishCard>[])
        .toList();
    final strengths = teamCards.map(ZapitiRules.strength).toList()..sort();
    final isWinningReparto =
        _roundWins[teamId]! > _roundWins[TeamRules.opponentOf(teamId)]!;
    final otherTeam = TeamRules.opponentOf(teamId);
    final raiseValue = BotTrucoRaiseStrategy.chooseRaiseValue(
      difficulty: _selectedDifficulty,
      pendingValue: pendingValue,
      maxAllowedValue: _game.maxAllowedTrucoValueForTeam(teamId),
      strengths: strengths,
      teamScore: _teamHandScore(teamId),
      hasStrongSignal: _isStrongSignal(_teamSignalsByTeam[teamId]),
      isWinningReparto: isWinningReparto,
      sawOpponentStrongSignal: _opponentSignalsSeenByTeam.containsKey(teamId),
      canCloseHand: _roundWins[teamId]! > 0,
      mustSaveHand: _roundWins[otherTeam]! > 0,
      needsPoints: _score[teamId]! < _score[otherTeam]! ||
          memory.teamIsUnderRoundPressure,
      scoreGap: _score[teamId]! - _score[otherTeam]!,
      roll: _random.nextDouble(),
    );
    if (_game.raiseOptions.contains(raiseValue)) return raiseValue;

    final bluffValue = BotBluffStrategy.bluffRaiseValue(
      difficulty: _selectedDifficulty,
      roll: _random.nextDouble(),
      pendingValue: pendingValue,
      maxAllowedValue: _game.maxAllowedTrucoValueForTeam(teamId),
      teamScore: _teamHandScore(teamId),
      hasStrongSignal: _isStrongSignal(_teamSignalsByTeam[teamId]),
      sawOpponentStrongSignal: _opponentSignalsSeenByTeam.containsKey(teamId),
      needsPoints: _score[teamId]! < _score[otherTeam]! ||
          memory.teamIsUnderRoundPressure,
      isWinningReparto: isWinningReparto,
      opponentsSpentPower: memory.opponentsSpentPower,
      teamSpentPower: memory.teamSpentPower,
      scoreGap: _score[teamId]! - _score[otherTeam]!,
    );
    return _game.raiseOptions.contains(bluffValue) ? bluffValue : null;
  }

  bool _shouldTeamAcceptTruco(int teamId, {required int pendingValue}) {
    if (pendingValue > _game.maxAllowedTrucoValue) return false;
    final otherTeam = TeamRules.opponentOf(teamId);
    final opponentSignal = _opponentSignalsSeenByTeam[teamId];
    final difficultyProfile = DifficultyProfiles.byLevel(_selectedDifficulty);
    if (_currentRoundIsUnsavableForTeam(teamId)) {
      return false;
    }
    if (difficultyProfile.readsOpponentSignals &&
        _isStrongSignal(opponentSignal) &&
        _roundWins[teamId] == 0 &&
        pendingValue > 3) {
      return false;
    }

    final teamCards = _teamCardsFor(teamId);
    final memory = BotMemoryContext.from(
      bot: _teamBotResponderPlayer(teamId),
      playedCards: _playedCards,
      roundHistory: _roundHistory,
    );
    return BotTrucoResponseStrategy.shouldAccept(
      difficulty: _selectedDifficulty,
      pendingValue: pendingValue,
      maxAllowedValue: _game.maxAllowedTrucoValue,
      teamScoreEstimate: _teamHandScore(teamId),
      handStrength: BotTrucoStrategy.evaluateHandStrength(teamCards),
      cardsOnTable: _playedCards.length,
      canCloseHand: _roundWins[teamId]! > 0,
      mustSaveHand: _roundWins[otherTeam]! > 0,
      hasStrongSignal: _isStrongSignal(_teamSignalsByTeam[teamId]),
      opponentHasStrongSignal:
          difficultyProfile.readsOpponentSignals && _isStrongSignal(opponentSignal),
      needsPoints:
          _score[teamId]! < _score[otherTeam]! || memory.teamIsUnderRoundPressure,
      scoreGap: _score[teamId]! - _score[otherTeam]!,
      currentRoundUnsavable: false,
      roll: _random.nextDouble(),
    );
  }

  bool _currentRoundIsUnsavableForTeam(int teamId) {
    return BotTableRead.currentRoundIsUnsavableForTeam(
      teamId: teamId,
      players: _players,
      hands: _hands,
      playedCards: _playedCards,
    );
  }

  void _sendMultiplayerTrucoAcceptIfNeeded(Player player) {
    if (!_isMultiplayerMatch) return;
    final socket = MultiplayerSessionStore.instance.socket;
    final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
    if (socket != null && socket.isConnected && roomId != null) {
      socket.acceptTruco(
        roomId: roomId,
        playerId: player.id,
        expectedStateVersion: _multiplayerStateVersion,
      );
    }
  }

  void _sendMultiplayerTrucoPassIfNeeded(Player player) {
    if (!_isMultiplayerMatch) return;
    final socket = MultiplayerSessionStore.instance.socket;
    final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
    if (socket != null && socket.isConnected && roomId != null) {
      socket.passTruco(
        roomId: roomId,
        playerId: player.id,
        expectedStateVersion: _multiplayerStateVersion,
      );
    }
  }

  void _sendMultiplayerTrucoRaiseIfNeeded(Player player, int value) {
    if (!_isMultiplayerMatch) return;
    final socket = MultiplayerSessionStore.instance.socket;
    final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
    if (socket != null && socket.isConnected && roomId != null) {
      socket.raiseTruco(
        roomId: roomId,
        playerId: player.id,
        value: value,
        expectedStateVersion: _multiplayerStateVersion,
      );
    }
  }

  int _teamHandScore(int teamId) {
    final strengths = _players
        .where((player) => player.teamId == teamId)
        .expand((player) => _hands[player.id] ?? <SpanishCard>[])
        .map(ZapitiRules.strength)
        .toList()
      ..sort();

    final signalBonus = _isStrongSignal(_teamSignalsByTeam[teamId]) ? 18 : 0;
    final capturedRisk =
        _isStrongSignal(_opponentSignalsSeenByTeam[teamId]) ? 18 : 0;
    return _handScoreFromStrengths(strengths) + signalBonus - capturedRisk;
  }

  int _handScoreFromStrengths(List<int> strengths) {
    if (strengths.isEmpty) return 0;

    final strongest = strengths.last;
    final second = strengths.length > 1 ? strengths[strengths.length - 2] : 0;
    final third = strengths.length > 2 ? strengths[strengths.length - 3] : 0;
    return strongest + (second ~/ 2) + (third ~/ 3);
  }
}
