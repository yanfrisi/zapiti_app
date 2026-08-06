import 'hand_rules.dart';
import 'played_card.dart';
import 'round_rules.dart';
import 'simulation_events.dart';
import 'simulation_game_state.dart';
import 'spanish_card.dart';
import 'team_rules.dart';

class GameTransition {
  final SimulationGameState previousState;
  final SimulationGameState nextState;
  final List<SimulationEvent> events;

  const GameTransition({
    required this.previousState,
    required this.nextState,
    required this.events,
  });
}

abstract interface class SimulationGameEngine {
  List<SpanishCard> legalCardsFor(SimulationGameState state, String playerId);
  GameTransition playCard(
    SimulationGameState state,
    String playerId,
    SpanishCard card,
  );
  bool isTerminal(SimulationGameState state);
}

class DefaultSimulationGameEngine implements SimulationGameEngine {
  const DefaultSimulationGameEngine();

  @override
  List<SpanishCard> legalCardsFor(SimulationGameState state, String playerId) {
    if (state.isHandFinished) return const [];
    if (state.currentPlayerId != playerId) return const [];
    return List.unmodifiable(state.playerState(playerId).hand);
  }

  @override
  GameTransition playCard(
    SimulationGameState state,
    String playerId,
    SpanishCard card,
  ) {
    final playerIndex =
        state.players.indexWhere((entry) => entry.player.id == playerId);
    if (playerIndex < 0) throw ArgumentError('Jugador desconocido.');
    if (state.currentPlayerId != playerId) {
      throw StateError('No es el turno del jugador.');
    }

    final playerState = state.players[playerIndex];
    if (!playerState.hand.contains(card)) {
      throw ArgumentError('Carta no disponible.');
    }

    final nextPlayers = [
      for (final entry in state.players)
        entry.player.id == playerId
            ? SimulationPlayerState(
                player: entry.player,
                hand: List.unmodifiable(
                  [...entry.hand]..remove(card),
                ),
              )
            : SimulationPlayerState(
                player: entry.player,
                hand: List.unmodifiable(entry.hand),
              ),
    ];
    final nextPlayed = [
      ...state.playedCards,
      PlayedCard(player: playerState.player, card: card),
    ];
    final events = <SimulationEvent>[
      CardPlayedEvent(playerId: playerId, card: card),
    ];

    final isTrickComplete = nextPlayed.length % state.players.length == 0;
    if (!isTrickComplete) {
      final nextPlayerIndex = (playerIndex + 1) % state.players.length;
      final nextState = SimulationGameState(
        players: List.unmodifiable(nextPlayers),
        currentTrick: List.unmodifiable(nextPlayed),
        playedCards: List.unmodifiable(nextPlayed),
        completedTricks: List.unmodifiable(state.completedTricks),
        currentPlayerId: state.players[nextPlayerIndex].player.id,
        trickLeaderId: state.trickLeaderId,
        betState: state.betState,
        score: state.score,
        roundWins: state.roundWins,
        roundNumber: state.roundNumber,
        isRoundFinished: false,
        isHandFinished: false,
      );
      return GameTransition(previousState: state, nextState: nextState, events: events);
    }

    final result = RoundRules.resolveRound(nextPlayed);
    final completed = [...state.completedTricks, result];
    final progress = HandRules.resolve(completed);
    final roundWins = {
      TeamRules.teamOne: progress.roundWinsFor(TeamRules.teamOne),
      TeamRules.teamTwo: progress.roundWinsFor(TeamRules.teamTwo),
    };
    final score = Map<int, int>.from(state.score);
    final isHandFinished = progress.isFinished;
    final isRoundFinished = true;
    if (progress.isFinished && progress.winningTeamId != null) {
      score[progress.winningTeamId!] = (score[progress.winningTeamId!] ?? 0) +
          state.betState.acceptedLevel.value;
      events.add(ScoreChangedEvent(score: Map.unmodifiable(score)));
      events.add(RoundCompletedEvent(winningTeamId: progress.winningTeamId));
    } else if (progress.isFinished) {
      events.add(const RoundCompletedEvent(winningTeamId: null));
    }
    final winnerPlayerId = result.winner?.player.id ?? state.trickLeaderId;
    final nextState = SimulationGameState(
      players: List.unmodifiable(nextPlayers),
      currentTrick: const [],
      playedCards: List.unmodifiable(nextPlayed),
      completedTricks: List.unmodifiable(completed),
      currentPlayerId: winnerPlayerId,
      trickLeaderId: winnerPlayerId,
      betState: state.betState,
      score: Map.unmodifiable(score),
      roundWins: Map.unmodifiable(roundWins),
      roundNumber: state.roundNumber + 1,
      isRoundFinished: isRoundFinished,
      isHandFinished: isHandFinished,
    );
    events.add(TrickCompletedEvent(winningTeamId: result.winningTeamId));
    return GameTransition(previousState: state, nextState: nextState, events: events);
  }

  @override
  bool isTerminal(SimulationGameState state) => state.isHandFinished;
}
