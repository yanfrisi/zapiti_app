import 'played_card.dart';

class RoundResult {
  final PlayedCard? winner;
  final List<PlayedCard> playedCards;

  const RoundResult({
    required this.winner,
    required this.playedCards,
  });

  bool get isTie => winner == null;

  int? get winningTeamId => winner?.player.teamId;
}
