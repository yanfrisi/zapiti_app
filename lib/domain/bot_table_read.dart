import 'played_card.dart';
import 'player.dart';
import 'spanish_card.dart';
import 'team_rules.dart';
import 'zapiti_rules.dart';

class BotTableRead {
  const BotTableRead._();

  static bool currentRoundIsUnsavableForTeam({
    required int teamId,
    required List<Player> players,
    required Map<String, List<SpanishCard>> hands,
    required List<PlayedCard> playedCards,
  }) {
    if (playedCards.isEmpty) return false;

    final opponentTeamId = TeamRules.opponentOf(teamId);
    final currentWinningTeam = currentWinningTeamOnTable(playedCards);
    if (currentWinningTeam != opponentTeamId) return false;

    final bestStrength = bestTableStrength(playedCards);
    if (bestStrength == null) return false;

    final teamHasPlayedSavingCard = playedCards.any((playedCard) {
      return playedCard.player.teamId == teamId &&
          ZapitiRules.strength(playedCard.card) >= bestStrength;
    });
    if (teamHasPlayedSavingCard) return false;

    final teamCanStillSaveRound = players.where((player) {
      final alreadyPlayed = playedCards.any(
        (playedCard) => playedCard.player.id == player.id,
      );
      return player.teamId == teamId && !alreadyPlayed;
    }).any((player) {
      return (hands[player.id] ?? const <SpanishCard>[]).any(
        (card) => ZapitiRules.strength(card) >= bestStrength,
      );
    });

    return !teamCanStillSaveRound;
  }

  static int? currentWinningTeamOnTable(List<PlayedCard> playedCards) {
    final bestStrength = bestTableStrength(playedCards);
    if (bestStrength == null) return null;

    final strongestTeams = {
      for (final playedCard in playedCards)
        if (ZapitiRules.strength(playedCard.card) == bestStrength)
          playedCard.player.teamId,
    };
    return strongestTeams.length == 1 ? strongestTeams.first : null;
  }

  static int? bestTableStrength(List<PlayedCard> playedCards) {
    if (playedCards.isEmpty) return null;
    return playedCards
        .map((playedCard) => ZapitiRules.strength(playedCard.card))
        .reduce((best, current) => current > best ? current : best);
  }
}
