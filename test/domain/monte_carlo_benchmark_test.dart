import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bet_state.dart';
import 'package:zapiti_app/domain/monte_carlo_card_selector.dart';
import 'package:zapiti_app/domain/monte_carlo_difficulty_config.dart';
import 'package:zapiti_app/domain/observable_game_state.dart';
import 'package:zapiti_app/domain/played_card.dart';
import 'package:zapiti_app/domain/player.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';
import 'package:zapiti_app/domain/zapiti_players.dart';

void main() {
  test('benchmark basico del selector Monte Carlo', () {
    final selector = MonteCarloCardSelector(random: Random(7));
    final state = ObservableGameState(
      botPlayerId: ZapitiPlayers.human.id,
      players: ZapitiPlayers.tableOrder,
      botHand: const [
        SpanishCard(value: 1, suit: Suit.espadas),
        SpanishCard(value: 3, suit: Suit.copas),
        SpanishCard(value: 4, suit: Suit.bastos),
      ],
      playedCards: const [
        PlayedCard(
          player: Player(id: 'p2', name: 'R1', teamId: 2),
          card: SpanishCard(value: 5, suit: Suit.oros),
        ),
      ],
      cardsRemainingByPlayerId: const {'p1': 3, 'p2': 3, 'p3': 3, 'p4': 3},
      publiclyKnownCardsByPlayerId: const {},
      currentPlayerId: 'p1',
      trickLeaderId: 'p2',
      betState: const BetState(
        acceptedLevel: BetLevel.none,
        proposedLevel: null,
        proposingTeam: null,
        respondingTeam: null,
        lastRaisingTeam: null,
        responsePending: false,
      ),
      score: const {1: 10, 2: 8},
      roundWins: const {1: 1, 2: 0},
      visibleSignals: const [],
    );

    final configs = <String, MonteCarloDifficultyConfig>{
      'easy': MonteCarloDifficultyConfigs.easy,
      'normal': MonteCarloDifficultyConfigs.normal,
      'hard': MonteCarloDifficultyConfigs.hard,
    };

    for (final entry in configs.entries) {
      final watch = Stopwatch()..start();
      final card = selector.selectCard(
        botPlayerId: state.botPlayerId,
        state: state,
        config: entry.value,
      );
      watch.stop();
      // ignore: avoid_print
      print('${entry.key}: ${watch.elapsedMilliseconds} ms -> $card');
      expect(state.botHand.contains(card), isTrue);
    }
  });
}

