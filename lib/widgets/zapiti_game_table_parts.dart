part of 'zapiti_game_table.dart';

enum _SeatPosition { top, right, bottom, left }

class RemotePlayerVisualMetrics {
  final double avatarWidth;
  final double avatarHeight;
  final double cardWidth;
  final double cardHeight;
  final double cardGap;
  final double avatarCardGap;

  const RemotePlayerVisualMetrics({
    required this.avatarWidth,
    required this.avatarHeight,
    required this.cardWidth,
    required this.cardHeight,
    required this.cardGap,
    required this.avatarCardGap,
  });
}

class _BoardMetrics {
  final Size size;
  final bool portrait;
  final double gap;
  final Rect tableRect;
  final double tableSide;
  final double avatarHeight;
  final double opponentCardWidth;
  final double companionCardWidth;
  final double companionAvatarHeight;
  final RemotePlayerVisualMetrics remotePlayer;
  final double humanCardWidth;
  final double humanCardHeight;
  final double playedCardWidth;

  const _BoardMetrics({
    required this.size,
    required this.portrait,
    required this.gap,
    required this.tableRect,
    required this.tableSide,
    required this.avatarHeight,
    required this.opponentCardWidth,
    required this.companionCardWidth,
    required this.companionAvatarHeight,
    required this.remotePlayer,
    required this.humanCardWidth,
    required this.humanCardHeight,
    required this.playedCardWidth,
  });

  factory _BoardMetrics.from(
    Size size, {
    bool reserveHumanSeat = true,
  }) {
    final portrait = size.height >= size.width;
    final shortest = min(size.width, size.height);
    final gap = shortest * 0.012;
    final availableWidthForHand = (size.width - gap * 3) / 4;
    final humanCardWidth = portrait
        ? min(
            availableWidthForHand,
            min(size.height * 0.3, shortest * 0.34),
          )
        : min(
            availableWidthForHand,
            min(size.height * 0.24, size.width * 0.108),
          );
    final humanCardHeight = humanCardWidth * 122 / 80;
    final baseRemoteCardWidth = portrait
        ? min(humanCardWidth * 0.72, shortest * 0.24)
        : min(size.height * 0.28, size.width * 0.102)
            .clamp(38.0, 56.0)
            .toDouble();
    final remotePlayerScaleFactor =
        portrait ? 1.0 : (size.width < 760 || size.height < 170 ? 1.7 : 2.0);
    final companionCardWidth = portrait
        ? baseRemoteCardWidth
        : (baseRemoteCardWidth * remotePlayerScaleFactor)
            .clamp(64.0, 104.0)
            .toDouble();
    final opponentCardWidth = portrait
        ? min(humanCardWidth * 0.68, shortest * 0.23)
        : companionCardWidth;
    final opponentCardHeight = opponentCardWidth * 122 / 80;
    final companionAvatarHeight = portrait
        ? companionCardWidth * 122 / 80
        : (companionCardWidth * 78 / 44).clamp(104.0, 164.0).toDouble();
    final remotePlayer = RemotePlayerVisualMetrics(
      avatarWidth: portrait
          ? companionCardWidth
          : (companionCardWidth * 52 / 44).clamp(76.0, 124.0).toDouble(),
      avatarHeight: companionAvatarHeight,
      cardWidth: companionCardWidth,
      cardHeight: opponentCardHeight,
      cardGap: portrait ? gap : max(gap * 1.45, 5.0),
      avatarCardGap: portrait ? gap * 1.4 : max(gap * 2.2, 8.0),
    );
    final tableSize = portrait
        ? Size.square(
            _portraitTableSide(
              size: size,
              seatCardWidth: opponentCardWidth,
              verticalSeatHeight: max(humanCardHeight, companionAvatarHeight),
              gap: gap,
              shortest: shortest,
            ),
          )
        : _landscapeTableSize(
            size: size,
            humanCardWidth: humanCardWidth,
            opponentCardWidth: opponentCardWidth,
            gap: gap,
            shortest: shortest,
            reserveHumanSeat: reserveHumanSeat,
          );
    final tableCenter = _tableCenter(
      size: size,
      tableSize: tableSize,
      portrait: portrait,
      bottomSeatHeight: reserveHumanSeat ? humanCardHeight : 0,
      gap: gap,
    );
    final tableRect = Rect.fromCenter(
      center: tableCenter,
      width: tableSize.width,
      height: tableSize.height,
    );
    final tableSide = min(tableSize.width, tableSize.height);
    final avatarHeight = opponentCardHeight;
    final playedCardWidth = portrait
        ? tableSide * 0.27
        : min(tableRect.height * 0.36, tableRect.width * 0.16);

    return _BoardMetrics(
      size: size,
      portrait: portrait,
      gap: gap,
      tableRect: tableRect,
      tableSide: tableSide,
      avatarHeight: avatarHeight,
      opponentCardWidth: opponentCardWidth,
      companionCardWidth: companionCardWidth,
      companionAvatarHeight: companionAvatarHeight,
      remotePlayer: remotePlayer,
      humanCardWidth: humanCardWidth,
      humanCardHeight: humanCardHeight,
      playedCardWidth: playedCardWidth,
    );
  }

  static double _portraitTableSide({
    required Size size,
    required double seatCardWidth,
    required double verticalSeatHeight,
    required double gap,
    required double shortest,
  }) {
    final topBottomMargin = verticalSeatHeight + gap * 2.4;
    final sideMargin = seatCardWidth + gap * 2.4;
    return min(
      size.width - sideMargin * 2,
      size.height - topBottomMargin * 2,
    ).clamp(seatCardWidth * 1.2, shortest * 0.85).toDouble();
  }

  static Size _landscapeTableSize({
    required Size size,
    required double humanCardWidth,
    required double opponentCardWidth,
    required double gap,
    required double shortest,
    required bool reserveHumanSeat,
  }) {
    final humanCardHeight = humanCardWidth * 122 / 80;
    final topSeatReserve = gap * 1.2;
    final bottomSeatReserve =
        reserveHumanSeat ? humanCardHeight + gap * 2.4 : gap * 1.2;
    final sideSeatReserve = opponentCardWidth * 4.35 + gap * 4.2;
    final availableHeight = max(
      humanCardWidth * 1.35,
      size.height - topSeatReserve - bottomSeatReserve,
    );
    final availableWidth = max(
      humanCardWidth * 1.9,
      size.width - sideSeatReserve * 2 - gap * 2,
    );
    final tableHeight = min(
      availableHeight,
      shortest * 1.04,
    ).clamp(humanCardWidth * 1.35, shortest * 1.08).toDouble();
    final tableWidth = min(
      availableWidth,
      tableHeight * 2.36,
    ).clamp(tableHeight, size.width - gap * 2).toDouble();

    return Size(tableWidth, tableHeight);
  }

  static Offset _tableCenter({
    required Size size,
    required Size tableSize,
    required bool portrait,
    required double bottomSeatHeight,
    required double gap,
  }) {
    if (portrait) return size.center(Offset.zero);

    final minY = tableSize.height / 2 + gap * 0.8;
    final maxY = size.height - tableSize.height / 2 - bottomSeatHeight - gap;
    final desiredY = minY + (maxY - minY) * 0.68;
    final y = minY <= maxY
        ? desiredY.clamp(minY, maxY).toDouble()
        : (minY + maxY) / 2;

    return Offset(
      size.width / 2,
      y,
    );
  }

  Rect seatRect(_SeatPosition position) {
    final topSeatHeight = companionAvatarHeight + gap * 4.2;
    final topSeatContentWidth = companionCardWidth * 4.55 + gap * 4.2;
    final topSeatWidth = min(
      size.width - gap * 2,
      max(topSeatContentWidth, tableRect.width + gap * 1.6),
    );
    final topSeatLeft = (tableRect.center.dx - topSeatWidth / 2)
        .clamp(gap, size.width - topSeatWidth - gap);
    final topSeatTop = portrait
        ? max(0.0, tableRect.top - topSeatHeight - gap)
        : -topSeatHeight * 0.33;
    final sideWidth = portrait
        ? max(
            opponentCardWidth * 1.95 + gap * 2.4,
            size.width * 0.2,
          )
        : max(
            opponentCardWidth * 4.2 + gap * 3,
            tableRect.left - gap,
          );
    final opponentCardHeight = opponentCardWidth * 122 / 80;
    final sideHeight = portrait
        ? max(tableSide * 1.04, opponentCardHeight * 3 + gap * 4.2)
        : avatarHeight + gap * 2;
    final bottomHeight = size.height - tableRect.bottom - gap;
    final bottomContentWidth = humanCardWidth * 4.35 + gap * 3.6;
    final bottomWidth = portrait
        ? size.width - gap * 2
        : min(
            size.width - gap * 2,
            max(bottomContentWidth, tableRect.width + gap * 1.8),
          );
    final bottomLeft = portrait
        ? gap
        : (tableRect.center.dx - bottomWidth / 2)
            .clamp(gap, size.width - bottomWidth - gap);

    return switch (position) {
      _SeatPosition.top => Rect.fromLTWH(
          topSeatLeft.toDouble(),
          topSeatTop.toDouble(),
          topSeatWidth,
          topSeatHeight,
        ),
      _SeatPosition.bottom => Rect.fromLTWH(
          bottomLeft.toDouble(),
          tableRect.bottom + gap,
          bottomWidth,
          bottomHeight,
        ),
      _SeatPosition.left => Rect.fromLTWH(
          0,
          tableRect.center.dy - sideHeight / 2,
          max(0.0, min(sideWidth, tableRect.left - gap)).toDouble(),
          sideHeight,
        ),
      _SeatPosition.right => Rect.fromLTWH(
          tableRect.right + gap,
          tableRect.center.dy - sideHeight / 2,
          max(0.0, size.width - tableRect.right - gap),
          sideHeight,
        ),
    };
  }

  Offset playedCardOffsetFor(Player player, List<Player> players) {
    final index = players.indexWhere((candidate) => candidate.id == player.id);
    final resolvedIndex = index < 0 ? 0 : index;
    return switch (resolvedIndex) {
      0 => Offset(0, tableRect.height * 0.17),
      1 => Offset(tableRect.width * 0.18, 0),
      2 => Offset(0, -tableRect.height * 0.17),
      _ => Offset(-tableRect.width * 0.18, 0),
    };
  }
}
