import 'dart:math';

import 'observable_game_state.dart';
import 'signal_context.dart';
import 'signal_rules.dart';
import 'spanish_card.dart';
import 'zapiti_deck.dart';
import 'zapiti_rules.dart';

enum BeliefEvidenceKind { cardSignal, playedCard, trucoAction }

class BeliefEvidence {
  final BeliefEvidenceKind kind;
  final String playerId;
  final double confidence;
  final String description;

  const BeliefEvidence({
    required this.kind,
    required this.playerId,
    required this.confidence,
    required this.description,
  });
}

/// Distribution over hidden card ownership derived only from observable data.
class BotBeliefState {
  final String botPlayerId;
  final Map<String, Set<SpanishCard>> knownCardsByPlayerId;
  final Map<String, Set<SpanishCard>> impossibleCardsByPlayerId;
  final Map<String, Set<SpanishCard>> possibleCardsByPlayerId;
  final Map<String, Map<SpanishCard, double>> assignmentWeightsByPlayerId;
  final Set<SpanishCard> publiclyObservedCards;
  final List<BeliefEvidence> evidence;

  const BotBeliefState._({
    required this.botPlayerId,
    required this.knownCardsByPlayerId,
    required this.impossibleCardsByPlayerId,
    required this.possibleCardsByPlayerId,
    required this.assignmentWeightsByPlayerId,
    required this.publiclyObservedCards,
    required this.evidence,
  });

  factory BotBeliefState.fromObservable(
    ObservableGameState state, {
    bool useSignals = true,
    bool useActionInference = true,
    bool useBetInference = true,
    bool usePartnerModel = false,
    bool useOpponentProfiles = false,
  }) {
    final deck = ZapitiDeck.fullDeck().toSet();
    final known = <String, Set<SpanishCard>>{
      for (final player in state.players) player.id: <SpanishCard>{},
    };
    known[state.botPlayerId]!.addAll(state.botHand);
    for (final entry in state.publiclyKnownCardsByPlayerId.entries) {
      final owner = known[entry.key];
      if (owner == null) throw ArgumentError('Unknown public-card owner.');
      owner.addAll(entry.value);
    }

    final observedPlayed = state.allObservedPlayedCards;
    final played = observedPlayed.map((entry) => entry.card).toSet();
    final knownOwners = <SpanishCard, String>{};
    for (final entry in known.entries) {
      for (final card in entry.value) {
        final previous = knownOwners[card];
        if ((previous != null && previous != entry.key) ||
            played.contains(card)) {
          throw StateError('A known card has conflicting locations.');
        }
        knownOwners[card] = entry.key;
      }
    }

    final publicCards = <SpanishCard>{...played};
    for (final cards in state.publiclyKnownCardsByPlayerId.values) {
      publicCards.addAll(cards);
    }
    final impossible = <String, Set<SpanishCard>>{};
    final possible = <String, Set<SpanishCard>>{};
    final weights = <String, Map<SpanishCard, double>>{};
    final evidence = <BeliefEvidence>[];
    for (final player in state.players) {
      final forbidden = <SpanishCard>{...played};
      for (final entry in known.entries) {
        if (entry.key != player.id) forbidden.addAll(entry.value);
      }
      impossible[player.id] = Set.unmodifiable(forbidden);
      final candidates = deck.difference(forbidden)..addAll(known[player.id]!);
      possible[player.id] = Set.unmodifiable(candidates);
      weights[player.id] = {for (final card in candidates) card: 1.0};
    }

    if (useSignals) _applySignalEvidence(state, weights, evidence);
    if (useActionInference) {
      _applyPlayedEvidence(
        state,
        weights,
        evidence,
        usePartnerModel,
        useOpponentProfiles,
      );
    }
    if (useBetInference) _applyBetEvidence(state, weights, evidence);

    return BotBeliefState._(
      botPlayerId: state.botPlayerId,
      knownCardsByPlayerId: {
        for (final entry in known.entries)
          entry.key: Set.unmodifiable(entry.value),
      },
      impossibleCardsByPlayerId: Map.unmodifiable(impossible),
      possibleCardsByPlayerId: Map.unmodifiable(possible),
      assignmentWeightsByPlayerId: {
        for (final entry in weights.entries)
          entry.key: Map.unmodifiable(entry.value),
      },
      publiclyObservedCards: Set.unmodifiable(publicCards),
      evidence: List.unmodifiable(evidence),
    );
  }

  double weightFor(String playerId, SpanishCard card) =>
      assignmentWeightsByPlayerId[playerId]?[card] ?? 0;

  bool isKnownBy(String playerId, SpanishCard card) =>
      knownCardsByPlayerId[playerId]?.contains(card) ?? false;

  bool isImpossibleFor(String playerId, SpanishCard card) =>
      impossibleCardsByPlayerId[playerId]?.contains(card) ?? true;

  String get publicFingerprint {
    final parts = <String>[botPlayerId];
    final ids = knownCardsByPlayerId.keys.toList()..sort();
    for (final id in ids) {
      parts.add('$id:${_sorted(knownCardsByPlayerId[id]!).join(',')}');
      final entries = assignmentWeightsByPlayerId[id]!.entries.toList()
        ..sort((a, b) => _compareCards(a.key, b.key));
      parts
          .addAll(entries.map((e) => '${e.key}=${e.value.toStringAsFixed(5)}'));
    }
    parts.addAll(_sorted(publiclyObservedCards).map((card) => card.toString()));
    return parts.join('|');
  }

  static void _applySignalEvidence(
    ObservableGameState state,
    Map<String, Map<SpanishCard, double>> weights,
    List<BeliefEvidence> evidence,
  ) {
    final botTeam =
        state.players.firstWhere((p) => p.id == state.botPlayerId).teamId;
    for (final signal in state.signalContext.signals) {
      if (!signal.active ||
          signal.type != StrategicSignalType.cardSignal ||
          signal.label == null ||
          signal.handVersion != state.handVersion) {
        continue;
      }
      final issuer = state.players.where((p) => p.id == signal.issuerPlayerId);
      if (issuer.isEmpty) {
        continue;
      }
      final player = issuer.first;
      final confidence = player.teamId == botTeam ? 0.62 : 0.52;
      final target = weights[player.id]!;
      final exact = SignalRules.exactCardForSignal(signal.label);
      final group = _signalGroup(signal.label!);
      if (exact != null) {
        _multiply(target, exact, 1 + confidence * 2);
        for (final card in target.keys.toList()) {
          if (card != exact) {
            target[card] = target[card]! * (1 - confidence * 0.42);
          }
        }
        evidence.add(BeliefEvidence(
          kind: BeliefEvidenceKind.cardSignal,
          playerId: player.id,
          confidence: confidence,
          description: 'Signal compatible with ${signal.label}',
        ));
      } else if (group != null) {
        for (final card in target.keys.toList()) {
          target[card] = target[card]! *
              (group(card) ? 1 + confidence * 0.85 : 1 - confidence * 0.20);
        }
        evidence.add(BeliefEvidence(
          kind: BeliefEvidenceKind.cardSignal,
          playerId: player.id,
          confidence: confidence,
          description: 'Group signal ${signal.label}',
        ));
      }
    }
  }

  static bool Function(SpanishCard)? _signalGroup(String label) =>
      switch (label) {
        'Treses' => (card) => card.value == 3,
        'Doses' => (card) => card.value == 2,
        'Ases' => (card) => card.value == 1,
        'Mala' => (card) => ZapitiRules.strength(card) < 70,
        _ => null,
      };

  static void _applyPlayedEvidence(
    ObservableGameState state,
    Map<String, Map<SpanishCard, double>> weights,
    List<BeliefEvidence> evidence,
    bool usePartnerModel,
    bool useOpponentProfiles,
  ) {
    final botTeam =
        state.players.firstWhere((p) => p.id == state.botPlayerId).teamId;
    final byPlayer = <String, List<SpanishCard>>{};
    for (final entry in state.allObservedPlayedCards) {
      byPlayer.putIfAbsent(entry.player.id, () => []).add(entry.card);
    }
    for (final entry in byPlayer.entries) {
      final strongest = entry.value.map(ZapitiRules.strength).reduce(max);
      final player = state.players.firstWhere((p) => p.id == entry.key);
      var confidence = strongest < 40 ? 0.12 : 0.05;
      if (player.teamId == botTeam && usePartnerModel) {
        confidence += 0.02;
      } else if (player.teamId != botTeam && useOpponentProfiles) {
        confidence += 0.02;
      }
      final factor = strongest < 40
          ? 1 + confidence
          : strongest >= 80
              ? 1 - confidence * 0.5
              : 1.0;
      for (final card in weights[entry.key]!.keys.toList()) {
        if (ZapitiRules.strength(card) >= 80) {
          weights[entry.key]![card] =
              (weights[entry.key]![card]! * factor).clamp(0.25, 4.0);
        }
      }
      evidence.add(BeliefEvidence(
        kind: BeliefEvidenceKind.playedCard,
        playerId: entry.key,
        confidence: confidence,
        description: strongest < 40
            ? 'Low card; possible conservation'
            : 'Strong card revealed',
      ));
    }
  }

  static void _applyBetEvidence(
    ObservableGameState state,
    Map<String, Map<SpanishCard, double>> weights,
    List<BeliefEvidence> evidence,
  ) {
    final team = state.betState.proposedLevel != null
        ? state.betState.proposingTeam
        : state.betState.lastRaisingTeam;
    if (team == null) return;
    final level = state.betState.proposedLevel?.value ??
        state.betState.acceptedLevel.value;
    final confidence = level >= 9 ? 0.18 : 0.12;
    for (final player in state.players.where(
      (p) => p.id != state.botPlayerId && p.teamId == team,
    )) {
      for (final card in weights[player.id]!.keys.toList()) {
        if (ZapitiRules.strength(card) >= 80) {
          weights[player.id]![card] =
              (weights[player.id]![card]! * (1 + confidence)).clamp(0.25, 4.0);
        }
      }
      evidence.add(BeliefEvidence(
        kind: BeliefEvidenceKind.trucoAction,
        playerId: player.id,
        confidence: confidence,
        description: 'Team made a bet',
      ));
    }
  }

  static void _multiply(
      Map<SpanishCard, double> weights, SpanishCard card, double factor) {
    if (weights.containsKey(card)) {
      weights[card] = (weights[card]! * factor).clamp(0.25, 4.0);
    }
  }

  static List<SpanishCard> _sorted(Iterable<SpanishCard> cards) =>
      cards.toList()..sort(_compareCards);

  static int _compareCards(SpanishCard a, SpanishCard b) {
    final value = a.value.compareTo(b.value);
    return value != 0 ? value : a.suit.index.compareTo(b.suit.index);
  }
}
