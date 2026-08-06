import 'observable_game_state.dart';
import 'possible_deal_sampler.dart';
import 'simulation_game_state.dart';
import 'played_card.dart';
import 'spanish_card.dart';
import 'round_result.dart';

abstract interface class SimulationStateFactory {
  SimulationGameState create({
    required ObservableGameState observableState,
    required PossibleDeal possibleDeal,
  });
}

class DefaultSimulationStateFactory implements SimulationStateFactory {
  const DefaultSimulationStateFactory();

  @override
  SimulationGameState create({
    required ObservableGameState observableState,
    required PossibleDeal possibleDeal,
  }) {
    final hands = possibleDeal.handsByPlayerId;
    final expectedPlayers = observableState.players.map((p) => p.id).toSet();
    if (!hands.keys.toSet().containsAll(expectedPlayers)) {
      throw ArgumentError('La determinizacion no cubre a todos los jugadores.');
    }
    final seen = <SpanishCard>{};
    for (final entry in hands.entries) {
      for (final card in entry.value) {
        if (!seen.add(card)) {
          throw StateError('Determinization duplicada.');
        }
      }
    }
    for (final card in observableState.botHand) {
      if (!hands[observableState.botPlayerId]!.contains(card)) {
        throw StateError('La mano del bot no coincide con la observable.');
      }
    }
    for (final played in observableState.playedCards) {
      if (seen.contains(played.card)) {
        throw StateError('Una carta jugada aparece en la determinizacion.');
      }
    }
    final players = [
      for (final player in observableState.players)
        SimulationPlayerState(
          player: player,
          hand: List.unmodifiable(hands[player.id] ?? const <SpanishCard>[]),
        ),
    ];
    final totalExpected = observableState.cardsRemainingByPlayerId.values
        .fold<int>(0, (sum, count) => sum + count);
    final totalAssigned = hands.values.fold<int>(0, (sum, hand) => sum + hand.length);
    if (totalAssigned != totalExpected) {
      throw StateError('El total de cartas no cuadra con el estado observable.');
    }
    final currentTrick = List<PlayedCard>.unmodifiable([
      for (final played in observableState.playedCards)
        PlayedCard(player: played.player, card: played.card),
    ]);
    return SimulationGameState(
      players: List.unmodifiable(players),
      currentTrick: currentTrick,
      playedCards: currentTrick,
      completedTricks: const <RoundResult>[],
      currentPlayerId: observableState.currentPlayerId,
      trickLeaderId: observableState.trickLeaderId,
      betState: observableState.betState,
      score: Map.unmodifiable(observableState.score),
      roundWins: Map.unmodifiable(observableState.roundWins),
      roundNumber: 1,
      isRoundFinished: false,
      isHandFinished: false,
    );
  }
}
