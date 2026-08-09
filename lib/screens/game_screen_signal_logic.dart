part of 'game_screen.dart';

extension _GameScreenSignalLogic on _GameScreenState {
  static const _signalMessagePrefix = 'SENAL: ';
  static const _companionSignalGestureDuration = Duration(milliseconds: 300);
  static const _companionNoSignalStatusDuration = Duration(milliseconds: 450);

  Future<void> _requestCompanionSignal() async {
    if (_handFinished || _isGameFinished || _isRequestingCompanionSignal) {
      return;
    }

    if (_isMultiplayerMatch) {
      if (!_ensureMultiplayerActionConnection()) return;
      _updateState(() {
        _isRequestingCompanionSignal = true;
        _setCompanionPrivateSignalStatus(context.tr('companionLooking'));
        _status = context.tr('askCompanionSignalStatus');
      });
      _requestMultiplayerCompanionSignal();
      return;
    }

    final version = _handVersion;
    final companion = _companionPlayer;
    final signal = SignalRules.signalForHand(_hands[companion.id] ?? const []);

    _updateState(() {
      _isRequestingCompanionSignal = true;
      _setCompanionPrivateSignalStatus(context.tr('companionLooking'));
    });

    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    if (version != _handVersion || _handFinished || _isGameFinished) {
      _updateState(() {
        _isRequestingCompanionSignal = false;
      });
      return;
    }

    if (signal == null) {
      _updateState(() {
        _setCompanionPrivateSignalStatus(
          context.tr('companionNoSignal'),
          clearAfter: _companionNoSignalStatusDuration,
        );
        _isRequestingCompanionSignal = false;
      });
      return;
    }

    final companionSignalStatus = context.tr(
      'companionSignal',
      params: {'signal': _localizedSignalName(signal)},
    );
    _updateState(() {
      _playersSignaledThisHand.add(companion.id);
      _playerMessages[companion.id] = '$_signalMessagePrefix$signal';
      _setCompanionPrivateSignalStatus(
        companionSignalStatus,
        clearAfter: const Duration(seconds: 2),
      );
      _teamSignalsByTeam[companion.teamId] = signal;
      _knownSignalsByTeam[companion.teamId] = signal;
      _maybeLetOpponentsSeeSignal(companion.teamId, signal);
      _isRequestingCompanionSignal = false;
    });
    if (_isGuidedTutorialMatch) {
      final scenario = _guidedTutorialScenarios[_guidedTutorialScenarioIndex];
      final correct =
          scenario.expectedAction == _TutorialScenarioAction.requestSignal &&
              (scenario.expectedSignal == null ||
                  scenario.expectedSignal == signal);
      await _advanceGuidedTutorialAfterSuccess(correct: correct);
      return;
    }

    await Future<void>.delayed(_companionSignalGestureDuration);
    if (!mounted || version != _handVersion) return;
    _updateState(() {
      if (_playerMessages[companion.id] == '$_signalMessagePrefix$signal') {
        _playerMessages.remove(companion.id);
      }
      if (_companionPrivateSignalStatus == companionSignalStatus) {
        _setCompanionPrivateSignalStatus(null);
      }
    });
  }

  void _startSignal(String label) {
    if (_handFinished || _isGameFinished) {
      return;
    }
    if (_isMultiplayerMatch && !_ensureMultiplayerActionConnection()) return;

    _updateState(() {
      _playerMessages[_humanPlayer.id] = '$_signalMessagePrefix$label';
      _knownSignalsByTeam[_humanPlayer.teamId] = label;
      _teamSignalsByTeam[_humanPlayer.teamId] = label;
      if (!_isMultiplayerMatch) {
        _maybeLetRivalsSeeHumanSignal(label);
      }
    });
    _sendMultiplayerSignalToCompanion(label: label);
    if (_isGuidedTutorialMatch) {
      final scenario = _guidedTutorialScenarios[_guidedTutorialScenarioIndex];
      final correct = scenario.expectedAction ==
              _TutorialScenarioAction.giveSignal &&
          (scenario.expectedSignal == null || scenario.expectedSignal == label);
      unawaited(_advanceGuidedTutorialAfterSuccess(
        correct: correct,
        fallbackMessage: scenario.expectedSignal == null
            ? null
            : context.tr(
                'expectedSignalWas',
                params: {'signal': scenario.expectedSignal},
              ),
      ));
    }
  }

  void _maybeLetRivalsSeeHumanSignal(String label) {
    _maybeLetOpponentsSeeSignal(_humanPlayer.teamId, label);
  }

  void _maybeLetOpponentsSeeSignal(int signalingTeamId, String label) {
    final rivalTeamId = TeamRules.opponentOf(signalingTeamId);
    if (_random.nextDouble() < 0.14) {
      _opponentSignalsSeenByTeam[rivalTeamId] = label;
    }
  }

  void _endSignal(String label) {
    if (_isMultiplayerMatch) {
      if (_playerMessages[_humanPlayer.id] == '$_signalMessagePrefix$label') {
        _updateState(() {
          _playerMessages.remove(_humanPlayer.id);
        });
      }
      _sendMultiplayerSignalToCompanion(label: label, active: false);
      return;
    }
    if (_playerMessages[_humanPlayer.id] != '$_signalMessagePrefix$label') {
      return;
    }

    _updateState(() {
      _playerMessages.remove(_humanPlayer.id);
    });
  }
}
