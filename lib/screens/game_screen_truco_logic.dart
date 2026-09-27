part of 'game_screen.dart';

const _botBetValueEvaluator = BotBetValueEvaluator();

extension _GameScreenTrucoLogic on _GameScreenState {
  void _humanCallsTruco() {
    if (!_canHumanCallTruco || _isGameFinished) return;
    if (_isMultiplayerMatch && !_ensureMultiplayerActionConnection()) return;

    final value = _game.nextTrucoValueForPlayer(_humanPlayer);
    if (value == null) return;
    if (_isGuidedTutorialMatch) {
      final scenario = _guidedTutorialScenarios[_guidedTutorialScenarioIndex];
      if (scenario.expectedAction != _TutorialScenarioAction.callTruco) {
        unawaited(_advanceGuidedTutorialAfterSuccess(correct: false));
        return;
      }
    }
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
      unawaited(_advanceGuidedTutorialAfterSuccess(correct: true));
      return;
    }
    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.activeRoomId;
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
    if (_isMultiplayerMatch && !_ensureMultiplayerActionConnection()) return;

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
    _closeIncomingTrucoOverlay(
      response: 'accept',
      actorPlayerId: _humanPlayer.id,
      value: _handValue,
    );
    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.activeRoomId;
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
    if (_isMultiplayerMatch && !_ensureMultiplayerActionConnection()) return;

    final passingTeamId = _game.respondingTrucoTeamId;
    if (passingTeamId == null) {
      return;
    }
    if (_isGuidedTutorialMatch) {
      final scenario = _guidedTutorialScenarios[_guidedTutorialScenarioIndex];
      if (scenario.expectedAction != _TutorialScenarioAction.passTruco) {
        unawaited(_advanceGuidedTutorialAfterSuccess(correct: false));
        return;
      }
    }
    _updateState(() {
      _showTemporaryPlayerMessage(_humanPlayer.id, context.tr('passSpeech'));
      _isWaitingHumanTrucoResponse = false;
      _passTruco(
        passingTeamId: passingTeamId,
        actorPlayerId: _humanPlayer.id,
      );
    });
    _closeIncomingTrucoOverlay(
      response: 'pass',
      actorPlayerId: _humanPlayer.id,
      value: _pendingTrucoValue,
    );
    if (_isGuidedTutorialMatch) {
      unawaited(_advanceGuidedTutorialAfterSuccess(correct: true));
      return;
    }
    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.activeRoomId;
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
    if (_isMultiplayerMatch && !_ensureMultiplayerActionConnection()) return;

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
    _closeIncomingTrucoOverlay(
      response: 'raise',
      actorPlayerId: _humanPlayer.id,
      value: value,
    );
    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.activeRoomId;
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
    _logGameplay('bot', 'truco_response_start', fields: {
      'pendingValue': _pendingTrucoValue,
      'callerTeamId': _trucoCallerTeamId,
    });

    // Bot-to-human truco responses should surface quickly; the decision is
    // already made, so a long pause only feels like UI lag.
    await _botDelay(180);
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
      _openIncomingTrucoOverlay(
        caller: _players.firstWhere((player) => player.teamId == callerTeamId),
        value: pendingValue,
        source: 'bot_response',
      );
      return;
    }

    final respondingPlayer = _teamBotResponderPlayer(respondingTeamId);
    final responseAction = _betEvaluatorChoose(respondingPlayer);
    final accepts = responseAction?.type == BetActionType.accept ||
        responseAction?.type == BetActionType.call;
    final raiseValue = responseAction?.type == BetActionType.call
        ? responseAction!.value
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
    _logGameplay('bot', 'truco_response_end', fields: {
      'respondingTeamId': respondingTeamId,
      'accepted': accepts,
      'raiseValue': raiseValue,
      'handFinished': _handFinished,
    });

    if (!mounted ||
        version != _handVersion ||
        _handFinished ||
        _isWaitingHumanTrucoResponse) {
      return;
    }
    _advanceBots(
      skipBetForPlayerId:
          accepts && raiseValue == null && _isLocalBotPlayer(_currentPlayer)
              ? _currentPlayer.id
              : null,
    );
  }

  int? _botBetValue(Player bot) {
    final rollOverride = _nextBotBetRollForTesting;
    _nextBotBetRollForTesting = null;
    if (!_isLocalBotPlayer(bot)) return null;
    final forcedByOrder = _forceBetEvaluationRequestedPlayerIds.remove(bot.id);
    if (forcedByOrder && bot.teamId == _humanPlayer.teamId) {
      return _game
          .legalBetActionsForPlayer(bot)
          .where((action) => action.type == BetActionType.call)
          .firstOrNull
          ?.value;
    }

    // Direct card orders must be resolved before any automatic truco call.
    final hasVoyATiOrder = _activeStrategicSignals.any(
      (signal) =>
          signal.type == StrategicSignalType.voyATi &&
          signal.teamId == bot.teamId &&
          signal.handVersion == _handVersion &&
          signal.trickIndex == _roundHistory.length,
    );
    final hasVenAMiOrder = _activeStrategicSignals.any(
      (signal) =>
          signal.type == StrategicSignalType.venAMi &&
          signal.teamId == bot.teamId &&
          signal.handVersion == _handVersion &&
          signal.trickIndex == _roundHistory.length,
    );
    if (_forceHighestRequestedPlayerIds.contains(bot.id) ||
        hasVoyATiOrder ||
        hasVenAMiOrder) {
      return null;
    }
    if (_pendingTrucoValue != null ||
        _handFinished ||
        _roundHistory.length >= 2 ||
        _game.trucoState == TrucoNegotiationState.awaitingResponse) {
      return null;
    }

    if (rollOverride != null && rollOverride >= 0.99) return null;

    final action = _betEvaluatorChoose(bot);
    return action?.value;
  }

  BetAction? _betEvaluatorChoose(Player player) {
    final opponent = TeamRules.opponentOf(player.teamId);
    final evaluation = _botBetValueEvaluator.evaluateHand(
      ownHand: _hands[player.id] ?? const <SpanishCard>[],
      cardsOnTable: _playedCards.length,
      teamRoundWins: _roundWins[player.teamId]!,
      opponentRoundWins: _roundWins[opponent]!,
      hasStrongSignal: _isStrongSignal(_teamSignalsByTeam[player.teamId]),
      opponentHasStrongSignal:
          _isStrongSignal(_opponentSignalsSeenByTeam[player.teamId]),
    );
    final legalActions = _game.legalBetActionsForPlayer(player);
    final chosen = _botBetValueEvaluator.chooseAction(
      legalActions: legalActions,
      hand: evaluation,
      teamScore: _score[player.teamId]!,
      opponentScore: _score[opponent]!,
      targetScore: _GameScreenState._targetScore,
      acceptedValue: _game.handValue,
      pendingValue: _game.pendingTrucoValue ?? _game.handValue,
      difficulty: _botDifficultyFor(player),
    );
    final openingCalls = legalActions
        .where(
            (action) => action.type == BetActionType.call && action.value == 3)
        .toList();
    if (openingCalls.isNotEmpty &&
        !_game.betState.responsePending &&
        _game.handValue == 1) {
      const openingCall = BetAction.call(3);
      final openingValue = _botBetValueEvaluator.actionValue(
        action: openingCall,
        hand: evaluation,
        teamScore: _score[player.teamId]!,
        opponentScore: _score[opponent]!,
        targetScore: _GameScreenState._targetScore,
        acceptedValue: _game.handValue,
        pendingValue: _game.handValue,
        proposedValue: 3,
        difficulty: _botDifficultyFor(player),
      );
      final difficulty = _botDifficultyFor(player);
      final requiredMargin =
          BotBetValueEvaluator.openingMarginForDifficulty(difficulty) +
              (1 - evaluation.confidence).clamp(0.0, 1.0) * 0.5 +
              (difficulty >= 5 ? 0.15 : 0.05);
      _logGameplay('bet', 'opening_truco_evaluation', fields: {
        'player': player.id,
        'estimatedWinProbability': evaluation.winProbability,
        'openingActionValue': openingValue,
        'requiredMargin': requiredMargin,
        'decision': chosen?.type == BetActionType.call,
      });
    }
    return chosen;
  }

  void _sendMultiplayerTrucoAcceptIfNeeded(Player player) {
    if (!_isMultiplayerMatch) return;
    if (!_canSendMultiplayerAction) return;
    final socket = MultiplayerSessionStore.instance.socket;
    final roomId = MultiplayerSessionStore.instance.activeRoomId;
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
    if (!_canSendMultiplayerAction) return;
    final socket = MultiplayerSessionStore.instance.socket;
    final roomId = MultiplayerSessionStore.instance.activeRoomId;
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
    if (!_canSendMultiplayerAction) return;
    final socket = MultiplayerSessionStore.instance.socket;
    final roomId = MultiplayerSessionStore.instance.activeRoomId;
    if (socket != null && socket.isConnected && roomId != null) {
      socket.raiseTruco(
        roomId: roomId,
        playerId: player.id,
        value: value,
        expectedStateVersion: _multiplayerStateVersion,
      );
    }
  }
}
