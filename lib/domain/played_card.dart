import 'player.dart';
import 'spanish_card.dart';

class PlayedCard {
  final Player player;
  final SpanishCard card;

  const PlayedCard({
    required this.player,
    required this.card,
  });
}
