import 'played_card.dart';
import 'round_result.dart';
import 'zapiti_rules.dart';

class RoundRules {
  const RoundRules._();

  static RoundResult resolveRound(List<PlayedCard> playedCards) {
    if (playedCards.isEmpty) {
      throw ArgumentError('No se puede resolver una ronda sin cartas.');
    }

    final teams = {for (final playedCard in playedCards) playedCard.player.teamId};
    if (teams.length != 2) {
      throw StateError(
        'Se esperaban exactamente dos equipos, pero hay ${teams.length}.',
      );
    }

    final bestStrength = playedCards
        .map((playedCard) => ZapitiRules.strength(playedCard.card))
        .reduce((best, current) => current > best ? current : best);
    final strongestCards = playedCards.where((playedCard) {
      return ZapitiRules.strength(playedCard.card) == bestStrength;
    }).toList();
    final strongestTeams = {
      for (final playedCard in strongestCards) playedCard.player.teamId,
    };

    return RoundResult(
      winner: strongestTeams.length == 1 ? strongestCards.first : null,
      playedCards: List.unmodifiable(playedCards),
    );
  }
}
