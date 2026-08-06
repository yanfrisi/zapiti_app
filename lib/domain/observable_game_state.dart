import 'bet_state.dart';
import 'played_card.dart';
import 'player.dart';
import 'spanish_card.dart';

class ObservableGameState {
  final String botPlayerId;
  final List<Player> players;
  final List<SpanishCard> botHand;
  final List<PlayedCard> playedCards;
  final Map<String, int> cardsRemainingByPlayerId;
  final Map<String, List<SpanishCard>> publiclyKnownCardsByPlayerId;
  final String currentPlayerId;
  final String trickLeaderId;
  final BetState betState;
  final Map<int, int> score;
  final Map<int, int> roundWins;
  final List<String> visibleSignals;

  const ObservableGameState({
    required this.botPlayerId,
    required this.players,
    required this.botHand,
    required this.playedCards,
    required this.cardsRemainingByPlayerId,
    required this.publiclyKnownCardsByPlayerId,
    required this.currentPlayerId,
    required this.trickLeaderId,
    required this.betState,
    required this.score,
    required this.roundWins,
    required this.visibleSignals,
  });

  factory ObservableGameState.fromController({
    required List<Player> players,
    required String botPlayerId,
    required Map<String, List<SpanishCard>> hands,
    required List<PlayedCard> playedCards,
    required Map<int, int> score,
    required Map<int, int> roundWins,
    required String currentPlayerId,
    required String trickLeaderId,
    required BetState betState,
    required List<String> visibleSignals,
    Map<String, List<SpanishCard>> publiclyKnownCardsByPlayerId = const {},
  }) {
    return ObservableGameState(
      botPlayerId: botPlayerId,
      players: List.unmodifiable(players),
      botHand: List.unmodifiable(hands[botPlayerId] ?? const <SpanishCard>[]),
      playedCards: List.unmodifiable(
        [
          for (final played in playedCards)
            PlayedCard(player: played.player, card: played.card),
        ],
      ),
      cardsRemainingByPlayerId: Map.unmodifiable({
        for (final player in players) player.id: hands[player.id]?.length ?? 0,
      }),
      publiclyKnownCardsByPlayerId: Map.unmodifiable({
        for (final entry in publiclyKnownCardsByPlayerId.entries)
          entry.key: List.unmodifiable([
            for (final card in entry.value) card,
          ]),
      }),
      currentPlayerId: currentPlayerId,
      trickLeaderId: trickLeaderId,
      betState: betState,
      score: Map.unmodifiable(score),
      roundWins: Map.unmodifiable(roundWins),
      visibleSignals: List.unmodifiable(visibleSignals),
    );
  }
}

