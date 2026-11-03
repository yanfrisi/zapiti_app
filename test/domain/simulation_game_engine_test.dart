import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bet_state.dart';
import 'package:zapiti_app/domain/observable_game_state.dart';
import 'package:zapiti_app/domain/possible_deal_sampler.dart';
import 'package:zapiti_app/domain/played_card.dart';
import 'package:zapiti_app/domain/round_rules.dart';
import 'package:zapiti_app/domain/simulation_events.dart';
import 'package:zapiti_app/domain/simulation_game_engine.dart';
import 'package:zapiti_app/domain/simulation_state_factory.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';
import 'package:zapiti_app/domain/zapiti_game_controller.dart';
import 'package:zapiti_app/domain/zapiti_players.dart';

void main() {
  const engine = DefaultSimulationGameEngine();
  const factory = DefaultSimulationStateFactory();

  ObservableGameState observable() {
    return ObservableGameState(
      botPlayerId: ZapitiPlayers.human.id,
      players: ZapitiPlayers.tableOrder,
      botHand: const [SpanishCard(value: 1, suit: Suit.espadas)],
      playedCards: const [],
      cardsRemainingByPlayerId: const {'p1': 1, 'p2': 1, 'p3': 1, 'p4': 1},
      publiclyKnownCardsByPlayerId: const {},
      currentPlayerId: ZapitiPlayers.human.id,
      trickLeaderId: ZapitiPlayers.human.id,
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

  test('construye estado simulado valido', () {
    const deal = PossibleDeal({
      'p1': [SpanishCard(value: 1, suit: Suit.espadas)],
      'p2': [SpanishCard(value: 3, suit: Suit.copas)],
      'p3': [SpanishCard(value: 4, suit: Suit.bastos)],
      'p4': [SpanishCard(value: 7, suit: Suit.oros)],
    });
    final state = factory.create(
      observableState: observable(),
      possibleDeal: deal,
    );

    expect(state.players, hasLength(4));
    expect(state.playerState('p1').hand, hasLength(1));
  });

  test('playCard no muta el estado anterior y avanza el turno', () {
    const deal = PossibleDeal({
      'p1': [SpanishCard(value: 1, suit: Suit.espadas)],
      'p2': [SpanishCard(value: 3, suit: Suit.copas)],
      'p3': [SpanishCard(value: 4, suit: Suit.bastos)],
      'p4': [SpanishCard(value: 7, suit: Suit.oros)],
    });
    final state = factory.create(
      observableState: observable(),
      possibleDeal: deal,
    );
    final transition = engine.playCard(
      state,
      ZapitiPlayers.human.id,
      const SpanishCard(value: 1, suit: Suit.espadas),
    );

    expect(state.playerState('p1').hand, hasLength(1));
    expect(transition.nextState.playerState('p1').hand, isEmpty);
    expect(transition.nextState.currentPlayerId, ZapitiPlayers.rightRival.id);
    expect(transition.events.first, isA<CardPlayedEvent>());
  });

  test('una baza completa usa RoundRules.resolveRound', () {
    final controller = ZapitiGameController(
      autoStart: false,
    );
    controller.startNewHand(fixedHands: const {
      'p1': [SpanishCard(value: 1, suit: Suit.espadas)],
      'p2': [SpanishCard(value: 3, suit: Suit.copas)],
      'p3': [SpanishCard(value: 4, suit: Suit.bastos)],
      'p4': [SpanishCard(value: 7, suit: Suit.oros)],
    });
    controller.turnIndex = 0;
    controller.leadIndex = 0;
    controller.playCard(
      ZapitiPlayers.human,
      const SpanishCard(value: 1, suit: Suit.espadas),
    );
    controller.playCard(
      ZapitiPlayers.rightRival,
      const SpanishCard(value: 3, suit: Suit.copas),
    );
    controller.playCard(
      ZapitiPlayers.companion,
      const SpanishCard(value: 4, suit: Suit.bastos),
    );
    final roundCompleted = controller.playCard(
      ZapitiPlayers.leftRival,
      const SpanishCard(value: 7, suit: Suit.oros),
    );
    expect(roundCompleted, isTrue);
    controller.resolveRound();

    final result = RoundRules.resolveRound([
      const PlayedCard(
        player: ZapitiPlayers.human,
        card: SpanishCard(value: 1, suit: Suit.espadas),
      ),
      const PlayedCard(
        player: ZapitiPlayers.rightRival,
        card: SpanishCard(value: 3, suit: Suit.copas),
      ),
      const PlayedCard(
        player: ZapitiPlayers.companion,
        card: SpanishCard(value: 4, suit: Suit.bastos),
      ),
      const PlayedCard(
        player: ZapitiPlayers.leftRival,
        card: SpanishCard(value: 7, suit: Suit.oros),
      ),
    ]);

    expect(result.winningTeamId, isNotNull);
  });
}
