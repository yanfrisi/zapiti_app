import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/al_ver_rules.dart';
import 'package:zapiti_app/domain/bet_state.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';
import 'package:zapiti_app/domain/team_rules.dart';
import 'package:zapiti_app/domain/truco_rules.dart';
import 'package:zapiti_app/domain/zapiti_deck.dart';
import 'package:zapiti_app/domain/zapiti_game_controller.dart';
import 'package:zapiti_app/domain/zapiti_players.dart';
import 'package:zapiti_app/domain/zapiti_rules.dart';

void main() {
  group('Reglamento de referencia', () {
    test('baraja de 40 y reparto de 3 cartas por jugador', () {
      final deck = ZapitiDeck.fullDeck();
      final controller = ZapitiGameController(players: ZapitiPlayers.tableOrder);

      expect(deck, hasLength(40));
      expect(deck.any((card) => card.value == 8 || card.value == 9), isFalse);
      expect(controller.hands.values.every((hand) => hand.length == 3), isTrue);
    });

    test('jerarquia principal coincide con la referencia', () {
      const fourBastos = SpanishCard(value: 4, suit: Suit.bastos);
      const sevenCopas = SpanishCard(value: 7, suit: Suit.copas);
      const sevenOros = SpanishCard(value: 7, suit: Suit.oros);
      const asEspadas = SpanishCard(value: 1, suit: Suit.espadas);
      const tres = SpanishCard(value: 3, suit: Suit.bastos);
      const dos = SpanishCard(value: 2, suit: Suit.bastos);
      const asBastos = SpanishCard(value: 1, suit: Suit.bastos);

      expect(ZapitiRules.strength(fourBastos), greaterThan(ZapitiRules.strength(sevenCopas)));
      expect(ZapitiRules.strength(sevenCopas), greaterThan(ZapitiRules.strength(sevenOros)));
      expect(ZapitiRules.strength(sevenOros), greaterThan(ZapitiRules.strength(asEspadas)));
      expect(ZapitiRules.strength(asEspadas), greaterThan(ZapitiRules.strength(tres)));
      expect(ZapitiRules.strength(tres), greaterThan(ZapitiRules.strength(dos)));
      expect(ZapitiRules.strength(dos), greaterThan(ZapitiRules.strength(asBastos)));
    });

    test('escalera de apuestas confirmada', () {
      expect(BetLevel.none.value, 1);
      expect(BetLevel.truco.value, 3);
      expect(BetLevel.six.value, 6);
      expect(BetLevel.nine.value, 9);
      expect(BetLevel.twelve.value, 12);
      expect(BetLevel.fifteen.value, 15);
      expect(BetLevel.ahorrisi.value, 30);
      expect(TrucoRules.raiseOptions(pendingValue: 15, maxAllowedValue: 30), [30]);
    });

    test('rechazo cobra nivel anterior y evita doble subida del mismo equipo', () {
      final controller = ZapitiGameController(players: ZapitiPlayers.tableOrder);

      controller.callTruco(ZapitiPlayers.human, value: 3);
      controller.raiseTruco(ZapitiPlayers.rightRival, value: 6);

      expect(controller.canCallTruco(ZapitiPlayers.rightRival, value: 9), isFalse);

      controller.passTruco(
        passingTeamId: TeamRules.teamOne,
        actorPlayerId: ZapitiPlayers.human.id,
      );

      expect(controller.score[TeamRules.teamTwo], 3);
    });

    test('primera empatada abre segunda quien empato en ultimo lugar', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
        autoStart: false,
      )..startNewHand(fixedHands: _firstTieLastByP4Hands());

      _playFullRound(controller);
      controller.resolveRound();

      expect(controller.currentPlayer, ZapitiPlayers.leftRival);
    });

    test('primera ganada y segunda empatada gana la primera', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
        autoStart: false,
      )..startNewHand(fixedHands: _firstWonSecondTiedHands());

      _playFullRound(controller);
      controller.resolveRound();
      controller.continueRound();
      _playFullRound(controller);
      controller.resolveRound();

      expect(controller.handFinished, isTrue);
      expect(controller.score[TeamRules.teamOne], 1);
    });

    test('Al Ver exactamente a 29 bloquea apuestas y jugar vale 2', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
        targetScore: 40,
        autoStart: false,
      );
      controller.score[TeamRules.teamOne] = AlVerRules.triggerScore;
      controller.startNewHand(fixedHands: _teamOneWinsTwoRoundsHands());

      expect(controller.alVerState, AlVerState.awaitingDecision);
      expect(controller.canCallTruco(ZapitiPlayers.human, value: 3), isFalse);
      expect(controller.canCallTruco(ZapitiPlayers.rightRival, value: 3), isFalse);

      controller.chooseAlVerDecision(teamId: TeamRules.teamOne, play: true);
      _finishTwoRounds(controller);

      expect(controller.score[TeamRules.teamOne], 31);
    });

    test('29-28 se juega obligatoriamente por 2 sin apuestas', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
        autoStart: false,
      );
      controller.score[TeamRules.teamOne] = 29;
      controller.score[TeamRules.teamTwo] = 28;
      controller.startNewHand(fixedHands: _teamOneWinsTwoRoundsHands());

      expect(controller.alVerState, AlVerState.playing);
      expect(controller.legalBetActionsForPlayer(ZapitiPlayers.human), isEmpty);
      expect(controller.legalBetActionsForPlayer(ZapitiPlayers.rightRival), isEmpty);

      _finishTwoRounds(controller);

      expect(controller.score[TeamRules.teamOne], 30);
      expect(controller.winningTeamId, TeamRules.teamOne);
    });
  });
}

void _playFullRound(ZapitiGameController controller) {
  for (var index = 0; index < ZapitiPlayers.tableOrder.length; index++) {
    final player = controller.currentPlayer;
    controller.playCard(player, controller.hands[player.id]!.first);
  }
}

void _finishTwoRounds(ZapitiGameController controller) {
  _playFullRound(controller);
  controller.resolveRound();
  controller.continueRound();
  _playFullRound(controller);
  controller.resolveRound();
}

Map<String, List<SpanishCard>> _teamOneWinsTwoRoundsHands() {
  return {
    ZapitiPlayers.human.id: [
      const SpanishCard(value: 4, suit: Suit.bastos),
      const SpanishCard(value: 3, suit: Suit.oros),
      const SpanishCard(value: 5, suit: Suit.copas),
    ],
    ZapitiPlayers.rightRival.id: [
      const SpanishCard(value: 12, suit: Suit.oros),
      const SpanishCard(value: 11, suit: Suit.oros),
      const SpanishCard(value: 5, suit: Suit.oros),
    ],
    ZapitiPlayers.companion.id: [
      const SpanishCard(value: 10, suit: Suit.bastos),
      const SpanishCard(value: 10, suit: Suit.copas),
      const SpanishCard(value: 6, suit: Suit.bastos),
    ],
    ZapitiPlayers.leftRival.id: [
      const SpanishCard(value: 4, suit: Suit.espadas),
      const SpanishCard(value: 5, suit: Suit.espadas),
      const SpanishCard(value: 6, suit: Suit.espadas),
    ],
  };
}

Map<String, List<SpanishCard>> _firstTieLastByP4Hands() {
  return {
    ZapitiPlayers.human.id: [
      const SpanishCard(value: 3, suit: Suit.oros),
      const SpanishCard(value: 4, suit: Suit.bastos),
      const SpanishCard(value: 5, suit: Suit.copas),
    ],
    ZapitiPlayers.rightRival.id: [
      const SpanishCard(value: 12, suit: Suit.oros),
      const SpanishCard(value: 6, suit: Suit.oros),
      const SpanishCard(value: 5, suit: Suit.oros),
    ],
    ZapitiPlayers.companion.id: [
      const SpanishCard(value: 10, suit: Suit.bastos),
      const SpanishCard(value: 6, suit: Suit.bastos),
      const SpanishCard(value: 5, suit: Suit.bastos),
    ],
    ZapitiPlayers.leftRival.id: [
      const SpanishCard(value: 3, suit: Suit.bastos),
      const SpanishCard(value: 6, suit: Suit.espadas),
      const SpanishCard(value: 5, suit: Suit.espadas),
    ],
  };
}

Map<String, List<SpanishCard>> _firstWonSecondTiedHands() {
  return {
    ZapitiPlayers.human.id: [
      const SpanishCard(value: 4, suit: Suit.bastos),
      const SpanishCard(value: 3, suit: Suit.oros),
      const SpanishCard(value: 5, suit: Suit.copas),
    ],
    ZapitiPlayers.rightRival.id: [
      const SpanishCard(value: 12, suit: Suit.oros),
      const SpanishCard(value: 3, suit: Suit.bastos),
      const SpanishCard(value: 5, suit: Suit.oros),
    ],
    ZapitiPlayers.companion.id: [
      const SpanishCard(value: 10, suit: Suit.bastos),
      const SpanishCard(value: 11, suit: Suit.copas),
      const SpanishCard(value: 6, suit: Suit.bastos),
    ],
    ZapitiPlayers.leftRival.id: [
      const SpanishCard(value: 4, suit: Suit.espadas),
      const SpanishCard(value: 10, suit: Suit.espadas),
      const SpanishCard(value: 6, suit: Suit.espadas),
    ],
  };
}
