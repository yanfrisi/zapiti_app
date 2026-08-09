import 'bet_state.dart';
import 'played_card.dart';
import 'player.dart';
import 'round_result.dart';
import 'signal_context.dart';
import 'spanish_card.dart';

class SimulationPlayerState {
  final Player player;
  final List<SpanishCard> hand;

  const SimulationPlayerState({required this.player, required this.hand});
}

class SimulationGameState {
  final List<SimulationPlayerState> players;
  final List<PlayedCard> currentTrick;
  final List<PlayedCard> playedCards;
  final List<RoundResult> completedTricks;
  final String currentPlayerId;
  final String trickLeaderId;
  final BetState betState;
  final Map<int, int> score;
  final Map<int, int> roundWins;
  final int roundNumber;
  final bool isRoundFinished;
  final bool isHandFinished;
  final SignalContext signalContext;
  final int handVersion;
  final int trickIndex;

  const SimulationGameState({
    required this.players,
    required this.currentTrick,
    required this.playedCards,
    required this.completedTricks,
    required this.currentPlayerId,
    required this.trickLeaderId,
    required this.betState,
    required this.score,
    required this.roundWins,
    required this.roundNumber,
    required this.isRoundFinished,
    required this.isHandFinished,
    this.signalContext = SignalContext.empty,
    this.handVersion = 0,
    this.trickIndex = 0,
  });

  SimulationPlayerState playerState(String playerId) => players.firstWhere(
        (entry) => entry.player.id == playerId,
      );
}
