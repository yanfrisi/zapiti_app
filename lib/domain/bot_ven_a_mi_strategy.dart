import 'bot_table_read.dart';
import 'played_card.dart';
import 'player.dart';
import 'spanish_card.dart';
import 'zapiti_rules.dart';

class BotVenAMiStrategy {
  const BotVenAMiStrategy._();

  static SpanishCard chooseCard({
    required Player bot,
    required List<SpanishCard> hand,
    required List<PlayedCard> playedCards,
    required List<Player> players,
    required Map<String, List<SpanishCard>> hands,
  }) {
    if (hand.isEmpty) {
      throw ArgumentError('El bot no puede obedecer ven a mi sin cartas.');
    }

    final sorted = [...hand]..sort(_compareByStrength);
    if (playedCards.isEmpty) return sorted.first;

    final bestTableStrength = BotTableRead.bestTableStrength(playedCards);
    if (bestTableStrength == null) return sorted.first;

    final currentWinningTeam = BotTableRead.currentWinningTeamOnTable(
      playedCards,
    );
    final safeLowCards = sorted.where((card) {
      return ZapitiRules.strength(card) <= bestTableStrength;
    }).toList();

    if (currentWinningTeam == bot.teamId && safeLowCards.isNotEmpty) {
      final tableRisk = _riskThatOpponentsAfterBotBeatStrength(
        bot: bot,
        cardStrength: bestTableStrength,
        players: players,
        hands: hands,
        playedCards: playedCards,
      );
      if (tableRisk < 1 || !_hasWinningCard(sorted, bestTableStrength)) {
        return safeLowCards.first;
      }

      final stabilizingWinningCards = sorted.where((card) {
        final candidateStrength = ZapitiRules.strength(card);
        if (candidateStrength <= bestTableStrength) return false;
        final simulated = [
          ...playedCards,
          PlayedCard(player: bot, card: card),
        ];
        final resultingBestStrength =
            BotTableRead.bestTableStrength(simulated) ?? bestTableStrength;
        return _riskThatOpponentsAfterBotBeatStrength(
              bot: bot,
              cardStrength: resultingBestStrength,
              players: players,
              hands: hands,
              playedCards: simulated,
            ) <
            1;
      }).toList();
      if (stabilizingWinningCards.isNotEmpty) {
        return stabilizingWinningCards.first;
      }
    }

    SpanishCard best = sorted.first;
    var bestScore = double.negativeInfinity;
    for (final candidate in sorted) {
      final score = _scoreCandidate(
        bot: bot,
        candidate: candidate,
        hand: sorted,
        playedCards: playedCards,
        players: players,
        hands: hands,
        bestTableStrength: bestTableStrength,
        currentWinningTeam: currentWinningTeam,
      );
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }
    return best;
  }

  static double _scoreCandidate({
    required Player bot,
    required SpanishCard candidate,
    required List<SpanishCard> hand,
    required List<PlayedCard> playedCards,
    required List<Player> players,
    required Map<String, List<SpanishCard>> hands,
    required int bestTableStrength,
    required int? currentWinningTeam,
  }) {
    final candidateStrength = ZapitiRules.strength(candidate);
    final simulated = [
      ...playedCards,
      PlayedCard(player: bot, card: candidate),
    ];
    final resultingWinningTeam = BotTableRead.currentWinningTeamOnTable(
      simulated,
    );
    final resultingBestStrength = BotTableRead.bestTableStrength(simulated) ??
        bestTableStrength;
    final responseRisk = _riskThatOpponentsAfterBotBeatStrength(
      bot: bot,
      cardStrength: resultingBestStrength,
      players: players,
      hands: hands,
      playedCards: simulated,
    );
    final obeysVenAMi = candidateStrength <= bestTableStrength;

    var score = 0.0;
    if (obeysVenAMi) {
      score += 120;
      score -= candidateStrength * 0.55;
    } else {
      score += 40;
      score -= candidateStrength * 0.9;
    }

    if (resultingWinningTeam == bot.teamId) {
      score += 90;
      score += (1 - responseRisk) * 140;
    } else if (resultingWinningTeam == null) {
      score += 8;
      score -= responseRisk * 80;
    } else {
      score -= 120;
      score -= responseRisk * 30;
    }

    if (currentWinningTeam == bot.teamId && obeysVenAMi) {
      score += 70;
    }

    if (!obeysVenAMi && currentWinningTeam == bot.teamId) {
      score -= 110;
    }

    if (!obeysVenAMi &&
        resultingWinningTeam == bot.teamId &&
        responseRisk >= 1) {
      score -= 180;
    }

    if (obeysVenAMi && currentWinningTeam != bot.teamId) {
      final tableRiskIfDuck = _riskThatOpponentsAfterBotBeatStrength(
        bot: bot,
        cardStrength: bestTableStrength,
        players: players,
        hands: hands,
        playedCards: playedCards,
      );
      if (tableRiskIfDuck >= 1 && _hasWinningCard(hand, bestTableStrength)) {
        score -= 220;
      }
    }

    if (currentWinningTeam != bot.teamId &&
        resultingWinningTeam != bot.teamId &&
        _hasWinningCard(hand, bestTableStrength)) {
      score -= obeysVenAMi ? 260 : 90;
    }

    return score;
  }

  static bool _hasWinningCard(List<SpanishCard> hand, int bestTableStrength) {
    return hand.any((card) => ZapitiRules.strength(card) > bestTableStrength);
  }

  static double _riskThatOpponentsAfterBotBeatStrength({
    required Player bot,
    required int cardStrength,
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

    for (final opponent in opponents) {
      final knownHand = hands[opponent.id] ?? const <SpanishCard>[];
      if (knownHand.any((card) => ZapitiRules.strength(card) > cardStrength)) {
        return 1;
      }
    }
    return 0;
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

  static int _compareByStrength(SpanishCard a, SpanishCard b) {
    return ZapitiRules.strength(a).compareTo(ZapitiRules.strength(b));
  }
}
