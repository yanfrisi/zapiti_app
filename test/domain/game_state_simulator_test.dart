import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/game_state_simulator.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';
import 'package:zapiti_app/domain/zapiti_game_controller.dart';
import 'package:zapiti_app/domain/zapiti_players.dart';

void main() {
  group('GameStateSimulator', () {
    test('simula hasta el final sin tocar el controlador original', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
        autoStart: false,
      );
      controller.startNewHand(
        fixedHands: const {
          'p1': [
            SpanishCard(value: 4, suit: Suit.bastos),
            SpanishCard(value: 12, suit: Suit.oros),
            SpanishCard(value: 5, suit: Suit.copas),
          ],
          'p2': [
            SpanishCard(value: 7, suit: Suit.copas),
            SpanishCard(value: 6, suit: Suit.espadas),
            SpanishCard(value: 4, suit: Suit.oros),
          ],
          'p3': [
            SpanishCard(value: 3, suit: Suit.oros),
            SpanishCard(value: 11, suit: Suit.bastos),
            SpanishCard(value: 5, suit: Suit.espadas),
          ],
          'p4': [
            SpanishCard(value: 1, suit: Suit.espadas),
            SpanishCard(value: 10, suit: Suit.espadas),
            SpanishCard(value: 4, suit: Suit.copas),
          ],
        },
      );

      final originalHands = {
        for (final entry in controller.hands.entries) entry.key: [...entry.value],
      };
      final snapshot = SimulatedHandSnapshot.fromController(
        controller,
        hands: originalHands,
      );

      final result = const GameStateSimulator().simulateToEnd(snapshot);

      expect(result.roundsPlayed, inInclusiveRange(1, 3));
      expect(result.roundWins[1]! + result.roundWins[2]!, greaterThan(0));
      expect(controller.hands['p1'], originalHands['p1']);
      expect(controller.playedCards, isEmpty);
      expect(controller.roundHistory, isEmpty);
      expect(controller.handFinished, isFalse);
    });

    test('respeta una baza ya empezada y produce resultado reproducible', () {
      final controller = ZapitiGameController(
        players: ZapitiPlayers.tableOrder,
        autoStart: false,
      );
      controller.startNewHand(
        fixedHands: const {
          'p1': [
            SpanishCard(value: 12, suit: Suit.oros),
            SpanishCard(value: 6, suit: Suit.copas),
            SpanishCard(value: 5, suit: Suit.bastos),
          ],
          'p2': [
            SpanishCard(value: 4, suit: Suit.oros),
            SpanishCard(value: 5, suit: Suit.bastos),
            SpanishCard(value: 11, suit: Suit.copas),
          ],
          'p3': [
            SpanishCard(value: 2, suit: Suit.copas),
            SpanishCard(value: 11, suit: Suit.bastos),
            SpanishCard(value: 3, suit: Suit.oros),
          ],
          'p4': [
            SpanishCard(value: 1, suit: Suit.espadas),
            SpanishCard(value: 4, suit: Suit.copas),
            SpanishCard(value: 6, suit: Suit.oros),
          ],
        },
      );

      controller.playCard(
        ZapitiPlayers.human,
        const SpanishCard(value: 12, suit: Suit.oros),
      );

      final snapshot = SimulatedHandSnapshot.fromController(
        controller,
        hands: {
          for (final entry in controller.hands.entries) entry.key: [...entry.value],
        },
      );

      final simulator = const GameStateSimulator();
      final first = simulator.simulateToEnd(snapshot);
      final second = simulator.simulateToEnd(snapshot);

      expect(first.winningTeamId, second.winningTeamId);
      expect(first.roundWins, second.roundWins);
      expect(first.roundsPlayed, second.roundsPlayed);
    });
  });
}
