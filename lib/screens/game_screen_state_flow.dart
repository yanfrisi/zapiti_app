part of 'game_screen.dart';

extension _GameScreenStateFlow on _GameScreenState {
  Future<void> _loadSavedCharacterSelection() async {
    final saved = await _preferencesStore.load(
      selectedCharacterKey: _GameScreenState._selectedCharacterPrefsKey,
      selectedDifficultyKey: _GameScreenState._selectedDifficultyPrefsKey,
      audioEnabledKey: _GameScreenState._audioEnabledPrefsKey,
      audioVolumeKey: _GameScreenState._audioVolumePrefsKey,
      botSpeedKey: _GameScreenState._botSpeedPrefsKey,
      showGameplayHelpKey: _GameScreenState._showGameplayHelpPrefsKey,
      confirmCardPlayKey: _GameScreenState._confirmCardPlayPrefsKey,
    );
    if (!mounted) return;

    _updateState(() {
      if (saved.audioEnabled != null) {
        _audioEnabled = saved.audioEnabled!;
      }
      if (saved.audioVolume != null) {
        _audioVolume = saved.audioVolume!.clamp(0, 1).toDouble();
      }
      if (saved.confirmCardPlay != null) {
        _confirmCardPlay = saved.confirmCardPlay!;
      }
      if (saved.botSpeedName != null) {
        _botSpeed = _BotSpeed.values.firstWhere(
          (speed) => speed.name == saved.botSpeedName,
          orElse: () => _BotSpeed.normal,
        );
      }
      if (saved.selectedDifficulty != null) {
        _selectedDifficulty = saved.selectedDifficulty!.clamp(1, 5);
      }
      if (saved.selectedCharacterId != null &&
          CharacterAssets.characterIds.contains(saved.selectedCharacterId)) {
        _selectedHumanCharacterId = saved.selectedCharacterId!;
        _applyCharacterSelection(saved.selectedCharacterId!);
      }
    });
    unawaited(_syncMusic());
  }

  Map<String, List<SpanishCard>>? get _debugFixedHands {
    if (kDebugMode && _GameScreenState._debugUsePresetHands) {
      final preset = DebugDeals.presets[_GameScreenState._debugPresetIndex];
      return {
        for (final player in _players) player.id: [...preset[player.id]!],
      };
    }

    return null;
  }

  void _startNewHand() {
    if (_isGameFinished) return;

    _handVersion += 1;
    _alVerDecisionPromptedKey = null;
    _isAlVerDecisionDialogOpen = false;
    final fixedHands = _isMultiplayerMatch
        ? MultiplayerSessionStore.instance.fixedHands ?? _debugFixedHands
        : _debugFixedHands;
    _game.startNewHand(fixedHands: fixedHands);
    for (final timer in _playerMessageTimers.values) {
      timer.cancel();
    }
    _playerMessageTimers.clear();
    _playerMessages.clear();
    _knownSignalsByTeam.clear();
    _teamSignalsByTeam.clear();
    _opponentSignalsSeenByTeam.clear();
    _forceWinRequestedPlayerIds.clear();
    _forceHighestRequestedPlayerIds.clear();
    _playersSignaledThisHand.clear();
    _aiTeamsConsideredTrucoThisHand.clear();
    _companionPrivateSignalStatus = null;
    _isAutoPlaying = false;
    _isWaitingHumanTrucoResponse = false;
    _isRequestingCompanionSignal = false;
    _companionVoyATiPromptedHandVersion = -1;
    _turnDeadlineAt = null;
    _turnSecondsRemaining = null;
    _syncTurnCountdownTimer();
  }

  void _maybeHandleAlVerDecision() {
    if (!mounted ||
        _showMainMenu ||
        _showCharacterSelection ||
        _showDifficultySelection ||
        _handFinished ||
        _isGameFinished ||
        _isAlVerDecisionDialogOpen) {
      return;
    }

    if (_game.alVerState != AlVerState.awaitingDecision) {
      return;
    }

    final teamId = _game.alVerTeamId;
    final promptKey = _alVerDecisionPromptKey(teamId);
    if (_alVerDecisionPromptedKey == promptKey) {
      return;
    }

    if (teamId == null) {
      _alVerDecisionPromptedKey = promptKey;
      return;
    }

    final teamIsHumanControlled = _isTeamControlledByHuman(teamId);
    _alVerDecisionPromptedKey = promptKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        _processPendingAlVerDecision(
          teamId,
          teamIsHumanControlled: teamIsHumanControlled,
        ),
      );
    });
  }

  String _alVerDecisionPromptKey(int? teamId) {
    final handKey =
        _isMultiplayerMatch && _multiplayerServerHandSequence != null
            ? 'server:${_multiplayerServerHandSequence!}'
            : 'local:$_handVersion';
    return '$handKey:team:${teamId ?? 'multiple'}';
  }

  bool _isTeamControlledByHuman(int teamId) {
    return _players.any(
      (player) =>
          player.teamId == teamId &&
          _controlledHumanPlayerIds.contains(player.id),
    );
  }

  bool _isLocalBotPlayer(Player player) {
    if (player.id == _humanPlayer.id) return false;
    if (_isMultiplayerMatch) return false;
    return true;
  }

  bool _teamHasLocalBot(int teamId) {
    return _players.any(
      (player) => player.teamId == teamId && _isLocalBotPlayer(player),
    );
  }

  bool _teamNeedsLocalHumanTrucoResponse(int? teamId) {
    return teamId != null && teamId == _humanPlayer.teamId;
  }

  bool _teamNeedsLocalBotTrucoResponse(int? teamId) {
    return teamId != null &&
        teamId != _humanPlayer.teamId &&
        _teamHasLocalBot(teamId);
  }

  List<SpanishCard> _teamCardsFor(int teamId) {
    return _players
        .where((player) => player.teamId == teamId)
        .expand((player) => _hands[player.id] ?? const <SpanishCard>[])
        .toList();
  }

  Future<void> _processPendingAlVerDecision(
    int teamId, {
    required bool teamIsHumanControlled,
  }) async {
    if (!mounted ||
        _game.alVerState != AlVerState.awaitingDecision ||
        _game.alVerTeamId != teamId ||
        _isAlVerDecisionDialogOpen ||
        _showMainMenu ||
        _showCharacterSelection ||
        _showDifficultySelection ||
        _handFinished ||
        _isGameFinished) {
      return;
    }

    if (teamIsHumanControlled) {
      await _presentAlVerDecisionDialog(teamId);
      return;
    }

    if (_isMultiplayerMatch) {
      return;
    }

    final play = BotAlVerStrategy.shouldPlay(
      cards: _teamCardsFor(teamId),
      difficulty: _selectedDifficulty,
      teamScore: _score[teamId]!,
      opponentScore: _score[TeamRules.opponentOf(teamId)]!,
      targetScore: 30,
    );

    _updateState(() {
      _game.chooseAlVerDecision(teamId: teamId, play: play);
    });
    if (play &&
        !_handFinished &&
        !_isRoundAwaitingContinue &&
        !_isWaitingHumanTrucoResponse &&
        !_isAutoPlaying &&
        !_isGameFinished &&
        _isLocalBotPlayer(_currentPlayer)) {
      _advanceBots();
    }
  }

  Future<void> _presentAlVerDecisionDialog(int teamId) async {
    if (_isAlVerDecisionDialogOpen || !mounted) {
      return;
    }

    _updateState(() {
      _isAlVerDecisionDialogOpen = true;
    });
  }

  void _handleHumanAlVerDecision(int teamId, {required bool play}) {
    if (!mounted ||
        _game.alVerState != AlVerState.awaitingDecision ||
        _game.alVerTeamId != teamId) {
      return;
    }
    _updateState(() {
      _isAlVerDecisionDialogOpen = false;
      _game.chooseAlVerDecision(teamId: teamId, play: play);
    });

    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        socket.chooseAlVerDecision(
          roomId: roomId,
          playerId: playerId,
          play: play,
        );
      }
    }

    if (play &&
        !_handFinished &&
        !_isRoundAwaitingContinue &&
        !_isWaitingHumanTrucoResponse &&
        !_isAutoPlaying &&
        !_isGameFinished &&
        _isLocalBotPlayer(_currentPlayer)) {
      _advanceBots();
    }
  }

  Future<void> _syncMusic() async {
    if (!_audioEnabled || _audioVolume <= 0) {
      await _musicPlayer.stop();
      return;
    }

    final isSetupFlow =
        _showMainMenu || _showCharacterSelection || _showDifficultySelection;
    if (isSetupFlow) {
      await _musicPlayer.playMenu(volume: _audioVolume);
    } else {
      await _musicPlayer.playTable(volume: _audioVolume);
    }
  }

  Future<void> _botDelay(int milliseconds) {
    final adjusted = (milliseconds * _botSpeed.delayFactor).round();
    return Future<void>.delayed(Duration(milliseconds: adjusted));
  }

  void _newHand() {
    if (_isGameFinished) return;
    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        socket.newHand(roomId: roomId, playerId: playerId);
        _updateState(() {
          _status = 'Pidiendo nuevo reparto...';
        });
      } else {
        _updateState(() {
          _status = 'La nueva mano online no pudo enviarse.';
        });
      }
      return;
    }

    _updateState(() {
      _startNewHand();
    });
    if (!_isHumanTurn) {
      _advanceBots();
    }
  }

  void _restartGame() {
    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        socket.restartGame(roomId: roomId, playerId: playerId);
        _updateState(() {
          _status = 'Pidiendo nueva partida...';
        });
      } else {
        _updateState(() {
          _status = 'El reinicio online no pudo enviarse.';
        });
      }
      return;
    }

    _updateState(() {
      _score
        ..[1] = 0
        ..[2] = 0;
      _handSummaries.clear();
      _game.nextLeadIndex = 0;
      _winningTeamId = null;
      _startNewHand();
    });
    if (!_isHumanTurn) {
      _advanceBots();
    }
  }

  Future<void> _confirmReturnToMainMenu() async {
    if (!mounted) return;
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: ZapitiColors.cardCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(
              color: ZapitiColors.oldGold,
              width: 2,
            ),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: ZapitiColors.wineRed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Salir de la partida',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ZapitiColors.darkBrown,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          content: Text(
            '¿Seguro que quieres volver al menú? La partida actual se cerrará.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ZapitiColors.darkBrown,
                  fontWeight: FontWeight.w700,
                ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              icon: const Icon(Icons.close),
              label: const Text('CANCELAR'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.logout),
              label: const Text('SALIR'),
            ),
          ],
        );
      },
    );

    if (shouldExit == true && mounted) {
      _returnToMainMenu();
    }
  }

  void _returnToMainMenu() {
    _updateState(() {
      _isMultiplayerMatch = false;
      _multiplayerPlayers = const [];
      _multiplayerServerHandSequence = null;
      _alVerDecisionPromptedKey = null;
      _controlledHumanPlayerIds = {ZapitiPlayers.human.id};
      _showMainMenu = true;
      _showCharacterSelection = false;
      _showDifficultySelection = false;
      _showGameOptions = false;
      _mainMenuPanel = _MainMenuPanel.home;
      _isWaitingHumanTrucoResponse = false;
      _isRequestingCompanionSignal = false;
      _turnDeadlineAt = null;
      _turnSecondsRemaining = null;
      _playerMessages.clear();
      _forceWinRequestedPlayerIds.clear();
      _companionPrivateSignalStatus = null;
    });
    MultiplayerSessionStore.instance.clearAll();
    unawaited(_syncMusic());
  }

  void _returnToMultiplayerLobby() {
    _updateState(() {
      _isMultiplayerMatch = false;
      _multiplayerPlayers = const [];
      _multiplayerServerHandSequence = null;
      _alVerDecisionPromptedKey = null;
      _controlledHumanPlayerIds = {ZapitiPlayers.human.id};
      _showMainMenu = true;
      _showCharacterSelection = false;
      _showDifficultySelection = false;
      _showGameOptions = false;
      _mainMenuPanel = _MainMenuPanel.multiplayer;
      _isWaitingHumanTrucoResponse = false;
      _isRequestingCompanionSignal = false;
      _turnDeadlineAt = null;
      _turnSecondsRemaining = null;
      _playerMessages.clear();
      _forceWinRequestedPlayerIds.clear();
      _companionPrivateSignalStatus = null;

      final session = MultiplayerSessionStore.instance;
      session.matchStarted = false;
      session.players = const [];
      session.controlledPlayerIds = const [];
      session.fixedHands = null;
      session.seed = null;
    });
    unawaited(_syncMusic());
  }

  void _resetMultiplayerHandState({required bool clearSummary}) {
    _playedCards.clear();
    _roundHistory.clear();
    _playerMessages.clear();
    _knownSignalsByTeam.clear();
    _teamSignalsByTeam.clear();
    _opponentSignalsSeenByTeam.clear();
    _forceWinRequestedPlayerIds.clear();
    _forceHighestRequestedPlayerIds.clear();
    _playersSignaledThisHand.clear();
    _companionPrivateSignalStatus = null;
    _isWaitingHumanTrucoResponse = false;
    _isRequestingCompanionSignal = false;
    _isAutoPlaying = false;
    _companionVoyATiPromptedHandVersion = -1;
    _alVerDecisionPromptedKey = null;
    _turnDeadlineAt = null;
    _turnSecondsRemaining = null;
    _pendingTrucoValue = null;
    _trucoCallerTeamId = null;
    _game.lastTrucoRaiserTeamId = null;
    _isTrucoAccepted = false;
    _handFinished = false;
    _isRoundAwaitingContinue = false;
    if (clearSummary) {
      _handSummaries.clear();
      _score
        ..[1] = 0
        ..[2] = 0;
      _winningTeamId = null;
      _game.nextLeadIndex = 0;
    }
    _game.eventLog.clear();
    _game.alVerTeamIds.clear();
    _game.alVerState = AlVerState.none;
    _aiTeamsConsideredTrucoThisHand.clear();
  }

  void _selectHumanCharacter(String characterId) {
    _updateState(() {
      _selectedHumanCharacterId = characterId;
    });
    unawaited(_saveSelectedSettings());
  }

  Set<String> _localAuthorizedTrucoPlayerIds(
    List<Player> players,
    String humanPlayerId,
  ) {
    final humanTeamId = players
        .firstWhere(
          (player) => player.id == humanPlayerId,
          orElse: () => players.first,
        )
        .teamId;
    return {
      for (final player in players)
        if (player.id == humanPlayerId || player.teamId != humanTeamId)
          player.id,
    };
  }

  void _applyCharacterSelection(String humanCharacterId) {
    _characterIdsByPlayer
      ..clear()
      ..addAll(
        CharacterAssets.assignmentForHuman(
          humanPlayerId: _humanPlayer.id,
          playerIds: _players.map((player) => player.id).toList(),
          humanCharacterId: humanCharacterId,
        ),
      );
  }

  void _continueToDifficultySelection() {
    _updateState(() {
      _applyCharacterSelection(_selectedHumanCharacterId);
      _showMainMenu = false;
      _showCharacterSelection = false;
      _showDifficultySelection = true;
    });
    unawaited(_syncMusic());
  }

  void _startFromMainMenu() {
    _updateState(() {
      _showMainMenu = false;
      _showCharacterSelection = true;
      _showDifficultySelection = false;
      _mainMenuPanel = _MainMenuPanel.home;
    });
    unawaited(_syncMusic());
  }

  void _openMainMenuTutorial() {
    _updateState(() {
      _mainMenuPanel = _MainMenuPanel.tutorial;
    });
  }

  void _openMainMenuOptions() {
    _updateState(() {
      _mainMenuPanel = _MainMenuPanel.options;
    });
  }

  void _openGameOptions() {
    _updateState(() {
      _showGameOptions = true;
    });
  }

  void _closeGameOptions() {
    _updateState(() {
      _showGameOptions = false;
    });
  }

  Future<void> _showSignalHelpDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _SignalHelpDialog(
          onClose: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  void _openMainMenuMultiplayer() {
    _updateState(() {
      _mainMenuPanel = _MainMenuPanel.multiplayer;
    });
  }

  void _openAboutScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AboutScreen(),
      ),
    );
  }

  void _enterMultiplayerMatch() {
    final session = MultiplayerSessionStore.instance;
    final socket = session.socket;
    final snapshotMatch = session.roomSnapshot?.match;
    if (!session.matchStarted ||
        session.localGamePlayerId == null ||
        session.players.isEmpty) {
      _updateState(() {
        _status = 'La partida todavía no está lista para entrar.';
      });
      return;
    }

    final localGamePlayerId = session.localGamePlayerId!;
    final multiplayerPlayers = session.players.isNotEmpty
        ? session.players
        : _GameScreenState._defaultPlayers;
    _updateState(() {
      _isMultiplayerMatch = true;
      _random = session.seed == null ? Random() : Random(session.seed!);
      _multiplayerPlayers = multiplayerPlayers;
      if (session.botDifficulty != null) {
        _selectedDifficulty = session.botDifficulty!.clamp(1, 5);
      }
      _allowPassHand = session.allowPassHand;
      _multiplayerServerHandSequence = null;
      _controlledHumanPlayerIds = {localGamePlayerId};
      _game = ZapitiGameController(
        targetScore: 30,
        players: _players,
        humanPlayerId: localGamePlayerId,
        authorizedTrucoPlayerIds: _players.map((player) => player.id),
        allowPassHand: _allowPassHand,
        autoStart: false,
      );
      final sessionCharacterIds = session.characterIdsByPlayer;
      _characterIdsByPlayer
        ..clear()
        ..addAll(
          sessionCharacterIds.isNotEmpty
              ? sessionCharacterIds
              : CharacterAssets.assignmentForHuman(
                  humanPlayerId: localGamePlayerId,
                  playerIds: _players.map((player) => player.id).toList(),
                  humanCharacterId: _selectedHumanCharacterId,
                ),
        );
      _showMainMenu = false;
      _showCharacterSelection = false;
      _showDifficultySelection = false;
      _showGameOptions = false;
      _mainMenuPanel = _MainMenuPanel.home;
      _score
        ..[1] = 0
        ..[2] = 0;
      _handSummaries.clear();
      _game.nextLeadIndex = 0;
      _winningTeamId = null;
      _startNewHand();
      if (snapshotMatch != null) {
        _applyMultiplayerMatchSnapshot(snapshotMatch);
      }
    });
    if (socket != null) {
      socket.onMessage = _handleMultiplayerMessage;
      socket.onError = (error) {
        if (!mounted) return;
        _updateState(() {
          _status = 'Error multijugador: $error';
        });
      };
      socket.onDone = () {
        if (!mounted) return;
        if (_isMultiplayerMatch) {
          _returnToMainMenu();
        }
      };
    }
    if (!_isHumanTurn) {
      _advanceBots();
    }
    unawaited(_syncMusic());
  }

  void _applyMultiplayerMatchSnapshot(Map<String, dynamic> match) {
    final parsedHands = <String, List<SpanishCard>>{};
    final rawHands = match['hands'];
    if (rawHands is Map) {
      for (final entry in rawHands.entries) {
        final playerId = entry.key.toString();
        final rawCards = entry.value;
        if (rawCards is List) {
          final cards = <SpanishCard>[];
          for (final rawCard in rawCards) {
            if (rawCard is Map<String, dynamic>) {
              cards.add(cardFromJson(rawCard));
            } else if (rawCard is Map) {
              cards.add(cardFromJson(Map<String, dynamic>.from(rawCard)));
            }
          }
          parsedHands[playerId] = cards;
        }
      }
    }

    final parsedPlayedCards = <PlayedCard>[];
    final rawPlayedCards = match['playedCards'];
    if (rawPlayedCards is List) {
      for (final rawPlayedCard in rawPlayedCards) {
        if (rawPlayedCard is! Map) continue;
        final playerId = rawPlayedCard['playerId']?.toString();
        final rawCard = rawPlayedCard['card'];
        if (playerId == null || rawCard is! Map) continue;
        final player = _players.firstWhere(
          (candidate) => candidate.id == playerId,
          orElse: () => _players.first,
        );
        parsedPlayedCards.add(
          PlayedCard(
            player: player,
            card: cardFromJson(Map<String, dynamic>.from(rawCard)),
          ),
        );
      }
    }

    final parsedScore = _parseIntMap(match['score']);
    final parsedRoundWins = _parseIntMap(match['roundWins']);
    final serverHandSequence = match['handSequence'] as int?;
    final currentPlayerId = match['currentPlayerId']?.toString();
    final leadPlayerId = match['leadPlayerId']?.toString();
    final nextLeadPlayerId = match['nextLeadPlayerId']?.toString();
    final shouldResetForNewHand = serverHandSequence != null &&
            serverHandSequence != _multiplayerServerHandSequence ||
        (_multiplayerServerHandSequence == null && serverHandSequence != null);
    if (shouldResetForNewHand) {
      final shouldClearSummary = (_score[1] != 0 ||
              _score[2] != 0 ||
              _handSummaries.items.isNotEmpty ||
              _winningTeamId != null) &&
          (parsedScore?[1] ?? 0) == 0 &&
          (parsedScore?[2] ?? 0) == 0;
      _resetMultiplayerHandState(clearSummary: shouldClearSummary);
    }
    if (serverHandSequence != null) {
      _multiplayerServerHandSequence = serverHandSequence;
    }
    final currentPlayerIndex = currentPlayerId == null
        ? -1
        : _players.indexWhere((player) => player.id == currentPlayerId);
    final leadIndex = leadPlayerId == null
        ? match['leadIndex'] as int?
        : _players.indexWhere((player) => player.id == leadPlayerId);
    final nextLeadIndex = nextLeadPlayerId == null
        ? match['nextLeadIndex'] as int?
        : _players.indexWhere((player) => player.id == nextLeadPlayerId);

    _hands
      ..clear()
      ..addAll(parsedHands);
    _playedCards
      ..clear()
      ..addAll(parsedPlayedCards);
    if (parsedScore != null) {
      _score[1] = parsedScore[1] ?? _score[1]!;
      _score[2] = parsedScore[2] ?? _score[2]!;
    }
    if (parsedRoundWins != null) {
      _roundWins[1] = parsedRoundWins[1] ?? _roundWins[1]!;
      _roundWins[2] = parsedRoundWins[2] ?? _roundWins[2]!;
    }
    if (currentPlayerIndex >= 0) {
      _turnIndex = currentPlayerIndex;
    }
    if (leadIndex != null && leadIndex >= 0 && leadIndex < _players.length) {
      _leadIndex = leadIndex;
    }
    if (nextLeadIndex != null && nextLeadIndex >= 0) {
      _nextLeadIndex = nextLeadIndex % _players.length;
    }
    if (match['handValue'] is int) {
      _handValue = match['handValue'] as int;
    }
    _pendingTrucoValue = match['pendingTrucoValue'] as int?;
    _trucoCallerTeamId = match['trucoCallerTeamId'] as int?;
    _allowPassHand = match['allowPassHand'] as bool? ?? _allowPassHand;
    _game.allowPassHand = _allowPassHand;
    _syncPassedHandFromMatch(match);
    _handFinished = match['handFinished'] as bool? ?? _handFinished;
    final snapshotAccepted =
        match['isTrucoAccepted'] as bool? ?? _isTrucoAccepted;
    if (_pendingTrucoValue != null) {
      _game.trucoState = TrucoNegotiationState.awaitingResponse;
    } else if (snapshotAccepted) {
      _game.trucoState = TrucoNegotiationState.acceptedClosed;
    } else {
      _game.trucoState = TrucoNegotiationState.notStarted;
    }
    _isRoundAwaitingContinue =
        match['isRoundAwaitingContinue'] as bool? ?? _isRoundAwaitingContinue;
    _winningTeamId = match['winningTeamId'] as int?;
    _status = match['status']?.toString() ?? _status;
    _turnDeadlineAt = _parseNullableInt(match['turnDeadlineAt']);
    _turnSecondsRemaining = _calculateTurnSecondsRemaining(_turnDeadlineAt);
    _syncAlVerFromMatch(match);
    _isWaitingHumanTrucoResponse = _pendingTrucoValue != null &&
        _teamNeedsLocalHumanTrucoResponse(_game.respondingTrucoTeamId);
    _isAutoPlaying = false;
    _syncTurnCountdownTimer();
  }

  void _syncPassedHandFromMatch(Map<String, dynamic> match) {
    final rawState = match['passedHandState'];
    if (rawState is Map) {
      final originalLeaderId = rawState['originalLeaderId']?.toString();
      final passedToPlayerId = rawState['passedToPlayerId']?.toString();
      if (originalLeaderId != null &&
          _players.any((player) => player.id == originalLeaderId)) {
        _game.passedHandState = PassedHandState(
          originalLeaderId: originalLeaderId,
          passedToPlayerId: passedToPlayerId,
        );
        return;
      }
    }
    final originalLeaderId = match['originalLeadPlayerId']?.toString();
    final passedToPlayerId = match['passedHandToPlayerId']?.toString();
    if (originalLeaderId != null &&
        _players.any((player) => player.id == originalLeaderId)) {
      _game.passedHandState = PassedHandState(
        originalLeaderId: originalLeaderId,
        passedToPlayerId: passedToPlayerId,
      );
    } else if (_playedCards.isEmpty) {
      _game.passedHandState = PassedHandState(
        originalLeaderId: _players[_game.leadIndex].id,
      );
    }
  }

  int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  int? _calculateTurnSecondsRemaining(int? deadlineAt) {
    if (deadlineAt == null) return null;
    final remainingMillis = deadlineAt - DateTime.now().millisecondsSinceEpoch;
    if (remainingMillis <= 0) return 0;
    return (remainingMillis / 1000).ceil();
  }

  void _syncTurnCountdownTimer() {
    _turnCountdownTimer?.cancel();
    _turnCountdownTimer = null;
    if (!_isMultiplayerMatch || _turnDeadlineAt == null) return;
    _turnCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = _calculateTurnSecondsRemaining(_turnDeadlineAt);
      if (remaining == _turnSecondsRemaining) return;
      _updateState(() {
        _turnSecondsRemaining = remaining;
      });
      if (remaining == null || remaining <= 0) {
        _turnCountdownTimer?.cancel();
        _turnCountdownTimer = null;
      }
    });
  }

  void _syncAlVerFromMatch(Map<String, dynamic> match) {
    final rawTeamIds = match['alVerTeamIds'];
    final teamIds = <int>{};
    if (rawTeamIds is List) {
      for (final value in rawTeamIds) {
        if (value is int) {
          teamIds.add(value);
        } else if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) teamIds.add(parsed);
        }
      }
    }

    final singleTeamId = match['alVerTeamId'];
    if (singleTeamId is int) {
      teamIds.add(singleTeamId);
    } else if (singleTeamId is String) {
      final parsed = int.tryParse(singleTeamId);
      if (parsed != null) teamIds.add(parsed);
    }

    final rawState = match['alVerState']?.toString();
    final state = switch (rawState) {
      'awaitingDecision' => AlVerState.awaitingDecision,
      'playing' => AlVerState.playing,
      'conceded' => AlVerState.conceded,
      _ => teamIds.isEmpty ? AlVerState.none : AlVerState.awaitingDecision,
    };

    _game.alVerTeamIds
      ..clear()
      ..addAll(teamIds);
    _game.alVerState = state;
  }

  Map<int, int>? _parseIntMap(dynamic rawMap) {
    if (rawMap is! Map) return null;
    final parsed = <int, int>{};
    for (final entry in rawMap.entries) {
      final key = int.tryParse(entry.key.toString());
      final value = entry.value;
      if (key == null || value is! int) continue;
      parsed[key] = value;
    }
    return parsed;
  }

  void _closeMainMenuPanel() {
    _updateState(() {
      _mainMenuPanel = _MainMenuPanel.home;
    });
  }

  void _setAudioEnabled(bool enabled) {
    _updateState(() {
      _audioEnabled = enabled;
    });
    unawaited(_musicPlayer.setEnabled(enabled, volume: _audioVolume));
    unawaited(_syncMusic());
    unawaited(_saveMenuOptions());
  }

  void _setAudioVolume(double volume) {
    _updateState(() {
      _audioVolume = volume.clamp(0, 1).toDouble();
    });
    unawaited(_musicPlayer.setVolume(_audioVolume));
    unawaited(_syncMusic());
    unawaited(_saveMenuOptions());
  }

  void _setBotSpeed(_BotSpeed speed) {
    _updateState(() {
      _botSpeed = speed;
    });
    unawaited(_saveMenuOptions());
  }

  void _setConfirmCardPlay(bool enabled) {
    _updateState(() {
      _confirmCardPlay = enabled;
    });
    unawaited(_saveMenuOptions());
  }

  void _selectDifficulty(int difficulty) {
    _updateState(() {
      _selectedDifficulty = difficulty.clamp(1, 5);
    });
  }

  void _startWithSelectedSettings() {
    _updateState(() {
      _applyCharacterSelection(_selectedHumanCharacterId);
      _showMainMenu = false;
      _showCharacterSelection = false;
      _showDifficultySelection = false;
      _score
        ..[1] = 0
        ..[2] = 0;
      _handSummaries.clear();
      _game.nextLeadIndex = 0;
      _winningTeamId = null;
      _startNewHand();
    });
    if (!_isHumanTurn) {
      _advanceBots();
    }
    unawaited(_syncMusic());
    unawaited(_saveSelectedSettings());
  }

  Future<void> _saveSelectedSettings() {
    return _preferencesStore.saveSelectedSettings(
      selectedCharacterKey: _GameScreenState._selectedCharacterPrefsKey,
      selectedCharacterId: _selectedHumanCharacterId,
      selectedDifficultyKey: _GameScreenState._selectedDifficultyPrefsKey,
      selectedDifficulty: _selectedDifficulty,
    );
  }

  Future<void> _saveMenuOptions() {
    return _preferencesStore.saveMenuOptions(
      audioEnabledKey: _GameScreenState._audioEnabledPrefsKey,
      audioEnabled: _audioEnabled,
      audioVolumeKey: _GameScreenState._audioVolumePrefsKey,
      audioVolume: _audioVolume,
      botSpeedKey: _GameScreenState._botSpeedPrefsKey,
      botSpeedName: _botSpeed.name,
      showGameplayHelpKey: _GameScreenState._showGameplayHelpPrefsKey,
      showGameplayHelp: true,
      confirmCardPlayKey: _GameScreenState._confirmCardPlayPrefsKey,
      confirmCardPlay: _confirmCardPlay,
    );
  }
}
