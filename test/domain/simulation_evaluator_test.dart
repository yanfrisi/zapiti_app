import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bet_state.dart';
import 'package:zapiti_app/domain/round_result.dart';
import 'package:zapiti_app/domain/simulation_evaluator.dart';
import 'package:zapiti_app/domain/simulation_game_state.dart';
import 'package:zapiti_app/domain/player.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';

void main() {
  const bot = Player(id: 'p1', name: 'Bot', teamId: 1);
  const rival = Player(id: 'p2', name: 'Rival', teamId: 2);
  const teammate = Player(id: 'p3', name: 'Mate', teamId: 1);
  const rearRival = Player(id: 'p4', name: 'Rear', teamId: 2);

  SimulationGameState buildState({
    required List<SpanishCard> botHand,
    required List<SpanishCard> rivalHand,
    required List<SpanishCard> teammateHand,
    required List<SpanishCard> rearRivalHand,
  }) {
    return SimulationGameState(
      players: [
        SimulationPlayerState(player: bot, hand: botHand),
        SimulationPlayerState(player: rival, hand: rivalHand),
        SimulationPlayerState(player: teammate, hand: teammateHand),
        SimulationPlayerState(player: rearRival, hand: rearRivalHand),
      ],
      currentTrick: const [],
      playedCards: const [],
      completedTricks: const <RoundResult>[],
      currentPlayerId: bot.id,
      trickLeaderId: bot.id,
      betState: const BetState(
        acceptedLevel: BetLevel.none,
        proposedLevel: null,
        proposingTeam: null,
        respondingTeam: null,
        lastRaisingTeam: null,
        responsePending: false,
      ),
      score: const {1: 6, 2: 6},
      roundWins: const {1: 1, 2: 1},
      roundNumber: 1,
      isRoundFinished: false,
      isHandFinished: false,
    );
  }

  test('TeamSimulationEvaluator premia conservar fuerza y señales de equipo', () {
    final evaluator = const TeamSimulationEvaluator();
    final strongTeamState = buildState(
      botHand: const [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 2, suit: Suit.copas),
      ],
      rivalHand: const [
        SpanishCard(value: 5, suit: Suit.copas),
        SpanishCard(value: 6, suit: Suit.oros),
      ],
      teammateHand: const [
        SpanishCard(value: 7, suit: Suit.copas),
        SpanishCard(value: 12, suit: Suit.oros),
      ],
      rearRivalHand: const [
        SpanishCard(value: 1, suit: Suit.espadas),
        SpanishCard(value: 3, suit: Suit.oros),
      ],
    );
    final weakTeamState = buildState(
      botHand: const [
        SpanishCard(value: 5, suit: Suit.copas),
        SpanishCard(value: 6, suit: Suit.oros),
      ],
      rivalHand: const [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 2, suit: Suit.copas),
      ],
      teammateHand: const [
        SpanishCard(value: 1, suit: Suit.espadas),
        SpanishCard(value: 3, suit: Suit.oros),
      ],
      rearRivalHand: const [
        SpanishCard(value: 7, suit: Suit.copas),
        SpanishCard(value: 12, suit: Suit.oros),
      ],
    );

    expect(
      evaluator.evaluate(strongTeamState, bot.id),
      greaterThan(evaluator.evaluate(weakTeamState, bot.id)),
    );
  });
}
