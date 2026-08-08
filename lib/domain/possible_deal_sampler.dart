import 'dart:math';

import 'observable_game_state.dart';
import 'player.dart';
import 'spanish_card.dart';
import 'zapiti_deck.dart';
import 'zapiti_rules.dart';

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

  const InferenceBiasedPossibleDealSampler({
    required this.useActionInference,
    required this.usePartnerModel,
    required this.useOpponentProfiles,
  });

  @override
  PossibleDeal sample(ObservableGameState state, Random random) {
    final setup = _SamplerSetup.create(state);
    final biases = _computeRetentionBiases(state);
    final orderedDeck = [...setup.deck]
      ..shuffle(random)
      ..sort(
        (a, b) => ZapitiRules.strength(b).compareTo(ZapitiRules.strength(a)),
      );
    final cardsToAssign = orderedDeck.take(setup.totalRemainingSlots).toList(growable: false);

    for (final card in cardsToAssign) {
      final targetPlayerId = _pickPlayerForCard(
        state: state,
        card: card,
        biases: biases,
        remainingSlots: setup.remainingSlots,
        random: random,
      );
      setup.sampledHands.putIfAbsent(targetPlayerId, () => <SpanishCard>[]).add(card);
      setup.remainingSlots[targetPlayerId] = setup.remainingSlots[targetPlayerId]! - 1;
    }

    return setup.buildDeal();
  }

  Map<String, double> _computeRetentionBiases(ObservableGameState state) {
    final biases = <String, double>{};
    for (final player in state.players) {
      if (player.id == state.botPlayerId) continue;
      var bias = 0.0;

      if (useActionInference) {
        bias += _actionInferenceBias(state, player);
      }
      if (usePartnerModel && player.teamId == _botTeamId(state)) {
        bias += 0.10;
      }
      if (useOpponentProfiles && player.teamId != _botTeamId(state)) {
        bias += _opponentProfileBias(state, player);
      }

      biases[player.id] = bias.clamp(-0.35, 0.35);
    }
    return biases;
  }

  double _actionInferenceBias(ObservableGameState state, Player player) {
    final played = state.playedCards.where((card) => card.player.id == player.id).toList();
    if (played.isEmpty) {
      return 0.05;
    }

    final averageStrength = played
            .map((entry) => ZapitiRules.strength(entry.card))
            .fold<int>(0, (sum, value) => sum + value) /
        played.length;
    if (averageStrength <= 35) return 0.18;
    if (averageStrength >= 80) return -0.14;
    return 0.02;
  }

  double _opponentProfileBias(ObservableGameState state, Player player) {
    final played = state.playedCards.where((card) => card.player.id == player.id).toList();
    if (played.isEmpty) {
      final seatIndex = state.players.indexWhere((entry) => entry.id == player.id);
      return seatIndex.isEven ? 0.04 : -0.02;
    }

    final bestPlayed = played
        .map((entry) => ZapitiRules.strength(entry.card))
        .reduce((best, current) => current > best ? current : best);
    if (bestPlayed >= 95) return -0.18;
    if (bestPlayed <= 25) return 0.12;
    return -0.03;
  }

  String _pickPlayerForCard({
    required ObservableGameState state,
    required SpanishCard card,
    required Map<String, double> biases,
    required Map<String, int> remainingSlots,
    required Random random,
  }) {
    final cardStrength = ZapitiRules.strength(card) / 100.0;
    final candidates = <String>[];
    final weights = <double>[];

    for (final player in state.players) {
      final playerId = player.id;
      final slots = remainingSlots[playerId] ?? 0;
      if (playerId == state.botPlayerId || slots <= 0) continue;

      final bias = biases[playerId] ?? 0.0;
      final strengthPull = 1 + (bias * ((cardStrength - 0.5) * 2.0));
      final slotWeight = 0.75 + (slots * 0.35);
      final weight = max(0.05, slotWeight * strengthPull);
      candidates.add(playerId);
      weights.add(weight);
    }

    if (candidates.isEmpty) {
      throw StateError('No hay jugador elegible para repartir carta oculta.');
    }
    return _weightedChoice(candidates, weights, random);
  }

  int _botTeamId(ObservableGameState state) {
    return state.players.firstWhere((player) => player.id == state.botPlayerId).teamId;
  }

  String _weightedChoice(
    List<String> candidates,
    List<double> weights,
    Random random,
  ) {
    final total = weights.fold<double>(0, (sum, value) => sum + value);
    var roll = random.nextDouble() * total;
    for (var index = 0; index < candidates.length; index++) {
      roll -= weights[index];
      if (roll <= 0) {
        return candidates[index];
      }
    }
    return candidates.last;
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
      remainingSlots.values.fold<int>(0, (sum, value) => sum + value);

  factory _SamplerSetup.create(ObservableGameState state) {
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

    final remainingSlots = <String, int>{};
    for (final player in state.players) {
      final targetCount = state.cardsRemainingByPlayerId[player.id] ?? 0;
      if (targetCount < 0) {
        throw ArgumentError('Un jugador no puede tener cartas pendientes negativas.');
      }
      final assigned = sampledHands.putIfAbsent(player.id, () => <SpanishCard>[]);
      final missingCount = targetCount - assigned.length;
      if (missingCount < 0) {
        throw ArgumentError(
          'La informacion publica excede las cartas esperadas para ${player.id}.',
        );
      }
      remainingSlots[player.id] = missingCount;
    }

    final neededCards = remainingSlots.values.fold<int>(0, (sum, value) => sum + value);
    if (neededCards > deck.length) {
      throw StateError('No hay suficientes cartas para determinizacion.');
    }

    return _SamplerSetup(
      deck: deck,
      sampledHands: sampledHands,
      remainingSlots: remainingSlots,
    );
  }

  PossibleDeal buildDeal() {
    return PossibleDeal({
      for (final entry in sampledHands.entries)
        entry.key: List.unmodifiable(entry.value),
    });
  }
}

void _fillUniformly(_SamplerSetup setup) {
  var deckIndex = 0;
  for (final entry in setup.remainingSlots.entries) {
    final playerId = entry.key;
    final missingCount = entry.value;
    if (missingCount <= 0) continue;
    setup.sampledHands[playerId]!.addAll(
      setup.deck.sublist(deckIndex, deckIndex + missingCount),
    );
    deckIndex += missingCount;
  }
}
