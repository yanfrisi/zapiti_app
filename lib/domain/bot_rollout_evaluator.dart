import 'dart:math';

import 'game_state_simulator.dart';
import 'hand_rules.dart';
import 'hidden_card_determinizer.dart';
import 'played_card.dart';
import 'player.dart';
import 'round_result.dart';
import 'round_rules.dart';
import 'spanish_card.dart';
import 'team_rules.dart';
import 'zapiti_rules.dart';

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
    List<RoundResult> roundHistory = const <RoundResult>[],
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
    final currentLeadPlayerId = playedCards.isEmpty ? player.id : playedCards.first.player.id;
    final playedAfterCandidate = [
      ...playedCards,
      PlayedCard(player: player, card: candidate),
    ];
    final currentLeadIndex = players.indexWhere(
      (entry) => entry.id == currentLeadPlayerId,
    );
    final candidatePlayerIndex = players.indexWhere((entry) => entry.id == player.id);
    final initialRoundHistory = [...roundHistory];
    final initialRoundWins = {
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
    };
    final trickComplete = playedAfterCandidate.length == players.length;
    final nextPlayedCards = trickComplete ? const <PlayedCard>[] : playedAfterCandidate;
    final nextRoundHistory = [...initialRoundHistory];
    final nextRoundWins = {...initialRoundWins};
    var nextTurnIndex = (candidatePlayerIndex + 1) % players.length;
    var nextLeadIndex = currentLeadIndex < 0 ? candidatePlayerIndex : currentLeadIndex;

    if (trickComplete) {
      final result = RoundRules.resolveRound(playedAfterCandidate);
      nextRoundHistory.add(result);
      final progress = HandRules.resolve(nextRoundHistory);
      nextRoundWins[TeamRules.teamOne] = progress.roundWinsFor(TeamRules.teamOne);
      nextRoundWins[TeamRules.teamTwo] = progress.roundWinsFor(TeamRules.teamTwo);
      if (result.isTie) {
        nextTurnIndex = nextLeadIndex;
      } else {
        nextLeadIndex = players.indexWhere(
          (entry) => entry.id == result.winner!.player.id,
        );
        nextTurnIndex = nextLeadIndex;
      }
    }

    final snapshot = SimulatedHandSnapshot(
      players: players,
      hands: simulatedHands,
      playedCards: nextPlayedCards,
      roundHistory: nextRoundHistory,
      roundWins: nextRoundWins,
      turnIndex: nextTurnIndex,
      leadIndex: nextLeadIndex,
      handValue: handValue,
    );
    final result = simulator.simulateToEnd(snapshot, difficulty: 4);
    return _scoreResult(
          playerTeamId: player.teamId,
          result: result,
          handValue: handValue,
        ) +
        _resourcePreservationAdjustment(
          player: player,
          hand: hand,
          candidate: candidate,
          teamRoundWins: teamRoundWins,
          opponentRoundWins: opponentRoundWins,
          result: result,
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
    List<RoundResult> roundHistory = const <RoundResult>[],
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
        roundHistory: roundHistory,
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

  static double _resourcePreservationAdjustment({
    required Player player,
    required List<SpanishCard> hand,
    required SpanishCard candidate,
    required int teamRoundWins,
    required int opponentRoundWins,
    required SimulatedHandResult result,
  }) {
    if (result.winningTeamId != player.teamId) return 0;
    if (hand.length <= 1) return 0;
    if (teamRoundWins <= opponentRoundWins) return 0;

    final weakestStrength = hand
        .map(ZapitiRules.strength)
        .reduce((best, current) => current < best ? current : best);
    final candidateStrength = ZapitiRules.strength(candidate);
    if (candidateStrength <= weakestStrength) return 0;
    return -(candidateStrength - weakestStrength) * 0.5;
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
