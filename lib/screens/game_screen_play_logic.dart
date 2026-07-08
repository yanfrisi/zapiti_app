part of 'game_screen.dart';

extension _GameScreenPlayLogic on _GameScreenState {
  void _playHumanCard(SpanishCard card) {
    unawaited(_playHumanCardAfterConfirmation(card));
  }

  Future<void> _playHumanCardAfterConfirmation(SpanishCard card) async {
    if (!_isHumanTurn) return;
    if (_confirmCardPlay) {
      final confirmed = await _confirmCardPlayDialog(card);
      if (!confirmed || !mounted || !_isHumanTurn) return;
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
        socket.playCard(roomId: roomId, playerId: playerId, card: card);
      }
      return;
    }
    if (roundCompleted) {
      _resolveRoundWithPause();
    } else {
      _advanceBots();
    }
  }

  Future<bool> _confirmCardPlayDialog(SpanishCard card) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ZapitiColors.cardCream,
          title: const Text('Confirmar jugada'),
          content: Text('Quieres jugar ${card.toString()}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Jugar'),
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

    final signal = SignalRules.signalForHand(_hands[bot.id] ?? const []);
    if (signal == null) return;

    _updateState(() {
      _playersSignaledThisHand.add(bot.id);
      _playerMessages[bot.id] = 'Sena: $signal';
      _teamSignalsByTeam[bot.teamId] = signal;
      _knownSignalsByTeam[bot.teamId] = signal;
    });

    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted || version != _handVersion) return;
    _updateState(() {
      if (_playerMessages[bot.id] == 'Sena: $signal') {
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

  Future<void> _advanceBots() async {
    if (_isMultiplayerMatch) return;
    final version = _handVersion;
    _isAutoPlaying = true;

    while (mounted &&
        version == _handVersion &&
        !_handFinished &&
        !_isRoundAwaitingContinue &&
        !_isGameFinished &&
        !_controlledHumanPlayerIds.contains(_currentPlayer.id)) {
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

        await _botDelay(650);
        if (!mounted || version != _handVersion || _handFinished) return;

        _updateState(() {
          _isAutoPlaying = false;
          _isWaitingHumanTrucoResponse = true;
          _status = '${bot.name} canta truco. Responde tu equipo.';
        });
        return;
      }

      _updateState(() {
        _status = '${bot.name} esta pensando.';
      });

      await _botDelay(1150);
      if (!mounted || version != _handVersion || _handFinished) return;

      final card = _chooseBotCard(bot, botHand);
      var roundCompleted = false;
      _updateState(() {
        roundCompleted = _playCard(bot, card);
      });

      if (roundCompleted) {
        _resolveRoundWithPause();
        return;
      }

      await _botDelay(350);
    }

    if (!mounted || version != _handVersion) return;

    _updateState(() {
      _isAutoPlaying = false;
      if (!_handFinished) {
        if (_currentPlayer.id == _humanPlayer.id) {
          _status = 'Te toca jugar.';
        } else if (_controlledHumanPlayerIds.contains(_currentPlayer.id)) {
          _status = 'Turno de ${_currentPlayer.name}.';
        }
      }
    });
  }

  SpanishCard _chooseBotCard(Player bot, List<SpanishCard> hand) {
    final teamSignal = _teamSignalsByTeam[bot.teamId];
    final opponentSignal = _opponentSignalsSeenByTeam[bot.teamId];
    final shouldObeyVoyATi = _forceWinRequestedPlayerIds.contains(bot.id);
    final memory = BotMemoryContext.from(
      bot: bot,
      playedCards: _playedCards,
      roundHistory: _roundHistory,
    );
    final strategicCard = BotStrategy.chooseCard(
      player: bot,
      hand: hand,
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
    );
    _forceWinRequestedPlayerIds.remove(bot.id);
    if (shouldObeyVoyATi) return _voyATiCard(hand, _playedCards);
    return _maybeApplyDifficultyCardMistake(bot, hand, strategicCard);
  }

  SpanishCard _voyATiCard(
    List<SpanishCard> hand,
    List<PlayedCard> playedCards,
  ) {
    final sorted = [...hand]..sort(
        (a, b) => ZapitiRules.strength(a).compareTo(ZapitiRules.strength(b)),
      );
    if (playedCards.isEmpty) return sorted.last;

    final bestTableStrength = playedCards
        .map((playedCard) => ZapitiRules.strength(playedCard.card))
        .reduce((best, current) => current > best ? current : best);
    return sorted.firstWhere(
      (card) => ZapitiRules.strength(card) > bestTableStrength,
      orElse: () => sorted.last,
    );
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
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        socket.continueRound(roomId: roomId, playerId: playerId);
      }
    }

    _updateState(() {
      _game.continueRound();
      _forceWinRequestedPlayerIds.clear();
      _isAutoPlaying = false;
      if (_currentPlayer.id == _humanPlayer.id) {
        _status = 'Te toca jugar.';
      }
    });

    if (!_isMultiplayerMatch &&
        !_controlledHumanPlayerIds.contains(_currentPlayer.id)) {
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
            _status = 'Esperando resolucion del servidor.';
            _isAutoPlaying = false;
          });
        } else if (_controlledHumanPlayerIds.contains(_currentPlayer.id)) {
          _updateState(() {
            _status = 'Te toca jugar.';
            _isAutoPlaying = false;
          });
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
          if (player.id != _humanPlayer.id) {
            _isWaitingHumanTrucoResponse = true;
          }
        });
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
          if (player.id != _humanPlayer.id) {
            _isWaitingHumanTrucoResponse = true;
          }
        });
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
      case MultiplayerMessageType.continueRound:
        _updateState(() {
          _game.continueRound();
          _forceWinRequestedPlayerIds.clear();
          _isAutoPlaying = false;
          if (_currentPlayer.id == _humanPlayer.id) {
            _status = 'Te toca jugar.';
          } else if (_controlledHumanPlayerIds.contains(_currentPlayer.id)) {
            _status = 'Turno de ${_currentPlayer.name}.';
          }
        });
        break;
      case MultiplayerMessageType.newHand:
        _updateState(() {
          _resetMultiplayerHandState(clearSummary: false);
          _status = 'Nuevo reparto sincronizado.';
        });
        break;
      case MultiplayerMessageType.restartGame:
        _updateState(() {
          _resetMultiplayerHandState(clearSummary: true);
          _status = 'Nueva partida sincronizada.';
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
        _updateState(() {
          if (active) {
            _playersSignaledThisHand.add(player.id);
            _playerMessages[player.id] = 'Sena: $rawLabel';
            _teamSignalsByTeam[player.teamId] = rawLabel;
            _knownSignalsByTeam[player.teamId] = rawLabel;
            if (player.teamId == _humanPlayer.teamId &&
                player.id != _humanPlayer.id) {
              _isRequestingCompanionSignal = false;
              _showTemporaryPlayerMessage(
                _humanPlayer.id,
                'Sena recibida: $rawLabel',
              );
              _status = 'Seña recibida de ${player.name}.';
            }
          } else if (_playerMessages[player.id] == 'Sena: $rawLabel') {
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
              _playerMessages.remove(_humanPlayer.id);
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
          _showTemporaryPlayerMessage(
            _humanPlayer.id,
            '${requester.name} te pide seña.',
          );
          _status = '${requester.name} te pide seña.';
        });
        break;
      case MultiplayerMessageType.roomSnapshot:
        final snapshot = MultiplayerRoomSnapshot.fromJson(message.payload);
        MultiplayerSessionStore.instance.roomSnapshot = snapshot;
        _updateState(() {
          if (snapshot.match != null) {
            _applyMultiplayerMatchSnapshot(snapshot.match!);
          }
          _status = snapshot.phase == 'playing'
              ? 'Partida sincronizada.'
              : 'Sala ${snapshot.roomId} actualizada.';
        });
        if (snapshot.phase == 'lobby') {
          _returnToMultiplayerLobby();
        }
        break;
      case MultiplayerMessageType.startGame:
        _updateState(() {
          _status = 'La partida online ha comenzado.';
        });
        break;
      case MultiplayerMessageType.error:
        _updateState(() {
          final code = message.payload['code']?.toString() ?? 'error';
          final text = message.payload['message']?.toString() ?? 'Error';
          _status = 'Servidor: $code - $text';
        });
        break;
      default:
        break;
    }
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
