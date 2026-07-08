part of 'zapiti_game_table.dart';

class _SquareTable extends StatelessWidget {
  final List<PlayedCard> playedCards;
  final List<Player> players;
  final _BoardMetrics metrics;

  const _SquareTable({
    required this.playedCards,
    required this.players,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ZapitiColors.tableGreen,
        borderRadius: BorderRadius.circular(metrics.gap * 2.2),
        border: Border.all(
          color: ZapitiColors.oldGold,
          width: max(metrics.gap * 0.32, 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: metrics.gap * 2.8,
            offset: Offset(0, metrics.gap),
          ),
          BoxShadow(
            color: ZapitiColors.oldGold.withValues(alpha: 0.16),
            blurRadius: metrics.gap * 1.6,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final played in playedCards)
            Transform.translate(
              offset: metrics.playedCardOffsetFor(played.player, players),
              child: ZapitiCardWidget(
                card: played.card,
                width: metrics.playedCardWidth,
              ),
            ),
        ],
      ),
    );
  }
}
