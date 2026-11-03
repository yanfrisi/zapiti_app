import 'dart:math';

import 'bot_belief_state.dart';
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
    final setup = _SamplerSetup.create(state);
    setup.deck.shuffle(random);
    _fillUniformly(setup);
    return setup.buildDeal();
  }
}

class InferenceBiasedPossibleDealSampler implements PossibleDealSampler {
  final bool useActionInference;
  final bool usePartnerModel;
  final bool useOpponentProfiles;
  final bool useSignalInference;
  final bool useBetInference;

  const InferenceBiasedPossibleDealSampler({
    required this.useActionInference,
    required this.usePartnerModel,
    required this.useOpponentProfiles,
    this.useSignalInference = false,
    this.useBetInference = false,
  });

  @override
  PossibleDeal sample(ObservableGameState state, Random random) {
    final setup = _SamplerSetup.create(state);
    final belief = BotBeliefState.fromObservable(
      state,
      useSignals: useSignalInference,
      useActionInference: useActionInference,
      useBetInference: useBetInference,
      usePartnerModel: usePartnerModel,
      useOpponentProfiles: useOpponentProfiles,
    );
    final cards = [...setup.deck]..shuffle(random);

    for (final card in cards.take(setup.totalRemainingSlots)) {
      final candidates = <String>[];
      final weights = <double>[];
      for (final player in state.players) {
        final slots = setup.remainingSlots[player.id] ?? 0;
        if (slots <= 0 || player.id == state.botPlayerId) continue;
        final weight = belief.weightFor(player.id, card);
        candidates.add(player.id);
        weights.add(weight * slots);
      }
      if (candidates.isEmpty) {
        throw StateError('No eligible player for hidden-card assignment.');
      }
      final recipient = _weightedChoice(candidates, weights, random);
      setup.sampledHands
          .putIfAbsent(recipient, () => <SpanishCard>[])
          .add(card);
      setup.remainingSlots[recipient] = setup.remainingSlots[recipient]! - 1;
    }
    return setup.buildDeal();
  }
}

class _SamplerSetup {
  final List<SpanishCard> deck;
  final Map<String, List<SpanishCard>> sampledHands;
  final Map<String, int> remainingSlots;

  const _SamplerSetup({
    required this.deck,
    required this.sampledHands,
    required this.remainingSlots,
  });

  int get totalRemainingSlots =>
      remainingSlots.values.fold<int>(0, (sum, count) => sum + count);

  factory _SamplerSetup.create(ObservableGameState state) {
    final deck = ZapitiDeck.fullDeck();
    final sampledHands = <String, List<SpanishCard>>{
      state.botPlayerId: [...state.botHand],
    };
    final seen = <SpanishCard>{...state.botHand};
    for (final card in state.botHand) {
      deck.remove(card);
    }
    for (final played in state.allObservedPlayedCards) {
      if (!seen.add(played.card)) {
        throw StateError('Played card ${played.card} duplicates a known card.');
      }
      deck.remove(played.card);
    }
    final knownCards = <SpanishCard>{};
    for (final entry in state.publiclyKnownCardsByPlayerId.entries) {
      if (entry.key == state.botPlayerId) continue;
      if (!state.players.any((player) => player.id == entry.key)) {
        throw ArgumentError('Known cards belong to an unknown player.');
      }
      sampledHands[entry.key] = [...entry.value];
      for (final card in entry.value) {
        if (!knownCards.add(card) || seen.contains(card)) {
          throw StateError('A known card has conflicting locations.');
        }
        seen.add(card);
        deck.remove(card);
      }
    }

    final remainingSlots = <String, int>{};
    for (final player in state.players) {
      final count = state.cardsRemainingByPlayerId[player.id] ?? 0;
      if (count < 0) throw ArgumentError('Negative pending-card count.');
      final assigned =
          sampledHands.putIfAbsent(player.id, () => <SpanishCard>[]);
      final missing = count - assigned.length;
      if (missing < 0) {
        throw ArgumentError(
            'Public information exceeds expected hand size for ${player.id}.');
      }
      remainingSlots[player.id] = missing;
    }
    final needed =
        remainingSlots.values.fold<int>(0, (sum, count) => sum + count);
    if (needed > deck.length) {
      throw StateError('Not enough cards for determinization.');
    }
    return _SamplerSetup(
      deck: deck,
      sampledHands: sampledHands,
      remainingSlots: remainingSlots,
    );
  }

  PossibleDeal buildDeal() => PossibleDeal({
        for (final entry in sampledHands.entries)
          entry.key: List.unmodifiable(entry.value),
      });
}

void _fillUniformly(_SamplerSetup setup) {
  var offset = 0;
  for (final entry in setup.remainingSlots.entries) {
    if (entry.value <= 0) continue;
    setup.sampledHands[entry.key]!.addAll(
      setup.deck.sublist(offset, offset + entry.value),
    );
    offset += entry.value;
  }
}

String _weightedChoice(
    List<String> candidates, List<double> weights, Random random) {
  final total = weights.fold<double>(0, (sum, value) => sum + value);
  if (total <= 0) {
    throw StateError('No positive belief weight for hidden card.');
  }
  var roll = random.nextDouble() * total;
  for (var index = 0; index < candidates.length; index++) {
    roll -= weights[index];
    if (roll < 0) return candidates[index];
  }
  return candidates.last;
}
