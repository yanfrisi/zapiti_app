import 'played_card.dart';
import 'player.dart';
import 'spanish_card.dart';
import 'bot_table_read.dart';
import 'zapiti_deck.dart';
import 'zapiti_rules.dart';

class BotVoyATiStrategy {
  const BotVoyATiStrategy._();

  static SpanishCard chooseCard({
    required Player bot,
    required List<SpanishCard> hand,
    required List<PlayedCard> playedCards,
    required List<Player> players,
    required Map<String, List<SpanishCard>> hands,
    double riskyCardThreshold = 0.58,
  }) {
    final sorted = [...hand]..sort(_compareByStrength);
    if (sorted.isEmpty) {
      throw ArgumentError('El bot no puede obedecer voy a ti sin cartas.');
    }
    if (playedCards.isEmpty) return sorted.last;

    final bestTableStrength = playedCards
        .map((playedCard) => ZapitiRules.strength(playedCard.card))
        .reduce((best, current) => current > best ? current : best);
    final winningCard = sorted.firstWhere(
      (card) => ZapitiRules.strength(card) > bestTableStrength,
      orElse: () => sorted.first,
    );
    if (ZapitiRules.strength(winningCard) <= bestTableStrength) {
      return sorted.first;
    }

    final risk = riskThatRivalStillToPlayBeats(
      bot: bot,
      card: winningCard,
      players: players,
      hands: hands,
      playedCards: playedCards,
    );
    final cardIsCostly = ZapitiRules.strength(winningCard) >= 80;
    if (cardIsCostly && risk >= riskyCardThreshold) {
      return sorted.first;
    }

    return winningCard;
  }

  static double riskThatRivalStillToPlayBeats({
    required Player bot,
    required SpanishCard card,
    required List<Player> players,
    required Map<String, List<SpanishCard>> hands,
    required List<PlayedCard> playedCards,
  }) {
    final opponents = _opponentsStillToPlayAfter(
      bot: bot,
      players: players,
      playedCards: playedCards,
    );
    if (opponents.isEmpty) return 0;

    final unknownCards = _unknownCardsFromBotPerspective(
      bot: bot,
      hands: hands,
      playedCards: playedCards,
    );
    if (unknownCards.isEmpty) return 0;

    final cardStrength = ZapitiRules.strength(card);
    var nobodyBeatsProbability = 1.0;
    for (final opponent in opponents) {
      final remainingCards = hands[opponent.id]?.length ?? 0;
      final opponentBeatsProbability = _probabilityHasHigherCard(
        unknownCards,
        cardStrength,
        remainingCards,
      );
      nobodyBeatsProbability *= 1 - opponentBeatsProbability;
    }
    return 1 - nobodyBeatsProbability;
  }

  static bool shouldAskTeammateToWin({
    required Player bot,
    required Player teammate,
    required List<Player> players,
    required Map<String, List<SpanishCard>> hands,
    required List<PlayedCard> playedCards,
    required int teamRoundWins,
    required int opponentRoundWins,
    required int handValue,
    required int difficulty,
    required double roll,
  }) {
    if (bot.teamId != teammate.teamId || bot.id == teammate.id) return false;
    if (playedCards.isEmpty) return false;
    if (!_playerStillToPlayAfter(
      bot: bot,
      player: teammate,
      players: players,
      playedCards: playedCards,
    )) {
      return false;
    }

    final currentWinningTeam = BotTableRead.currentWinningTeamOnTable(
      playedCards,
    );
    if (currentWinningTeam == bot.teamId) return false;

    final bestStrength = BotTableRead.bestTableStrength(playedCards);
    if (bestStrength == null) return false;

    final teammateWinningCards = (hands[teammate.id] ?? const <SpanishCard>[])
        .where((card) => ZapitiRules.strength(card) > bestStrength)
        .toList()
      ..sort(_compareByStrength);
    if (teammateWinningCards.isEmpty) return false;

    final botWinningCards = (hands[bot.id] ?? const <SpanishCard>[])
        .where((card) => ZapitiRules.strength(card) > bestStrength)
        .toList()
      ..sort(_compareByStrength);
    final botCanWinCheap = botWinningCards.any((card) {
      return ZapitiRules.strength(card) < 80;
    });
    if (botCanWinCheap) return false;

    final teammateCanWinCheap = ZapitiRules.strength(
          teammateWinningCards.first,
        ) <
        80;
    final botOnlyWinsCostly = botWinningCards.isNotEmpty && !botCanWinCheap;
    final isUrgent = opponentRoundWins > teamRoundWins ||
        opponentRoundWins > 0 ||
        handValue >= 3;

    var chance = switch (difficulty.clamp(1, 5)) {
      1 => 0.08,
      2 => 0.14,
      3 => 0.24,
      4 => 0.34,
      _ => 0.42,
    };
    if (isUrgent) chance += 0.18;
    if (teammateCanWinCheap) chance += 0.08;
    if (botOnlyWinsCostly) chance += 0.10;

    return roll < chance.clamp(0, 0.75);
  }

  static List<Player> _opponentsStillToPlayAfter({
    required Player bot,
    required List<Player> players,
    required List<PlayedCard> playedCards,
  }) {
    final remainingTurnsAfterBot = players.length - playedCards.length - 1;
    if (remainingTurnsAfterBot <= 0) return const [];

    final botIndex = players.indexWhere((player) => player.id == bot.id);
    return [
      for (final opponent in players.where((player) {
        final alreadyPlayed = playedCards.any(
          (playedCard) => playedCard.player.id == player.id,
        );
        return player.teamId != bot.teamId && !alreadyPlayed;
      }))
        if (((players.indexWhere((player) => player.id == opponent.id) -
                    botIndex) %
                players.length) <=
            remainingTurnsAfterBot)
          opponent,
    ];
  }

  static bool _playerStillToPlayAfter({
    required Player bot,
    required Player player,
    required List<Player> players,
    required List<PlayedCard> playedCards,
  }) {
    final alreadyPlayed = playedCards.any(
      (playedCard) => playedCard.player.id == player.id,
    );
    if (alreadyPlayed) return false;

    final remainingTurnsAfterBot = players.length - playedCards.length - 1;
    if (remainingTurnsAfterBot <= 0) return false;

    final botIndex = players.indexWhere((candidate) => candidate.id == bot.id);
    final playerIndex =
        players.indexWhere((candidate) => candidate.id == player.id);
    final turnsUntilPlayer = (playerIndex - botIndex) % players.length;
    return turnsUntilPlayer > 0 && turnsUntilPlayer <= remainingTurnsAfterBot;
  }

  static List<SpanishCard> _unknownCardsFromBotPerspective({
    required Player bot,
    required Map<String, List<SpanishCard>> hands,
    required List<PlayedCard> playedCards,
  }) {
    final unknownCards = ZapitiDeck.fullDeck();
    for (final card in hands[bot.id] ?? const <SpanishCard>[]) {
      unknownCards.remove(card);
    }
    for (final playedCard in playedCards) {
      unknownCards.remove(playedCard.card);
    }
    return unknownCards;
  }

  static double _probabilityHasHigherCard(
    List<SpanishCard> unknownCards,
    int cardStrength,
    int cardsInHand,
  ) {
    if (unknownCards.isEmpty || cardsInHand <= 0) return 0;

    final total = unknownCards.length;
    final higherCards = unknownCards.where((card) {
      return ZapitiRules.strength(card) > cardStrength;
    }).length;
    if (higherCards == 0) return 0;
    if (cardsInHand >= total) return 1;

    var noHigherProbability = 1.0;
    final safeCards = total - higherCards;
    for (var draw = 0; draw < cardsInHand; draw++) {
      final denominator = total - draw;
      final numerator = safeCards - draw;
      if (numerator <= 0) return 1;
      noHigherProbability *= numerator / denominator;
    }
    return 1 - noHigherProbability;
  }

  static int _compareByStrength(SpanishCard a, SpanishCard b) {
    return ZapitiRules.strength(a).compareTo(ZapitiRules.strength(b));
  }
}
