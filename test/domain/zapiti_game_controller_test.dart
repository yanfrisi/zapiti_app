import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/debug_deals.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';
import 'package:zapiti_app/domain/team_rules.dart';
import 'package:zapiti_app/domain/zapiti_game_controller.dart';
import 'package:zapiti_app/domain/zapiti_players.dart';

void main() {
  group('ZapitiGameController', () {
    test('empieza reparto y rota mano en cada nuevo reparto', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      expect(controller.currentPlayer, ZapitiPlayers.human);

      controller.startNewHand(fixedHands: DebugDeals.presets.first);

      expect(controller.currentPlayer, ZapitiPlayers.rightRival);
    });

    test('jugar cuatro cartas resuelve ronda y continuar limpia mesa', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      )..startNewHand(fixedHands: DebugDeals.presets.first);

      final order = [
        ZapitiPlayers.rightRival,
        ZapitiPlayers.companion,
        ZapitiPlayers.leftRival,
        ZapitiPlayers.human,
      ];

      var completed = false;
      for (final player in order) {
        completed =
            controller.playCard(player, controller.hands[player.id]!.first);
      }

      expect(completed, isTrue);
      controller.resolveRound();
      expect(controller.isRoundAwaitingContinue, isTrue);
      expect(controller.playedCards, hasLength(4));

      controller.continueRound();
      expect(controller.isRoundAwaitingContinue, isFalse);
      expect(controller.playedCards, isEmpty);
    });

    test('truco, subir y pasar suma el valor aceptado anterior', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);
      controller.raiseTruco(
        ZapitiPlayers.rightRival,
        value: 6,
        actorPlayerId: ZapitiPlayers.human.id,
      );

      expect(controller.handValue, 3);
      expect(controller.pendingTrucoValue, 6);

      controller.passTruco(passingTeamId: TeamRules.teamOne);

      expect(controller.score[TeamRules.teamTwo], 3);
      expect(controller.handFinished, isTrue);
    });

    test('rechaza subidas de truco que no van de tres en tres', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);

      expect(
        () => controller.raiseTruco(
          ZapitiPlayers.rightRival,
          value: 5,
          actorPlayerId: ZapitiPlayers.human.id,
        ),
        throwsArgumentError,
      );
    });

    test('aceptar truco convierte valor pendiente en valor del reparto', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);
      controller.acceptTruco(teamId: TeamRules.teamTwo);

      expect(controller.handValue, 3);
      expect(controller.pendingTrucoValue, isNull);
      expect(controller.isTrucoAccepted, isTrue);
      expect(controller.lastTrucoRaiserTeamId, TeamRules.teamOne);
    });

    test('tras aceptar no se puede volver a subir en el reparto', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);
      controller.acceptTruco(teamId: TeamRules.teamTwo);

      expect(controller.handValue, 3);
      expect(controller.pendingTrucoValue, isNull);
      expect(
        () => controller.callTruco(
          ZapitiPlayers.rightRival,
          value: 6,
          actorPlayerId: ZapitiPlayers.human.id,
        ),
        throwsArgumentError,
      );
    });

    test('el mismo equipo no puede subir su propio truco pendiente', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);

      expect(
        () => controller.raiseTruco(
          ZapitiPlayers.companion,
          value: 6,
          actorPlayerId: ZapitiPlayers.human.id,
        ),
        throwsArgumentError,
      );
      expect(controller.pendingTrucoValue, 3);
      expect(controller.trucoCallerTeamId, TeamRules.teamOne);
    });

    test('una vez aceptado no se puede volver a cantar truco desde cero', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);
      controller.acceptTruco(teamId: TeamRules.teamTwo);

      expect(
        () => controller.callTruco(
          ZapitiPlayers.rightRival,
          value: 3,
          actorPlayerId: ZapitiPlayers.human.id,
        ),
        throwsArgumentError,
      );
      expect(controller.handValue, 3);
      expect(controller.pendingTrucoValue, isNull);
    });

    test('las subidas solo pueden hacerse mientras el truco esta pendiente',
        () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);
      controller.callTruco(
        ZapitiPlayers.rightRival,
        value: 6,
        actorPlayerId: ZapitiPlayers.human.id,
      );

      expect(controller.pendingTrucoValue, 6);
      expect(controller.trucoCallerTeamId, TeamRules.teamTwo);

      controller.acceptTruco(teamId: TeamRules.teamOne);
      expect(
        () => controller.callTruco(
          ZapitiPlayers.companion,
          value: 9,
          actorPlayerId: ZapitiPlayers.human.id,
        ),
        throwsArgumentError,
      );
    });

    test('empate de maxima produce 1-1 sin sumar chinos ni repartir de nuevo',
        () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      )..startNewHand(fixedHands: _tieThenTeamTwoWinsHands());

      _playFullRound(controller);
      controller.resolveRound();

      expect(controller.roundWins[TeamRules.teamOne], 1);
      expect(controller.roundWins[TeamRules.teamTwo], 1);
      expect(controller.score[TeamRules.teamOne], 0);
      expect(controller.score[TeamRules.teamTwo], 0);
      expect(controller.handFinished, isFalse);
      expect(controller.isRoundAwaitingContinue, isTrue);
      expect(controller.hands[ZapitiPlayers.human.id], hasLength(2));

      controller.continueRound();

      expect(controller.playedCards, isEmpty);
      expect(controller.hands[ZapitiPlayers.human.id], hasLength(2));
    });

    test('victoria posterior desde 1-1 termina la mano y suma chinos', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      )..startNewHand(fixedHands: _tieThenTeamTwoWinsHands());

      _playFullRound(controller);
      controller.resolveRound();
      controller.continueRound();
      _playFullRound(controller);
      controller.resolveRound();

      expect(controller.roundWins[TeamRules.teamOne], 1);
      expect(controller.roundWins[TeamRules.teamTwo], 2);
      expect(controller.score[TeamRules.teamTwo], 1);
      expect(controller.handFinished, isTrue);
    });

    test('mano sin truco vale un chino', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      )..startNewHand(fixedHands: _teamOneWinsTwoRoundsHands());

      _finishTwoRounds(controller);

      expect(controller.score[TeamRules.teamOne], 1);
      expect(controller.handValue, 1);
    });

    test('truco aceptado suma tres chinos al ganar la mano', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      )..startNewHand(fixedHands: _teamOneWinsTwoRoundsHands());

      controller.callTruco(ZapitiPlayers.human, value: 3);
      controller.acceptTruco(
        teamId: TeamRules.teamTwo,
        actorPlayerId: ZapitiPlayers.human.id,
      );
      _finishTwoRounds(controller);

      expect(controller.score[TeamRules.teamOne], 3);
      expect(controller.handValue, 3);
    });

    test('subida aceptada actualiza el valor de la mano', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      )..startNewHand(fixedHands: _teamOneWinsTwoRoundsHands());

      controller.callTruco(ZapitiPlayers.human, value: 3);
      controller.raiseTruco(
        ZapitiPlayers.rightRival,
        value: 6,
        actorPlayerId: ZapitiPlayers.human.id,
      );
      controller.acceptTruco(
        teamId: TeamRules.teamOne,
        actorPlayerId: ZapitiPlayers.human.id,
      );
      _finishTwoRounds(controller);

      expect(controller.score[TeamRules.teamOne], 6);
      expect(controller.handValue, 6);
    });

    test('rechazar el primer truco concede el valor anterior', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);
      controller.passTruco(
        passingTeamId: TeamRules.teamTwo,
        actorPlayerId: ZapitiPlayers.human.id,
      );

      expect(controller.score[TeamRules.teamOne], 1);
      expect(controller.handFinished, isTrue);
      expect(controller.trucoState, TrucoNegotiationState.rejectedHandFinished);
    });

    test('rechazar una subida concede el valor aceptado anterior', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);
      controller.raiseTruco(
        ZapitiPlayers.rightRival,
        value: 6,
        actorPlayerId: ZapitiPlayers.human.id,
      );
      controller.passTruco(
        passingTeamId: TeamRules.teamOne,
        actorPlayerId: ZapitiPlayers.human.id,
      );

      expect(controller.score[TeamRules.teamTwo], 3);
      expect(controller.handFinished, isTrue);
    });

    test('un rechazo repetido no suma dos veces', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);
      controller.passTruco(
        passingTeamId: TeamRules.teamTwo,
        actorPlayerId: ZapitiPlayers.human.id,
      );

      expect(
        () => controller.passTruco(
          passingTeamId: TeamRules.teamTwo,
          actorPlayerId: ZapitiPlayers.human.id,
        ),
        throwsStateError,
      );
      expect(controller.score[TeamRules.teamOne], 1);
    });

    test('nueva mano reinicia apuesta y chicos sin tocar marcador general', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);
      controller.acceptTruco(
        teamId: TeamRules.teamTwo,
        actorPlayerId: ZapitiPlayers.human.id,
      );
      controller.score[TeamRules.teamOne] = 7;

      controller.startNewHand(fixedHands: DebugDeals.presets.first);

      expect(controller.score[TeamRules.teamOne], 7);
      expect(controller.handValue, 1);
      expect(controller.pendingTrucoValue, isNull);
      expect(controller.trucoState, TrucoNegotiationState.notStarted);
      expect(controller.roundWins[TeamRules.teamOne], 0);
      expect(controller.roundWins[TeamRules.teamTwo], 0);
    });

    test('el companero local no puede ejecutar acciones de apuesta', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      expect(
        () => controller.callTruco(ZapitiPlayers.companion, value: 3),
        throwsArgumentError,
      );
      expect(
        controller.canCallTruco(
          ZapitiPlayers.rightRival,
          value: 3,
          actorPlayerId: ZapitiPlayers.rightRival.id,
        ),
        isTrue,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);
      expect(
        controller.canAcceptTruco(
          teamId: TeamRules.teamTwo,
          actorPlayerId: ZapitiPlayers.rightRival.id,
        ),
        isTrue,
      );
      expect(
        controller.canPassTruco(
          passingTeamId: TeamRules.teamTwo,
          actorPlayerId: ZapitiPlayers.rightRival.id,
        ),
        isTrue,
      );
      expect(
        () => controller.raiseTruco(
          ZapitiPlayers.companion,
          value: 6,
        ),
        throwsArgumentError,
      );
    });

    test('humano local puede decidir la respuesta del equipo que corresponda',
        () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);

      expect(controller.respondingTrucoTeamId, TeamRules.teamTwo);
      expect(
        controller.canAcceptTruco(
          teamId: TeamRules.teamTwo,
          actorPlayerId: ZapitiPlayers.human.id,
        ),
        isTrue,
      );
    });

    test('no permite aceptar, pasar ni subir sin propuesta', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      expect(
        () => controller.acceptTruco(teamId: TeamRules.teamTwo),
        throwsStateError,
      );
      expect(
        () => controller.passTruco(passingTeamId: TeamRules.teamTwo),
        throwsStateError,
      );
      expect(
        () => controller.raiseTruco(
          ZapitiPlayers.rightRival,
          value: 6,
          actorPlayerId: ZapitiPlayers.human.id,
        ),
        throwsStateError,
      );
    });

    test('no permite saltar nivel ni superar el maximo', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);

      expect(
        () => controller.raiseTruco(
          ZapitiPlayers.rightRival,
          value: 9,
          actorPlayerId: ZapitiPlayers.human.id,
        ),
        throwsArgumentError,
      );

      controller.score[TeamRules.teamOne] = 26;
      controller.score[TeamRules.teamTwo] = 26;
      expect(
        () => controller.raiseTruco(
          ZapitiPlayers.rightRival,
          value: 6,
          actorPlayerId: ZapitiPlayers.human.id,
        ),
        throwsArgumentError,
      );
    });

    test('solo el equipo con margen puede abrir truco a 3 con marcador 19-27',
        () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );
      controller.score[TeamRules.teamOne] = 19;
      controller.score[TeamRules.teamTwo] = 27;

      expect(
        controller.canCallTruco(
          ZapitiPlayers.human,
          value: 3,
          actorPlayerId: ZapitiPlayers.human.id,
        ),
        isTrue,
      );
      expect(
        controller.canCallTruco(
          ZapitiPlayers.rightRival,
          value: 3,
          actorPlayerId: ZapitiPlayers.rightRival.id,
        ),
        isFalse,
      );
      expect(
        () => controller.callTruco(
          ZapitiPlayers.rightRival,
          value: 3,
          actorPlayerId: ZapitiPlayers.rightRival.id,
        ),
        throwsArgumentError,
      );

      controller.callTruco(
        ZapitiPlayers.human,
        value: 3,
        actorPlayerId: ZapitiPlayers.human.id,
      );

      expect(controller.pendingTrucoValue, 3);
      expect(controller.raiseOptions, isEmpty);
      expect(
        controller.canAcceptTruco(
          teamId: TeamRules.teamTwo,
          actorPlayerId: ZapitiPlayers.rightRival.id,
        ),
        isTrue,
      );
    });

    test('subidas alternan equipos y no puede haber dos propuestas pendientes',
        () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);
      expect(
        () => controller.callTruco(
          ZapitiPlayers.companion,
          value: 6,
          actorPlayerId: ZapitiPlayers.human.id,
        ),
        throwsArgumentError,
      );

      controller.raiseTruco(
        ZapitiPlayers.rightRival,
        value: 6,
        actorPlayerId: ZapitiPlayers.human.id,
      );
      expect(
        () => controller.raiseTruco(
          ZapitiPlayers.leftRival,
          value: 9,
          actorPlayerId: ZapitiPlayers.human.id,
        ),
        throwsArgumentError,
      );
    });

    test('detecta final de partida al llegar al objetivo', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );
      controller.score[TeamRules.teamOne] = 29;
      controller.hands = {
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

      for (final player in ZapitiPlayers.tableOrder) {
        controller.playCard(player, controller.hands[player.id]!.first);
      }
      controller.resolveRound();
      controller.continueRound();
      for (final player in ZapitiPlayers.tableOrder) {
        controller.playCard(player, controller.hands[player.id]!.first);
      }
      controller.resolveRound();

      expect(controller.winningTeamId, TeamRules.teamOne);
      expect(controller.isGameFinished, isTrue);
    });

    test('rechaza cartas que no estan en la mano del jugador', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );
      final humanHand = controller.hands[ZapitiPlayers.human.id]!;
      final missingCard = [
        for (final suit in Suit.values)
          for (final value in [1, 2, 3, 4, 5, 6, 7, 10, 11, 12])
            SpanishCard(value: value, suit: suit),
      ].firstWhere((card) => !humanHand.contains(card));

      expect(
        () => controller.playCard(
          ZapitiPlayers.human,
          missingCard,
        ),
        throwsArgumentError,
      );
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

Map<String, List<SpanishCard>> _tieThenTeamTwoWinsHands() {
  return {
    ZapitiPlayers.human.id: [
      const SpanishCard(value: 3, suit: Suit.oros),
      const SpanishCard(value: 12, suit: Suit.oros),
      const SpanishCard(value: 5, suit: Suit.copas),
    ],
    ZapitiPlayers.rightRival.id: [
      const SpanishCard(value: 3, suit: Suit.bastos),
      const SpanishCard(value: 4, suit: Suit.bastos),
      const SpanishCard(value: 5, suit: Suit.oros),
    ],
    ZapitiPlayers.companion.id: [
      const SpanishCard(value: 12, suit: Suit.copas),
      const SpanishCard(value: 5, suit: Suit.bastos),
      const SpanishCard(value: 6, suit: Suit.bastos),
    ],
    ZapitiPlayers.leftRival.id: [
      const SpanishCard(value: 2, suit: Suit.copas),
      const SpanishCard(value: 6, suit: Suit.oros),
      const SpanishCard(value: 6, suit: Suit.espadas),
    ],
  };
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
