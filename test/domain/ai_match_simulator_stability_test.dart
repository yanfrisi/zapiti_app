import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/game_state_simulator.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';
import 'package:zapiti_app/domain/zapiti_game_controller.dart';
import 'package:zapiti_app/domain/zapiti_players.dart';

void main() {
  group('Ai simulation stability', () {
    SimulatedHandSnapshot acceptedTrucoSnapshot() {
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

      controller.handValue = 3;
      controller.playCard(
        ZapitiPlayers.human,
        const SpanishCard(value: 12, suit: Suit.oros),
      );

      return SimulatedHandSnapshot.fromController(
        controller,
        hands: {
          for (final entry in controller.hands.entries) entry.key: [...entry.value],
        },
      );
    }

    test('una mano simulada con truco aceptado termina sin bloquearse', () {
      final result = const GameStateSimulator().simulateToEnd(
        acceptedTrucoSnapshot(),
      );

      expect(result.roundsPlayed, inInclusiveRange(1, 3));
      expect(result.roundWins[1]! + result.roundWins[2]!, greaterThan(0));
    });

    test('varias simulaciones del mismo estado siguen siendo reproducibles', () {
      final snapshot = acceptedTrucoSnapshot();
      final simulator = const GameStateSimulator();

      final first = simulator.simulateToEnd(snapshot);
      final second = simulator.simulateToEnd(snapshot);
      final third = simulator.simulateToEnd(snapshot);

      expect(first.winningTeamId, second.winningTeamId);
      expect(second.winningTeamId, third.winningTeamId);
      expect(first.roundWins, second.roundWins);
      expect(second.roundWins, third.roundWins);
      expect(first.roundsPlayed, second.roundsPlayed);
      expect(second.roundsPlayed, third.roundsPlayed);
    });
  });
}
