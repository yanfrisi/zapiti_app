part of 'game_screen.dart';

extension _GameScreenPlayLogic on _GameScreenState {
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

    var roundCompleted = false;
    _updateState(() {
      roundCompleted = _playCard(_humanPlayer, card);
    });
    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
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
    if (_isGuidedTutorialMatch) {
      await _handleGuidedTutorialCard(card);
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

  Future<void> _maybeShowBotSignal(Player bot, int version) async {
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
      _playerMessages[bot.id] = 'Seña: $signal';
      _teamSignalsByTeam[bot.teamId] = signal;
      _knownSignalsByTeam[bot.teamId] = signal;
    });

    final revealDuration = isRivalBot
        ? Duration(
            milliseconds: difficultyProfile.rivalSignalRevealMilliseconds,
          )
        : const Duration(milliseconds: 300);
    await Future<void>.delayed(revealDuration);
    if (!mounted || version != _handVersion) return;
    _updateState(() {
      if (_playerMessages[bot.id] == 'Seña: $signal') {
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
    final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
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
    final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
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

      await _maybeShowBotSignal(bot, version);
      if (!mounted || version != _handVersion || _handFinished) return;

      if (_shouldBotCallTruco(bot)) {
        _updateState(() {
          _callTruco(
            bot,
            value: TrucoRules.firstTrucoValue,
            actorPlayerId: bot.id,
          );
        });
        _sendMultiplayerTrucoCallIfNeeded(bot, TrucoRules.firstTrucoValue);

        await _botDelay(650);
        if (!mounted || version != _handVersion || _handFinished) return;

        _updateState(() {
          _isAutoPlaying = false;
          _isWaitingHumanTrucoResponse =
              _teamNeedsLocalHumanTrucoResponse(_game.respondingTrucoTeamId);
          _status = _isWaitingHumanTrucoResponse
              ? context.tr('playerCallsTruco', params: {'name': bot.name})
              : context.tr(
                  'playerCallsTrucoShort',
                  params: {'name': bot.name},
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
        _status = context.tr('botThinking', params: {'name': bot.name});
      });

      await _botDelay(1150);
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
            params: {'name': _currentPlayer.name},
          );
        } else if (_controlledHumanPlayerIds.contains(_currentPlayer.id)) {
          _status = context.tr(
            'turnOfPlayer',
            params: {'name': _currentPlayer.name},
          );
        }
      }
    });
  }

  SpanishCard _chooseBotCard(Player bot, List<SpanishCard> hand) {
    final teamSignal = _teamSignalsByTeam[bot.teamId];
    final opponentSignal = _opponentSignalsSeenByTeam[bot.teamId];
    final shouldObeyVoyATi = _forceWinRequestedPlayerIds.contains(bot.id);
    final shouldPlayHighest = _forceHighestRequestedPlayerIds.contains(bot.id);
    final shouldPlayLowest = _forceLowestRequestedPlayerIds.contains(bot.id);
    if (shouldPlayLowest) {
      _forceLowestRequestedPlayerIds.remove(bot.id);
      return BotVenAMiStrategy.chooseCard(
        bot: bot,
        hand: hand,
        playedCards: _playedCards,
        players: _players,
        hands: _hands,
      );
    }
    if (shouldPlayHighest) {
      _forceHighestRequestedPlayerIds.remove(bot.id);
      final sorted = [...hand]..sort(
          (a, b) => ZapitiRules.strength(a).compareTo(ZapitiRules.strength(b)),
        );
      return sorted.last;
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
        forceWinIfPossible:
            shouldObeyVoyATi || _shouldBotForceWin(bot, memory: memory),
        teammateStillToPlay:
            _teammateStillToPlay(bot) && !memory.opponentsWonAnyRound,
        opponentStillToPlay: _opponentStillToPlay(bot),
      ),
    );
    _forceWinRequestedPlayerIds.remove(bot.id);
    if (shouldObeyVoyATi) {
      return BotVoyATiStrategy.chooseCard(
        bot: bot,
        hand: hand,
        playedCards: _playedCards,
        players: _players,
        hands: _hands,
      );
    }
    return _maybeApplyDifficultyCardMistake(bot, hand, strategicCard);
  }

  int _botDifficultyFor(Player bot) {
    if (_isMultiplayerMatch) {
      return _selectedDifficulty;
    }
    if (bot.id == _companionPlayer.id) {
      return 3;
    }
    return _selectedDifficulty;
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
      difficulty: _selectedDifficulty,
      roll: _random.nextDouble(),
    );
    if (!shouldAsk) return false;

    _updateState(() {
      _companionVoyATiPromptedHandVersion = _handVersion;
      _forceWinRequestedPlayerIds.add(_humanPlayer.id);
      _showTemporaryPlayerMessage(
        bot.id,
        '¡Voy a ti!',
        duration: const Duration(milliseconds: 1300),
      );
      _status = context.tr('botSendsVoyATi', params: {'name': bot.name});
    });
    _sendMultiplayerVoyATiIfNeeded(bot);
    return true;
  }

  void _sendMultiplayerVoyATiIfNeeded(Player player) {
    if (!_isMultiplayerMatch) return;
    final socket = MultiplayerSessionStore.instance.socket;
    final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
    if (socket != null && socket.isConnected && roomId != null) {
      socket.signal(
        roomId: roomId,
        playerId: player.id,
        label: '¡Voy a ti!',
        kind: 'voy_a_ti',
      );
    }
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
      difficulty: _selectedDifficulty,
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
      final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
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
    if (!mounted || !_isMultiplayerMatch) return;

    switch (message.type) {
      case MultiplayerMessageType.playCard:
        final playerId = message.playerId;
        final rawCard = message.payload['card'];
        if (playerId == null || rawCard is! Map<String, dynamic>) return;
        final player = _players.firstWhere(
          (candidate) => candidate.id == playerId,
          orElse: () => _players.first,
        );
        final card = cardFromJson(rawCard);
        var roundCompleted = false;
        var applied = false;
        _updateState(() {
          if (!_hands[player.id]!.contains(card)) {
            return;
          }
          applied = true;
          roundCompleted = _playCard(player, card);
        });
        if (!applied) return;
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
        if (playerId == null || rawValue is! int) return;
        final player = _players.firstWhere(
          (candidate) => candidate.id == playerId,
          orElse: () => _players.first,
        );
        if (!_isLegalTrucoCall(player, rawValue)) return;
        _updateState(() {
          _callTruco(player, value: rawValue, actorPlayerId: player.id);
          _isAutoPlaying = false;
          final respondingTeamId = _game.respondingTrucoTeamId;
          _isWaitingHumanTrucoResponse =
              _teamNeedsLocalHumanTrucoResponse(respondingTeamId);
          if (_isWaitingHumanTrucoResponse) {
            _status =
                context.tr('playerCallsTruco', params: {'name': player.name});
          }
        });
        if (_teamNeedsLocalBotTrucoResponse(_game.respondingTrucoTeamId)) {
          _resolveBotResponseToTruco();
        }
        break;
      case MultiplayerMessageType.raiseTruco:
        final playerId = message.playerId;
        final rawValue = message.payload['value'];
        if (playerId == null || rawValue is! int) return;
        final player = _players.firstWhere(
          (candidate) => candidate.id == playerId,
          orElse: () => _players.first,
        );
        if (!_isLegalTrucoCall(player, rawValue)) return;
        _updateState(() {
          _raiseTruco(player, value: rawValue, actorPlayerId: player.id);
          _isAutoPlaying = false;
          final respondingTeamId = _game.respondingTrucoTeamId;
          _isWaitingHumanTrucoResponse =
              _teamNeedsLocalHumanTrucoResponse(respondingTeamId);
          if (_isWaitingHumanTrucoResponse) {
            _status = context.tr(
              'playerRaisesTo',
              params: {'name': player.name, 'value': rawValue},
            );
          }
        });
        if (_teamNeedsLocalBotTrucoResponse(_game.respondingTrucoTeamId)) {
          _resolveBotResponseToTruco();
        }
        break;
      case MultiplayerMessageType.acceptTruco:
        final playerId = message.playerId;
        if (playerId == null) return;
        final player = _players.firstWhere(
          (candidate) => candidate.id == playerId,
          orElse: () => _players.first,
        );
        if (!_game.canAcceptTruco(
          teamId: player.teamId,
          actorPlayerId: player.id,
        )) {
          return;
        }
        _updateState(() {
          _acceptTruco(teamId: player.teamId, actorPlayerId: player.id);
          _showTemporaryPlayerMessage(player.id, 'Acepto truco.');
          _isWaitingHumanTrucoResponse = false;
          _isAutoPlaying = false;
        });
        break;
      case MultiplayerMessageType.passTruco:
        final playerId = message.playerId;
        if (playerId == null) return;
        final player = _players.firstWhere(
          (candidate) => candidate.id == playerId,
          orElse: () => _players.first,
        );
        if (!_game.canPassTruco(
          passingTeamId: player.teamId,
          actorPlayerId: player.id,
        )) {
          return;
        }
        _updateState(() {
          _showTemporaryPlayerMessage(player.id, 'Paso.');
          _passTruco(passingTeamId: player.teamId, actorPlayerId: player.id);
          _isWaitingHumanTrucoResponse = false;
          _isAutoPlaying = false;
        });
        break;
      case MultiplayerMessageType.passHand:
        final playerId = message.playerId;
        final toPlayerId = message.payload['toPlayerId']?.toString();
        if (playerId == null || toPlayerId == null) return;
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
          return;
        }
        _updateState(() {
          _game.passHand(from: player, to: teammate, actorPlayerId: player.id);
          _showTemporaryPlayerMessage(player.id, 'Paso mano.');
          _isAutoPlaying = false;
        });
        if (_isLocalBotPlayer(_currentPlayer)) {
          _advanceBots();
        }
        break;
      case MultiplayerMessageType.continueRound:
        _updateState(() {
          _game.continueRound();
          _forceWinRequestedPlayerIds.clear();
          _isAutoPlaying = false;
          if (_currentPlayer.id == _humanPlayer.id) {
            _status = context.tr('yourTurn');
          } else if (_isLocalBotPlayer(_currentPlayer)) {
            _status = 'Turno de ${_currentPlayer.name}.';
          }
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
        break;
      case MultiplayerMessageType.restartGame:
        _updateState(() {
          _resetMultiplayerHandState(clearSummary: true);
          _status = context.tr('newMatchSynced');
        });
        break;
      case MultiplayerMessageType.signal:
        final playerId = message.playerId;
        final rawLabel = message.payload['label'];
        final kind = message.payload['kind'];
        final active = message.payload['active'] as bool? ?? true;
        if (playerId == null || rawLabel is! String || rawLabel.isEmpty) {
          return;
        }
        final player = _players.firstWhere(
          (candidate) => candidate.id == playerId,
          orElse: () => _players.first,
        );
        if (kind == 'voy_a_ti') {
          if (!active) return;
          _updateState(() {
            _showTemporaryPlayerMessage(player.id, rawLabel);
            if (player.teamId == _humanPlayer.teamId &&
                player.id != _humanPlayer.id) {
              _status = '${player.name}: $rawLabel';
            }
            if (player.teamId == _humanPlayer.teamId &&
                !_controlledHumanPlayerIds.contains(_humanPlayer.id) &&
                !_playedCards
                    .any((card) => card.player.id == _humanPlayer.id)) {
              _forceWinRequestedPlayerIds.add(_humanPlayer.id);
            }
          });
          return;
        }
        if (kind == 'ven_a_mi') {
          if (!active) return;
          _updateState(() {
            _showTemporaryPlayerMessage(player.id, rawLabel);
            if (player.teamId == _humanPlayer.teamId &&
                player.id != _humanPlayer.id) {
              _status = context.tr(
                'partnerComeToMeInstruction',
                params: {'name': player.name},
              );
            }
            if (player.teamId == _humanPlayer.teamId &&
                !_controlledHumanPlayerIds.contains(_humanPlayer.id) &&
                !_playedCards
                    .any((card) => card.player.id == _humanPlayer.id)) {
              _forceLowestRequestedPlayerIds.add(_humanPlayer.id);
            }
          });
          return;
        }
        if (kind == 'mata') {
          if (!active) return;
          _updateState(() {
            _showTemporaryPlayerMessage(player.id, rawLabel);
            if (player.teamId == _humanPlayer.teamId &&
                player.id != _humanPlayer.id) {
              _status = context.tr(
                'askCompanionKill',
                params: {'name': player.name},
              );
            }
            if (player.teamId == _humanPlayer.teamId &&
                !_controlledHumanPlayerIds.contains(_humanPlayer.id) &&
                !_playedCards
                    .any((card) => card.player.id == _humanPlayer.id)) {
              _forceHighestRequestedPlayerIds.add(_humanPlayer.id);
            }
          });
          return;
        }
        _updateState(() {
          if (active) {
            _playersSignaledThisHand.add(player.id);
            _playerMessages[player.id] = 'Seña: $rawLabel';
            _teamSignalsByTeam[player.teamId] = rawLabel;
            _knownSignalsByTeam[player.teamId] = rawLabel;
            if (player.teamId == _humanPlayer.teamId &&
                player.id != _humanPlayer.id) {
              _isRequestingCompanionSignal = false;
              _companionPrivateSignalStatus = 'Compa: $rawLabel';
              _status = context
                  .tr('signalReceivedFrom', params: {'name': player.name});
            }
          } else if (_playerMessages[player.id] == 'Seña: $rawLabel') {
            _playersSignaledThisHand.remove(player.id);
            _playerMessages.remove(player.id);
            if (_teamSignalsByTeam[player.teamId] == rawLabel) {
              _teamSignalsByTeam.remove(player.teamId);
            }
            if (_knownSignalsByTeam[player.teamId] == rawLabel) {
              _knownSignalsByTeam.remove(player.teamId);
            }
            if (_opponentSignalsSeenByTeam[player.teamId] == rawLabel) {
              _opponentSignalsSeenByTeam.remove(player.teamId);
            }
            if (player.teamId == _humanPlayer.teamId &&
                player.id != _humanPlayer.id) {
              if (_companionPrivateSignalStatus == 'Compa: $rawLabel') {
                _companionPrivateSignalStatus = null;
              }
            }
          }
        });
        break;
      case MultiplayerMessageType.requestSignal:
        final playerId = message.playerId;
        if (playerId == null) return;
        final requester = _players.firstWhere(
          (candidate) => candidate.id == playerId,
          orElse: () => _players.first,
        );
        if (requester.teamId != _humanPlayer.teamId ||
            requester.id == _humanPlayer.id) {
          return;
        }
        _updateState(() {
          _isRequestingCompanionSignal = false;
          _companionPrivateSignalStatus = context.tr(
            'playerAsksSignalShort',
            params: {'name': requester.name},
          );
          _status =
              context.tr('playerAsksSignal', params: {'name': requester.name});
        });
        break;
      case MultiplayerMessageType.roomSnapshot:
        final snapshot = MultiplayerRoomSnapshot.fromJson(message.payload);
        MultiplayerSessionStore.instance.roomSnapshot = snapshot;
        if (_shouldDelayMultiplayerBotSnapshot(snapshot)) {
          unawaited(_applyDelayedMultiplayerBotSnapshot(snapshot));
          return;
        }
        _applyMultiplayerRoomSnapshot(snapshot);
        break;
      case MultiplayerMessageType.startGame:
        _updateState(() {
          _status = 'La partida online ha comenzado.';
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
        break;
      default:
        break;
    }
  }

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
        _status = context.tr('botThinking', params: {'name': player.name});
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
    _multiplayerSnapshotDelayGeneration += 1;
    MultiplayerSessionStore.instance.roomSnapshot = snapshot;
    if (snapshot.phase != 'playing' || snapshot.match == null) {
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
