import 'played_card.dart';
import 'player.dart';
import 'spanish_card.dart';
import 'zapiti_rules.dart';

class BotVenAMiStrategy {
  const BotVenAMiStrategy._();

  static SpanishCard chooseCard({
    required Player bot,
    required List<SpanishCard> hand,
    required List<PlayedCard> playedCards,
    required List<Player> players,
    required Map<String, List<SpanishCard>> hands,
    List<SpanishCard>? legalCards,
  }) {
    final playableCards = legalCards ?? hand;
    if (playableCards.isEmpty) {
      throw ArgumentError('El bot no puede obedecer ven a mi sin cartas.');
    }

    final sorted = [...playableCards]..sort(_compareByStrength);
    return sorted.first;
  }

  static int _compareByStrength(SpanishCard a, SpanishCard b) {
    return ZapitiRules.strength(a).compareTo(ZapitiRules.strength(b));
  }
}
