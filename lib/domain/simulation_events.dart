sealed class SimulationEvent {
  const SimulationEvent();
}

class CardPlayedEvent extends SimulationEvent {
  final String playerId;
  final Object card;
  const CardPlayedEvent({required this.playerId, required this.card});
}

class TrickCompletedEvent extends SimulationEvent {
  final int? winningTeamId;
  const TrickCompletedEvent({required this.winningTeamId});
}

class RoundCompletedEvent extends SimulationEvent {
  final int? winningTeamId;
  const RoundCompletedEvent({required this.winningTeamId});
}

class ScoreChangedEvent extends SimulationEvent {
  final Map<int, int> score;
  const ScoreChangedEvent({required this.score});
}

