import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/card_strength_comparator.dart';
import 'package:zapiti_app/domain/legal_actions.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';
import 'package:zapiti_app/domain/team_rules.dart';
import 'package:zapiti_app/domain/zapiti_game_controller.dart';
import 'package:zapiti_app/domain/zapiti_players.dart';

void main() {
  group('CardStrengthComparator', () {
    test('ordena con la jerarquia real de Zapiti', () {
      final cards = [
        const SpanishCard(value: 4, suit: Suit.copas),
        const SpanishCard(value: 3, suit: Suit.oros),
        const SpanishCard(value: 4, suit: Suit.bastos),
        const SpanishCard(value: 7, suit: Suit.oros),
      ]..sort(const CardStrengthComparator().compare);

      expect(
        cards,
        [
          const SpanishCard(value: 4, suit: Suit.copas),
          const SpanishCard(value: 3, suit: Suit.oros),
          const SpanishCard(value: 7, suit: Suit.oros),
          const SpanishCard(value: 4, suit: Suit.bastos),
        ],
      );
    });
  });

  group('ControllerLegalActionProvider', () {
    test('solo ofrece cartas legales al jugador en turno', () {
      final controller = ZapitiGameController(players: ZapitiPlayers.tableOrder);

      expect(
        controller.legalCardsForPlayer(ZapitiPlayers.human),
        orderedEquals(controller.hands[ZapitiPlayers.human.id]!),
      );
      expect(
        controller.legalCardsForPlayer(ZapitiPlayers.rightRival),
        isEmpty,
      );
    });

    test('bloquea jugar carta fuera de turno', () {
      final controller = ZapitiGameController(players: ZapitiPlayers.tableOrder);

      expect(
        controller.canPlayCard(
          ZapitiPlayers.rightRival,
          controller.hands[ZapitiPlayers.rightRival.id]!.first,
        ),
        isFalse,
      );
      expect(
        () => controller.playCard(
          ZapitiPlayers.rightRival,
          controller.hands[ZapitiPlayers.rightRival.id]!.first,
        ),
        throwsStateError,
      );
    });

    test('expone aceptar, pasar y contra-subir al equipo que responde', () {
      final controller = ZapitiGameController(players: ZapitiPlayers.tableOrder);
      controller.callTruco(
        ZapitiPlayers.human,
        value: 3,
        actorPlayerId: ZapitiPlayers.human.id,
      );

      expect(
        controller.legalBetActionsForPlayer(ZapitiPlayers.rightRival),
        containsAll(const [
          BetAction.accept(),
          BetAction.pass(),
          BetAction.call(6),
        ]),
      );
      expect(
        controller.legalBetActionsForPlayer(ZapitiPlayers.companion),
        isEmpty,
      );
    });

    test('tras aceptar no quedan acciones de apuesta abiertas', () {
      final controller = ZapitiGameController(players: ZapitiPlayers.tableOrder);
      controller.callTruco(
        ZapitiPlayers.human,
        value: 3,
        actorPlayerId: ZapitiPlayers.human.id,
      );
      controller.acceptTruco(
        teamId: TeamRules.teamTwo,
        actorPlayerId: ZapitiPlayers.rightRival.id,
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
  });
}
