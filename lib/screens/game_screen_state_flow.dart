part of 'game_screen.dart';

class _TutorialPreplay {
  final Player player;
  final SpanishCard card;

  const _TutorialPreplay({
    required this.player,
    required this.card,
  });
}

class _TutorialTableScenario {
  final String titleKey;
  final String instructionKey;
  final String successKey;
  final Map<String, List<SpanishCard>> hands;
  final int leadIndex;
  final List<_TutorialPreplay> preplays;
  final SpanishCard? expectedCard;
  final String? expectedSignal;
  final _TutorialScenarioAction expectedAction;
  final Player? pendingTrucoCaller;
  final int pendingTrucoValue = TrucoRules.firstTrucoValue;

  const _TutorialTableScenario({
    required this.titleKey,
    required this.instructionKey,
    required this.successKey,
    required this.hands,
    required this.leadIndex,
    required this.preplays,
    this.expectedCard,
    this.expectedSignal,
    this.expectedAction = _TutorialScenarioAction.playCard,
    this.pendingTrucoCaller,
  });
}

enum _TutorialScenarioAction {
  playCard,
  requestSignal,
  giveSignal,
  callTruco,
  passTruco,
}

const _guidedTutorialScenarios = [
  _TutorialTableScenario(
    titleKey: 'guidedScenario1Title',
    instructionKey: 'guidedScenario1Instruction',
    successKey: 'guidedScenario1Success',
    leadIndex: 1,
    expectedCard: SpanishCard(value: 4, suit: Suit.copas),
    hands: {
      'p1': [
        SpanishCard(value: 4, suit: Suit.copas),
        SpanishCard(value: 1, suit: Suit.espadas),
        SpanishCard(value: 5, suit: Suit.bastos),
      ],
      'p2': [
        SpanishCard(value: 3, suit: Suit.copas),
        SpanishCard(value: 11, suit: Suit.oros),
        SpanishCard(value: 6, suit: Suit.espadas),
      ],
      'p3': [
        SpanishCard(value: 7, suit: Suit.oros),
        SpanishCard(value: 12, suit: Suit.bastos),
        SpanishCard(value: 5, suit: Suit.espadas),
      ],
      'p4': [
        SpanishCard(value: 6, suit: Suit.copas),
        SpanishCard(value: 10, suit: Suit.espadas),
        SpanishCard(value: 4, suit: Suit.oros),
      ],
    },
    preplays: [
      _TutorialPreplay(
        player: ZapitiPlayers.rightRival,
        card: SpanishCard(value: 3, suit: Suit.copas),
      ),
      _TutorialPreplay(
        player: ZapitiPlayers.companion,
        card: SpanishCard(value: 7, suit: Suit.oros),
      ),
      _TutorialPreplay(
        player: ZapitiPlayers.leftRival,
        card: SpanishCard(value: 6, suit: Suit.copas),
      ),
    ],
  ),
  _TutorialTableScenario(
    titleKey: 'guidedScenario2Title',
    instructionKey: 'guidedScenario2Instruction',
    successKey: 'guidedScenario2Success',
    leadIndex: 1,
    expectedCard: SpanishCard(value: 3, suit: Suit.bastos),
    hands: {
      'p1': [
        SpanishCard(value: 3, suit: Suit.bastos),
        SpanishCard(value: 7, suit: Suit.copas),
        SpanishCard(value: 5, suit: Suit.oros),
      ],
      'p2': [
        SpanishCard(value: 2, suit: Suit.copas),
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 4, suit: Suit.espadas),
      ],
      'p3': [
        SpanishCard(value: 11, suit: Suit.bastos),
        SpanishCard(value: 6, suit: Suit.copas),
        SpanishCard(value: 5, suit: Suit.espadas),
      ],
      'p4': [
        SpanishCard(value: 1, suit: Suit.oros),
        SpanishCard(value: 10, suit: Suit.espadas),
        SpanishCard(value: 4, suit: Suit.oros),
      ],
    },
    preplays: [
      _TutorialPreplay(
        player: ZapitiPlayers.rightRival,
        card: SpanishCard(value: 2, suit: Suit.copas),
      ),
      _TutorialPreplay(
        player: ZapitiPlayers.companion,
        card: SpanishCard(value: 11, suit: Suit.bastos),
      ),
      _TutorialPreplay(
        player: ZapitiPlayers.leftRival,
        card: SpanishCard(value: 1, suit: Suit.oros),
      ),
    ],
  ),
  _TutorialTableScenario(
    titleKey: 'guidedScenario3Title',
    instructionKey: 'guidedScenario3Instruction',
    successKey: 'guidedScenario3Success',
    leadIndex: 1,
    expectedCard: SpanishCard(value: 5, suit: Suit.copas),
    hands: {
      'p1': [
        SpanishCard(value: 5, suit: Suit.copas),
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 6, suit: Suit.bastos),
      ],
      'p2': [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 3, suit: Suit.oros),
        SpanishCard(value: 2, suit: Suit.espadas),
      ],
      'p3': [
        SpanishCard(value: 7, suit: Suit.bastos),
        SpanishCard(value: 6, suit: Suit.copas),
        SpanishCard(value: 4, suit: Suit.oros),
      ],
      'p4': [
        SpanishCard(value: 7, suit: Suit.oros),
        SpanishCard(value: 10, suit: Suit.espadas),
        SpanishCard(value: 4, suit: Suit.espadas),
      ],
    },
    preplays: [
      _TutorialPreplay(
        player: ZapitiPlayers.rightRival,
        card: SpanishCard(value: 4, suit: Suit.bastos),
      ),
      _TutorialPreplay(
        player: ZapitiPlayers.companion,
        card: SpanishCard(value: 7, suit: Suit.bastos),
      ),
      _TutorialPreplay(
        player: ZapitiPlayers.leftRival,
        card: SpanishCard(value: 7, suit: Suit.oros),
      ),
    ],
  ),
  _TutorialTableScenario(
    titleKey: 'guidedScenario4Title',
    instructionKey: 'guidedScenario4Instruction',
    successKey: 'guidedScenario4Success',
    leadIndex: 0,
    expectedAction: _TutorialScenarioAction.requestSignal,
    expectedSignal: '7 Copas',
    hands: {
      'p1': [
        SpanishCard(value: 3, suit: Suit.bastos),
        SpanishCard(value: 6, suit: Suit.copas),
        SpanishCard(value: 4, suit: Suit.espadas),
      ],
      'p2': [
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 6, suit: Suit.espadas),
        SpanishCard(value: 4, suit: Suit.oros),
      ],
      'p3': [
        SpanishCard(value: 7, suit: Suit.copas),
        SpanishCard(value: 11, suit: Suit.bastos),
        SpanishCard(value: 5, suit: Suit.espadas),
      ],
      'p4': [
        SpanishCard(value: 2, suit: Suit.oros),
        SpanishCard(value: 10, suit: Suit.espadas),
        SpanishCard(value: 4, suit: Suit.copas),
      ],
    },
    preplays: [],
  ),
  _TutorialTableScenario(
    titleKey: 'guidedScenario5Title',
    instructionKey: 'guidedScenario5Instruction',
    successKey: 'guidedScenario5Success',
    leadIndex: 0,
    expectedAction: _TutorialScenarioAction.giveSignal,
    expectedSignal: '4 Bastos',
    hands: {
      'p1': [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 6, suit: Suit.copas),
        SpanishCard(value: 12, suit: Suit.oros),
      ],
      'p2': [
        SpanishCard(value: 7, suit: Suit.oros),
        SpanishCard(value: 11, suit: Suit.copas),
        SpanishCard(value: 4, suit: Suit.oros),
      ],
      'p3': [
        SpanishCard(value: 3, suit: Suit.espadas),
        SpanishCard(value: 10, suit: Suit.bastos),
        SpanishCard(value: 5, suit: Suit.espadas),
      ],
      'p4': [
        SpanishCard(value: 1, suit: Suit.copas),
        SpanishCard(value: 10, suit: Suit.espadas),
        SpanishCard(value: 4, suit: Suit.copas),
      ],
    },
    preplays: [],
  ),
  _TutorialTableScenario(
    titleKey: 'guidedScenario6Title',
    instructionKey: 'guidedScenario6Instruction',
    successKey: 'guidedScenario6Success',
    leadIndex: 0,
    expectedAction: _TutorialScenarioAction.callTruco,
    hands: {
      'p1': [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 7, suit: Suit.oros),
        SpanishCard(value: 3, suit: Suit.espadas),
      ],
      'p2': [
        SpanishCard(value: 12, suit: Suit.copas),
        SpanishCard(value: 6, suit: Suit.espadas),
        SpanishCard(value: 4, suit: Suit.espadas),
      ],
      'p3': [
        SpanishCard(value: 2, suit: Suit.oros),
        SpanishCard(value: 11, suit: Suit.bastos),
        SpanishCard(value: 5, suit: Suit.espadas),
      ],
      'p4': [
        SpanishCard(value: 1, suit: Suit.copas),
        SpanishCard(value: 10, suit: Suit.espadas),
        SpanishCard(value: 4, suit: Suit.oros),
      ],
    },
    preplays: [],
  ),
  _TutorialTableScenario(
    titleKey: 'guidedScenario7Title',
    instructionKey: 'guidedScenario7Instruction',
    successKey: 'guidedScenario7Success',
    leadIndex: 0,
    expectedAction: _TutorialScenarioAction.callTruco,
    hands: {
      'p1': [
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 6, suit: Suit.copas),
        SpanishCard(value: 4, suit: Suit.espadas),
      ],
      'p2': [
        SpanishCard(value: 5, suit: Suit.oros),
        SpanishCard(value: 11, suit: Suit.copas),
        SpanishCard(value: 4, suit: Suit.oros),
      ],
      'p3': [
        SpanishCard(value: 7, suit: Suit.oros),
        SpanishCard(value: 3, suit: Suit.bastos),
        SpanishCard(value: 10, suit: Suit.espadas),
      ],
      'p4': [
        SpanishCard(value: 6, suit: Suit.bastos),
        SpanishCard(value: 5, suit: Suit.espadas),
        SpanishCard(value: 4, suit: Suit.copas),
      ],
    },
    preplays: [],
  ),
  _TutorialTableScenario(
    titleKey: 'guidedScenario8Title',
    instructionKey: 'guidedScenario8Instruction',
    successKey: 'guidedScenario8Success',
    leadIndex: 0,
    expectedAction: _TutorialScenarioAction.passTruco,
    pendingTrucoCaller: ZapitiPlayers.rightRival,
    hands: {
      'p1': [
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 6, suit: Suit.copas),
        SpanishCard(value: 4, suit: Suit.espadas),
      ],
      'p2': [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 7, suit: Suit.copas),
        SpanishCard(value: 3, suit: Suit.oros),
      ],
      'p3': [
        SpanishCard(value: 11, suit: Suit.bastos),
        SpanishCard(value: 6, suit: Suit.espadas),
        SpanishCard(value: 5, suit: Suit.espadas),
      ],
      'p4': [
        SpanishCard(value: 2, suit: Suit.oros),
        SpanishCard(value: 1, suit: Suit.copas),
        SpanishCard(value: 4, suit: Suit.oros),
      ],
    },
    preplays: [],
  ),
];

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
      languageKey: _GameScreenState._languagePrefsKey,
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
      _language = ZapitiLanguage.fromCode(saved.languageCode);
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
    _activeStrategicSignals.clear();
    _forceWinRequestedPlayerIds.clear();
    _forceHighestRequestedPlayerIds.clear();
    _forceLowestRequestedPlayerIds.clear();
    _forceBetEvaluationRequestedPlayerIds.clear();
    _playersSignaledThisHand.clear();
    _aiTeamsConsideredTrucoThisHand.clear();
    _companionPrivateSignalStatus = null;
    _companionPrivateSignalRequestId = null;
    _isAutoPlaying = false;
    _companionBotOrderWindowPlayerId = null;
    _companionBotOrderWindowCompleter = null;
    _companionBotOrderWindowFuture = null;
    _advanceBotsInFlight = false;
    _advanceBotsActiveRunId = 0;
    _advanceBotsInFlightHandVersion = null;
    _advanceBotsInFlightPlayerId = null;
    _incomingTrucoOverlayOpenedAtMicros = null;
    _incomingTrucoOverlayValue = null;
    _incomingTrucoOverlayCallerPlayerId = null;
    _isWaitingHumanTrucoResponse = false;
    _isRequestingCompanionSignal = false;
    _companionVoyATiPromptedHandVersion = -1;
    _turnDeadlineAt = null;
    _turnSecondsRemaining = null;
    _syncTurnCountdownTimer();
  }

  void _startGuidedTutorialMatch() {
    _updateState(() {
      _resetMultiplayerStateForLocalMode();
      _beginGameSession('offline');
      _createCleanOfflineController(reason: 'guided_tutorial_start');
      _isGuidedTutorialMatch = true;
      _guidedTutorialCompleted = false;
      _guidedTutorialScenarioIndex = 0;
      _showMainMenu = false;
      _showCharacterSelection = false;
      _showDifficultySelection = false;
      _showGameOptions = false;
      _mainMenuPanel = _MainMenuPanel.home;
      _score
        ..[1] = 0
        ..[2] = 0;
      _handSummaries.clear();
      _winningTeamId = null;
      _loadGuidedTutorialScenario(0);
    });
    unawaited(_syncMusic());
  }

  void _loadGuidedTutorialScenario(int index) {
    final scenario =
        _guidedTutorialScenarios[index % _guidedTutorialScenarios.length];
    _handVersion += 1;
    _guidedTutorialCompleted = false;
    _guidedTutorialAdvancePending = false;
    _guidedTutorialScenarioIndex = index % _guidedTutorialScenarios.length;
    _alVerDecisionPromptedKey = null;
    _isAlVerDecisionDialogOpen = false;
    for (final timer in _playerMessageTimers.values) {
      timer.cancel();
    }
    _playerMessageTimers.clear();
    _playerMessages.clear();
    _knownSignalsByTeam.clear();
    _teamSignalsByTeam.clear();
    _opponentSignalsSeenByTeam.clear();
    _activeStrategicSignals.clear();
    _forceWinRequestedPlayerIds.clear();
    _forceHighestRequestedPlayerIds.clear();
    _forceLowestRequestedPlayerIds.clear();
    _forceBetEvaluationRequestedPlayerIds.clear();
    _playersSignaledThisHand.clear();
    _aiTeamsConsideredTrucoThisHand.clear();
    _companionPrivateSignalStatus = null;
    _companionPrivateSignalRequestId = null;
    _isAutoPlaying = false;
    _companionBotOrderWindowPlayerId = null;
    _companionBotOrderWindowCompleter = null;
    _companionBotOrderWindowFuture = null;
    _advanceBotsInFlight = false;
    _advanceBotsActiveRunId = 0;
    _advanceBotsInFlightHandVersion = null;
    _advanceBotsInFlightPlayerId = null;
    _incomingTrucoOverlayOpenedAtMicros = null;
    _incomingTrucoOverlayValue = null;
    _incomingTrucoOverlayCallerPlayerId = null;
    _isWaitingHumanTrucoResponse = false;
    _isRequestingCompanionSignal = false;
    _companionVoyATiPromptedHandVersion = -1;
    _turnDeadlineAt = null;
    _turnSecondsRemaining = null;
    _syncTurnCountdownTimer();

    _game.nextLeadIndex = scenario.leadIndex;
    _game.startNewHand(
      fixedHands: {
        for (final entry in scenario.hands.entries) entry.key: [...entry.value],
      },
    );
    for (final preplay in scenario.preplays) {
      _game.playCard(preplay.player, preplay.card);
    }
    if (scenario.pendingTrucoCaller != null) {
      final pendingCallerIndex = _players.indexWhere(
        (player) => player.id == scenario.pendingTrucoCaller!.id,
      );
      if (pendingCallerIndex >= 0) {
        _game.turnIndex = pendingCallerIndex;
      }
      _game.callTruco(
        scenario.pendingTrucoCaller!,
        value: scenario.pendingTrucoValue,
        actorPlayerId: scenario.pendingTrucoCaller!.id,
      );
      _isWaitingHumanTrucoResponse = true;
      _isAutoPlaying = false;
    }
    _status = context.tr(scenario.instructionKey);
  }

  Future<void> _advanceGuidedTutorialAfterSuccess({
    required bool correct,
    String? fallbackMessage,
  }) async {
    final scenarioIndex = _guidedTutorialScenarioIndex;
    if (correct && _guidedTutorialAdvancePending) {
      return;
    }
    if (correct) {
      _guidedTutorialAdvancePending = true;
    }
    final scenario = _guidedTutorialScenarios[scenarioIndex];
    _updateState(() {
      _status = correct
          ? context.tr(scenario.successKey)
          : context.tr(
              'guidedAlmost',
              params: {
                'message': fallbackMessage ?? context.tr(scenario.successKey),
              },
            );
      _showTemporaryPlayerMessage(
        _humanPlayer.id,
        correct
            ? context.tr('guidedGoodSpeech')
            : context.tr('guidedAlmostSpeech'),
        duration: const Duration(milliseconds: 900),
      );
    });
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted || !_isGuidedTutorialMatch) return;
    if (!correct) return;
    if (_guidedTutorialScenarioIndex != scenarioIndex) return;

    final nextIndex = scenarioIndex + 1;
    _updateState(() {
      _guidedTutorialAdvancePending = false;
      if (nextIndex >= _guidedTutorialScenarios.length) {
        _status = context.tr('guidedCompleteStatus');
        _showTemporaryPlayerMessage(
          _humanPlayer.id,
          context.tr('guidedCompleteSpeech'),
          duration: const Duration(seconds: 2),
        );
        _isGuidedTutorialMatch = false;
        _guidedTutorialCompleted = true;
        _isAutoPlaying = false;
        return;
      }
      _loadGuidedTutorialScenario(nextIndex);
    });
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
    if (_isMultiplayerMatch && !_ensureMultiplayerActionConnection()) return;
    _updateState(() {
      _isAlVerDecisionDialogOpen = false;
      _game.chooseAlVerDecision(teamId: teamId, play: play);
    });

    if (_isMultiplayerMatch) {
      if (!_ensureMultiplayerActionConnection()) return;
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.activeRoomId;
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
      if (!_ensureMultiplayerActionConnection()) return;
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.activeRoomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        socket.newHand(roomId: roomId, playerId: playerId);
        _updateState(() {
          _status = context.tr('onlineHandRequesting');
        });
      } else {
        _updateState(() {
          _status = context.tr('onlineHandSendError');
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
      final roomId = MultiplayerSessionStore.instance.activeRoomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        socket.restartGame(roomId: roomId, playerId: playerId);
        _updateState(() {
          _status = context.tr('onlineRestartRequesting');
        });
      } else {
        _updateState(() {
          _status = context.tr('onlineRestartSendError');
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
    String tr(String key, {Map<String, Object?> params = const {}}) {
      return ZapitiI18n.text(_language, key, params: params);
    }

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
                  tr('exitMatchTitle'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ZapitiColors.darkBrown,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          content: Text(
            tr('exitMatchBody'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ZapitiColors.darkBrown,
                  fontWeight: FontWeight.w700,
                ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              icon: const Icon(Icons.close),
              label: Text(tr('cancelUpper')),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.logout),
              label: Text(tr('exit')),
            ),
          ],
        );
      },
    );

    if (shouldExit == true && mounted) {
      _returnToMainMenu();
    }
  }

  void _notifyMultiplayerLeaveIfNeeded() {
    if (!_isMultiplayerMatch) return;
    final session = MultiplayerSessionStore.instance;
    final socket = session.socket;
    final roomId = session.activeRoomId;
    final playerId = session.localGamePlayerId;
    if (socket == null ||
        !socket.isConnected ||
        roomId == null ||
        playerId == null) {
      return;
    }
    try {
      socket.leaveRoom(roomId: roomId, playerId: playerId);
    } catch (_) {
      // Salir de la mesa no debe mostrar una excepcion al jugador.
    }
  }

  int _beginGameSession(String mode) {
    final sessionId = _sessionLifecycle.create(mode: mode);
    _sessionLifecycle.activate(sessionId: sessionId, mode: mode);
    return sessionId;
  }

  void _clearTransientGameUiState({required String reason}) {
    ZapitiLogger.info('session_lifecycle', 'transient_state_clear_begin',
        fields: {
          'sessionId': _sessionLifecycle.generation,
          'reason': reason,
          'playerMessageTimers': _playerMessageTimers.length,
          'activeSignals': _activeStrategicSignals.length,
          'forceWin': _forceWinRequestedPlayerIds.length,
          'forceHighest': _forceHighestRequestedPlayerIds.length,
          'forceLowest': _forceLowestRequestedPlayerIds.length,
          'forceBetEvaluation': _forceBetEvaluationRequestedPlayerIds.length,
        });
    for (final timer in _playerMessageTimers.values) {
      timer.cancel();
    }
    _playerMessageTimers.clear();
    _companionPrivateSignalTimer?.cancel();
    _companionPrivateSignalTimer = null;
    _turnCountdownTimer?.cancel();
    _turnCountdownTimer = null;
    _playerMessages.clear();
    _knownSignalsByTeam.clear();
    _teamSignalsByTeam.clear();
    _opponentSignalsSeenByTeam.clear();
    _activeStrategicSignals.clear();
    _playersSignaledThisHand.clear();
    _forceWinRequestedPlayerIds.clear();
    _forceHighestRequestedPlayerIds.clear();
    _forceLowestRequestedPlayerIds.clear();
    _forceBetEvaluationRequestedPlayerIds.clear();
    _aiTeamsConsideredTrucoThisHand.clear();
    _companionPrivateSignalStatus = null;
    _companionPrivateSignalRequestId = null;
    _isWaitingHumanTrucoResponse = false;
    _isRequestingCompanionSignal = false;
    _isAutoPlaying = false;
    _companionBotOrderWindowPlayerId = null;
    _companionBotOrderWindowCompleter = null;
    _companionBotOrderWindowFuture = null;
    _advanceBotsInFlight = false;
    _advanceBotsActiveRunId = 0;
    _advanceBotsInFlightHandVersion = null;
    _advanceBotsInFlightPlayerId = null;
    _incomingTrucoOverlayOpenedAtMicros = null;
    _incomingTrucoOverlayValue = null;
    _incomingTrucoOverlayCallerPlayerId = null;
    _companionVoyATiPromptedHandVersion = -1;
    _alVerDecisionPromptedKey = null;
    _turnDeadlineAt = null;
    _turnSecondsRemaining = null;
    ZapitiLogger.info('session_lifecycle', 'transient_state_clear_done',
        fields: {
          'sessionId': _sessionLifecycle.generation,
          'reason': reason,
          'playerMessageTimers': _playerMessageTimers.length,
          'activeSignals': _activeStrategicSignals.length,
        });
  }

  void _endCurrentGameSession(
      {required String reason, bool notifyLeave = true}) {
    if (notifyLeave) {
      _notifyMultiplayerLeaveIfNeeded();
    }
    final session = MultiplayerSessionStore.instance;
    _multiplayerConnectionGeneration += 1;
    _multiplayerSnapshotDelayGeneration += 1;
    _clearTransientGameUiState(reason: reason);
    _sessionLifecycle.end(reason: reason, socket: session.socket);
    session.clearAll(closeSocket: false);
  }

  void _returnToMainMenu() {
    _endCurrentGameSession(reason: 'return_to_main_menu');
    _updateState(() {
      _isMultiplayerMatch = false;
      _multiplayerPlayers = const [];
      _multiplayerServerHandSequence = null;
      _multiplayerStateVersion = null;
      _alVerDecisionPromptedKey = null;
      _controlledHumanPlayerIds = {ZapitiPlayers.human.id};
      _showMainMenu = true;
      _showCharacterSelection = false;
      _showDifficultySelection = false;
      _isGuidedTutorialMatch = false;
      _guidedTutorialCompleted = false;
      _isRecoveringMultiplayerConnection = false;
      _isAwaitingMultiplayerResync = false;
      _multiplayerConnectionFailed = false;
      _multiplayerMatchCanceled = false;
      _showGameOptions = false;
      _mainMenuPanel = _MainMenuPanel.home;
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
    _activeStrategicSignals.clear();
    _forceWinRequestedPlayerIds.clear();
    _forceHighestRequestedPlayerIds.clear();
    _forceLowestRequestedPlayerIds.clear();
    _forceBetEvaluationRequestedPlayerIds.clear();
    _playersSignaledThisHand.clear();
    _companionPrivateSignalStatus = null;
    _companionPrivateSignalRequestId = null;
    _isWaitingHumanTrucoResponse = false;
    _isRequestingCompanionSignal = false;
    _isAutoPlaying = false;
    _companionBotOrderWindowPlayerId = null;
    _companionBotOrderWindowCompleter = null;
    _companionBotOrderWindowFuture = null;
    _advanceBotsInFlight = false;
    _advanceBotsActiveRunId = 0;
    _advanceBotsInFlightHandVersion = null;
    _advanceBotsInFlightPlayerId = null;
    _incomingTrucoOverlayOpenedAtMicros = null;
    _incomingTrucoOverlayValue = null;
    _incomingTrucoOverlayCallerPlayerId = null;
    _companionVoyATiPromptedHandVersion = -1;
    _alVerDecisionPromptedKey = null;
    _turnDeadlineAt = null;
    _turnSecondsRemaining = null;
    _multiplayerStateVersion = null;
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

  void _createCleanOfflineController({required String reason}) {
    ZapitiLogger.info('session_lifecycle', 'offline_controller_create',
        fields: {
          'sessionId': _sessionLifecycle.generation,
          'reason': reason,
          'previousPlayers': _game.players.map((player) => player.id).toList(),
          'previousHands': {
            for (final entry in _game.hands.entries)
              entry.key: entry.value.length,
          },
        });
    _isMultiplayerMatch = false;
    _multiplayerPlayers = const [];
    _controlledHumanPlayerIds = {ZapitiPlayers.human.id};
    _allowPassHand = false;
    _game = ZapitiGameController(
      targetScore: _GameScreenState._targetScore,
      players: _GameScreenState._defaultPlayers,
      humanPlayerId: ZapitiPlayers.human.id,
      authorizedTrucoPlayerIds: _localAuthorizedTrucoPlayerIds(
        _GameScreenState._defaultPlayers,
        ZapitiPlayers.human.id,
      ),
      allowPassHand: _allowPassHand,
      autoStart: false,
    );
    _game.startNewHand(fixedHands: _debugFixedHands);
    _applyCharacterSelection(_selectedHumanCharacterId);
    ZapitiLogger.info('session_lifecycle', 'offline_controller_created',
        fields: {
          'sessionId': _sessionLifecycle.generation,
          'reason': reason,
          'players': _game.players.map((player) => player.id).toList(),
          'humanPlayerId': _game.humanPlayer.id,
          'isMultiplayerMatch': _isMultiplayerMatch,
          'roomId': MultiplayerSessionStore.instance.activeRoomId,
          'hasSocket': MultiplayerSessionStore.instance.socket != null,
        });
  }

  void _selectHumanCharacter(String characterId) {
    _updateState(() {
      if (!_isMultiplayerMatch &&
          (_showMainMenu ||
              _showCharacterSelection ||
              _showDifficultySelection)) {
        _resetMultiplayerStateForLocalMode();
      }
      _selectedHumanCharacterId = characterId;
    });
    unawaited(_saveSelectedSettings());
  }

  Set<String> _localAuthorizedTrucoPlayerIds(
    List<Player> players,
    String humanPlayerId,
  ) {
    return {
      for (final player in players) player.id,
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
    ZapitiLogger.info('offline_flow', 'continue_to_difficulty_begin', fields: {
      'isMultiplayerMatch': _isMultiplayerMatch,
      'showMainMenu': _showMainMenu,
      'showCharacterSelection': _showCharacterSelection,
      'showDifficultySelection': _showDifficultySelection,
      'multiplayerRoomId': MultiplayerSessionStore.instance.activeRoomId,
      'multiplayerPlayerId': MultiplayerSessionStore.instance.localGamePlayerId,
      'multiplayerMatchStarted': MultiplayerSessionStore.instance.matchStarted,
      'selectedHumanCharacterId': _selectedHumanCharacterId,
      'status': _status,
    });
    _updateState(() {
      _resetMultiplayerStateForLocalMode();
      _createCleanOfflineController(reason: 'continue_to_difficulty');
      _showMainMenu = false;
      _showCharacterSelection = false;
      _showDifficultySelection = true;
    });
    ZapitiLogger.info('offline_flow', 'continue_to_difficulty_done', fields: {
      'isMultiplayerMatch': _isMultiplayerMatch,
      'showMainMenu': _showMainMenu,
      'showCharacterSelection': _showCharacterSelection,
      'showDifficultySelection': _showDifficultySelection,
      'multiplayerRoomId': MultiplayerSessionStore.instance.activeRoomId,
      'multiplayerPlayerId': MultiplayerSessionStore.instance.localGamePlayerId,
      'multiplayerMatchStarted': MultiplayerSessionStore.instance.matchStarted,
      'selectedHumanCharacterId': _selectedHumanCharacterId,
    });
    unawaited(_syncMusic());
  }

  void _backToCharacterSelection() {
    _updateState(() {
      _showMainMenu = false;
      _showCharacterSelection = true;
      _showDifficultySelection = false;
    });
    unawaited(_syncMusic());
  }

  void _backToMainMenuFromCharacterSelection() {
    _updateState(() {
      _showMainMenu = true;
      _showCharacterSelection = false;
      _showDifficultySelection = false;
      _mainMenuPanel = _MainMenuPanel.home;
    });
    unawaited(_syncMusic());
  }

  void _startFromMainMenu() {
    ZapitiLogger.info('offline_flow', 'start_from_main_menu_begin', fields: {
      'isMultiplayerMatch': _isMultiplayerMatch,
      'showMainMenu': _showMainMenu,
      'showCharacterSelection': _showCharacterSelection,
      'showDifficultySelection': _showDifficultySelection,
      'multiplayerRoomId': MultiplayerSessionStore.instance.activeRoomId,
      'multiplayerPlayerId': MultiplayerSessionStore.instance.localGamePlayerId,
      'multiplayerMatchStarted': MultiplayerSessionStore.instance.matchStarted,
      'status': _status,
    });
    _updateState(() {
      _resetMultiplayerStateForLocalMode();
      _showMainMenu = false;
      _showCharacterSelection = true;
      _showDifficultySelection = false;
      _isGuidedTutorialMatch = false;
      _guidedTutorialCompleted = false;
      _mainMenuPanel = _MainMenuPanel.home;
    });
    ZapitiLogger.info('offline_flow', 'start_from_main_menu_done', fields: {
      'isMultiplayerMatch': _isMultiplayerMatch,
      'showMainMenu': _showMainMenu,
      'showCharacterSelection': _showCharacterSelection,
      'showDifficultySelection': _showDifficultySelection,
      'multiplayerRoomId': MultiplayerSessionStore.instance.activeRoomId,
      'multiplayerPlayerId': MultiplayerSessionStore.instance.localGamePlayerId,
      'multiplayerMatchStarted': MultiplayerSessionStore.instance.matchStarted,
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
        return ZapitiLocalizations(
          language: _language,
          child: _SignalHelpDialog(
            onClose: () => Navigator.of(dialogContext).pop(),
          ),
        );
      },
    );
  }

  Future<void> _openMainMenuMultiplayer() async {
    if (_versionCheck.status == AppVersionCheckStatus.checking) {
      return;
    }
    _updateState(() {
      _mainMenuPanel = _MainMenuPanel.multiplayer;
    });
    await _checkAppVersion();
  }

  void _openAboutScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ZapitiLocalizations(
          language: _language,
          child: const AboutScreen(),
        ),
      ),
    );
  }

  void _enterMultiplayerMatch() {
    final session = MultiplayerSessionStore.instance;
    final socket = session.socket;
    final snapshot = session.roomSnapshot;
    if (snapshot != null) {
      _syncMultiplayerSessionFromSnapshot(snapshot);
    }
    final snapshotMatch = session.roomSnapshot?.match;
    if (!session.matchStarted ||
        session.localGamePlayerId == null ||
        session.players.length < 2) {
      _updateState(() {
        _status = context.tr('matchNotReady');
      });
      return;
    }

    final localGamePlayerId = session.localGamePlayerId!;
    final multiplayerPlayers = List<Player>.unmodifiable(session.players);
    final sessionId = _beginGameSession('multiplayer');
    _updateState(() {
      _isMultiplayerMatch = true;
      _isRecoveringMultiplayerConnection = false;
      _isAwaitingMultiplayerResync = false;
      _multiplayerConnectionFailed = false;
      _multiplayerMatchCanceled = false;
      _isGuidedTutorialMatch = false;
      _guidedTutorialCompleted = false;
      _random = session.seed == null ? Random() : Random(session.seed!);
      _multiplayerPlayers = multiplayerPlayers;
      if (session.botDifficulty != null) {
        _selectedDifficulty = session.botDifficulty!.clamp(1, 5);
      }
      _allowPassHand = session.allowPassHand;
      _multiplayerServerHandSequence = null;
      _multiplayerStateVersion = null;
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
      socket.onMessage = (message) {
        if (!_sessionLifecycle.isCurrent(sessionId)) {
          _logClientIgnore('stale_session_message', message: message, fields: {
            'sessionId': sessionId,
            'activeSessionId': _sessionLifecycle.generation,
          });
          return;
        }
        _handleMultiplayerMessage(message);
      };
      socket.onError = (error) {
        if (!_sessionLifecycle.isCurrent(sessionId)) return;
        _handleMultiplayerSocketDropped();
      };
      socket.onDone = () {
        if (!_sessionLifecycle.isCurrent(sessionId)) return;
        _handleMultiplayerSocketDropped();
      };
    }
    if (!_isHumanTurn) {
      _advanceBots();
    }
    unawaited(_syncMusic());
  }

  void _syncMultiplayerSessionFromSnapshot(MultiplayerRoomSnapshot snapshot) {
    final session = MultiplayerSessionStore.instance;
    final snapshotMatchPlayers =
        _parseMultiplayerPlayers(snapshot.match?['players']);
    if (snapshotMatchPlayers.isNotEmpty &&
        (session.players.isEmpty ||
            snapshotMatchPlayers.length > session.players.length)) {
      session.players = _multiplayerPlayersStartingWithLocal(
        snapshotMatchPlayers,
      );
      final snapshotCharacterIds =
          _parseMultiplayerCharacterIds(snapshot.match?['players']);
      if (snapshotCharacterIds.isNotEmpty) {
        session.characterIdsByPlayer = snapshotCharacterIds;
      }
    } else if (session.players.isEmpty && snapshot.seats.isNotEmpty) {
      session.players = [
        for (final seat in snapshot.seats)
          Player(
            id: seat.playerId,
            name: seat.name,
            teamId: seat.teamId ??
                (seat.seatIndex.isEven ? TeamRules.teamOne : TeamRules.teamTwo),
          ),
      ];
    }
    if (session.controlledPlayerIds.isEmpty) {
      final localPlayerId = session.localGamePlayerId;
      session.controlledPlayerIds =
          localPlayerId == null ? const [] : [localPlayerId];
    }
    session.matchStarted = snapshot.phase == 'playing' ||
        snapshot.match != null ||
        session.matchStarted;
    session.roomSnapshot = snapshot;
  }

  List<Player> _multiplayerPlayersStartingWithLocal(List<Player> players) {
    final localPlayerId = MultiplayerSessionStore.instance.localGamePlayerId;
    if (localPlayerId == null || localPlayerId.isEmpty) {
      return List<Player>.unmodifiable(players);
    }
    final localIndex =
        players.indexWhere((player) => player.id == localPlayerId);
    if (localIndex <= 0) {
      return List<Player>.unmodifiable(players);
    }
    return List<Player>.unmodifiable([
      ...players.skip(localIndex),
      ...players.take(localIndex),
    ]);
  }

  List<Player> _parseMultiplayerPlayers(dynamic rawPlayers) {
    if (rawPlayers is! List) return const [];
    return [
      for (final rawPlayer in rawPlayers)
        if (rawPlayer is Map)
          Player(
            id: rawPlayer['playerId']?.toString() ?? '',
            name: rawPlayer['name']?.toString() ?? 'Jugador',
            teamId: rawPlayer['teamId'] as int? ?? 1,
          ),
    ].where((player) => player.id.isNotEmpty).toList();
  }

  Map<String, String> _parseMultiplayerCharacterIds(dynamic rawPlayers) {
    if (rawPlayers is! List) return const {};
    final parsed = <String, String>{};
    for (final rawPlayer in rawPlayers) {
      if (rawPlayer is! Map) continue;
      final playerId = rawPlayer['playerId']?.toString();
      final characterId = rawPlayer['characterId']?.toString();
      if (playerId == null ||
          playerId.isEmpty ||
          characterId == null ||
          characterId.isEmpty ||
          !CharacterAssets.characterIds.contains(characterId)) {
        continue;
      }
      parsed[playerId] = characterId;
    }
    return parsed;
  }

  bool get _canSendMultiplayerAction {
    if (!_isMultiplayerMatch ||
        _isRecoveringMultiplayerConnection ||
        _isAwaitingMultiplayerResync ||
        _multiplayerMatchCanceled) {
      return false;
    }
    final socket = MultiplayerSessionStore.instance.socket;
    return socket != null && socket.isConnected;
  }

  bool _ensureMultiplayerActionConnection() {
    if (!_isMultiplayerMatch) return true;
    if (_canSendMultiplayerAction) return true;

    _updateState(() {
      _status = context.tr('multiplayerRecoveringConnection');
    });
    if (_isAwaitingMultiplayerResync) return false;

    _handleMultiplayerSocketDropped();
    return false;
  }

  void _handleMultiplayerSocketDropped() {
    ZapitiLogger.warn('match', 'socket_dropped', fields: {
      'isMultiplayerMatch': _isMultiplayerMatch,
      'isRecovering': _isRecoveringMultiplayerConnection,
      'roomId': MultiplayerSessionStore.instance.activeRoomId,
      'playerId': MultiplayerSessionStore.instance.localGamePlayerId,
    });
    if (!mounted ||
        !_isMultiplayerMatch ||
        _isRecoveringMultiplayerConnection) {
      return;
    }
    unawaited(_recoverMultiplayerMatchConnection());
  }

  Future<void> _recoverMultiplayerMatchConnection() async {
    if (!mounted || !_isMultiplayerMatch) return;
    final sessionId = _sessionLifecycle.generation;

    final session = MultiplayerSessionStore.instance;
    final roomId = session.activeRoomId;
    final playerId = session.localGamePlayerId;
    ZapitiLogger.info('match', 'recover_connection_begin', fields: {
      'roomId': roomId,
      'playerId': playerId,
      'canReconnect': session.canReconnectMatch,
    });
    if (!session.canReconnectMatch || roomId == null || playerId == null) {
      ZapitiLogger.warn('match', 'recover_connection_impossible', fields: {
        'roomId': roomId,
        'playerId': playerId,
        'canReconnect': session.canReconnectMatch,
      });
      _updateState(() {
        _isRecoveringMultiplayerConnection = false;
        _isAwaitingMultiplayerResync = false;
        _multiplayerConnectionFailed = true;
        _status = context.tr('connectionLostMatch');
      });
      return;
    }

    final generation = ++_multiplayerConnectionGeneration;
    final previousSocket = session.socket;
    previousSocket?.onMessage = null;
    previousSocket?.onError = null;
    previousSocket?.onDone = null;
    previousSocket?.close();
    session.socket = null;

    _updateState(() {
      _isRecoveringMultiplayerConnection = true;
      _isAwaitingMultiplayerResync = false;
      _multiplayerConnectionFailed = false;
      _isAutoPlaying = false;
      _status = context.tr('multiplayerRecoveringConnection');
    });

    const attemptDelays = [
      Duration.zero,
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 10),
    ];
    const attemptTimeout = Duration(seconds: 18);

    for (var attempt = 0; attempt < attemptDelays.length; attempt++) {
      if (!mounted ||
          !_isMultiplayerMatch ||
          !_sessionLifecycle.isCurrent(sessionId) ||
          generation != _multiplayerConnectionGeneration) {
        return;
      }

      final delay = attemptDelays[attempt];
      ZapitiLogger.info('match', 'recover_connection_attempt_begin', fields: {
        'attempt': attempt + 1,
        'roomId': roomId,
        'playerId': playerId,
        'delayMs': delay.inMilliseconds,
        'generation': generation,
      });
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
        if (!mounted ||
            !_isMultiplayerMatch ||
            !_sessionLifecycle.isCurrent(sessionId) ||
            generation != _multiplayerConnectionGeneration) {
          return;
        }
      }

      final nextSocket = GameSocket(ServerConfig.websocketUrl);
      nextSocket.onMessage = _handleMultiplayerMessage;
      nextSocket.onError = (error) {
        if (!mounted ||
            !_sessionLifecycle.isCurrent(sessionId) ||
            generation != _multiplayerConnectionGeneration ||
            !_isMultiplayerMatch) {
          return;
        }
        session.socket = null;
        _handleMultiplayerSocketDropped();
      };
      nextSocket.onDone = () {
        if (!mounted ||
            !_sessionLifecycle.isCurrent(sessionId) ||
            generation != _multiplayerConnectionGeneration ||
            !_isMultiplayerMatch) {
          return;
        }
        session.socket = null;
        _handleMultiplayerSocketDropped();
      };

      try {
        await nextSocket.connect(timeout: attemptTimeout);
        if (!mounted ||
            !_isMultiplayerMatch ||
            !_sessionLifecycle.isCurrent(sessionId) ||
            generation != _multiplayerConnectionGeneration) {
          nextSocket.close();
          return;
        }
        session.socket = nextSocket;
        ZapitiLogger.info('match', 'recover_connection_socket_ready', fields: {
          'attempt': attempt + 1,
          'roomId': roomId,
          'playerId': playerId,
          'generation': generation,
        });
        nextSocket.joinRoom(
          roomId: roomId,
          playerId: playerId,
          username: session.reconnectUsername!,
          playerName: session.reconnectPlayerName!,
          teamName: session.reconnectTeamName!,
          password: session.reconnectSessionToken == null
              ? session.reconnectPassword
              : null,
          sessionToken: session.reconnectSessionToken,
          pairId: session.reconnectPairId,
          characterId: session.reconnectCharacterId,
        );
        _updateState(() {
          _isRecoveringMultiplayerConnection = false;
          _isAwaitingMultiplayerResync = true;
          _multiplayerConnectionFailed = false;
          _status = context.tr('multiplayerRecoveringConnection');
        });
        return;
      } catch (error, stackTrace) {
        ZapitiLogger.error(
          'match',
          'recover_connection_attempt_failed',
          error: error,
          stackTrace: stackTrace,
          fields: {
            'attempt': attempt + 1,
            'roomId': roomId,
            'playerId': playerId,
            'generation': generation,
          },
        );
        nextSocket.close();
      }
    }

    if (!mounted ||
        !_isMultiplayerMatch ||
        !_sessionLifecycle.isCurrent(sessionId) ||
        generation != _multiplayerConnectionGeneration) {
      return;
    }
    _updateState(() {
      _isRecoveringMultiplayerConnection = false;
      _isAwaitingMultiplayerResync = false;
      _multiplayerConnectionFailed = true;
      _status = context.tr('connectionLostMatch');
    });
    ZapitiLogger.warn('match', 'recover_connection_exhausted', fields: {
      'roomId': roomId,
      'playerId': playerId,
      'generation': generation,
    });
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
    final serverHandSequence = _parseNullableInt(match['handSequence']);
    final serverStateVersion = _parseNullableInt(match['stateVersion']);
    final currentPlayerId = match['currentPlayerId']?.toString();
    final leadPlayerId = match['leadPlayerId']?.toString();
    final nextLeadPlayerId = match['nextLeadPlayerId']?.toString();
    final shouldResetForNewHand = serverHandSequence != null &&
            serverHandSequence != _multiplayerServerHandSequence ||
        (_multiplayerServerHandSequence == null && serverHandSequence != null);
    ZapitiLogger.info('match', 'snapshot_apply_begin', fields: {
      'roomId': MultiplayerSessionStore.instance.activeRoomId,
      'serverHandSequence': serverHandSequence,
      'previousHandSequence': _multiplayerServerHandSequence,
      'serverStateVersion': serverStateVersion,
      'previousStateVersion': _multiplayerStateVersion,
      'currentPlayerId': currentPlayerId,
      'leadPlayerId': leadPlayerId,
      'nextLeadPlayerId': nextLeadPlayerId,
      'playedCards': parsedPlayedCards.length,
      'playersWithHands': parsedHands.length,
      'shouldResetForNewHand': shouldResetForNewHand,
      'status': match['status']?.toString(),
    });
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
    _multiplayerStateVersion = serverStateVersion;
    final currentPlayerIndex = currentPlayerId == null
        ? -1
        : _players.indexWhere((player) => player.id == currentPlayerId);
    final leadIndex = leadPlayerId == null
        ? _parseNullableInt(match['leadIndex'])
        : _players.indexWhere((player) => player.id == leadPlayerId);
    final nextLeadIndex = nextLeadPlayerId == null
        ? _parseNullableInt(match['nextLeadIndex'])
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
    final rawBetState = match['betState'];
    if (rawBetState is Map) {
      final betState = Map<String, dynamic>.from(rawBetState);
      final proposedLevel = betState['proposedLevel']?.toString();
      final acceptedLevel = betState['acceptedLevel']?.toString();
      _pendingTrucoValue = switch (proposedLevel) {
        'truco' => 3,
        'six' => 6,
        'nine' => 9,
        'twelve' => 12,
        'fifteen' => 15,
        'ahorrisi' => 18,
        _ => null,
      };
      _trucoCallerTeamId = _parseNullableInt(betState['proposingTeam']);
      _game.lastTrucoRaiserTeamId =
          _parseNullableInt(betState['lastRaisingTeam']);
      _handValue = switch (acceptedLevel) {
        'truco' => 3,
        'six' => 6,
        'nine' => 9,
        'twelve' => 12,
        'fifteen' => 15,
        'ahorrisi' => 18,
        _ => 1,
      };
    } else {
      _pendingTrucoValue = _parseNullableInt(match['pendingTrucoValue']);
      _trucoCallerTeamId = _parseNullableInt(match['trucoCallerTeamId']);
    }
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
    _winningTeamId = _parseNullableInt(match['winningTeamId']);
    _status = match['status']?.toString() ?? _status;
    _turnDeadlineAt = _parseNullableInt(match['turnDeadlineAt']);
    _turnSecondsRemaining = _calculateTurnSecondsRemaining(_turnDeadlineAt);
    _syncAlVerFromMatch(match);
    _isWaitingHumanTrucoResponse = _pendingTrucoValue != null &&
        _teamNeedsLocalHumanTrucoResponse(_game.respondingTrucoTeamId);
    _isAutoPlaying = false;
    _syncTurnCountdownTimer();
    ZapitiLogger.info('match', 'snapshot_apply_done', fields: {
      'roomId': MultiplayerSessionStore.instance.activeRoomId,
      'stateVersion': _multiplayerStateVersion,
      'handSequence': _multiplayerServerHandSequence,
      'turnIndex': _game.turnIndex,
      'leadIndex': _game.leadIndex,
      'nextLeadIndex': _game.nextLeadIndex,
      'handValue': _handValue,
      'pendingTrucoValue': _pendingTrucoValue,
      'winningTeamId': _winningTeamId,
      'turnDeadlineAt': _turnDeadlineAt,
      'turnSecondsRemaining': _turnSecondsRemaining,
    });
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
    final sessionId = _sessionLifecycle.generation;
    _turnCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_sessionLifecycle.isCurrent(sessionId)) {
        _turnCountdownTimer?.cancel();
        _turnCountdownTimer = null;
        return;
      }
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
      _ => teamIds.isEmpty
          ? AlVerState.none
          : teamIds.length == 1
              ? AlVerState.awaitingDecision
              : AlVerState.playing,
    };

    _game.syncAlVerSnapshot(
      teamIds: teamIds,
      requestedState: state,
    );
    if (_game.alVerState != AlVerState.awaitingDecision ||
        _game.alVerTeamId == null) {
      _isAlVerDecisionDialogOpen = false;
      _alVerDecisionPromptedKey = null;
    }
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

  void _setLanguage(ZapitiLanguage language) {
    _updateState(() {
      _language = language;
    });
    unawaited(_saveMenuOptions());
  }

  void _selectDifficulty(int difficulty) {
    _updateState(() {
      _selectedDifficulty = difficulty.clamp(1, 5);
    });
  }

  void _startWithSelectedSettings() {
    ZapitiLogger.info('offline_flow', 'start_with_selected_settings_begin',
        fields: {
          'isMultiplayerMatch': _isMultiplayerMatch,
          'showMainMenu': _showMainMenu,
          'showCharacterSelection': _showCharacterSelection,
          'showDifficultySelection': _showDifficultySelection,
          'multiplayerRoomId': MultiplayerSessionStore.instance.activeRoomId,
          'multiplayerPlayerId':
              MultiplayerSessionStore.instance.localGamePlayerId,
          'multiplayerMatchStarted':
              MultiplayerSessionStore.instance.matchStarted,
          'selectedHumanCharacterId': _selectedHumanCharacterId,
          'selectedDifficulty': _selectedDifficulty,
          'status': _status,
        });
    _updateState(() {
      _resetMultiplayerStateForLocalMode();
      _beginGameSession('offline');
      _createCleanOfflineController(reason: 'start_with_selected_settings');
      _showMainMenu = false;
      _showCharacterSelection = false;
      _showDifficultySelection = false;
      _isGuidedTutorialMatch = false;
      _guidedTutorialCompleted = false;
      _score
        ..[1] = 0
        ..[2] = 0;
      _handSummaries.clear();
      _game.nextLeadIndex = 0;
      _winningTeamId = null;
      _startNewHand();
    });
    ZapitiLogger.info('offline_flow', 'start_with_selected_settings_done',
        fields: {
          'isMultiplayerMatch': _isMultiplayerMatch,
          'showMainMenu': _showMainMenu,
          'showCharacterSelection': _showCharacterSelection,
          'showDifficultySelection': _showDifficultySelection,
          'multiplayerRoomId': MultiplayerSessionStore.instance.activeRoomId,
          'multiplayerPlayerId':
              MultiplayerSessionStore.instance.localGamePlayerId,
          'multiplayerMatchStarted':
              MultiplayerSessionStore.instance.matchStarted,
          'selectedHumanCharacterId': _selectedHumanCharacterId,
          'selectedDifficulty': _selectedDifficulty,
          'humanPlayerId': _humanPlayer.id,
          'players': _players.map((player) => player.id).toList(),
        });
    if (!_isHumanTurn) {
      _advanceBots();
    }
    unawaited(_syncMusic());
    unawaited(_saveSelectedSettings());
  }

  void _resetMultiplayerStateForLocalMode() {
    final session = MultiplayerSessionStore.instance;
    final socket = session.socket;
    ZapitiLogger.info(
        'offline_flow', 'reset_multiplayer_state_for_local_mode_begin',
        fields: {
          'activeRoomId': session.activeRoomId,
          'localGamePlayerId': session.localGamePlayerId,
          'matchStarted': session.matchStarted,
          'players': session.players.map((player) => player.id).toList(),
          'controlledPlayerIds': session.controlledPlayerIds,
          'hasSocket': socket != null,
          'socketConnected': socket?.isConnected,
          'roomSnapshotPhase': session.roomSnapshot?.phase,
        });
    _endCurrentGameSession(reason: 'reset_for_local_mode', notifyLeave: false);
    _isMultiplayerMatch = false;
    _multiplayerPlayers = const [];
    _multiplayerServerHandSequence = null;
    _multiplayerStateVersion = null;
    _isRecoveringMultiplayerConnection = false;
    _isAwaitingMultiplayerResync = false;
    _multiplayerConnectionFailed = false;
    _multiplayerMatchCanceled = false;
    _controlledHumanPlayerIds = {ZapitiPlayers.human.id};
    _showGameOptions = false;
    ZapitiLogger.info(
        'offline_flow', 'reset_multiplayer_state_for_local_mode_done',
        fields: {
          'activeRoomId': session.activeRoomId,
          'localGamePlayerId': session.localGamePlayerId,
          'matchStarted': session.matchStarted,
          'players': session.players.map((player) => player.id).toList(),
          'controlledPlayerIds': session.controlledPlayerIds,
          'hasSocket': session.socket != null,
          'roomSnapshotPhase': session.roomSnapshot?.phase,
          'isMultiplayerMatch': _isMultiplayerMatch,
          'showMainMenu': _showMainMenu,
          'showCharacterSelection': _showCharacterSelection,
          'showDifficultySelection': _showDifficultySelection,
        });
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
      languageKey: _GameScreenState._languagePrefsKey,
      languageCode: _language.code,
    );
  }
}
