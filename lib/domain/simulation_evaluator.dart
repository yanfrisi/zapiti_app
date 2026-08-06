import 'simulation_game_state.dart';
import 'team_rules.dart';

abstract interface class SimulationEvaluator {
  double evaluate(SimulationGameState state, String botPlayerId);
}

class TeamSimulationEvaluator implements SimulationEvaluator {
  const TeamSimulationEvaluator();

  @override
  double evaluate(SimulationGameState state, String botPlayerId) {
    final botTeam = state.players
        .firstWhere((player) => player.player.id == botPlayerId)
        .player
        .teamId;
    final rivalTeam = TeamRules.opponentOf(botTeam);
    return (state.score[botTeam] ?? 0) * 100 -
        (state.score[rivalTeam] ?? 0) * 100 +
        (state.roundWins[botTeam] ?? 0) * 10 -
        (state.roundWins[rivalTeam] ?? 0) * 10 +
        _conservationBonus(state, botTeam);
  }

  double _conservationBonus(SimulationGameState state, int botTeamId) {
    final remainingStrength = state.players
        .where((entry) => entry.player.teamId == botTeamId)
        .expand((entry) => entry.hand)
        .fold<int>(0, (sum, card) => sum + card.value);
    return remainingStrength * 0.12;
  }
}
