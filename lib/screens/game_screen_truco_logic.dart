part of 'game_screen.dart';

extension _GameScreenTrucoLogic on _GameScreenState {
  void _humanCallsTruco() {
    if (!_canHumanCallTruco || _isGameFinished) return;

    const value = TrucoRules.firstTrucoValue;
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
    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        socket.callTruco(roomId: roomId, playerId: playerId, value: value);
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
      _showTemporaryPlayerMessage(_humanPlayer.id, 'Acepto truco.');
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
        socket.acceptTruco(roomId: roomId, playerId: playerId);
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
      _showTemporaryPlayerMessage(_humanPlayer.id, 'Paso.');
      _isWaitingHumanTrucoResponse = false;
      _passTruco(
        passingTeamId: passingTeamId,
        actorPlayerId: _humanPlayer.id,
      );
    });
    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        socket.passTruco(roomId: roomId, playerId: playerId);
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
        socket.raiseTruco(roomId: roomId, playerId: playerId, value: value);
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
    if (value == TrucoRules.firstTrucoValue) return '¡Truco!';
    return 'Subo a $value';
  }

  Player _teamLeadPlayer(int teamId) {
    return _players.firstWhere((player) => player.teamId == teamId);
  }

  Future<void> _resolveBotResponseToTruco() async {
    if (_isMultiplayerMatch) return;
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
    if (respondingTeamId == _humanPlayer.teamId) {
      _updateState(() {
        _isAutoPlaying = false;
        _isWaitingHumanTrucoResponse = true;
        _status = 'Responde tu equipo.';
      });
      return;
    }

    final respondingPlayer = _teamLeadPlayer(respondingTeamId);
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
        _isAutoPlaying = false;
        _isWaitingHumanTrucoResponse = true;
        _status =
            'Equipo $respondingTeamId sube a $raiseValue. Responde tu equipo.';
      } else if (accepts) {
        _acceptTruco(teamId: respondingTeamId, actorPlayerId: respondingPlayer.id);
        _showTemporaryPlayerMessage(respondingPlayer.id, 'Aceptamos.');
      } else {
        _showTemporaryPlayerMessage(respondingPlayer.id, 'Pasamos.');
        _passTruco(
          passingTeamId: respondingTeamId,
          actorPlayerId: respondingPlayer.id,
        );
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
    if (_isMultiplayerMatch || bot.teamId == _humanPlayer.teamId) return false;
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

    final teamSignal = _teamSignalsByTeam[bot.teamId];
    final opponentSignal = _opponentSignalsSeenByTeam[bot.teamId];
    final teamScore = _teamHandScore(bot.teamId);
    final otherTeam = TeamRules.opponentOf(bot.teamId);
    final needsPoints = _score[bot.teamId]! < _score[otherTeam]!;
    final ownMaxStrength = hand
        .map(ZapitiRules.strength)
        .reduce((best, current) => current > best ? current : best);
    final difficultyProfile = DifficultyProfiles.byLevel(_selectedDifficulty);
    final impulsiveBonus = difficultyProfile.impulsiveTrucoChance > 0 &&
        _playedCards.isNotEmpty &&
        _random.nextDouble() < difficultyProfile.impulsiveTrucoChance;
    if (impulsiveBonus && teamScore >= 80) return true;

    if (BotTrucoStrategy.shouldCall(
      difficulty: _selectedDifficulty,
      teamScore: teamScore,
      ownMaxStrength: ownMaxStrength,
      cardsOnTable: _playedCards.length,
      teamRoundWins: _roundWins[bot.teamId]!,
      opponentRoundWins: _roundWins[otherTeam]!,
      teamHasStrongSignal: _isStrongSignal(teamSignal),
      opponentHasStrongSignal: _isStrongSignal(opponentSignal),
      isCompanion: false,
      needsPoints: needsPoints,
    )) {
      return true;
    }

    return BotBluffStrategy.shouldBluffCall(
      difficulty: _selectedDifficulty,
      roll: _random.nextDouble(),
      teamScore: teamScore,
      ownMaxStrength: ownMaxStrength,
      cardsOnTable: _playedCards.length,
      teamRoundWins: _roundWins[bot.teamId]!,
      opponentRoundWins: _roundWins[otherTeam]!,
      teamHasStrongSignal: _isStrongSignal(teamSignal),
      opponentHasStrongSignal: _isStrongSignal(opponentSignal),
      needsPoints: needsPoints,
    );
  }

  int? _botRaiseValue(int teamId, {required int pendingValue}) {
    final teamCards = _players
        .where((player) => player.teamId == teamId)
        .expand((player) => _hands[player.id] ?? <SpanishCard>[])
        .toList();
    final strengths = teamCards.map(ZapitiRules.strength).toList()..sort();
    final isWinningReparto =
        _roundWins[teamId]! > _roundWins[TeamRules.opponentOf(teamId)]!;
    final raiseValue = BotTrucoRaiseStrategy.chooseRaiseValue(
      difficulty: _selectedDifficulty,
      pendingValue: pendingValue,
      maxAllowedValue: _game.maxAllowedTrucoValueForTeam(teamId),
      strengths: strengths,
      teamScore: _teamHandScore(teamId),
      hasStrongSignal: _isStrongSignal(_teamSignalsByTeam[teamId]),
      isWinningReparto: isWinningReparto,
      sawOpponentStrongSignal: _opponentSignalsSeenByTeam.containsKey(teamId),
    );
    return _game.raiseOptions.contains(raiseValue) ? raiseValue : null;
  }

  bool _shouldTeamAcceptTruco(int teamId, {required int pendingValue}) {
    if (pendingValue > _game.maxAllowedTrucoValue) return false;
    final otherTeam = TeamRules.opponentOf(teamId);
    final opponentSignal = _opponentSignalsSeenByTeam[teamId];
    final difficultyProfile = DifficultyProfiles.byLevel(_selectedDifficulty);
    if (difficultyProfile.readsOpponentSignals &&
        _isStrongSignal(opponentSignal) &&
        _roundWins[teamId] == 0 &&
        pendingValue > 3) {
      return false;
    }

    final teamScore = _teamHandScore(teamId);
    final canCloseHand = _roundWins[teamId]! > 0;
    final mustSaveHand = _roundWins[otherTeam]! > 0;
    final scorePressure = _score[teamId]! < _score[otherTeam]!;
    final closingThreshold = _callThreshold(94) - _tableInformationDiscount;

    if (canCloseHand && teamScore >= closingThreshold) return true;

    if (difficultyProfile.impulsiveTrucoChance > 0 &&
        _random.nextDouble() < difficultyProfile.impulsiveTrucoChance) {
      return pendingValue <= 5;
    }
    if (canCloseHand && pendingValue <= 6) return true;
    if (mustSaveHand && teamScore >= _callThreshold(85) && pendingValue <= 5) {
      return true;
    }
    if (_isStrongSignal(_teamSignalsByTeam[teamId]) && pendingValue <= 8) {
      return true;
    }
    if (scorePressure &&
        teamScore >= _callThreshold(105) &&
        pendingValue <= 6) {
      return true;
    }
    if (teamScore >= _callThreshold(125)) return pendingValue <= 8;
    if (teamScore >= _callThreshold(95)) return pendingValue <= 5;
    return teamScore >= _callThreshold(75) && pendingValue <= 3;
  }

  int get _tableInformationDiscount => _playedCards.length >= 2 ? 14 : 6;

  int _callThreshold(int base) {
    return base +
        DifficultyProfiles.byLevel(_selectedDifficulty).callThresholdModifier;
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
