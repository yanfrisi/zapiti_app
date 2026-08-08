import 'simulation_game_state.dart';
import 'signal_rules.dart';
import 'team_rules.dart';
import 'zapiti_rules.dart';

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
    final scoreGap = (state.score[botTeam] ?? 0) - (state.score[rivalTeam] ?? 0);
    final roundGap =
        (state.roundWins[botTeam] ?? 0) - (state.roundWins[rivalTeam] ?? 0);
    final reserveGap = _reserveStrength(state, botTeam) - _reserveStrength(state, rivalTeam);
    final strongCardGap =
        _strongCardCount(state, botTeam) - _strongCardCount(state, rivalTeam);
    final signalGap =
        _strongSignalCount(state, botTeam) - _strongSignalCount(state, rivalTeam);
    final tempoGap = _tempoBonus(state, botTeam) - _tempoBonus(state, rivalTeam);
    final trickGap = _currentTrickPressure(state, botTeam) - _currentTrickPressure(state, rivalTeam);

    return scoreGap * 120 +
        roundGap * 24 +
        reserveGap * 0.32 +
        strongCardGap * 18 +
        signalGap * 10 +
        tempoGap * 14 +
        trickGap * 0.9 +
        _teamShapeBonus(state, botTeam);
  }

  int _reserveStrength(SimulationGameState state, int teamId) {
    return state.players
        .where((entry) => entry.player.teamId == teamId)
        .expand((entry) => entry.hand)
        .fold<int>(0, (sum, card) => sum + ZapitiRules.strength(card));
  }

  int _strongCardCount(SimulationGameState state, int teamId) {
    return state.players
        .where((entry) => entry.player.teamId == teamId)
        .expand((entry) => entry.hand)
        .where((card) => ZapitiRules.strength(card) >= 80)
        .length;
  }

  int _strongSignalCount(SimulationGameState state, int teamId) {
    return state.players
        .where((entry) => entry.player.teamId == teamId)
        .where((entry) => SignalRules.isStrongSignal(
              SignalRules.signalForHand(entry.hand),
            ))
        .length;
  }

  double _teamShapeBonus(SimulationGameState state, int botTeamId) {
    final teamCards = state.players
        .where((entry) => entry.player.teamId == botTeamId)
        .expand((entry) => entry.hand)
        .toList();
    if (teamCards.isEmpty) return 0;

    final strengths = teamCards.map(ZapitiRules.strength).toList()..sort();
    final strongest = strengths.last;
    final second = strengths.length > 1 ? strengths[strengths.length - 2] : 0;
    final third = strengths.length > 2 ? strengths[strengths.length - 3] : 0;
    return strongest * 0.18 + second * 0.12 + third * 0.08;
  }

  double _tempoBonus(SimulationGameState state, int teamId) {
    final currentPlayer = state.players
        .firstWhere((entry) => entry.player.id == state.currentPlayerId)
        .player;
    var bonus = currentPlayer.teamId == teamId ? 1.0 : -0.4;
    if (state.currentTrick.isEmpty) {
      bonus += currentPlayer.teamId == teamId ? 0.6 : -0.2;
    }
    return bonus;
  }

  double _currentTrickPressure(SimulationGameState state, int teamId) {
    if (state.currentTrick.isEmpty) return 0;
    final bestStrength = state.currentTrick
        .map((played) => ZapitiRules.strength(played.card))
        .reduce((best, current) => current > best ? current : best);
    final strongestTeams = {
      for (final played in state.currentTrick)
        if (ZapitiRules.strength(played.card) == bestStrength) played.player.teamId,
    };
    final winningTeam = strongestTeams.length == 1 ? strongestTeams.first : null;
    final teamReserve = state.players
        .where((entry) => entry.player.teamId == teamId)
        .expand((entry) => entry.hand)
        .toList();
    final canStillBeat = teamReserve.any(
      (card) => ZapitiRules.strength(card) > bestStrength,
    );

    if (winningTeam == teamId) {
      return 18 + (canStillBeat ? 6 : 0);
    }
    if (winningTeam == null) {
      return canStillBeat ? 8 : 2;
    }
    return canStillBeat ? -6 : -18;
  }
}
