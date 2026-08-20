part of 'game_screen.dart';

extension _GameScreenPlayLogic on _GameScreenState {
  Map<String, Object?> _multiplayerMessageFields(MultiplayerMessage message) {
    return {
      'type': message.type.wireName,
      'roomId': message.roomId,
      'playerId': message.playerId,
      'messageId': message.messageId,
      'correlationId': message.correlationId,
      'payload': message.payload,
      'stateVersion': _multiplayerStateVersion,
      'handSequence': _multiplayerServerHandSequence,
      'currentPlayerId': _currentPlayer.id,
    };
  }

  Map<String, Object?> _clientMatchStateFields() {
    return {
      'stateVersion': _multiplayerStateVersion,
      'handSequence': _multiplayerServerHandSequence,
      'turnIndex': _game.turnIndex,
      'leadIndex': _game.leadIndex,
      'nextLeadIndex': _game.nextLeadIndex,
      'currentPlayerId': _currentPlayer.id,
      'playedCards': [
        for (final played in _playedCards)
          {
            'playerId': played.player.id,
            'card': cardToJson(played.card),
          },
      ],
      'score': _score,
      'roundWins': _roundWins,
      'handValue': _handValue,
      'pendingTrucoValue': _pendingTrucoValue,
      'isRoundAwaitingContinue': _isRoundAwaitingContinue,
      'handFinished': _handFinished,
      'status': _status,
    };
  }

  void _logClientIgnore(
    String event, {
    MultiplayerMessage? message,
    Map<String, Object?> fields = const {},
  }) {
    ZapitiLogger.warn('client_ignore', event, fields: {
      if (message != null) ..._multiplayerMessageFields(message),
      ...fields,
    });
  }

  void _logClientApply(
    String event, {
    MultiplayerMessage? message,
    Map<String, Object?> fields = const {},
  }) {
    ZapitiLogger.info('client_apply', event, fields: {
      if (message != null) ..._multiplayerMessageFields(message),
      ...fields,
    });
  }

  void _playHumanCard(SpanishCard card) {
    unawaited(_playHumanCardAfterConfirmation(card));
  }

  Future<void> _playHumanCardAfterConfirmation(SpanishCard card) async {
    if (!_isHumanTurn) return;
    if (_isMultiplayerMatch && !_ensureMultiplayerActionConnection()) return;
    if (_confirmCardPlay) {
      final confirmed = await _confirmCardPlayDialog(card);
      if (!confirmed || !mounted || !_isHumanTurn) return;
      if (_isMultiplayerMatch && !_ensureMultiplayerActionConnection()) return;
    }

    if (_isGuidedTutorialMatch) {
      await _handleGuidedTutorialCard(card);
      return;
    }

    var roundCompleted = false;
    _updateState(() {
      roundCompleted = _playCard(_humanPlayer, card);
    });
    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.activeRoomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        socket.playCard(
          roomId: roomId,
          playerId: playerId,
          card: card,
          expectedStateVersion: _multiplayerStateVersion,
        );
      }
      return;
    }
    if (roundCompleted) {
      _resolveRoundWithPause();
    } else {
      _advanceBots();
    }
  }

  Future<void> _handleGuidedTutorialCard(SpanishCard card) async {
    final scenario = _guidedTutorialScenarios[_guidedTutorialScenarioIndex];
    final correct =
        scenario.expectedAction == _TutorialScenarioAction.playCard &&
            card == scenario.expectedCard;
    await _advanceGuidedTutorialAfterSuccess(correct: correct);
  }

  Future<bool> _confirmCardPlayDialog(SpanishCard card) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ZapitiColors.cardCream,
          title: Text(context.tr('confirmPlayTitle')),
          content: Text(
            context.tr('confirmPlayBody', params: {'card': card.toString()}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.tr('playCard')),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _maybeShowBotSignal(
    Player bot,
    int version, {
    bool awaitReveal = true,
  }) async {
    if (_playersSignaledThisHand.contains(bot.id) ||
        _handFinished ||
        _isGameFinished ||
        version != _handVersion) {
      return;
    }

    final difficultyProfile = DifficultyProfiles.byLevel(_selectedDifficulty);
    final isRivalBot = bot.teamId != _humanPlayer.teamId;
    if (isRivalBot && !difficultyProfile.rivalsGiveSignals) {
      return;
    }

    final signal = SignalRules.signalForHand(_hands[bot.id] ?? const []);
    if (signal == null) return;

    _updateState(() {
      _playersSignaledThisHand.add(bot.id);
      _playerMessages[bot.id] = 'SENAL: $signal';
      _recordStrategicSignal(
        type: StrategicSignalType.cardSignal,
        issuer: bot,
        label: signal,
        visibility: isRivalBot
            ? StrategicSignalVisibility.observedByOpponents
            : StrategicSignalVisibility.teamOnly,
      );
      _teamSignalsByTeam[bot.teamId] = signal;
      _knownSignalsByTeam[bot.teamId] = signal;
    });

    final revealDuration = isRivalBot
        ? Duration(
            milliseconds: difficultyProfile.rivalSignalRevealMilliseconds,
          )
        : _GameScreenState._teammateBotSignalRevealDuration;
    if (!awaitReveal) {
      _playerMessageTimers.remove(bot.id)?.cancel();
      _playerMessageTimers[bot.id] = Timer(revealDuration, () {
        if (!mounted || version != _handVersion) return;
        _updateState(() {
          if (_playerMessages[bot.id] == 'SENAL: $signal') {
            _playerMessages.remove(bot.id);
          }
          _playerMessageTimers.remove(bot.id);
        });
      });
      return;
    }
    await Future<void>.delayed(revealDuration);
    if (!mounted || version != _handVersion) return;
    _updateState(() {
      if (_playerMessages[bot.id] == 'SENAL: $signal') {
        _playerMessages.remove(bot.id);
      }
    });
  }

  bool _playCard(Player player, SpanishCard card) {
    try {
      return _game.playCard(player, card);
    } on Object {
      return false;
    }
  }

  void _sendMultiplayerCardIfNeeded(Player player, SpanishCard card) {
    if (!_isMultiplayerMatch) return;
    if (!_canSendMultiplayerAction) return;
    final socket = MultiplayerSessionStore.instance.socket;
    final roomId = MultiplayerSessionStore.instance.activeRoomId;
    if (socket != null && socket.isConnected && roomId != null) {
      socket.playCard(
        roomId: roomId,
        playerId: player.id,
        card: card,
        expectedStateVersion: _multiplayerStateVersion,
      );
    }
  }

  void _sendMultiplayerTrucoCallIfNeeded(Player player, int value) {
    if (!_isMultiplayerMatch) return;
    if (!_canSendMultiplayerAction) return;
    final socket = MultiplayerSessionStore.instance.socket;
    final roomId = MultiplayerSessionStore.instance.activeRoomId;
    if (socket != null && socket.isConnected && roomId != null) {
      socket.callTruco(
        roomId: roomId,
        playerId: player.id,
        value: value,
        expectedStateVersion: _multiplayerStateVersion,
      );
    }
  }

  Future<void> _advanceBots() async {
    if (_game.alVerState == AlVerState.awaitingDecision) {
      return;
    }
    if (_isMultiplayerMatch && !_isLocalBotPlayer(_currentPlayer)) {
      return;
    }
    final version = _handVersion;
    _isAutoPlaying = true;

    while (mounted &&
        version == _handVersion &&
        !_handFinished &&
        !_isRoundAwaitingContinue &&
        !_isGameFinished &&
        _isLocalBotPlayer(_currentPlayer)) {
      final bot = _currentPlayer;
      final botHand = _hands[bot.id]!;
      final hasCompanionOrderWindow = _shouldOpenCompanionBotOrderWindow(bot);
      if (hasCompanionOrderWindow) {
        _beginCompanionBotOrderWindow(bot);
      }

      await _maybeShowBotSignal(
        bot,
        version,
        awaitReveal: !hasCompanionOrderWindow,
      );
      if (!mounted || version != _handVersion || _handFinished) return;

      final betValue = _botBetValue(bot);
      if (betValue != null) {
        _updateState(() {
          _callTruco(
            bot,
            value: betValue,
            actorPlayerId: bot.id,
          );
        });
        _sendMultiplayerTrucoCallIfNeeded(bot, betValue);

        await _botDelay(650);
        if (!mounted || version != _handVersion || _handFinished) return;

        _updateState(() {
          _isAutoPlaying = false;
          _isWaitingHumanTrucoResponse =
              _teamNeedsLocalHumanTrucoResponse(_game.respondingTrucoTeamId);
          _status = _isWaitingHumanTrucoResponse
              ? context.tr(
                  'playerCallsTruco',
                  params: {'name': _localizedPlayerName(bot)},
                )
              : context.tr(
                  'playerCallsTrucoShort',
                  params: {'name': _localizedPlayerName(bot)},
                );
        });
        if (_teamNeedsLocalBotTrucoResponse(_game.respondingTrucoTeamId)) {
          _resolveBotResponseToTruco();
        }
        return;
      }

      final didAskHumanToWin = _maybeCompanionBotRequestsHumanVoyATi(bot);
      if (didAskHumanToWin) {
        await _botDelay(450);
        if (!mounted || version != _handVersion || _handFinished) return;
      }

      _updateState(() {
        _status = context.tr(
          'botThinking',
          params: {'name': _localizedPlayerName(bot)},
        );
      });

      if (hasCompanionOrderWindow) {
        final wasOrderReceived =
            await _finishCompanionBotOrderWindow(bot, version);
        if (wasOrderReceived) {
          await Future<void>.delayed(
            _GameScreenState._companionBotPostOrderVisualDelay,
          );
        }
      } else {
        await _botDelay(1150);
      }
      if (!mounted || version != _handVersion || _handFinished) return;

      final card = _chooseBotCard(bot, botHand);
      var roundCompleted = false;
      _updateState(() {
        roundCompleted = _playCard(bot, card);
      });
      _sendMultiplayerCardIfNeeded(bot, card);

      if (roundCompleted) {
        if (_isMultiplayerMatch) {
          _updateState(() {
            _status = context.tr('waitingMatchResolution');
            _isAutoPlaying = false;
          });
        } else {
          _resolveRoundWithPause();
        }
        return;
      }

      await _botDelay(350);
    }

    if (!mounted || version != _handVersion) return;

    _updateState(() {
      _isAutoPlaying = false;
      if (!_handFinished) {
        if (_currentPlayer.id == _humanPlayer.id) {
          _status = context.tr('yourTurn');
        } else if (_isMultiplayerMatch &&
            !_controlledHumanPlayerIds.contains(_currentPlayer.id)) {
          _status = context.tr(
            'waitingForPlayer',
            params: {'name': _localizedPlayerName(_currentPlayer)},
          );
        } else if (_controlledHumanPlayerIds.contains(_currentPlayer.id)) {
          _status = context.tr(
            'turnOfPlayer',
            params: {'name': _localizedPlayerName(_currentPlayer)},
          );
        }
      }
    });
  }

  SpanishCard _chooseBotCard(Player bot, List<SpanishCard> hand) {
    _botCardSelectionCountForTesting += 1;
    final teamSignal = _teamSignalsByTeam[bot.teamId];
    final opponentSignal = _opponentSignalsSeenByTeam[bot.teamId];
    final shouldObeyVoyATi = _forceWinRequestedPlayerIds.contains(bot.id);
    final shouldPlayHighest = _forceHighestRequestedPlayerIds.contains(bot.id);
    final shouldPlayLowest = _forceLowestRequestedPlayerIds.contains(bot.id);
    if (shouldPlayLowest) {
      _forceWinRequestedPlayerIds.remove(bot.id);
      _forceHighestRequestedPlayerIds.remove(bot.id);
      _forceLowestRequestedPlayerIds.remove(bot.id);
      return BotVenAMiStrategy.chooseCard(
        bot: bot,
        hand: hand,
        playedCards: _playedCards,
        players: _players,
        hands: _hands,
        legalCards: _game.legalCardsForPlayer(bot),
      );
    }
    if ((shouldObeyVoyATi || shouldPlayHighest) &&
        _shouldIgnoreAggressiveCompanionCommand(bot)) {
      _forceWinRequestedPlayerIds.remove(bot.id);
      _forceHighestRequestedPlayerIds.remove(bot.id);
      return BotVenAMiStrategy.chooseCard(
        bot: bot,
        hand: hand,
        playedCards: _playedCards,
        players: _players,
        hands: _hands,
        legalCards: _game.legalCardsForPlayer(bot),
      );
    }
    final memory = BotMemoryContext.from(
      bot: bot,
      playedCards: _playedCards,
      roundHistory: _roundHistory,
    );
    final difficulty = _botDifficultyFor(bot);
    final policy = BotPolicySelector.forDifficulty(difficulty);
    final strategicCard = policy.chooseCard(
      BotDecisionContext(
        difficulty: difficulty,
        bot: bot,
        players: _players,
        hand: hand,
        hands: _hands,
        playedCards: _playedCards,
        teamRoundWins: _roundWins[bot.teamId]!,
        opponentRoundWins: _roundWins[TeamRules.opponentOf(bot.teamId)]!,
        preserveStrongCards: bot.teamId == _humanPlayer.teamId ||
            _isStrongSignal(teamSignal) ||
            memory.teammateWonLastRound ||
            memory.opponentsSpentPower,
        teammateHasStrongSignal: _isStrongSignal(teamSignal),
        opponentHasStrongSignal:
            _isStrongSignal(opponentSignal) && !memory.tableIsDrained,
        forceWinIfPossible: shouldObeyVoyATi ||
            shouldPlayHighest ||
            _shouldBotForceWin(bot, memory: memory),
        teammateStillToPlay:
            _teammateStillToPlay(bot) && !memory.opponentsWonAnyRound,
        opponentStillToPlay: _opponentStillToPlay(bot),
        signalContext: _signalContextFor(bot),
        handVersion: _handVersion,
        trickIndex: _roundHistory.length,
        betState: _betState,
        score: _score,
        roundHistory: _roundHistory,
      ),
    );
    _forceWinRequestedPlayerIds.remove(bot.id);
    _forceHighestRequestedPlayerIds.remove(bot.id);
    _forceLowestRequestedPlayerIds.remove(bot.id);
    return _maybeApplyDifficultyCardMistake(bot, hand, strategicCard);
  }

  bool _shouldIgnoreAggressiveCompanionCommand(Player bot) {
    if (_playedCards.length != _players.length - 1) {
      return false;
    }
    final winningTeam = BotTableRead.currentWinningTeamOnTable(_playedCards);
    if (winningTeam != bot.teamId) {
      return false;
    }
    final bestStrength = BotTableRead.bestTableStrength(_playedCards);
    if (bestStrength == null) {
      return false;
    }
    return _playedCards.any(
      (playedCard) =>
          playedCard.player.teamId == bot.teamId &&
          playedCard.player.id != bot.id &&
          ZapitiRules.strength(playedCard.card) == bestStrength,
    );
  }

  int _botDifficultyFor(Player bot) {
    if (_isMultiplayerMatch) {
      return _selectedDifficulty;
    }
    return BotAgentDifficulty.forOfflineBot(
      bot: bot,
      human: _humanPlayer,
      companion: _companionPlayer,
      selectedDifficulty: _selectedDifficulty,
    );
  }

  bool _shouldOpenCompanionBotOrderWindow(Player bot) {
    if (_isMultiplayerMatch) return false;
    if (!_isLocalBotPlayer(bot)) return false;
    if (bot.id != _companionPlayer.id) return false;
    if (bot.teamId != _humanPlayer.teamId) return false;
    if (_handFinished ||
        _isGameFinished ||
        _isRoundAwaitingContinue ||
        _game.alVerState == AlVerState.awaitingDecision) {
      return false;
    }
    if (_playedCards.any((card) => card.player.id == bot.id)) return false;
    return _game.legalCardsForPlayer(bot).isNotEmpty;
  }

  void _beginCompanionBotOrderWindow(Player bot) {
    _updateState(() {
      final completer = Completer<void>();
      _companionBotOrderWindowPlayerId = bot.id;
      _companionBotOrderWindowCompleter = completer;
      _companionBotOrderWindowFuture = Future.any<bool>(
        [
          Future<void>.delayed(
            _GameScreenState._companionBotOrderWindowDuration,
          ).then((_) => false),
          completer.future.then((_) => true),
        ],
      );
    });
  }

  Future<bool> _finishCompanionBotOrderWindow(Player bot, int version) async {
    final completer = _companionBotOrderWindowCompleter;
    final windowFuture = _companionBotOrderWindowFuture;
    final wasOrderReceived = await (windowFuture ??
        Future<void>.delayed(
          _GameScreenState._companionBotOrderWindowDuration,
        ).then((_) => false));

    if (!mounted || version != _handVersion) return false;
    _updateState(() {
      if (_companionBotOrderWindowPlayerId == bot.id &&
          _companionBotOrderWindowCompleter == completer) {
        _companionBotOrderWindowPlayerId = null;
        _companionBotOrderWindowCompleter = null;
        _companionBotOrderWindowFuture = null;
      }
    });
    return wasOrderReceived;
  }

  void _notifyCompanionBotOrderRegistered(String playerId) {
    if (_companionBotOrderWindowPlayerId != playerId) return;
    final completer = _companionBotOrderWindowCompleter;
    if (completer == null || completer.isCompleted) return;
    completer.complete();
  }

  bool _maybeCompanionBotRequestsHumanVoyATi(Player bot) {
    if (_companionVoyATiPromptedHandVersion == _handVersion ||
        bot.id == _humanPlayer.id ||
        bot.teamId != _humanPlayer.teamId ||
        _playedCards.any((card) => card.player.id == _humanPlayer.id)) {
      return false;
    }

    final shouldAsk = BotVoyATiStrategy.shouldAskTeammateToWin(
      bot: bot,
      teammate: _humanPlayer,
      players: _players,
      hands: _hands,
      playedCards: _playedCards,
      teamRoundWins: _roundWins[bot.teamId]!,
      opponentRoundWins: _roundWins[TeamRules.opponentOf(bot.teamId)]!,
      handValue: _handValue,
      difficulty: _botDifficultyFor(bot),
      roll: _random.nextDouble(),
    );
    if (!shouldAsk) return false;

    _updateState(() {
      _companionVoyATiPromptedHandVersion = _handVersion;
      _forceWinRequestedPlayerIds.add(_humanPlayer.id);
      _recordStrategicSignal(
        type: StrategicSignalType.voyATi,
        issuer: bot,
        targetPlayerId: bot.id,
        label: context.tr('voyATi'),
      );
      _showTemporaryPlayerMessage(
        bot.id,
        context.tr('voyATi'),
        duration: const Duration(milliseconds: 1300),
      );
      _status = context.tr(
        'botSendsVoyATi',
        params: {'name': _localizedPlayerName(bot)},
      );
    });
    return true;
  }

  bool _teammateStillToPlay(Player bot) {
    final teammate = _players.firstWhere(
      (player) => player.teamId == bot.teamId && player.id != bot.id,
    );
    final teammateAlreadyPlayed = _playedCards.any(
      (playedCard) => playedCard.player.id == teammate.id,
    );
    if (teammateAlreadyPlayed) return false;

    final botIndex = _players.indexWhere((player) => player.id == bot.id);
    final teammateIndex =
        _players.indexWhere((player) => player.id == teammate.id);
    final turnsUntilTeammate = (teammateIndex - botIndex) % _players.length;
    return turnsUntilTeammate > 0 && turnsUntilTeammate <= 2;
  }

  bool _opponentStillToPlay(Player bot) {
    final remainingTurnsAfterBot = _players.length - _playedCards.length - 1;
    if (remainingTurnsAfterBot <= 0) return false;

    final botIndex = _players.indexWhere((player) => player.id == bot.id);
    for (final opponent in _players.where((player) {
      final alreadyPlayed = _playedCards.any(
        (playedCard) => playedCard.player.id == player.id,
      );
      return player.teamId != bot.teamId && !alreadyPlayed;
    })) {
      final opponentIndex =
          _players.indexWhere((player) => player.id == opponent.id);
      final turnsUntilOpponent = (opponentIndex - botIndex) % _players.length;
      if (turnsUntilOpponent > 0 &&
          turnsUntilOpponent <= remainingTurnsAfterBot) {
        return true;
      }
    }
    return false;
  }

  SpanishCard _maybeApplyDifficultyCardMistake(
    Player bot,
    List<SpanishCard> hand,
    SpanishCard strategicCard,
  ) {
    return DifficultyStrategy.applyCardMistake(
      difficulty: _botDifficultyFor(bot),
      random: _random,
      player: bot,
      hand: hand,
      strategicCard: strategicCard,
      playedCards: _playedCards,
    );
  }

  bool _shouldBotForceWin(Player bot, {required BotMemoryContext memory}) {
    final botTeam = bot.teamId;
    final otherTeam = TeamRules.opponentOf(botTeam);
    final repartoIsExpensive =
        _handValue >= 4 || (_pendingTrucoValue ?? 0) >= 5;
    final teamIsBehind = _roundWins[botTeam]! < _roundWins[otherTeam]!;
    final canCloseHand = _roundWins[botTeam]! > 0;
    final mustSaveHand = _roundWins[otherTeam]! > 0;
    final companionMustProtectHuman =
        botTeam == _humanPlayer.teamId && _playedCards.isNotEmpty;
    return repartoIsExpensive ||
        teamIsBehind ||
        canCloseHand ||
        mustSaveHand ||
        companionMustProtectHuman ||
        memory.opponentsWonAnyRound;
  }

  bool _isStrongSignal(String? signal) {
    return SignalRules.isStrongSignal(signal);
  }

  void _resolveRoundWithPause() {
    _updateState(() {
      _isAutoPlaying = true;
      _finishRound();
    });

    _updateState(() {
      _isAutoPlaying = false;
      _isRoundAwaitingContinue = !_handFinished && !_isGameFinished;
    });
  }

  void _continueAfterRound() {
    if (!_isRoundAwaitingContinue || _handFinished || _isGameFinished) return;

    if (_isMultiplayerMatch) {
      if (!_ensureMultiplayerActionConnection()) return;
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.activeRoomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        socket.continueRound(
          roomId: roomId,
          playerId: playerId,
          expectedStateVersion: _multiplayerStateVersion,
        );
      }
    }

    _updateState(() {
      _game.continueRound();
      _activeStrategicSignals.removeWhere(
        (signal) => signal.handVersion == _handVersion,
      );
      _forceWinRequestedPlayerIds.clear();
      _isAutoPlaying = false;
      if (_currentPlayer.id == _humanPlayer.id) {
        _status = context.tr('yourTurn');
      }
    });

    if (_isLocalBotPlayer(_currentPlayer)) {
      _advanceBots();
    }
  }

  void _handleMultiplayerMessage(MultiplayerMessage message) {
    if (!mounted || !_isMultiplayerMatch || !_sessionLifecycle.isActive) {
      _logClientIgnore('message_dropped_before_processing',
          message: message,
          fields: {
            'mounted': mounted,
            'isMultiplayerMatch': _isMultiplayerMatch,
            'sessionId': _sessionLifecycle.generation,
            'sessionPhase': _sessionLifecycle.phase.name,
          });
      return;
    }
    _logClientApply('message_received', message: message, fields: {
      'stateBefore': _clientMatchStateFields(),
    });

    switch (message.type) {
      case MultiplayerMessageType.playCard:
        final playerId = message.playerId;
        final rawCard = message.payload['card'];
        if (playerId == null || rawCard is! Map<String, dynamic>) {
          _logClientIgnore('play_card_invalid_payload', message: message);
          return;
        }
        final player = _players.firstWhere(
          (candidate) => candidate.id == playerId,
          orElse: () => _players.first,
        );
        final card = cardFromJson(rawCard);
        var roundCompleted = false;
        var applied = false;
        _updateState(() {
          if (!_hands[player.id]!.contains(card)) {
            _logClientIgnore('play_card_not_in_hand',
                message: message,
                fields: {
                  'targetPlayerId': player.id,
                  'card': cardToJson(card),
                  'knownHand': [
                    for (final item in _hands[player.id]!) cardToJson(item)
                  ],
                });
            return;
          }
          applied = true;
          roundCompleted = _playCard(player, card);
        });
        if (!applied) return;
        _logClientApply('play_card_applied', message: message, fields: {
          'targetPlayerId': player.id,
          'card': cardToJson(card),
          'roundCompleted': roundCompleted,
          'stateAfter': _clientMatchStateFields(),
        });
        if (roundCompleted) {
          _updateState(() {
            _status = context.tr('waitingMatchResolution');
            _isAutoPlaying = false;
          });
        } else if (_currentPlayer.id == _humanPlayer.id) {
          _updateState(() {
            _status = context.tr('yourTurn');
            _isAutoPlaying = false;
          });
        } else if (_isLocalBotPlayer(_currentPlayer)) {
          _advanceBots();
        } else {
          _updateState(() {
            _isAutoPlaying = false;
          });
        }
        break;
      case MultiplayerMessageType.callTruco:
        final playerId = message.playerId;
        final rawValue = message.payload['value'];
        if (playerId == null || rawValue is! int) {
          _logClientIgnore('call_truco_invalid_payload', message: message);
          return;
        }
        final player = _players.firstWhere(
          (candidate) => candidate.id == playerId,
          orElse: () => _players.first,
        );
        if (!_isLegalTrucoCall(player, rawValue)) {
          _logClientIgnore('call_truco_illegal', message: message, fields: {
            'targetPlayerId': player.id,
            'value': rawValue,
          });
          return;
        }
        _updateState(() {
          _callTruco(player, value: rawValue, actorPlayerId: player.id);
          _isAutoPlaying = false;
          final respondingTeamId = _game.respondingTrucoTeamId;
          _isWaitingHumanTrucoResponse =
              _teamNeedsLocalHumanTrucoResponse(respondingTeamId);
          if (_isWaitingHumanTrucoResponse) {
            _status = context.tr(
              'playerCallsTruco',
              params: {'name': _localizedPlayerName(player)},
            );
          }
        });
        _logClientApply('call_truco_applied', message: message, fields: {
          'targetPlayerId': player.id,
          'value': rawValue,
          'stateAfter': _clientMatchStateFields(),
        });
        if (_teamNeedsLocalBotTrucoResponse(_game.respondingTrucoTeamId)) {
          _resolveBotResponseToTruco();
        }
        break;
      case MultiplayerMessageType.raiseTruco:
        final playerId = message.playerId;
        final rawValue = message.payload['value'];
        if (playerId == null || rawValue is! int) {
          _logClientIgnore('raise_truco_invalid_payload', message: message);
          return;
        }
        final player = _players.firstWhere(
          (candidate) => candidate.id == playerId,
          orElse: () => _players.first,
        );
        if (!_isLegalTrucoCall(player, rawValue)) {
          _logClientIgnore('raise_truco_illegal', message: message, fields: {
            'targetPlayerId': player.id,
            'value': rawValue,
          });
          return;
        }
        _updateState(() {
          _raiseTruco(player, value: rawValue, actorPlayerId: player.id);
          _isAutoPlaying = false;
          final respondingTeamId = _game.respondingTrucoTeamId;
          _isWaitingHumanTrucoResponse =
              _teamNeedsLocalHumanTrucoResponse(respondingTeamId);
          if (_isWaitingHumanTrucoResponse) {
            _status = context.tr(
              'playerRaisesTo',
              params: {
                'name': _localizedPlayerName(player),
                'value': rawValue,
              },
            );
          }
        });
        _logClientApply('raise_truco_applied', message: message, fields: {
          'targetPlayerId': player.id,
          'value': rawValue,
          'stateAfter': _clientMatchStateFields(),
        });
        if (_teamNeedsLocalBotTrucoResponse(_game.respondingTrucoTeamId)) {
          _resolveBotResponseToTruco();
        }
        break;
      case MultiplayerMessageType.acceptTruco:
        final playerId = message.playerId;
        if (playerId == null) {
          _logClientIgnore('accept_truco_missing_player', message: message);
          return;
        }
        final player = _players.firstWhere(
          (candidate) => candidate.id == playerId,
          orElse: () => _players.first,
        );
        if (!_game.canAcceptTruco(
          teamId: player.teamId,
          actorPlayerId: player.id,
        )) {
          _logClientIgnore('accept_truco_rejected_by_local_state',
              message: message,
              fields: {
                'targetPlayerId': player.id,
                'teamId': player.teamId,
              });
          return;
        }
        _updateState(() {
          _acceptTruco(teamId: player.teamId, actorPlayerId: player.id);
          _showTemporaryPlayerMessage(
            player.id,
            context.tr('acceptTrucoSpeech'),
          );
          _isWaitingHumanTrucoResponse = false;
          _isAutoPlaying = false;
        });
        _logClientApply('accept_truco_applied', message: message, fields: {
          'targetPlayerId': player.id,
          'stateAfter': _clientMatchStateFields(),
        });
        break;
      case MultiplayerMessageType.passTruco:
        final playerId = message.playerId;
        if (playerId == null) {
          _logClientIgnore('pass_truco_missing_player', message: message);
          return;
        }
        final player = _players.firstWhere(
          (candidate) => candidate.id == playerId,
          orElse: () => _players.first,
        );
        if (!_game.canPassTruco(
          passingTeamId: player.teamId,
          actorPlayerId: player.id,
        )) {
          _logClientIgnore('pass_truco_rejected_by_local_state',
              message: message,
              fields: {
                'targetPlayerId': player.id,
                'teamId': player.teamId,
              });
          return;
        }
        _updateState(() {
          _showTemporaryPlayerMessage(player.id, context.tr('passSpeech'));
          _passTruco(passingTeamId: player.teamId, actorPlayerId: player.id);
          _isWaitingHumanTrucoResponse = false;
          _isAutoPlaying = false;
        });
        _logClientApply('pass_truco_applied', message: message, fields: {
          'targetPlayerId': player.id,
          'stateAfter': _clientMatchStateFields(),
        });
        break;
      case MultiplayerMessageType.passHand:
        final playerId = message.playerId;
        final toPlayerId = message.payload['toPlayerId']?.toString();
        if (playerId == null || toPlayerId == null) {
          _logClientIgnore('pass_hand_invalid_payload', message: message);
          return;
        }
        final player = _players.firstWhere(
          (candidate) => candidate.id == playerId,
          orElse: () => _players.first,
        );
        final teammate = _players.firstWhere(
          (candidate) => candidate.id == toPlayerId,
          orElse: () => _players.first,
        );
        if (!_game.canPassHand(
          from: player,
          to: teammate,
          actorPlayerId: player.id,
        )) {
          _logClientIgnore('pass_hand_rejected_by_local_state',
              message: message,
              fields: {
                'fromPlayerId': player.id,
                'toPlayerId': teammate.id,
              });
          return;
        }
        _updateState(() {
          _game.passHand(from: player, to: teammate, actorPlayerId: player.id);
          _showTemporaryPlayerMessage(player.id, context.tr('passHandSpeech'));
          _isAutoPlaying = false;
        });
        _logClientApply('pass_hand_applied', message: message, fields: {
          'fromPlayerId': player.id,
          'toPlayerId': teammate.id,
          'stateAfter': _clientMatchStateFields(),
        });
        if (_isLocalBotPlayer(_currentPlayer)) {
          _advanceBots();
        }
        break;
      case MultiplayerMessageType.continueRound:
        _updateState(() {
          _game.continueRound();
          _activeStrategicSignals.removeWhere(
            (signal) => signal.handVersion == _handVersion,
          );
          _forceWinRequestedPlayerIds.clear();
          _isAutoPlaying = false;
          if (_currentPlayer.id == _humanPlayer.id) {
            _status = context.tr('yourTurn');
          } else if (_isLocalBotPlayer(_currentPlayer)) {
            _status = context.tr(
              'turnOfPlayer',
              params: {'name': _localizedPlayerName(_currentPlayer)},
            );
          }
        });
        _logClientApply('continue_round_applied', message: message, fields: {
          'stateAfter': _clientMatchStateFields(),
        });
        if (_isLocalBotPlayer(_currentPlayer)) {
          _advanceBots();
        }
        break;
      case MultiplayerMessageType.newHand:
        _updateState(() {
          _resetMultiplayerHandState(clearSummary: false);
          _status = context.tr('newHandSynced');
        });
        _logClientApply('new_hand_applied', message: message, fields: {
          'stateAfter': _clientMatchStateFields(),
        });
        break;
      case MultiplayerMessageType.restartGame:
        _updateState(() {
          _resetMultiplayerHandState(clearSummary: true);
          _status = context.tr('newMatchSynced');
        });
        _logClientApply('restart_game_applied', message: message, fields: {
          'stateAfter': _clientMatchStateFields(),
        });
        break;
      case MultiplayerMessageType.signal:
        _handleIncomingMultiplayerSignal(message);
        break;
      case MultiplayerMessageType.requestSignal:
        _handleIncomingMultiplayerSignalRequest(message);
        break;
      case MultiplayerMessageType.roomSnapshot:
        final snapshot = MultiplayerRoomSnapshot.fromJson(message.payload);
        if (!_isMultiplayerMatch &&
            snapshot.phase != 'playing' &&
            snapshot.phase != 'starting' &&
            snapshot.match == null) {
          _logClientIgnore(
            'room_snapshot_ignored_outside_multiplayer_match',
            message: message,
            fields: {
              'snapshotPhase': snapshot.phase,
              'roomId': snapshot.roomId,
            },
          );
          return;
        }
        _syncMultiplayerSessionFromSnapshot(snapshot);
        if (_shouldDelayMultiplayerBotSnapshot(snapshot)) {
          _logClientApply('room_snapshot_delayed_for_bot_animation',
              message: message,
              fields: {
                'snapshotPhase': snapshot.phase,
                'roomId': snapshot.roomId,
              });
          unawaited(_applyDelayedMultiplayerBotSnapshot(snapshot));
          return;
        }
        if ((snapshot.phase == 'playing' || snapshot.match != null) &&
            !_isMultiplayerMatch &&
            mounted) {
          _enterMultiplayerMatch();
        }
        _applyMultiplayerRoomSnapshot(snapshot);
        _logClientApply('room_snapshot_applied', message: message, fields: {
          'snapshotPhase': snapshot.phase,
          'roomId': snapshot.roomId,
          'stateAfter': _clientMatchStateFields(),
        });
        break;
      case MultiplayerMessageType.startGame:
        _updateState(() {
          _status = 'La partida online ha comenzado.';
        });
        _logClientApply('start_game_received', message: message, fields: {
          'stateAfter': _clientMatchStateFields(),
        });
        break;
      case MultiplayerMessageType.error:
        _updateState(() {
          _isRecoveringMultiplayerConnection = false;
          _isAwaitingMultiplayerResync = false;
          _multiplayerConnectionFailed = true;
          _multiplayerMatchCanceled = false;
          _status = context.tr('onlineMatchSyncError');
        });
        _logClientApply('server_error_received', message: message, fields: {
          'stateAfter': _clientMatchStateFields(),
        });
        break;
      default:
        _logClientIgnore('message_type_not_handled', message: message);
        break;
    }
  }

  void _handleIncomingMultiplayerSignal(MultiplayerMessage message) {
    final player = _multiplayerPlayerById(message.playerId);
    if (player == null ||
        player.id == _humanPlayer.id ||
        player.teamId != _humanPlayer.teamId) {
      _logClientIgnore('signal_ignored_by_player_filter',
          message: message,
          fields: {
            'resolvedPlayerId': player?.id,
            'resolvedTeamId': player?.teamId,
            'humanPlayerId': _humanPlayer.id,
            'humanTeamId': _humanPlayer.teamId,
          });
      return;
    }

    final rawLabel = message.payload['label'];
    final label = rawLabel is String ? rawLabel : null;
    if (label == null || label.isEmpty) {
      _logClientIgnore('signal_invalid_label', message: message);
      return;
    }

    final kind = message.payload['kind']?.toString();
    final active = message.payload['active'] as bool? ?? true;
    final displayLabel = _multiplayerSignalDisplayLabel(kind, label);

    if (!active) {
      _updateState(() {
        if (_playerMessages[player.id] == displayLabel ||
            _playerMessages[player.id] == _signalBubbleText(label)) {
          _playerMessages.remove(player.id);
        }
      });
      _logClientApply('signal_cleared', message: message, fields: {
        'targetPlayerId': player.id,
        'displayLabel': displayLabel,
      });
      return;
    }

    _updateState(() {
      _isRequestingCompanionSignal = false;
      _showTemporaryPlayerMessage(
        player.id,
        kind == null ? _signalBubbleText(label) : displayLabel,
        duration: const Duration(milliseconds: 1300),
      );

      switch (kind) {
        case 'voy_a_ti':
          if (!_playedCards.any((card) => card.player.id == _humanPlayer.id)) {
            _forceWinRequestedPlayerIds.add(_humanPlayer.id);
          }
          _status = context.tr(
            'botSendsVoyATi',
            params: {'name': _localizedPlayerName(player)},
          );
          break;
        case 'ven_a_mi':
          if (!_playedCards.any((card) => card.player.id == _humanPlayer.id)) {
            _forceLowestRequestedPlayerIds.add(_humanPlayer.id);
          }
          _status = context.tr(
            'partnerComeToMeInstruction',
            params: {'name': _localizedPlayerName(player)},
          );
          break;
        case 'mata':
          if (!_playedCards.any((card) => card.player.id == _humanPlayer.id)) {
            _forceHighestRequestedPlayerIds.add(_humanPlayer.id);
          }
          _status = context.tr(
            'askCompanionKill',
            params: {'name': _localizedPlayerName(player)},
          );
          break;
        default:
          _playersSignaledThisHand.add(player.id);
          _teamSignalsByTeam[player.teamId] = label;
          _knownSignalsByTeam[player.teamId] = label;
          _setCompanionPrivateSignalStatus(
            context.tr(
              'companionSignal',
              params: {'signal': _localizedSignalName(label)},
            ),
            clearAfter: _GameScreenState._companionSignalFeedbackDuration,
          );
          _status = context.tr(
            'signalReceivedFrom',
            params: {'name': _localizedPlayerName(player)},
          );
      }
    });
    _logClientApply('signal_applied', message: message, fields: {
      'targetPlayerId': player.id,
      'label': label,
      'kind': kind,
      'active': active,
      'stateAfter': _clientMatchStateFields(),
    });
  }

  void _handleIncomingMultiplayerSignalRequest(MultiplayerMessage message) {
    final requester = _multiplayerPlayerById(message.playerId);
    final localPlayerId =
        MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
    final localPlayer = _multiplayerPlayerById(localPlayerId) ?? _humanPlayer;
    final receiverPlayerId = message.payload['receiverPlayerId']?.toString();
    final requestId = message.payload['requestId']?.toString() ??
        message.messageId ??
        message.correlationId ??
        '${message.playerId}-${DateTime.now().microsecondsSinceEpoch}';
    final isRequestedLocalPlayer = requester != null &&
        requester.id != localPlayer.id &&
        requester.teamId == localPlayer.teamId &&
        (receiverPlayerId == null ||
            receiverPlayerId.isEmpty ||
            receiverPlayerId == localPlayer.id);
    ZapitiLogger.info('client_receive', 'signal_request_receive', fields: {
      'sessionId': _sessionLifecycle.generation,
      'roomId': message.roomId,
      'senderPlayerId': message.playerId,
      'receiverPlayerId': receiverPlayerId,
      'localPlayerId': localPlayer.id,
      'eventType': message.type.wireName,
      'requestId': requestId,
      'ts': DateTime.now().toIso8601String(),
      'statusBefore': _companionPrivateSignalStatus,
      'requestStatusBefore': _companionPrivateSignalRequestId,
      'willShow': isRequestedLocalPlayer,
    });
    if (!isRequestedLocalPlayer) {
      _logClientIgnore('signal_request_ignored_by_player_filter',
          message: message,
          fields: {
            'resolvedPlayerId': requester?.id,
            'resolvedTeamId': requester?.teamId,
            'localPlayerId': localPlayer.id,
            'localTeamId': localPlayer.teamId,
            'receiverPlayerId': receiverPlayerId,
            'requestId': requestId,
          });
      return;
    }

    _updateState(() {
      _isRequestingCompanionSignal = false;
      _setCompanionPrivateSignalStatus(
        context.tr(
          'playerAsksSignalShort',
          params: {'name': _localizedPlayerName(requester)},
        ),
        clearAfter: const Duration(seconds: 2),
        requestId: requestId,
      );
      _status = context.tr(
        'playerAsksSignal',
        params: {'name': _localizedPlayerName(requester)},
      );
    });
    _logClientApply('signal_request_applied', message: message, fields: {
      'requesterPlayerId': requester.id,
      'receiverPlayerId': localPlayer.id,
      'requestId': requestId,
      'stateAfter': _clientMatchStateFields(),
    });
  }

  Player? _multiplayerPlayerById(String? playerId) {
    if (playerId == null || playerId.isEmpty) return null;
    for (final player in _players) {
      if (player.id == playerId) return player;
    }
    return null;
  }

  String _multiplayerSignalDisplayLabel(String? kind, String fallbackLabel) {
    switch (kind) {
      case 'voy_a_ti':
        return context.tr('voyATi');
      case 'ven_a_mi':
        return context.tr('comeToMe');
      case 'mata':
        return context.tr('kill');
      default:
        return fallbackLabel;
    }
  }

  String _signalBubbleText(String label) => 'SENAL: $label';

  bool _shouldDelayMultiplayerBotSnapshot(MultiplayerRoomSnapshot snapshot) {
    if (snapshot.phase != 'playing' || snapshot.match == null) return false;
    final rawPlayedCards = snapshot.match!['playedCards'];
    if (rawPlayedCards is! List) return false;
    final newCards = rawPlayedCards.length - _playedCards.length;
    if (newCards != 1) return false;
    final rawLastCard = rawPlayedCards.last;
    if (rawLastCard is! Map) return false;
    final playerId = rawLastCard['playerId']?.toString();
    if (playerId == null || _controlledHumanPlayerIds.contains(playerId)) {
      return false;
    }
    return playerId.startsWith('bot_');
  }

  Future<void> _applyDelayedMultiplayerBotSnapshot(
    MultiplayerRoomSnapshot snapshot,
  ) async {
    final rawPlayedCards = snapshot.match?['playedCards'];
    final rawLastCard = rawPlayedCards is List && rawPlayedCards.isNotEmpty
        ? rawPlayedCards.last
        : null;
    final playerId =
        rawLastCard is Map ? rawLastCard['playerId']?.toString() : null;
    final player = playerId == null
        ? null
        : _players.firstWhere(
            (candidate) => candidate.id == playerId,
            orElse: () => _players.first,
          );
    final generation = ++_multiplayerSnapshotDelayGeneration;
    if (player != null) {
      _updateState(() {
        _isAutoPlaying = true;
        _status = context.tr(
          'botThinking',
          params: {'name': _localizedPlayerName(player)},
        );
      });
    }

    await _botDelay(1500);
    if (!mounted ||
        generation != _multiplayerSnapshotDelayGeneration ||
        !_isMultiplayerMatch) {
      return;
    }
    _applyMultiplayerRoomSnapshot(snapshot);
  }

  void _applyMultiplayerRoomSnapshot(MultiplayerRoomSnapshot snapshot) {
    if (!_isMultiplayerMatch || !_sessionLifecycle.isActive) {
      ZapitiLogger.warn('match', 'snapshot_ignored_stale_session', fields: {
        'sessionId': _sessionLifecycle.generation,
        'sessionPhase': _sessionLifecycle.phase.name,
        'roomId': snapshot.roomId,
        'phase': snapshot.phase,
      });
      return;
    }
    _multiplayerSnapshotDelayGeneration += 1;
    MultiplayerSessionStore.instance.roomSnapshot = snapshot;
    final hasMatchData = snapshot.match != null;
    if (snapshot.phase == 'starting' && !hasMatchData) {
      _updateState(() {
        _isRecoveringMultiplayerConnection = false;
        _isAwaitingMultiplayerResync = false;
        _multiplayerConnectionFailed = false;
        _multiplayerMatchCanceled = false;
        _isAutoPlaying = false;
        _isWaitingHumanTrucoResponse = false;
        _isRequestingCompanionSignal = false;
        _status = context.tr('multiplayerReadyToStart');
      });
      return;
    }
    if ((snapshot.phase != 'playing' && snapshot.phase != 'starting') ||
        snapshot.match == null) {
      _updateState(() {
        _isRecoveringMultiplayerConnection = false;
        _isAwaitingMultiplayerResync = false;
        _multiplayerConnectionFailed = false;
        _multiplayerMatchCanceled = true;
        _isAutoPlaying = false;
        _isWaitingHumanTrucoResponse = false;
        _isRequestingCompanionSignal = false;
        _status = context.tr('multiplayerMatchCanceledByLeave');
      });
      return;
    }
    _updateState(() {
      _isRecoveringMultiplayerConnection = false;
      _isAwaitingMultiplayerResync = false;
      _multiplayerConnectionFailed = false;
      _multiplayerMatchCanceled = false;
      if (snapshot.match != null) {
        _applyMultiplayerMatchSnapshot(snapshot.match!);
      }
      _status = snapshot.phase == 'playing'
          ? context.tr('matchSynced')
          : 'Sala ${snapshot.roomId} actualizada.';
    });
  }

  void _finishRound() {
    if (_handFinished ||
        _isGameFinished ||
        _playedCards.length != _players.length) {
      return;
    }

    _game.resolveRound();
  }
}
