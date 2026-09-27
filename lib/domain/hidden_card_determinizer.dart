import 'dart:math';

import 'played_card.dart';
import 'player.dart';
import 'spanish_card.dart';
import 'zapiti_deck.dart';

class HiddenCardDeterminizer {
  const HiddenCardDeterminizer._();

  static Map<String, List<SpanishCard>> determinizeHands({
    required Player bot,
    required List<Player> players,
    required Map<String, List<SpanishCard>> hands,
    required List<PlayedCard> playedCards,
    Map<String, List<SpanishCard>> publiclyKnownCardsByPlayer = const {},
    Random? random,
  }) {
    final rng = random ?? Random(_publicStateSeed(
      bot: bot,
      players: players,
      hands: hands,
      playedCards: playedCards,
      publiclyKnownCardsByPlayer: publiclyKnownCardsByPlayer,
    ));

    final remainingDeck = ZapitiDeck.fullDeck();
    final result = <String, List<SpanishCard>>{};

    final botHand = [...?hands[bot.id]];
    result[bot.id] = botHand;
    for (final card in botHand) {
      remainingDeck.remove(card);
    }

    for (final playedCard in playedCards) {
      remainingDeck.remove(playedCard.card);
    }

    for (final player in players) {
      if (player.id == bot.id) continue;
      final knownCards = [...?publiclyKnownCardsByPlayer[player.id]];
      result[player.id] = knownCards;
      for (final card in knownCards) {
        remainingDeck.remove(card);
      }
    }

    remainingDeck.shuffle(rng);

    for (final player in players) {
      if (player.id == bot.id) continue;
      final targetCount = hands[player.id]?.length ?? 0;
      final assigned = result[player.id] ?? <SpanishCard>[];
      final missingCount = targetCount - assigned.length;
      if (missingCount < 0) {
        throw ArgumentError(
          'La informacion publica excede las cartas esperadas para ${player.id}.',
        );
      }
      if (remainingDeck.length < missingCount) {
        throw StateError('No hay suficientes cartas para determinizar la mano.');
      }
      assigned.addAll(remainingDeck.take(missingCount));
      remainingDeck.removeRange(0, missingCount);
      result[player.id] = assigned;
    }

    return result;
  }

  static int _publicStateSeed({
    required Player bot,
    required List<Player> players,
    required Map<String, List<SpanishCard>> hands,
    required List<PlayedCard> playedCards,
    required Map<String, List<SpanishCard>> publiclyKnownCardsByPlayer,
  }) {
    var hash = bot.id.hashCode;
    for (final player in players) {
      hash = Object.hash(
        hash,
        player.id,
        player.teamId,
        hands[player.id]?.length ?? 0,
      );
    }
    for (final playedCard in playedCards) {
      hash = Object.hash(hash, playedCard.player.id, playedCard.card);
    }
    final publicKeys = publiclyKnownCardsByPlayer.keys.toList()..sort();
    for (final playerId in publicKeys) {
      hash = Object.hash(hash, playerId);
      for (final card in publiclyKnownCardsByPlayer[playerId]!) {
        hash = Object.hash(hash, card);
      }
    }
    return hash & 0x3fffffff;
  }
}
