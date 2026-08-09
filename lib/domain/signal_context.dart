enum StrategicSignalType {
  venAMi,
  mata,
  voyATi,
  cardSignal,
}

enum StrategicSignalVisibility {
  teamOnly,
  observedByOpponents,
  public,
}

class StrategicSignal {
  final StrategicSignalType type;
  final String issuerPlayerId;
  final String? targetPlayerId;
  final int teamId;
  final int handVersion;
  final int trickIndex;
  final bool active;
  final StrategicSignalVisibility visibility;
  final String? label;

  const StrategicSignal({
    required this.type,
    required this.issuerPlayerId,
    required this.teamId,
    required this.handVersion,
    required this.trickIndex,
    this.targetPlayerId,
    this.active = true,
    this.visibility = StrategicSignalVisibility.teamOnly,
    this.label,
  });

  bool isActiveForTrick(int currentTrickIndex) {
    return active && trickIndex == currentTrickIndex;
  }

  bool isVisibleToTeam(int viewerTeamId) {
    return teamId == viewerTeamId ||
        visibility == StrategicSignalVisibility.public ||
        visibility == StrategicSignalVisibility.observedByOpponents;
  }

  bool appliesToPlayer({
    required String playerId,
    required int playerTeamId,
    required int currentTrickIndex,
  }) {
    if (!isActiveForTrick(currentTrickIndex)) return false;
    if (teamId != playerTeamId) return false;
    if (targetPlayerId != null) return targetPlayerId == playerId;
    return issuerPlayerId == playerId;
  }
}

class SignalContext {
  final List<StrategicSignal> signals;

  const SignalContext({this.signals = const []});

  static const empty = SignalContext();

  SignalContext visibleToTeam(int teamId) {
    return SignalContext(
      signals: [
        for (final signal in signals)
          if (signal.isVisibleToTeam(teamId)) signal,
      ],
    );
  }

  Iterable<StrategicSignal> activeForPlayer({
    required String playerId,
    required int playerTeamId,
    required int trickIndex,
  }) {
    return signals.where(
      (signal) => signal.appliesToPlayer(
        playerId: playerId,
        playerTeamId: playerTeamId,
        currentTrickIndex: trickIndex,
      ),
    );
  }

  bool hasActive({
    required StrategicSignalType type,
    required String playerId,
    required int playerTeamId,
    required int trickIndex,
  }) {
    return activeForPlayer(
      playerId: playerId,
      playerTeamId: playerTeamId,
      trickIndex: trickIndex,
    ).any((signal) => signal.type == type);
  }

  bool teamHasObservedStrongCardSignal(int teamId) {
    return signals.any(
      (signal) =>
          signal.type == StrategicSignalType.cardSignal &&
          signal.teamId == teamId &&
          signal.active,
    );
  }
}
