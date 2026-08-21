import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bet_state.dart';
import 'package:zapiti_app/domain/observable_game_state.dart';
import 'package:zapiti_app/domain/possible_deal_sampler.dart';
import 'package:zapiti_app/domain/played_card.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';
import 'package:zapiti_app/domain/zapiti_players.dart';

void main() {
  const sampler = UniformPossibleDealSampler();
  const biasedSampler = InferenceBiasedPossibleDealSampler(
    useActionInference: true,
    usePartnerModel: true,
    useOpponentProfiles: true,
  );

  ObservableGameState state() {
    return ObservableGameState(
      botPlayerId: ZapitiPlayers.human.id,
      players: ZapitiPlayers.tableOrder,
      botHand: const [
        SpanishCard(value: 1, suit: Suit.espadas),
      ],
      playedCards: const [
        PlayedCard(
          player: ZapitiPlayers.leftRival,
          card: SpanishCard(value: 3, suit: Suit.copas),
        ),
      ],
      cardsRemainingByPlayerId: const {
        'p1': 1,
        'p2': 2,
        'p3': 2,
        'p4': 2,
      },
      publiclyKnownCardsByPlayerId: const {},
      currentPlayerId: 'p1',
      trickLeaderId: 'p1',
      betState: const BetState(
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
    );
  }

  test('no reparte cartas propias ni jugadas', () {
    final deal = sampler.sample(state(), Random(1));
    expect(deal.handsByPlayerId['p1'], contains(const SpanishCard(value: 1, suit: Suit.espadas)));
    expect(
      deal.handsByPlayerId.values.expand((hand) => hand),
      isNot(contains(const SpanishCard(value: 3, suit: Suit.copas))),
    );
  });

  test('mantiene unicidad y cantidades correctas con semilla fija', () {
    final deal1 = sampler.sample(state(), Random(42));
    final deal2 = sampler.sample(state(), Random(42));

    expect(deal1.handsByPlayerId, equals(deal2.handsByPlayerId));
    expect(deal1.handsByPlayerId['p2'], hasLength(2));
    expect(deal1.handsByPlayerId['p3'], hasLength(2));
    expect(deal1.handsByPlayerId['p4'], hasLength(2));

    final allCards = deal1.handsByPlayerId.values.expand((hand) => hand).toList();
    expect(allCards.toSet().length, allCards.length);
  });

  test('el sampler sesgado mantiene cantidades y unicidad', () {
    final deal = biasedSampler.sample(state(), Random(7));

    expect(deal.handsByPlayerId['p2'], hasLength(2));
    expect(deal.handsByPlayerId['p3'], hasLength(2));
    expect(deal.handsByPlayerId['p4'], hasLength(2));

    final allCards = deal.handsByPlayerId.values.expand((hand) => hand).toList();
    expect(allCards.toSet().length, allCards.length);
    expect(
      allCards,
      isNot(contains(const SpanishCard(value: 3, suit: Suit.copas))),
    );
  });
}
