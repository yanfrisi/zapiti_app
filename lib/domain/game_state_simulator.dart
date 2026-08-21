import 'dart:math';

import 'bot_strategy.dart';
import 'hand_rules.dart';
import 'played_card.dart';
import 'player.dart';
import 'round_result.dart';
import 'round_rules.dart';
import 'spanish_card.dart';
import 'team_rules.dart';
import 'zapiti_game_controller.dart';

class SimulatedHandSnapshot {
  final List<Player> players;
  final Map<String, List<SpanishCard>> hands;
  final List<PlayedCard> playedCards;
  final List<RoundResult> roundHistory;
  final Map<int, int> roundWins;
  final int turnIndex;
  final int leadIndex;
  final int handValue;

  const SimulatedHandSnapshot({
    required this.players,
    required this.hands,
    required this.playedCards,
    required this.roundHistory,
    required this.roundWins,
    required this.turnIndex,
    required this.leadIndex,
    required this.handValue,
  });

  factory SimulatedHandSnapshot.fromController(
    ZapitiGameController controller, {
    required Map<String, List<SpanishCard>> hands,
  }) {
    return SimulatedHandSnapshot(
      players: controller.players,
      hands: {
        for (final entry in hands.entries) entry.key: [...entry.value],
      },
      playedCards: [
        for (final played in controller.playedCards)
          PlayedCard(player: played.player, card: played.card),
      ],
      roundHistory: [...controller.roundHistory],
      roundWins: {
        TeamRules.teamOne: controller.roundWins[TeamRules.teamOne] ?? 0,
        TeamRules.teamTwo: controller.roundWins[TeamRules.teamTwo] ?? 0,
      },
      turnIndex: controller.turnIndex,
      leadIndex: controller.leadIndex,
      handValue: controller.handValue,
    );
  }
}

class SimulatedHandResult {
  final int? winningTeamId;
  final Map<int, int> roundWins;
  final int roundsPlayed;
  final List<RoundResult> roundHistory;

  const SimulatedHandResult({
    required this.winningTeamId,
    required this.roundWins,
    required this.roundsPlayed,
    required this.roundHistory,
  });
}

class GameStateSimulator {
  const GameStateSimulator();

  SimulatedHandResult simulateToEnd(
    SimulatedHandSnapshot snapshot, {
    Random? random,
    int difficulty = 4,
  }) {
    final state = _MutableSimulatedHandState.fromSnapshot(snapshot);
    final rng = random ?? Random(0);

    while (!state.handFinished) {
      final player = state.currentPlayer;
      final hand = state.hands[player.id] ?? const <SpanishCard>[];
      if (hand.isEmpty) {
        state.finishFromExhaustedHands();
        break;
      }

      final chosen = BotStrategy.chooseCardWithLookahead(
        difficulty: difficulty,
        player: player,
        hand: hand,
        playedCards: state.playedCards,
        players: state.players,
        hands: state.hands,
        teamRoundWins: state.roundWins[player.teamId] ?? 0,
        opponentRoundWins:
            state.roundWins[TeamRules.opponentOf(player.teamId)] ?? 0,
        roundHistory: state.roundHistory,
        allowPerfectInformation: true,
        forceWinIfPossible: state.handValue >= 4,
        teammateStillToPlay: state.teammateStillToPlay(player),
        opponentStillToPlay: state.opponentStillToPlay(player),
      );

      state.playCard(player, chosen);
      if (state.playedCards.length == state.players.length) {
        state.resolveRound();
      } else if (rng.nextDouble() < -1) {
        // Keeps `rng` consumed by call sites that want deterministic APIs later.
      }
    }

    return SimulatedHandResult(
      winningTeamId: state.winningTeamId,
      roundWins: Map.unmodifiable(state.roundWins),
      roundsPlayed: state.roundHistory.length,
      roundHistory: List.unmodifiable(state.roundHistory),
    );
  }
}

class _MutableSimulatedHandState {
  final List<Player> players;
  final Map<String, List<SpanishCard>> hands;
  final List<PlayedCard> playedCards;
  final List<RoundResult> roundHistory;
  final Map<int, int> roundWins;
  int turnIndex;
  int leadIndex;
  final int handValue;
  bool handFinished = false;
  int? winningTeamId;

  _MutableSimulatedHandState({
    required this.players,
    required this.hands,
    required this.playedCards,
    required this.roundHistory,
    required this.roundWins,
    required this.turnIndex,
    required this.leadIndex,
    required this.handValue,
  });

  factory _MutableSimulatedHandState.fromSnapshot(SimulatedHandSnapshot value) {
    final state = _MutableSimulatedHandState(
      players: value.players,
      hands: {
        for (final entry in value.hands.entries) entry.key: [...entry.value],
      },
      playedCards: [
        for (final played in value.playedCards)
          PlayedCard(player: played.player, card: played.card),
      ],
      roundHistory: [...value.roundHistory],
      roundWins: {
        TeamRules.teamOne: value.roundWins[TeamRules.teamOne] ?? 0,
        TeamRules.teamTwo: value.roundWins[TeamRules.teamTwo] ?? 0,
      },
      turnIndex: value.turnIndex,
      leadIndex: value.leadIndex,
      handValue: value.handValue,
    );
    final progress = HandRules.resolve(state.roundHistory);
    if (progress.isFinished) {
      state.handFinished = true;
      state.winningTeamId = progress.winningTeamId;
      state.roundWins[TeamRules.teamOne] = progress.roundWinsFor(TeamRules.teamOne);
      state.roundWins[TeamRules.teamTwo] = progress.roundWinsFor(TeamRules.teamTwo);
    }
    return state;
  }

  Player get currentPlayer => players[turnIndex];

  void finishFromExhaustedHands() {
    handFinished = true;
    final progress = HandRules.resolve(roundHistory);
    winningTeamId = progress.winningTeamId;
  }

  void playCard(Player player, SpanishCard card) {
    if (player.id != currentPlayer.id) {
      throw StateError('Turno incorrecto en simulacion.');
    }
    final hand = hands[player.id];
    if (hand == null || !hand.contains(card)) {
      throw ArgumentError('Carta no disponible en simulacion.');
    }
    hand.remove(card);
    playedCards.add(PlayedCard(player: player, card: card));
    if (playedCards.length < players.length) {
      turnIndex = (turnIndex + 1) % players.length;
    }
  }

  void resolveRound() {
    final result = RoundRules.resolveRound(playedCards);
    roundHistory.add(result);
    final progress = HandRules.resolve(roundHistory);
    roundWins[TeamRules.teamOne] = progress.roundWinsFor(TeamRules.teamOne);
    roundWins[TeamRules.teamTwo] = progress.roundWinsFor(TeamRules.teamTwo);

    if (result.isTie) {
      turnIndex = leadIndex;
    } else {
      final winner = result.winner!;
      leadIndex = players.indexWhere((player) => player.id == winner.player.id);
      turnIndex = leadIndex;
    }

    if (progress.isFinished) {
      handFinished = true;
      winningTeamId = progress.winningTeamId;
      return;
    }

    playedCards.clear();
  }

  bool teammateStillToPlay(Player player) {
    final teammate = players.firstWhere(
      (candidate) => candidate.teamId == player.teamId && candidate.id != player.id,
      orElse: () => player,
    );
    if (teammate.id == player.id) return false;
    if (playedCards.any((played) => played.player.id == teammate.id)) {
      return false;
    }
    final playerIndex = players.indexWhere((candidate) => candidate.id == player.id);
    final teammateIndex =
        players.indexWhere((candidate) => candidate.id == teammate.id);
    final turnsUntilTeammate = (teammateIndex - playerIndex) % players.length;
    final remainingTurnsAfterPlayer = players.length - playedCards.length - 1;
    return turnsUntilTeammate > 0 &&
        turnsUntilTeammate <= remainingTurnsAfterPlayer;
  }

  bool opponentStillToPlay(Player player) {
    final playerIndex = players.indexWhere((candidate) => candidate.id == player.id);
    final remainingTurnsAfterPlayer = players.length - playedCards.length - 1;
    if (remainingTurnsAfterPlayer <= 0) return false;
    for (final opponent in players.where((candidate) {
      return candidate.teamId != player.teamId &&
          !playedCards.any((played) => played.player.id == candidate.id);
    })) {
      final opponentIndex =
          players.indexWhere((candidate) => candidate.id == opponent.id);
      final turnsUntilOpponent = (opponentIndex - playerIndex) % players.length;
      if (turnsUntilOpponent > 0 &&
          turnsUntilOpponent <= remainingTurnsAfterPlayer) {
        return true;
      }
    }
    return false;
  }
}
