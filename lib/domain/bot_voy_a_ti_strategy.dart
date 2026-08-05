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
      final opponentBeatsProbability = _probabilityOpponentBeatsCard(
        opponent: opponent,
        cardStrength: cardStrength,
        hands: hands,
        unknownCards: unknownCards,
      );
      nobodyBeatsProbability *= 1 - opponentBeatsProbability;
    }
    return 1 - nobodyBeatsProbability;
  }

  static double riskThatRivalBeforeTeammateRaisesPastCard({
    required Player bot,
    required Player teammate,
    required SpanishCard teammateCard,
    required List<Player> players,
    required Map<String, List<SpanishCard>> hands,
    required List<PlayedCard> playedCards,
  }) {
    final opponents = _opponentsStillToPlayBeforeTeammate(
      bot: bot,
      teammate: teammate,
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

    final teammateStrength = ZapitiRules.strength(teammateCard);
    var nobodyRaisesPastTeammate = 1.0;
    for (final opponent in opponents) {
      final opponentBeatsProbability = _probabilityOpponentBeatsCard(
        opponent: opponent,
        cardStrength: teammateStrength,
        hands: hands,
        unknownCards: unknownCards,
      );
      nobodyRaisesPastTeammate *= 1 - opponentBeatsProbability;
    }
    return 1 - nobodyRaisesPastTeammate;
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
    final teammateCheapestWinningCard = teammateWinningCards.first;

    final botWinningCards = (hands[bot.id] ?? const <SpanishCard>[])
        .where((card) => ZapitiRules.strength(card) > bestStrength)
        .toList()
      ..sort(_compareByStrength);
    final botCheapestWinningCard =
        botWinningCards.isEmpty ? null : botWinningCards.first;
    final botCanWinCheap = botWinningCards.any((card) {
      return ZapitiRules.strength(card) < 80;
    });
    if (botCanWinCheap) return false;

    final teammateCanWinCheap =
        ZapitiRules.strength(teammateCheapestWinningCard) < 80;
    final botOnlyWinsCostly = botWinningCards.isNotEmpty && !botCanWinCheap;
    final isUrgent = opponentRoundWins > teamRoundWins ||
        opponentRoundWins > 0 ||
        handValue >= 3;
    final teammateRisk = riskThatRivalBeforeTeammateRaisesPastCard(
      bot: bot,
      teammate: teammate,
      teammateCard: teammateCheapestWinningCard,
      players: players,
      hands: hands,
      playedCards: playedCards,
    );
    final botRisk = botCheapestWinningCard == null
        ? 1.0
        : riskThatRivalStillToPlayBeats(
            bot: bot,
            card: botCheapestWinningCard,
            players: players,
            hands: hands,
            playedCards: playedCards,
          );
    final teammateStrength = ZapitiRules.strength(teammateCheapestWinningCard);
    final botStrength = botCheapestWinningCard == null
        ? 0
        : ZapitiRules.strength(botCheapestWinningCard);
    final teammateSavesStrength = botStrength - teammateStrength >= 8;
    final teammateImprovesSecurity =
        teammateRisk + 0.10 < botRisk || teammateStrength >= botStrength + 12;
    final teammatePlanIsBetter =
        teammateImprovesSecurity ||
        teammateSavesStrength ||
        teammateCanWinCheap;
    if (!teammatePlanIsBetter) {
      return false;
    }
    if (teammateRisk >= 0.78) return false;
    if (!isUrgent &&
        teammateRisk >= 0.58 &&
        !teammateImprovesSecurity &&
        !teammateSavesStrength) {
      return false;
    }

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
    if (teammateImprovesSecurity) chance += 0.16;
    if (teammateSavesStrength) chance += 0.12;
    chance -= teammateRisk * 0.30;
    chance += botRisk * 0.18;

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

  static List<Player> _opponentsStillToPlayBeforeTeammate({
    required Player bot,
    required Player teammate,
    required List<Player> players,
    required List<PlayedCard> playedCards,
  }) {
    final alreadyPlayedIds = {
      for (final playedCard in playedCards) playedCard.player.id,
    };
    final turnsUntilTeammate = _turnsFrom(
      bot: bot,
      player: teammate,
      players: players,
    );
    if (turnsUntilTeammate <= 1) return const [];

    return [
      for (final player in players)
        if (player.teamId != bot.teamId &&
            !alreadyPlayedIds.contains(player.id) &&
            _turnsFrom(bot: bot, player: player, players: players) > 0 &&
            _turnsFrom(bot: bot, player: player, players: players) <
                turnsUntilTeammate)
          player,
    ];
  }

  static int _turnsFrom({
    required Player bot,
    required Player player,
    required List<Player> players,
  }) {
    final botIndex = players.indexWhere((candidate) => candidate.id == bot.id);
    final playerIndex =
        players.indexWhere((candidate) => candidate.id == player.id);
    return (playerIndex - botIndex) % players.length;
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

  static double _probabilityOpponentBeatsCard({
    required Player opponent,
    required int cardStrength,
    required Map<String, List<SpanishCard>> hands,
    required List<SpanishCard> unknownCards,
  }) {
    final knownHand = hands[opponent.id];
    if (knownHand != null && knownHand.isNotEmpty) {
      return knownHand.any((card) => ZapitiRules.strength(card) > cardStrength)
          ? 1.0
          : 0.0;
    }

    final remainingCards = knownHand?.length ?? 0;
    return _probabilityHasHigherCard(
      unknownCards,
      cardStrength,
      remainingCards,
    );
  }

  static int _compareByStrength(SpanishCard a, SpanishCard b) {
    return ZapitiRules.strength(a).compareTo(ZapitiRules.strength(b));
  }
}
