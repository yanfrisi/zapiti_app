import 'played_card.dart';
import 'player.dart';
import 'round_result.dart';
import 'zapiti_rules.dart';

class BotMemoryContext {
  final int strongCardsPlayed;
  final int strongCardsPlayedByOpponents;
  final int strongCardsPlayedByTeam;
  final bool teamWonAnyRound;
  final bool opponentsWonAnyRound;
  final bool teammateWonLastRound;
  final bool opponentWonLastRound;
  final int opponentRoundsWon;
  final int teamRoundsWon;

  const BotMemoryContext({
    required this.strongCardsPlayed,
    required this.strongCardsPlayedByOpponents,
    required this.strongCardsPlayedByTeam,
    required this.teamWonAnyRound,
    required this.opponentsWonAnyRound,
    required this.teammateWonLastRound,
    required this.opponentWonLastRound,
    required this.opponentRoundsWon,
    required this.teamRoundsWon,
  });

  bool get tableIsDrained => strongCardsPlayed >= 2;
  bool get opponentsSpentPower => strongCardsPlayedByOpponents >= 1;
  bool get teamSpentPower => strongCardsPlayedByTeam >= 1;
  bool get opponentsSpentMorePower =>
      strongCardsPlayedByOpponents > strongCardsPlayedByTeam;
  bool get teamIsUnderRoundPressure => opponentRoundsWon > teamRoundsWon;

  static BotMemoryContext from({
    required Player bot,
    required List<PlayedCard> playedCards,
    required List<RoundResult> roundHistory,
  }) {
    final strongPlayed = playedCards.where(_isStrong).toList();
    final strongByOpponents = strongPlayed.where((playedCard) {
      return playedCard.player.teamId != bot.teamId;
    }).length;
    final strongByTeam = strongPlayed.length - strongByOpponents;
    final teamWonAnyRound = roundHistory.any((result) {
      return result.winningTeamId == bot.teamId;
    });
    final opponentsWonAnyRound = roundHistory.any((result) {
      final winningTeamId = result.winningTeamId;
      return winningTeamId != null && winningTeamId != bot.teamId;
    });
    final lastWinner = roundHistory.isEmpty ? null : roundHistory.last.winner;
    final opponentRoundsWon = roundHistory.where((result) {
      final winningTeamId = result.winningTeamId;
      return winningTeamId != null && winningTeamId != bot.teamId;
    }).length;
    final teamRoundsWon = roundHistory.where((result) {
      return result.winningTeamId == bot.teamId;
    }).length;

    return BotMemoryContext(
      strongCardsPlayed: strongPlayed.length,
      strongCardsPlayedByOpponents: strongByOpponents,
      strongCardsPlayedByTeam: strongByTeam,
      teamWonAnyRound: teamWonAnyRound,
      opponentsWonAnyRound: opponentsWonAnyRound,
      teammateWonLastRound: lastWinner != null &&
          lastWinner.player.teamId == bot.teamId &&
          lastWinner.player.id != bot.id,
      opponentWonLastRound:
          lastWinner != null && lastWinner.player.teamId != bot.teamId,
      opponentRoundsWon: opponentRoundsWon,
      teamRoundsWon: teamRoundsWon,
    );
  }

  static bool _isStrong(PlayedCard playedCard) {
    return ZapitiRules.strength(playedCard.card) >= 80;
  }
}
