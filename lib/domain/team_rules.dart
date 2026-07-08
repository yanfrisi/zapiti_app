class TeamRules {
  const TeamRules._();

  static const teamOne = 1;
  static const teamTwo = 2;

  /// Devuelve el equipo rival en una partida de dos parejas.
  static int opponentOf(int teamId) {
    if (teamId == teamOne) return teamTwo;
    if (teamId == teamTwo) return teamOne;
    throw ArgumentError.value(teamId, 'teamId', 'Equipo desconocido');
  }
}
