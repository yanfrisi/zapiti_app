import 'bet_state.dart';
import 'played_card.dart';
import 'player.dart';
import 'round_result.dart';
import 'signal_context.dart';
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
  final List<RoundResult> completedTricks;
  final List<String> visibleSignals;
  final SignalContext signalContext;
  final int handVersion;
  final int trickIndex;

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
    this.completedTricks = const <RoundResult>[],
    required this.visibleSignals,
    this.signalContext = SignalContext.empty,
    this.handVersion = 0,
    this.trickIndex = 0,
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
    List<RoundResult> completedTricks = const <RoundResult>[],
    SignalContext signalContext = SignalContext.empty,
    int handVersion = 0,
    int trickIndex = 0,
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
      completedTricks: List.unmodifiable([
        for (final trick in completedTricks)
          RoundResult(
            winner: trick.winner == null
                ? null
                : PlayedCard(
                    player: trick.winner!.player,
                    card: trick.winner!.card,
                  ),
            playedCards: List.unmodifiable([
              for (final played in trick.playedCards)
                PlayedCard(player: played.player, card: played.card),
            ]),
          ),
      ]),
      visibleSignals: List.unmodifiable(visibleSignals),
      signalContext: signalContext,
      handVersion: handVersion,
      trickIndex: trickIndex,
    );
  }
}
