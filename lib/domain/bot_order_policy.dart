import 'bot_voy_a_ti_strategy.dart';
import 'played_card.dart';
import 'player.dart';
import 'spanish_card.dart';
import 'zapiti_rules.dart';

/// Resuelve órdenes explícitas antes de cualquier estrategia de cartas.
///
/// Devuelve null cuando no existe una orden activa: el llamador puede entonces
/// emplear heurísticas o Monte Carlo sin alterar las instrucciones del equipo.
class BotOrderPolicy {
  const BotOrderPolicy._();

  static SpanishCard? chooseOrderedCard({
    required Player bot,
    required List<SpanishCard> hand,
    required List<PlayedCard> playedCards,
    required List<Player> players,
    required Map<String, List<SpanishCard>> hands,
    required bool mataRequested,
    required bool voyATiRequested,
  }) {
    if (hand.isEmpty) {
      throw ArgumentError('El bot no puede jugar sin cartas.');
    }

    // Si coinciden ambas órdenes, Mata es la más específica.
    if (mataRequested) {
      return hand.reduce((a, b) =>
          ZapitiRules.strength(a) >= ZapitiRules.strength(b) ? a : b);
    }

    if (voyATiRequested) {
      return BotVoyATiStrategy.chooseCard(
        bot: bot,
        hand: hand,
        playedCards: playedCards,
        players: players,
        hands: hands,
      );
    }

    return null;
  }
}
