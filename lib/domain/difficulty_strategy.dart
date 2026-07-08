import 'dart:math';

import 'played_card.dart';
import 'player.dart';
import 'spanish_card.dart';
import 'zapiti_rules.dart';
import 'difficulty_profile.dart';

class DifficultyStrategy {
  const DifficultyStrategy._();

  static double cardMistakeChance(int difficulty) {
    return DifficultyProfiles.byLevel(difficulty).cardMistakeChance;
  }

  static SpanishCard applyCardMistake({
    required int difficulty,
    required Random random,
    required Player player,
    required List<SpanishCard> hand,
    required SpanishCard strategicCard,
    required List<PlayedCard> playedCards,
  }) {
    if (hand.length <= 1 ||
        _currentWinningTeamId(playedCards) == player.teamId) {
      return strategicCard;
    }

    final mistakeChance = cardMistakeChance(difficulty);
    if (mistakeChance == 0 || random.nextDouble() >= mistakeChance) {
      return strategicCard;
    }

    final alternatives = hand.where((card) => card != strategicCard).toList();
    if (alternatives.isEmpty) return strategicCard;
    alternatives.sort((a, b) => ZapitiRules.strength(a).compareTo(
          ZapitiRules.strength(b),
        ));
    return random.nextBool() ? alternatives.first : alternatives.last;
  }

  static int? _currentWinningTeamId(List<PlayedCard> playedCards) {
    if (playedCards.isEmpty) return null;

    final bestStrength = playedCards
        .map((playedCard) => ZapitiRules.strength(playedCard.card))
        .reduce((best, current) => current > best ? current : best);
    final strongestTeams = {
      for (final playedCard in playedCards)
        if (ZapitiRules.strength(playedCard.card) == bestStrength)
          playedCard.player.teamId,
    };
    return strongestTeams.length == 1 ? strongestTeams.first : null;
  }
}
