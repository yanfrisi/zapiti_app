import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bet_state.dart';
import 'package:zapiti_app/domain/team_rules.dart';
import 'package:zapiti_app/domain/zapiti_game_controller.dart';
import 'package:zapiti_app/domain/zapiti_players.dart';

void main() {
  group('BetState', () {
    test('expone truco pendiente con equipos y nivel', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
        autoStart: false,
      )..startNewHand();

      controller.callTruco(
        ZapitiPlayers.human,
        value: 3,
        actorPlayerId: ZapitiPlayers.human.id,
      );

      expect(controller.betState.acceptedLevel, BetLevel.none);
      expect(controller.betState.proposedLevel, BetLevel.truco);
      expect(controller.betState.proposingTeam, TeamRules.teamOne);
      expect(controller.betState.respondingTeam, TeamRules.teamTwo);
      expect(controller.betState.responsePending, isTrue);
    });

    test('expone nivel aceptado tras aceptar', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
        autoStart: false,
      )..startNewHand();

      controller.callTruco(
        ZapitiPlayers.human,
        value: 3,
        actorPlayerId: ZapitiPlayers.human.id,
      );
      controller.acceptTruco(teamId: TeamRules.teamTwo);

      expect(controller.betState.acceptedLevel, BetLevel.truco);
      expect(controller.betState.proposedLevel, isNull);
      expect(controller.betState.responsePending, isFalse);
      expect(controller.betState.lastRaisingTeam, TeamRules.teamOne);
    });
  });
}
