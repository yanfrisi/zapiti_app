part of 'game_screen.dart';

extension _GameScreenSignalLogic on _GameScreenState {
  static const _companionSignalGestureDuration = Duration(milliseconds: 300);
  static const _companionNoSignalStatusDuration = Duration(milliseconds: 450);

  Future<void> _requestCompanionSignal() async {
    if (_handFinished || _isGameFinished || _isRequestingCompanionSignal) {
      return;
    }

    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        _updateState(() {
          _isRequestingCompanionSignal = true;
          _companionPrivateSignalStatus = 'Compa mira...';
          _status = 'Pides seña a tu compañero.';
        });
        socket.requestSignal(roomId: roomId, playerId: playerId);
        return;
      }
    }

    final version = _handVersion;
    final companion = _companionPlayer;
    final signal = SignalRules.signalForHand(_hands[companion.id] ?? const []);

    _updateState(() {
      _isRequestingCompanionSignal = true;
      _companionPrivateSignalStatus = 'Compa mira...';
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
        _companionPrivateSignalStatus = 'Compa: sin seña';
        _isRequestingCompanionSignal = false;
      });
      await Future<void>.delayed(_companionNoSignalStatusDuration);
      if (!mounted || version != _handVersion) return;
      _updateState(() {
        if (_companionPrivateSignalStatus == 'Compa: sin seña') {
          _companionPrivateSignalStatus = null;
        }
      });
      return;
    }

    _updateState(() {
      _playersSignaledThisHand.add(companion.id);
      _playerMessages[companion.id] = 'Seña: $signal';
      _companionPrivateSignalStatus = 'Compa: $signal';
      _teamSignalsByTeam[companion.teamId] = signal;
      _knownSignalsByTeam[companion.teamId] = signal;
      _maybeLetOpponentsSeeSignal(companion.teamId, signal);
      _isRequestingCompanionSignal = false;
    });

    await Future<void>.delayed(_companionSignalGestureDuration);
    if (!mounted || version != _handVersion) return;
    _updateState(() {
      if (_playerMessages[companion.id] == 'Seña: $signal') {
        _playerMessages.remove(companion.id);
      }
      if (_companionPrivateSignalStatus == 'Compa: $signal') {
        _companionPrivateSignalStatus = null;
      }
    });
  }

  void _startSignal(String label) {
    if (_handFinished || _isGameFinished) {
      return;
    }

    _updateState(() {
      _playerMessages[_humanPlayer.id] = 'Seña: $label';
      _knownSignalsByTeam[_humanPlayer.teamId] = label;
      _teamSignalsByTeam[_humanPlayer.teamId] = label;
      _maybeLetRivalsSeeHumanSignal(label);
    });
    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        socket.signal(
          roomId: roomId,
          playerId: playerId,
          label: label,
        );
      }
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
    if (_playerMessages[_humanPlayer.id] != 'Seña: $label') return;

    _updateState(() {
      _playerMessages.remove(_humanPlayer.id);
    });
    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        socket.signal(
          roomId: roomId,
          playerId: playerId,
          label: label,
          active: false,
        );
      }
    }
  }
}
