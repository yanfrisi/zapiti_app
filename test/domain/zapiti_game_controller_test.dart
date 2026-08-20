import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/al_ver_rules.dart';
import 'package:zapiti_app/domain/bet_state.dart';
import 'package:zapiti_app/domain/debug_deals.dart';
import 'package:zapiti_app/domain/legal_actions.dart';
import 'package:zapiti_app/domain/played_card.dart';
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

    test('aceptar truco no cambia el ultimo equipo que subio', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);
      final lastRaisingTeamBeforeAccept = controller.lastTrucoRaiserTeamId;

      controller.acceptTruco(teamId: TeamRules.teamTwo);

      expect(controller.lastTrucoRaiserTeamId, lastRaisingTeamBeforeAccept);
      expect(controller.betState.lastRaisingTeam, TeamRules.teamOne);
      expect(controller.betState.proposingTeam, isNull);
      expect(controller.betState.responsePending, isFalse);
    });

    test('tras aceptar el mismo equipo no puede volver a subir enseguida', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);
      controller.acceptTruco(teamId: TeamRules.teamTwo);

      expect(controller.handValue, 3);
      expect(controller.pendingTrucoValue, isNull);
      expect(
        controller.canCallTruco(
          ZapitiPlayers.human,
          value: 6,
          actorPlayerId: ZapitiPlayers.human.id,
        ),
        isFalse,
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

    test('una vez aceptado el rival puede subir al siguiente nivel', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);
      controller.acceptTruco(teamId: TeamRules.teamTwo);

      expect(
        controller.canCallTruco(
          ZapitiPlayers.rightRival,
          value: 6,
          actorPlayerId: ZapitiPlayers.rightRival.id,
        ),
        isTrue,
      );
      controller.callTruco(
        ZapitiPlayers.rightRival,
        value: 6,
        actorPlayerId: ZapitiPlayers.rightRival.id,
      );
      expect(controller.handValue, 3);
      expect(controller.pendingTrucoValue, 6);
    });

    test('el equipo que canta seis no puede cantar nueve inmediatamente', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);
      controller.acceptTruco(teamId: TeamRules.teamTwo);
      controller.callTruco(ZapitiPlayers.rightRival, value: 6);

      expect(controller.pendingTrucoValue, 6);
      expect(controller.trucoCallerTeamId, TeamRules.teamTwo);
      expect(
        controller.canCallTruco(
          ZapitiPlayers.rightRival,
          value: 9,
        ),
        isFalse,
      );
    });

    test('despues de seis el equipo rival puede cantar nueve', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);
      controller.acceptTruco(teamId: TeamRules.teamTwo);
      controller.callTruco(ZapitiPlayers.rightRival, value: 6);

      expect(
        controller.canCallTruco(
          ZapitiPlayers.human,
          value: 9,
        ),
        isTrue,
      );
    });

    test('marcador 26-20 no bloquea subir a seis tras aceptar truco', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.score
        ..[TeamRules.teamOne] = 26
        ..[TeamRules.teamTwo] = 20;
      controller.startNewHand();

      controller.callTruco(ZapitiPlayers.rightRival, value: 3);
      controller.acceptTruco(teamId: TeamRules.teamOne);

      expect(controller.maxAllowedTrucoValueForTeam(TeamRules.teamOne), 18);
      expect(controller.lastTrucoRaiserTeamId, TeamRules.teamTwo);
      expect(
        controller.canCallTruco(ZapitiPlayers.human, value: 6),
        isTrue,
      );
      expect(
        controller.legalBetActionsForPlayer(ZapitiPlayers.human),
        contains(const BetAction.call(6)),
      );
    });

    test('responder una apuesta pendiente no depende del turno de carta', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      expect(controller.currentPlayer, ZapitiPlayers.human);

      controller.callTruco(ZapitiPlayers.human, value: 3);

      expect(
        controller.canAcceptTruco(
          teamId: TeamRules.teamTwo,
          actorPlayerId: ZapitiPlayers.rightRival.id,
        ),
        isTrue,
      );
      expect(
        controller.legalBetActionsForPlayer(ZapitiPlayers.rightRival),
        contains(const BetAction.accept()),
      );
    });

    test('la escalera completa alterna equipos hasta ahorrisi', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.callTruco(ZapitiPlayers.human, value: 3);
      expect(controller.canCallTruco(ZapitiPlayers.human, value: 6), isFalse);
      expect(
        controller.canCallTruco(ZapitiPlayers.rightRival, value: 6),
        isTrue,
      );

      controller.callTruco(ZapitiPlayers.rightRival, value: 6);
      expect(
        controller.canCallTruco(ZapitiPlayers.rightRival, value: 9),
        isFalse,
      );
      expect(controller.canCallTruco(ZapitiPlayers.human, value: 9), isTrue);

      controller.callTruco(ZapitiPlayers.human, value: 9);
      expect(controller.canCallTruco(ZapitiPlayers.human, value: 12), isFalse);
      expect(
        controller.canCallTruco(ZapitiPlayers.rightRival, value: 12),
        isTrue,
      );

      controller.callTruco(ZapitiPlayers.rightRival, value: 12);
      expect(
        controller.canCallTruco(ZapitiPlayers.rightRival, value: 15),
        isFalse,
      );
      expect(controller.canCallTruco(ZapitiPlayers.human, value: 15), isTrue);

      controller.callTruco(ZapitiPlayers.human, value: 15);
      expect(controller.canCallTruco(ZapitiPlayers.human, value: 18), isFalse);
      expect(
        controller.canCallTruco(ZapitiPlayers.rightRival, value: 18),
        isTrue,
      );

      controller.callTruco(ZapitiPlayers.rightRival, value: 18);

      expect(controller.pendingTrucoValue, 18);
      expect(controller.betState.proposedLevel, BetLevel.ahorrisi);
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

    test('dos empates seguidos abren una tercera sin sumar chinos aun', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      )..startNewHand(fixedHands: _twoTiedRoundsHands());

      _playFullRound(controller);
      controller.resolveRound();
      controller.continueRound();
      _playFullRound(controller);
      controller.resolveRound();

      expect(controller.roundWins[TeamRules.teamOne], 2);
      expect(controller.roundWins[TeamRules.teamTwo], 2);
      expect(controller.score[TeamRules.teamOne], 0);
      expect(controller.score[TeamRules.teamTwo], 0);
      expect(controller.handFinished, isFalse);
      expect(controller.isRoundAwaitingContinue, isTrue);
    });

    test('si las dos primeras empatan, la tercera ganada decide el reparto', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      )..startNewHand(fixedHands: _twoTiesThenTeamOneWinsHands());

      _playFullRound(controller);
      controller.resolveRound();
      controller.continueRound();
      _playFullRound(controller);
      controller.resolveRound();
      controller.continueRound();
      _playFullRound(controller);
      controller.resolveRound();

      expect(controller.roundWins[TeamRules.teamOne], 3);
      expect(controller.roundWins[TeamRules.teamTwo], 2);
      expect(controller.score[TeamRules.teamOne], 1);
      expect(controller.handFinished, isTrue);
    });

    test('tercera empatada tras 1-1 finaliza y suma puntos una sola vez', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      )..startNewHand(fixedHands: _teamOneThenTeamTwoThenTieHands());

      _playFullRound(controller);
      controller.resolveRound();
      controller.continueRound();
      _playFullRound(controller);
      controller.resolveRound();
      controller.continueRound();
      _playFullRound(controller);
      controller.resolveRound();

      expect(controller.roundWins[TeamRules.teamOne], 2);
      expect(controller.roundWins[TeamRules.teamTwo], 2);
      expect(controller.score[TeamRules.teamOne], 1);
      expect(controller.score[TeamRules.teamTwo], 0);
      expect(controller.handFinished, isTrue);
      expect(controller.isRoundAwaitingContinue, isFalse);

      controller.resolveRound();

      expect(controller.score[TeamRules.teamOne], 1);
      expect(controller.score[TeamRules.teamTwo], 0);
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
        autoStart: false,
      )..startNewHand(fixedHands: _teamOneWinsTwoRoundsHands());

      controller.callTruco(
        ZapitiPlayers.human,
        value: 3,
        actorPlayerId: ZapitiPlayers.human.id,
      );
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
        autoStart: false,
      )..startNewHand(fixedHands: _teamOneWinsTwoRoundsHands());

      controller.callTruco(
        ZapitiPlayers.human,
        value: 3,
        actorPlayerId: ZapitiPlayers.human.id,
      );
      controller.raiseTruco(
        ZapitiPlayers.rightRival,
        value: 6,
        actorPlayerId: ZapitiPlayers.rightRival.id,
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

    test('rechazar truco mantiene la salida del siguiente jugador en mesa', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      controller.startNewHand();
      expect(controller.currentPlayer, ZapitiPlayers.rightRival);

      controller.callTruco(
        ZapitiPlayers.rightRival,
        value: 3,
      );
      controller.passTruco(
        passingTeamId: TeamRules.teamOne,
        actorPlayerId: ZapitiPlayers.human.id,
      );

      expect(controller.score[TeamRules.teamTwo], 1);
      expect(controller.handFinished, isTrue);

      controller.startNewHand();

      expect(controller.currentPlayer, ZapitiPlayers.companion);
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

    test('el companero local puede abrir truco pero no responder a su equipo',
        () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );
      controller
        ..startNewHand()
        ..startNewHand();

      expect(
        controller.canCallTruco(
          ZapitiPlayers.companion,
          value: 3,
          actorPlayerId: ZapitiPlayers.companion.id,
        ),
        isTrue,
      );
      controller.callTruco(
        ZapitiPlayers.companion,
        value: 3,
        actorPlayerId: ZapitiPlayers.companion.id,
      );

      expect(controller.trucoCallerTeamId, TeamRules.teamOne);
      expect(
        controller.canCallTruco(
          ZapitiPlayers.rightRival,
          value: 3,
          actorPlayerId: ZapitiPlayers.rightRival.id,
        ),
        isFalse,
      );

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
          actorPlayerId: ZapitiPlayers.companion.id,
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

      expect(
        () => controller.raiseTruco(
          ZapitiPlayers.rightRival,
          value: 21,
          actorPlayerId: ZapitiPlayers.human.id,
        ),
        throwsArgumentError,
      );
    });

    test('un equipo con 27 chinos puede abrir truco a 3 para jugarse la partida',
        () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );
      controller.score[TeamRules.teamOne] = 27;

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

      controller.callTruco(
        ZapitiPlayers.human,
        value: 3,
        actorPlayerId: ZapitiPlayers.human.id,
      );

      expect(controller.pendingTrucoValue, 3);
      expect(controller.raiseOptions, [6]);
      expect(
        controller.canAcceptTruco(
          teamId: TeamRules.teamTwo,
          actorPlayerId: ZapitiPlayers.rightRival.id,
        ),
        isTrue,
      );
    });

    test('la siguiente subida de truco sigue la escalera oficial', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );
      for (final score in [24, 25, 26, 27, 28, 29]) {
        controller.score[TeamRules.teamOne] = score;
        expect(
          controller.maxAllowedTrucoValueForTeam(TeamRules.teamOne),
          18,
          reason: 'score=$score',
        );
      }

      controller.score[TeamRules.teamOne] = 25;
      controller.callTruco(
        ZapitiPlayers.human,
        value: 3,
        actorPlayerId: ZapitiPlayers.human.id,
      );
      expect(controller.raiseOptionsForTeam(TeamRules.teamTwo), [6]);

      controller.score[TeamRules.teamTwo] = 25;
      expect(controller.raiseOptionsForTeam(TeamRules.teamTwo), [6]);
    });

    test('permite subidas oficiales cerca de 30 en 24 a 29 chinos', () {
      for (final score in [24, 25, 26, 27, 28, 29]) {
        final controller = ZapitiGameController(
          players: ZapitiPlayers.tableOrder,
        );
        controller.score[TeamRules.teamOne] = score;
        controller.score[TeamRules.teamTwo] = score;

        expect(
          controller.canCallTruco(
            ZapitiPlayers.human,
            value: 3,
            actorPlayerId: ZapitiPlayers.human.id,
          ),
          isTrue,
          reason: 'score=$score',
        );

        controller.callTruco(
          ZapitiPlayers.human,
          value: 3,
          actorPlayerId: ZapitiPlayers.human.id,
        );
        expect(
          controller.nextTrucoValueForPlayer(ZapitiPlayers.rightRival),
          6,
          reason: 'score=$score',
        );
        expect(
          controller.raiseOptionsForTeam(TeamRules.teamTwo),
          [6],
          reason: 'score=$score',
        );
      }
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

    test('detecta al ver cuando equipo 1 empieza con 29 chinos', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );
      controller.score[TeamRules.teamOne] = 29;

      controller.startNewHand(fixedHands: DebugDeals.presets.first);

      expect(controller.alVerState, AlVerState.awaitingDecision);
      expect(controller.alVerTeamId, TeamRules.teamOne);
      expect(controller.alVerTeamIds, contains(TeamRules.teamOne));
    });

    test('detecta al ver cuando equipo 2 empieza con 29 chinos', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );
      controller.score[TeamRules.teamTwo] = 29;

      controller.startNewHand(fixedHands: DebugDeals.presets.first);

      expect(controller.alVerState, AlVerState.awaitingDecision);
      expect(controller.alVerTeamId, TeamRules.teamTwo);
      expect(controller.alVerTeamIds, contains(TeamRules.teamTwo));
    });

    test('no activa al ver cuando nadie tiene 29 chinos', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );

      expect(controller.alVerState, AlVerState.none);
      expect(controller.alVerTeamId, isNull);
      expect(controller.alVerTeamIds, isEmpty);
    });

    test('al ver debe decidir antes de poder jugar una carta', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );
      controller.score[TeamRules.teamOne] = 29;
      controller.startNewHand(fixedHands: DebugDeals.presets.first);

      expect(
        () => controller.playCard(
          ZapitiPlayers.human,
          controller.hands[ZapitiPlayers.human.id]!.first,
        ),
        throwsStateError,
      );
    });

    test('si el equipo al ver decide jugar, la mano continua y vale 3 chinos',
        () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );
      controller.score[TeamRules.teamOne] = 29;
      controller.startNewHand(fixedHands: _teamOneWinsTwoRoundsHands());

      controller.chooseAlVerDecision(
        teamId: TeamRules.teamOne,
        play: true,
      );

      expect(controller.alVerState, AlVerState.playing);
      expect(controller.handValue, 1);
      expect(
        () => controller.playCard(
          controller.currentPlayer,
          controller.hands[controller.currentPlayer.id]!.first,
        ),
        returnsNormally,
      );
    });

    test('si ambos equipos estan al ver la mano sigue sin decision pendiente',
        () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
        targetScore: 40,
      );
      controller.score[TeamRules.teamOne] = 29;
      controller.score[TeamRules.teamTwo] = 29;
      controller.startNewHand(fixedHands: _teamOneWinsTwoRoundsHands());

      expect(controller.alVerState, AlVerState.playing);
      expect(controller.alVerTeamId, isNull);
      expect(controller.currentPlayer.id, isNotEmpty);
      expect(
        () => controller.playCard(
          controller.currentPlayer,
          controller.hands[controller.currentPlayer.id]!.first,
        ),
        returnsNormally,
      );
      expect(controller.pendingTrucoValue, isNull);
      expect(controller.respondingTrucoTeamId, isNull);
    });

    test(
        'normaliza snapshot invalido de ambos equipos al ver a playing sin decision',
        () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
        targetScore: 40,
      );
      controller.startNewHand(fixedHands: _teamOneWinsTwoRoundsHands());

      controller.syncAlVerSnapshot(
        teamIds: const [TeamRules.teamOne, TeamRules.teamTwo],
        requestedState: AlVerState.awaitingDecision,
      );

      expect(controller.alVerState, AlVerState.playing);
      expect(controller.alVerTeamId, isNull);
      expect(controller.pendingTrucoValue, isNull);
      expect(controller.respondingTrucoTeamId, isNull);
      expect(
        controller.legalActions.legalCardsFor(controller.currentPlayer),
        isNotEmpty,
      );
    });

    test('desde ambos equipos al ver la mano completa termina correctamente',
        () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
        targetScore: 40,
      );
      controller.score[TeamRules.teamOne] = 29;
      controller.score[TeamRules.teamTwo] = 29;
      controller.startNewHand(fixedHands: _teamOneWinsTwoRoundsHands());

      _finishTwoRounds(controller);

      expect(controller.handFinished, isTrue);
      expect(controller.score[TeamRules.teamOne], 29 + AlVerRules.playPoints);
      expect(controller.score[TeamRules.teamTwo], 29);
    });

    test('ambos equipos al ver no duplican la puntuacion final', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
        targetScore: 40,
      );
      controller.score[TeamRules.teamOne] = 29;
      controller.score[TeamRules.teamTwo] = 29;
      controller.startNewHand(fixedHands: _teamOneWinsTwoRoundsHands());

      _finishTwoRounds(controller);
      expect(controller.score[TeamRules.teamOne], 29 + AlVerRules.playPoints);

      controller.resolveRound();

      expect(controller.score[TeamRules.teamOne], 29 + AlVerRules.playPoints);
      expect(controller.score[TeamRules.teamTwo], 29);
    });

    test('ambos equipos al ver bloquean apuestas de apertura para ambos equipos',
        () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
        targetScore: 40,
      );
      controller.score[TeamRules.teamOne] = 29;
      controller.score[TeamRules.teamTwo] = 29;
      controller.startNewHand(fixedHands: _teamOneWinsTwoRoundsHands());

      expect(
        controller.canCallTruco(
          ZapitiPlayers.human,
          value: 3,
          actorPlayerId: ZapitiPlayers.human.id,
        ),
        isFalse,
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
        controller.legalBetActionsForPlayer(ZapitiPlayers.human),
        isEmpty,
      );
      expect(
        controller.legalBetActionsForPlayer(ZapitiPlayers.rightRival),
        isEmpty,
      );
    });

    test('si el equipo al ver se va a casa, el rival suma 2 chinos', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );
      controller.score[TeamRules.teamOne] = 29;
      controller.startNewHand(fixedHands: DebugDeals.presets.first);

      controller.chooseAlVerDecision(
        teamId: TeamRules.teamOne,
        play: false,
      );

      expect(controller.alVerState, AlVerState.conceded);
      expect(controller.score[TeamRules.teamTwo], 2);
      expect(controller.handFinished, isTrue);
      expect(controller.isRoundAwaitingContinue, isFalse);
      expect(controller.roundHistory, isEmpty);
      expect(controller.playedCards, isEmpty);
    });

    test('al ver bloquea truco y subida para ese equipo, pero no para el rival',
        () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );
      controller.score[TeamRules.teamOne] = 29;
      controller.startNewHand(fixedHands: _teamOneWinsTwoRoundsHands());
      controller.chooseAlVerDecision(teamId: TeamRules.teamOne, play: true);

      expect(
        controller.canCallTruco(
          ZapitiPlayers.human,
          value: 3,
          actorPlayerId: ZapitiPlayers.human.id,
        ),
        isFalse,
      );
      expect(
        controller.canCallTruco(
          ZapitiPlayers.rightRival,
          value: 3,
          actorPlayerId: ZapitiPlayers.rightRival.id,
        ),
        isTrue,
      );

      controller.callTruco(
        ZapitiPlayers.rightRival,
        value: 3,
        actorPlayerId: ZapitiPlayers.rightRival.id,
      );

      expect(controller.raiseOptionsForTeam(TeamRules.teamOne), isEmpty);
      expect(
        controller.canCallTruco(
          ZapitiPlayers.human,
          value: 6,
          actorPlayerId: ZapitiPlayers.human.id,
        ),
        isFalse,
      );
    });

    test('si el equipo al ver juega y gana sin truco, suma 3 chinos', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
        targetScore: 40,
      );
      controller.score[TeamRules.teamOne] = 29;
      controller.startNewHand(fixedHands: _teamOneWinsTwoRoundsHands());
      controller.chooseAlVerDecision(
        teamId: TeamRules.teamOne,
        play: true,
      );

      _finishTwoRounds(controller);

      expect(controller.score[TeamRules.teamOne], 29 + AlVerRules.playPoints);
      expect(controller.handFinished, isTrue);
      expect(controller.winningTeamId, isNull);
    });

    test('una mano nueva sin 29 limpia el estado al ver', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
      );
      controller.score[TeamRules.teamOne] = 29;
      controller.startNewHand(fixedHands: DebugDeals.presets.first);
      expect(controller.alVerState, AlVerState.awaitingDecision);

      controller.score[TeamRules.teamOne] = 0;
      controller.score[TeamRules.teamTwo] = 0;
      controller.startNewHand(fixedHands: DebugDeals.presets.first);

      expect(controller.alVerState, AlVerState.none);
      expect(controller.alVerTeamId, isNull);
      expect(controller.alVerTeamIds, isEmpty);
    });

    group('pasar mano', () {
      test('con la opcion desactivada no cambia el estado', () {
        final controller = _passHandController(allowPassHand: false);
        final originalTurn = controller.turnIndex;
        final originalScore = Map<int, int>.from(controller.score);

        expect(
          controller.canPassHand(
            from: ZapitiPlayers.human,
            to: ZapitiPlayers.companion,
          ),
          isFalse,
        );
        expect(
          () => controller.passHand(
            from: ZapitiPlayers.human,
            to: ZapitiPlayers.companion,
          ),
          throwsStateError,
        );
        expect(controller.turnIndex, originalTurn);
        expect(controller.score, originalScore);
      });

      test('el jugador con salida puede pasar mano al companero', () {
        final controller = _passHandController();

        controller.passHand(
          from: ZapitiPlayers.human,
          to: ZapitiPlayers.companion,
        );

        expect(controller.currentPlayer, ZapitiPlayers.companion);
        expect(controller.passedHandState.originalLeaderId,
            ZapitiPlayers.human.id);
        expect(controller.passedHandState.passedToPlayerId,
            ZapitiPlayers.companion.id);
      });

      test('no se puede pasar mano a un rival', () {
        final controller = _passHandController();

        expect(
          controller.canPassHand(
            from: ZapitiPlayers.human,
            to: ZapitiPlayers.rightRival,
          ),
          isFalse,
        );
      });

      test('no se puede pasar mano despues de una carta jugada', () {
        final controller = _passHandController();
        controller.playCard(
          ZapitiPlayers.human,
          controller.hands[ZapitiPlayers.human.id]!.first,
        );

        expect(
          controller.canPassHand(
            from: ZapitiPlayers.human,
            to: ZapitiPlayers.companion,
          ),
          isFalse,
        );
      });

      test('no se puede pasar mano si el jugador original ya jugo', () {
        final controller = _passHandController();
        controller.playedCards.add(
          PlayedCard(
            player: ZapitiPlayers.human,
            card: controller.hands[ZapitiPlayers.human.id]!.first,
          ),
        );

        expect(
          controller.canPassHand(
            from: ZapitiPlayers.human,
            to: ZapitiPlayers.companion,
          ),
          isFalse,
        );
      });

      test('no se puede pasar mano si el companero ya jugo', () {
        final controller = _passHandController();
        controller.playedCards.add(
          PlayedCard(
            player: ZapitiPlayers.companion,
            card: controller.hands[ZapitiPlayers.companion.id]!.first,
          ),
        );

        expect(
          controller.canPassHand(
            from: ZapitiPlayers.human,
            to: ZapitiPlayers.companion,
          ),
          isFalse,
        );
      });

      test('no se puede pasar mano dos veces en el mismo chico', () {
        final controller = _passHandController();
        controller.passHand(
          from: ZapitiPlayers.human,
          to: ZapitiPlayers.companion,
        );

        expect(
          () => controller.passHand(
            from: ZapitiPlayers.companion,
            to: ZapitiPlayers.human,
          ),
          throwsStateError,
        );
        expect(controller.currentPlayer, ZapitiPlayers.companion);
      });

      test('despues de que el companero juegue sigue el orden normal', () {
        final controller = _passHandController();
        controller.passHand(
          from: ZapitiPlayers.human,
          to: ZapitiPlayers.companion,
        );

        controller.playCard(
          ZapitiPlayers.companion,
          controller.hands[ZapitiPlayers.companion.id]!.first,
        );

        expect(controller.currentPlayer, ZapitiPlayers.leftRival);
      });

      test('pasar mano no suma chicos, chinos ni cambia truc', () {
        final controller = _passHandController();
        final score = Map<int, int>.from(controller.score);
        final roundWins = Map<int, int>.from(controller.roundWins);

        controller.passHand(
          from: ZapitiPlayers.human,
          to: ZapitiPlayers.companion,
        );

        expect(controller.score, score);
        expect(controller.roundWins, roundWins);
        expect(controller.handValue, 1);
        expect(controller.pendingTrucoValue, isNull);
        expect(controller.isTrucoAccepted, isFalse);
        expect(controller.handFinished, isFalse);
        expect(controller.roundHistory, isEmpty);
      });

      test('no acepta ni rechaza truc ni inicia nuevo reparto', () {
        final controller = _passHandController();
        final nextLeadIndex = controller.nextLeadIndex;
        final hand = controller.hands.map(
          (key, value) => MapEntry(key, List<SpanishCard>.from(value)),
        );

        controller.passHand(
          from: ZapitiPlayers.human,
          to: ZapitiPlayers.companion,
        );

        expect(controller.trucoState, TrucoNegotiationState.notStarted);
        expect(controller.nextLeadIndex, nextLeadIndex);
        expect(controller.hands, hand);
      });

      test('al empezar un nuevo chico ya no se puede pasar mano', () {
        final controller = _passHandController();
        controller.passHand(
          from: ZapitiPlayers.human,
          to: ZapitiPlayers.companion,
        );

        _playFullRound(controller);
        controller.resolveRound();
        controller.continueRound();

        expect(controller.passedHandState.hasPassed, isFalse);
        expect(controller.passedHandState.originalLeaderId,
            controller.currentPlayer.id);
        expect(
          controller.canPassHand(
            from: controller.currentPlayer,
            to: ZapitiPlayers.tableOrder.firstWhere(
              (player) =>
                  player.teamId == controller.currentPlayer.teamId &&
                  player.id != controller.currentPlayer.id,
            ),
          ),
          isFalse,
        );
      });

      test('al empezar una nueva mano se reinicia completamente', () {
        final controller = _passHandController();
        controller.passHand(
          from: ZapitiPlayers.human,
          to: ZapitiPlayers.companion,
        );

        controller.startNewHand(fixedHands: DebugDeals.presets.first);

        expect(controller.passedHandState.hasPassed, isFalse);
        expect(controller.passedHandState.originalLeaderId,
            controller.currentPlayer.id);
        expect(controller.playedCards, isEmpty);
      });

      test('solo el actor con salida puede ejecutar la accion', () {
        final controller = _passHandController();

        expect(
          controller.canPassHand(
            from: ZapitiPlayers.human,
            to: ZapitiPlayers.companion,
            actorPlayerId: ZapitiPlayers.rightRival.id,
          ),
          isFalse,
        );
      });

      test('un mensaje duplicado no cambia dos veces el estado', () {
        final controller = _passHandController();
        controller.passHand(
          from: ZapitiPlayers.human,
          to: ZapitiPlayers.companion,
        );
        final status = controller.status;

        expect(
          () => controller.passHand(
            from: ZapitiPlayers.human,
            to: ZapitiPlayers.companion,
          ),
          throwsStateError,
        );
        expect(controller.currentPlayer, ZapitiPlayers.companion);
        expect(controller.status, status);
      });
    });
  });
}

ZapitiGameController _passHandController({bool allowPassHand = true}) {
  return ZapitiGameController(
    players: ZapitiPlayers.tableOrder,
    allowPassHand: allowPassHand,
    autoStart: false,
  )..startNewHand(fixedHands: DebugDeals.presets.first);
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

Map<String, List<SpanishCard>> _twoTiedRoundsHands() {
  return {
    ZapitiPlayers.human.id: [
      const SpanishCard(value: 3, suit: Suit.oros),
      const SpanishCard(value: 2, suit: Suit.oros),
      const SpanishCard(value: 5, suit: Suit.copas),
    ],
    ZapitiPlayers.rightRival.id: [
      const SpanishCard(value: 3, suit: Suit.bastos),
      const SpanishCard(value: 2, suit: Suit.bastos),
      const SpanishCard(value: 5, suit: Suit.oros),
    ],
    ZapitiPlayers.companion.id: [
      const SpanishCard(value: 12, suit: Suit.copas),
      const SpanishCard(value: 11, suit: Suit.bastos),
      const SpanishCard(value: 6, suit: Suit.bastos),
    ],
    ZapitiPlayers.leftRival.id: [
      const SpanishCard(value: 10, suit: Suit.copas),
      const SpanishCard(value: 7, suit: Suit.espadas),
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

Map<String, List<SpanishCard>> _twoTiesThenTeamOneWinsHands() {
  return {
    ZapitiPlayers.human.id: [
      const SpanishCard(value: 3, suit: Suit.oros),
      const SpanishCard(value: 2, suit: Suit.oros),
      const SpanishCard(value: 4, suit: Suit.bastos),
    ],
    ZapitiPlayers.rightRival.id: [
      const SpanishCard(value: 3, suit: Suit.bastos),
      const SpanishCard(value: 2, suit: Suit.bastos),
      const SpanishCard(value: 12, suit: Suit.oros),
    ],
    ZapitiPlayers.companion.id: [
      const SpanishCard(value: 12, suit: Suit.copas),
      const SpanishCard(value: 11, suit: Suit.bastos),
      const SpanishCard(value: 5, suit: Suit.copas),
    ],
    ZapitiPlayers.leftRival.id: [
      const SpanishCard(value: 10, suit: Suit.copas),
      const SpanishCard(value: 7, suit: Suit.espadas),
      const SpanishCard(value: 6, suit: Suit.espadas),
    ],
  };
}

Map<String, List<SpanishCard>> _teamOneThenTeamTwoThenTieHands() {
  return {
    ZapitiPlayers.human.id: [
      const SpanishCard(value: 4, suit: Suit.bastos),
      const SpanishCard(value: 12, suit: Suit.copas),
      const SpanishCard(value: 5, suit: Suit.copas),
    ],
    ZapitiPlayers.rightRival.id: [
      const SpanishCard(value: 12, suit: Suit.oros),
      const SpanishCard(value: 7, suit: Suit.copas),
      const SpanishCard(value: 3, suit: Suit.bastos),
    ],
    ZapitiPlayers.companion.id: [
      const SpanishCard(value: 10, suit: Suit.bastos),
      const SpanishCard(value: 11, suit: Suit.bastos),
      const SpanishCard(value: 3, suit: Suit.oros),
    ],
    ZapitiPlayers.leftRival.id: [
      const SpanishCard(value: 4, suit: Suit.espadas),
      const SpanishCard(value: 5, suit: Suit.espadas),
      const SpanishCard(value: 6, suit: Suit.espadas),
    ],
  };
}
