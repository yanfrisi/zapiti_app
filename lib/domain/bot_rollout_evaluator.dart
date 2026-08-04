import 'dart:math';

import 'game_state_simulator.dart';
import 'hidden_card_determinizer.dart';
import 'played_card.dart';
import 'player.dart';
import 'spanish_card.dart';
import 'team_rules.dart';

class BotRolloutEvaluator {
  const BotRolloutEvaluator._();

  static double evaluateCardOnce({
    required Player player,
    required SpanishCard candidate,
    required List<SpanishCard> hand,
    required List<PlayedCard> playedCards,
    required List<Player> players,
    required Map<String, List<SpanishCard>> hands,
    required int teamRoundWins,
    required int opponentRoundWins,
    required int handValue,
    required int rolloutIndex,
  }) {
    final simulator = const GameStateSimulator();
    final determinizedHands = HiddenCardDeterminizer.determinizeHands(
      bot: player,
      players: players,
      hands: hands,
      playedCards: playedCards,
      random: Random(_rolloutSeed(
        player: player,
        candidate: candidate,
        playedCards: playedCards,
        index: rolloutIndex,
      )),
    );
    final simulatedHands = {
      for (final entry in determinizedHands.entries) entry.key: [...entry.value],
    };
    simulatedHands[player.id]?.remove(candidate);
    final snapshot = SimulatedHandSnapshot(
      players: players,
      hands: simulatedHands,
      playedCards: [
        ...playedCards,
        PlayedCard(player: player, card: candidate),
      ],
      roundHistory: const [],
      roundWins: {
        TeamRules.teamOne: teamRoundWinsForTeam(
          player.teamId,
          teamRoundWins,
          opponentRoundWins,
          true,
        ),
        TeamRules.teamTwo: teamRoundWinsForTeam(
          player.teamId,
          teamRoundWins,
          opponentRoundWins,
          false,
        ),
      },
      turnIndex: (players.indexWhere((entry) => entry.id == player.id) + 1) %
          players.length,
      leadIndex: players.indexWhere((entry) => entry.id == player.id),
      handValue: handValue,
    );
    final result = simulator.simulateToEnd(snapshot, difficulty: 4);
    return _scoreResult(
      playerTeamId: player.teamId,
      result: result,
      handValue: handValue,
    );
  }

  static double evaluateCard({
    required Player player,
    required SpanishCard candidate,
    required List<SpanishCard> hand,
    required List<PlayedCard> playedCards,
    required List<Player> players,
    required Map<String, List<SpanishCard>> hands,
    required int teamRoundWins,
    required int opponentRoundWins,
    required int handValue,
    int rollouts = 12,
  }) {
    var totalScore = 0.0;

    for (var index = 0; index < rollouts; index++) {
      totalScore += evaluateCardOnce(
        player: player,
        candidate: candidate,
        hand: hand,
        playedCards: playedCards,
        players: players,
        hands: hands,
        teamRoundWins: teamRoundWins,
        opponentRoundWins: opponentRoundWins,
        handValue: handValue,
        rolloutIndex: index,
      );
    }

    return totalScore / rollouts;
  }

  static int teamRoundWinsForTeam(
    int playerTeamId,
    int teamRoundWins,
    int opponentRoundWins,
    bool teamOne,
  ) {
    if (playerTeamId == TeamRules.teamOne) {
      return teamOne ? teamRoundWins : opponentRoundWins;
    }
    return teamOne ? opponentRoundWins : teamRoundWins;
  }

  static double _scoreResult({
    required int playerTeamId,
    required SimulatedHandResult result,
    required int handValue,
  }) {
    final roundMargin =
        (result.roundWins[playerTeamId] ?? 0) -
        (result.roundWins[TeamRules.opponentOf(playerTeamId)] ?? 0);
    if (result.winningTeamId == playerTeamId) {
      return 1000 + handValue * 50 + roundMargin * 30;
    }
    if (result.winningTeamId == null) {
      return roundMargin * 20;
    }
    return -1000 - handValue * 50 + roundMargin * 30;
  }

  static int _rolloutSeed({
    required Player player,
    required SpanishCard candidate,
    required List<PlayedCard> playedCards,
    required int index,
  }) {
    var hash = Object.hash(player.id, candidate, index);
    for (final played in playedCards) {
      hash = Object.hash(hash, played.player.id, played.card);
    }
    return hash & 0x3fffffff;
  }
}
