import 'dart:math';

import 'observable_game_state.dart';
import 'spanish_card.dart';
import 'zapiti_deck.dart';

class PossibleDeal {
  final Map<String, List<SpanishCard>> handsByPlayerId;

  const PossibleDeal(this.handsByPlayerId);
}

abstract interface class PossibleDealSampler {
  PossibleDeal sample(ObservableGameState state, Random random);
}

class UniformPossibleDealSampler implements PossibleDealSampler {
  const UniformPossibleDealSampler();

  @override
  PossibleDeal sample(ObservableGameState state, Random random) {
    final deck = ZapitiDeck.fullDeck();
    final sampledHands = <String, List<SpanishCard>>{
      state.botPlayerId: [...state.botHand],
    };
    final seen = <SpanishCard>{...state.botHand};

    for (final card in state.botHand) {
      deck.remove(card);
    }
    for (final played in state.playedCards) {
      if (!seen.add(played.card)) {
        throw StateError('Una carta no vista coincide con una carta propia.');
      }
      deck.remove(played.card);
    }
    for (final entry in state.publiclyKnownCardsByPlayerId.entries) {
      if (entry.key == state.botPlayerId) continue;
      sampledHands[entry.key] = [...entry.value];
      for (final card in entry.value) {
        deck.remove(card);
      }
    }

    deck.shuffle(random);

    final otherPlayers = [
      for (final player in state.players)
        if (player.id != state.botPlayerId) player.id,
    ];
    var deckIndex = 0;
    for (final playerId in otherPlayers) {
      final targetCount = state.cardsRemainingByPlayerId[playerId] ?? 0;
      if (targetCount < 0) {
        throw ArgumentError('Un jugador no puede tener cartas pendientes negativas.');
      }
      final assigned = sampledHands.putIfAbsent(playerId, () => <SpanishCard>[]);
      final missingCount = targetCount - assigned.length;
      if (missingCount < 0) {
        throw ArgumentError(
          'La informacion publica excede las cartas esperadas para $playerId.',
        );
      }
      if (deckIndex + missingCount > deck.length) {
        throw StateError('No hay suficientes cartas para determinizacion.');
      }
      assigned.addAll(deck.sublist(deckIndex, deckIndex + missingCount));
      deckIndex += missingCount;
    }

    return PossibleDeal({
      for (final entry in sampledHands.entries)
        entry.key: List.unmodifiable(entry.value),
    });
  }
}
