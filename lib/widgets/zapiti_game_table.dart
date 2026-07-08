import 'dart:math';

import 'package:flutter/material.dart';

import '../domain/character_assets.dart';
import '../domain/played_card.dart';
import '../domain/player.dart';
import '../domain/spanish_card.dart';
import '../theme/zapiti_theme.dart';
import 'avatar_with_silhouette.dart';
import 'zapiti_card_widget.dart';
import 'zapiti_speech_bubble.dart';

part 'zapiti_game_table_parts.dart';
part 'zapiti_game_table_surface.dart';
part 'zapiti_game_table_seats.dart';

class ZapitiGameTable extends StatelessWidget {
  final double height;
  final List<Player> players;
  final Player currentPlayer;
  final List<SpanishCard> humanHand;
  final List<PlayedCard> playedCards;
  final Map<String, String> playerMessages;
  final Map<String, String> characterIdsByPlayer;
  final Map<String, int> cardsRemaining;
  final bool isHumanTurn;
  final bool showHumanSeat;
  final ValueChanged<SpanishCard> onPlayCard;

  const ZapitiGameTable({
    super.key,
    required this.height,
    required this.players,
    required this.currentPlayer,
    required this.humanHand,
    required this.playedCards,
    required this.playerMessages,
    required this.characterIdsByPlayer,
    required this.cardsRemaining,
    required this.isHumanTurn,
    this.showHumanSeat = true,
    required this.onPlayCard,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _BoardMetrics.from(
          Size(constraints.maxWidth, height),
          reserveHumanSeat: showHumanSeat,
        );
        final bottomPlayer = players[0];
        final rightPlayer = players[1];
        final topPlayer = players[2];
        final leftPlayer = players[3];

        return SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fromRect(
                rect: metrics.tableRect,
                child: _SquareTable(
                  playedCards: playedCards,
                  players: players,
                  metrics: metrics,
                ),
              ),
              Positioned.fromRect(
                rect: metrics.seatRect(_SeatPosition.top),
                child: _OpponentSeat(
                  position: _SeatPosition.top,
                  isCurrent: topPlayer.id == currentPlayer.id,
                  cardsRemaining: cardsRemaining[topPlayer.id] ?? 0,
                  message: playerMessages[topPlayer.id],
                  characterId:
                      characterIdsByPlayer[topPlayer.id] ?? topPlayer.id,
                  metrics: metrics,
                ),
              ),
              Positioned.fromRect(
                rect: metrics.seatRect(_SeatPosition.left),
                child: _OpponentSeat(
                  position: _SeatPosition.left,
                  isCurrent: leftPlayer.id == currentPlayer.id,
                  cardsRemaining: cardsRemaining[leftPlayer.id] ?? 0,
                  message: playerMessages[leftPlayer.id],
                  characterId:
                      characterIdsByPlayer[leftPlayer.id] ?? leftPlayer.id,
                  metrics: metrics,
                ),
              ),
              Positioned.fromRect(
                rect: metrics.seatRect(_SeatPosition.right),
                child: _OpponentSeat(
                  position: _SeatPosition.right,
                  isCurrent: rightPlayer.id == currentPlayer.id,
                  cardsRemaining: cardsRemaining[rightPlayer.id] ?? 0,
                  message: playerMessages[rightPlayer.id],
                  characterId:
                      characterIdsByPlayer[rightPlayer.id] ?? rightPlayer.id,
                  metrics: metrics,
                ),
              ),
              if (showHumanSeat)
                Positioned.fromRect(
                  rect: metrics.seatRect(_SeatPosition.bottom),
                  child: _HumanSeat(
                    isCurrent: bottomPlayer.id == currentPlayer.id,
                    message: playerMessages[bottomPlayer.id],
                    characterId: characterIdsByPlayer[bottomPlayer.id] ??
                        bottomPlayer.id,
                    cards: humanHand,
                    enabled: isHumanTurn,
                    metrics: metrics,
                    onPlayCard: onPlayCard,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
