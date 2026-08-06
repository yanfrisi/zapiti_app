import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bet_state.dart';
import 'package:zapiti_app/domain/observable_game_state.dart';
import 'package:zapiti_app/domain/played_card.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';
import 'package:zapiti_app/domain/zapiti_players.dart';

void main() {
  test('ObservableGameState no contiene manos ocultas ni controlador', () {
    final state = ObservableGameState.fromController(
      players: ZapitiPlayers.tableOrder,
      botPlayerId: ZapitiPlayers.human.id,
      hands: {
        ZapitiPlayers.human.id: const [
          SpanishCard(value: 1, suit: Suit.espadas),
        ],
      },
      playedCards: const [],
      score: const {1: 0, 2: 0},
      roundWins: const {1: 0, 2: 0},
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
      visibleSignals: const [],
    );

    expect(state.botHand.length, 1);
    expect(state.cardsRemainingByPlayerId[ZapitiPlayers.human.id], 1);
    expect(state, isA<ObservableGameState>());
  });

  test('ObservableGameState copia solo datos permitidos', () {
    final state = ObservableGameState.fromController(
      players: ZapitiPlayers.tableOrder,
      botPlayerId: ZapitiPlayers.human.id,
      hands: {
        ZapitiPlayers.human.id: const [
          SpanishCard(value: 1, suit: Suit.espadas),
        ],
      },
      playedCards: const [
        PlayedCard(
          player: ZapitiPlayers.leftRival,
          card: SpanishCard(value: 3, suit: Suit.copas),
        ),
      ],
      score: const {1: 5, 2: 7},
      roundWins: const {1: 1, 2: 0},
      currentPlayerId: ZapitiPlayers.human.id,
      trickLeaderId: ZapitiPlayers.leftRival.id,
      betState: const BetState(
        acceptedLevel: BetLevel.none,
        proposedLevel: null,
        proposingTeam: null,
        respondingTeam: null,
        lastRaisingTeam: null,
        responsePending: false,
      ),
      visibleSignals: const ['signal'],
    );

    expect(state.playedCards, hasLength(1));
    expect(state.visibleSignals, contains('signal'));
    expect(state.publiclyKnownCardsByPlayerId, isNot(contains('hidden')));
  });
}
