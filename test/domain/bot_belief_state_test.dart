import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bet_state.dart';
import 'package:zapiti_app/domain/bot_belief_state.dart';
import 'package:zapiti_app/domain/bot_decision_context.dart';
import 'package:zapiti_app/domain/bot_policy.dart';
import 'package:zapiti_app/domain/monte_carlo_card_selector.dart';
import 'package:zapiti_app/domain/monte_carlo_difficulty_config.dart';
import 'package:zapiti_app/domain/observable_game_state.dart';
import 'package:zapiti_app/domain/played_card.dart';
import 'package:zapiti_app/domain/possible_deal_sampler.dart';
import 'package:zapiti_app/domain/round_result.dart';
import 'package:zapiti_app/domain/signal_context.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';
import 'package:zapiti_app/domain/zapiti_deck.dart';
import 'package:zapiti_app/domain/zapiti_players.dart';

void main() {
  const own = SpanishCard(value: 1, suit: Suit.espadas);
  const played = SpanishCard(value: 3, suit: Suit.copas);
  const low = SpanishCard(value: 4, suit: Suit.oros);
  const revealed = SpanishCard(value: 4, suit: Suit.bastos);
  const high = SpanishCard(value: 7, suit: Suit.copas);

  ObservableGameState makeState({
    List<PlayedCard> playedCards = const [],
    Map<String, List<SpanishCard>> known = const {},
    SignalContext signals = SignalContext.empty,
    BetState? bet,
    int trickIndex = 0,
    List<RoundResult> completedTricks = const [],
  }) =>
      ObservableGameState(
        botPlayerId: 'p1',
        players: ZapitiPlayers.tableOrder,
        botHand: const [own],
        playedCards: playedCards,
        cardsRemainingByPlayerId: const {'p1': 1, 'p2': 2, 'p3': 2, 'p4': 2},
        publiclyKnownCardsByPlayerId: known,
        currentPlayerId: 'p1',
        trickLeaderId: 'p1',
        betState: bet ??
            const BetState(
              acceptedLevel: BetLevel.none,
              proposedLevel: null,
              proposingTeam: null,
              respondingTeam: null,
              lastRaisingTeam: null,
              responsePending: false,
            ),
        score: const {1: 0, 2: 0},
        roundWins: const {1: 0, 2: 0},
        visibleSignals: const [],
        signalContext: signals,
        trickIndex: trickIndex,
        completedTricks: completedTricks,
      );

  test('IMPERFECT-AI-001 played cards are impossible in every hand', () {
    final state = makeState(playedCards: const [
      PlayedCard(player: ZapitiPlayers.leftRival, card: played),
    ]);
    final belief = BotBeliefState.fromObservable(state);
    for (final player in ZapitiPlayers.tableOrder) {
      expect(belief.weightFor(player.id, played), 0);
      expect(belief.isImpossibleFor(player.id, played), isTrue);
    }
  });

  test('IMPERFECT-AI-002 own cards never appear in another hand', () {
    final belief = BotBeliefState.fromObservable(makeState());
    final deal = const InferenceBiasedPossibleDealSampler(
      useActionInference: true,
      usePartnerModel: true,
      useOpponentProfiles: true,
    ).sample(makeState(), Random(2));
    for (final player in ['p2', 'p3', 'p4']) {
      expect(belief.weightFor(player, own), 0);
      expect(deal.handsByPlayerId[player], isNot(contains(own)));
    }
  });

  test('IMPERFECT-AI-003 publicly revealed cards stay with their known owner',
      () {
    final state = makeState(known: const {
      'p2': [revealed]
    });
    final belief = BotBeliefState.fromObservable(state);
    expect(belief.isKnownBy('p2', revealed), isTrue);
    for (final other in ['p1', 'p3', 'p4']) {
      expect(belief.weightFor(other, revealed), 0);
    }
    for (var seed = 0; seed < 20; seed++) {
      final deal =
          const UniformPossibleDealSampler().sample(state, Random(seed));
      expect(deal.handsByPlayerId['p2'], contains(revealed));
    }
  });

  test('IMPERFECT-AI-004 valid teammate signal changes weights, not certainty',
      () {
    final plain = BotBeliefState.fromObservable(makeState());
    final signaledState = makeState(
        signals: const SignalContext(signals: [
      StrategicSignal(
        type: StrategicSignalType.cardSignal,
        issuerPlayerId: 'p3',
        teamId: 1,
        handVersion: 0,
        trickIndex: 0,
        label: '7 Copas',
      ),
    ]));
    final signaled = BotBeliefState.fromObservable(signaledState);
    expect(signaled.weightFor('p3', high),
        greaterThan(plain.weightFor('p3', high)));
    expect(signaled.weightFor('p3', high), greaterThan(0));
    expect(signaled.isKnownBy('p3', high), isFalse);
    expect(signaled.evidence.single.confidence, lessThan(1));
    expect(signaled.publicFingerprint, isNot(plain.publicFingerprint));
  });

  test('IMPERFECT-AI-004 signal shifts seeded sampler distribution', () {
    const signal = SignalContext(signals: [
      StrategicSignal(
        type: StrategicSignalType.cardSignal,
        issuerPlayerId: 'p3',
        teamId: 1,
        handVersion: 0,
        trickIndex: 0,
        label: '7 Copas',
      ),
    ]);
    final plainState = makeState();
    final signalState = makeState(signals: signal);
    const sampler = InferenceBiasedPossibleDealSampler(
      useActionInference: false,
      usePartnerModel: false,
      useOpponentProfiles: false,
      useSignalInference: true,
    );
    var plainCount = 0;
    var signalCount = 0;
    for (var seed = 0; seed < 1000; seed++) {
      if (sampler
          .sample(plainState, Random(seed))
          .handsByPlayerId['p3']!
          .contains(high)) {
        plainCount++;
      }
      if (sampler
          .sample(signalState, Random(seed))
          .handsByPlayerId['p3']!
          .contains(high)) {
        signalCount++;
      }
    }
    expect(signalCount, greaterThan(plainCount));
    expect(signalCount, lessThan(1000));
  });

  test('IMPERFECT-AI-005 strong rival bet modestly favors high cards', () {
    final state = makeState(
        bet: const BetState(
      acceptedLevel: BetLevel.truco,
      proposedLevel: BetLevel.nine,
      proposingTeam: 2,
      respondingTeam: 1,
      lastRaisingTeam: 2,
      responsePending: true,
    ));
    final plain = BotBeliefState.fromObservable(state, useBetInference: false);
    final inferred =
        BotBeliefState.fromObservable(state, useBetInference: true);
    expect(inferred.weightFor('p2', high),
        greaterThan(plain.weightFor('p2', high)));
    expect(inferred.weightFor('p2', high), lessThan(2));
    expect(inferred.weightFor('p3', high), plain.weightFor('p3', high));
  });

  test('IMPERFECT-AI-006 private deals with same observation give same belief',
      () {
    const ownHand = [
      SpanishCard(value: 4, suit: Suit.bastos),
      SpanishCard(value: 7, suit: Suit.copas),
    ];
    final privateDealA = <String, List<SpanishCard>>{
      'p1': ownHand,
      'p2': const [
        SpanishCard(value: 3, suit: Suit.oros),
        SpanishCard(value: 5, suit: Suit.oros)
      ],
      'p3': const [
        SpanishCard(value: 2, suit: Suit.copas),
        SpanishCard(value: 6, suit: Suit.copas)
      ],
      'p4': const [
        SpanishCard(value: 1, suit: Suit.oros),
        SpanishCard(value: 4, suit: Suit.copas)
      ],
    };
    final privateDealB = <String, List<SpanishCard>>{
      'p1': ownHand,
      'p2': const [
        SpanishCard(value: 2, suit: Suit.bastos),
        SpanishCard(value: 4, suit: Suit.oros)
      ],
      'p3': const [
        SpanishCard(value: 3, suit: Suit.copas),
        SpanishCard(value: 6, suit: Suit.oros)
      ],
      'p4': const [
        SpanishCard(value: 1, suit: Suit.bastos),
        SpanishCard(value: 5, suit: Suit.espadas)
      ],
    };
    final sampler = _CapturingSampler();
    final policy = MonteCarloBotPolicy(
      selector: MonteCarloCardSelector(sampler: sampler),
    );
    BotDecisionContext context(Map<String, List<SpanishCard>> hands) =>
        BotDecisionContext(
          difficulty: 1,
          bot: ZapitiPlayers.human,
          players: ZapitiPlayers.tableOrder,
          hand: ownHand,
          hands: hands,
          playedCards: const [],
          teamRoundWins: 0,
          opponentRoundWins: 0,
          preserveStrongCards: false,
          teammateHasStrongSignal: false,
          opponentHasStrongSignal: false,
          forceWinIfPossible: false,
          teammateStillToPlay: true,
          opponentStillToPlay: true,
        );

    policy.chooseCard(context(privateDealA));
    final beliefA = BotBeliefState.fromObservable(sampler.states.last);
    policy.chooseCard(context(privateDealB));
    final beliefB = BotBeliefState.fromObservable(sampler.states.last);

    expect(beliefA.publicFingerprint, beliefB.publicFingerprint);
    expect(beliefA.assignmentWeightsByPlayerId,
        beliefB.assignmentWeightsByPlayerId);
  });

  test('IMPERFECT-AI-007 evidence is reconstructed from current hand history',
      () {
    final firstTrick = BotBeliefState.fromObservable(makeState(
      playedCards: const [
        PlayedCard(player: ZapitiPlayers.rightRival, card: played)
      ],
      trickIndex: 1,
    ));
    final secondTrick = BotBeliefState.fromObservable(makeState(
      playedCards: const [
        PlayedCard(player: ZapitiPlayers.rightRival, card: played),
        PlayedCard(player: ZapitiPlayers.companion, card: revealed),
      ],
      trickIndex: 2,
    ));
    expect(firstTrick.publiclyObservedCards, contains(played));
    expect(secondTrick.publiclyObservedCards, containsAll([played, revealed]));
    expect(secondTrick.evidence.map((e) => e.playerId), contains('p3'));
  });

  test('IMPERFECT-AI-008 fresh hand has no previous-hand evidence', () {
    final oldHand = BotBeliefState.fromObservable(makeState(playedCards: const [
      PlayedCard(player: ZapitiPlayers.leftRival, card: played),
    ]));
    final newHand = BotBeliefState.fromObservable(makeState());
    expect(oldHand.publiclyObservedCards, contains(played));
    expect(newHand.publiclyObservedCards, isNot(contains(played)));
    expect(newHand.evidence, isEmpty);
  });

  test('IMPERFECT-AI-009 low teammate play weakly changes high-card weight',
      () {
    final plain = BotBeliefState.fromObservable(makeState());
    final observed =
        BotBeliefState.fromObservable(makeState(playedCards: const [
      PlayedCard(player: ZapitiPlayers.companion, card: low),
    ]));
    expect(observed.weightFor('p3', high),
        greaterThan(plain.weightFor('p3', high)));
    expect(observed.weightFor('p3', high), greaterThan(0));
    expect(observed.weightFor('p3', high), lessThan(2));
    expect(observed.weightFor('p2', high), greaterThan(0));
  });

  test('IMPERFECT-AI-010 1000 seeded determinizations preserve invariants', () {
    final state = makeState(
      playedCards: const [
        PlayedCard(player: ZapitiPlayers.leftRival, card: played)
      ],
      known: const {
        'p2': [revealed]
      },
    );
    final sampler = const InferenceBiasedPossibleDealSampler(
      useActionInference: true,
      usePartnerModel: true,
      useOpponentProfiles: true,
      useSignalInference: true,
      useBetInference: true,
    );
    final all = ZapitiDeck.fullDeck().toSet();
    for (var seed = 0; seed < 1000; seed++) {
      final deal = sampler.sample(state, Random(seed));
      final cards = deal.handsByPlayerId.values.expand((hand) => hand).toList();
      expect(cards.toSet().length, cards.length, reason: 'seed=$seed');
      expect(cards, isNot(contains(played)), reason: 'seed=$seed');
      expect(deal.handsByPlayerId['p1'], contains(own), reason: 'seed=$seed');
      expect(deal.handsByPlayerId['p2'], contains(revealed),
          reason: 'seed=$seed');
      expect(deal.handsByPlayerId['p2'], hasLength(2), reason: 'seed=$seed');
      expect(deal.handsByPlayerId['p3'], hasLength(2), reason: 'seed=$seed');
      expect(deal.handsByPlayerId['p4'], hasLength(2), reason: 'seed=$seed');
      expect(cards.every(all.contains), isTrue, reason: 'seed=$seed');
    }
  });

  test('simulation budgets stay fixed', () {
    expect(MonteCarloDifficultyConfigs.easy.simulationsPerMove, 10);
    expect(MonteCarloDifficultyConfigs.normal.simulationsPerMove, 75);
    expect(MonteCarloDifficultyConfigs.hard.simulationsPerMove, 240);
    expect(MonteCarloDifficultyConfigs.expert.simulationsPerMove, 600);
  });
}

class _CapturingSampler implements PossibleDealSampler {
  final states = <ObservableGameState>[];
  final UniformPossibleDealSampler delegate =
      const UniformPossibleDealSampler();

  @override
  PossibleDeal sample(ObservableGameState state, Random random) {
    states.add(state);
    return delegate.sample(state, random);
  }
}
