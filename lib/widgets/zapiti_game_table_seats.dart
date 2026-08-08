part of 'zapiti_game_table.dart';

enum _BubblePosition { above, right }

double _bubbleScaleForAvatarHeight(double avatarHeight) {
  return (avatarHeight / 180).clamp(0.46, 0.9).toDouble();
}

String? _extractSignalMessage(String? message) {
  if (message == null) return null;
  const prefix = 'SeÃ±a: ';
  if (message.startsWith(prefix)) {
    return message.substring(prefix.length);
  }

  final separatorIndex = message.indexOf(': ');
  if (separatorIndex == -1 || !message.toLowerCase().startsWith('se')) {
    return null;
  }
  return message.substring(separatorIndex + 2);
}

class _OpponentSeat extends StatelessWidget {
  final _SeatPosition position;
  final String playerName;
  final bool isCurrent;
  final int? turnSecondsRemaining;
  final int cardsRemaining;
  final String? message;
  final String characterId;
  final _BoardMetrics metrics;

  const _OpponentSeat({
    required this.position,
    required this.playerName,
    required this.isCurrent,
    required this.turnSecondsRemaining,
    required this.cardsRemaining,
    required this.message,
    required this.characterId,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarFor(
      double height, {
      bool compact = false,
      double? width,
      bool showBubble = true,
    }) {
      return _SeatAvatar(
        isCurrent: isCurrent,
        turnSecondsRemaining: turnSecondsRemaining,
        playerName: playerName,
        message: message,
        characterId: characterId,
        height: height,
        width: width,
        gap: metrics.gap,
        compact: compact,
        bubblePosition: position == _SeatPosition.top
            ? _BubblePosition.right
            : _BubblePosition.above,
        showBubble: showBubble,
        teammateAccent: position == _SeatPosition.left,
      );
    }

    if (position == _SeatPosition.top) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final avatarHeight = min(
            metrics.remotePlayer.avatarHeight,
            constraints.maxHeight * 0.94,
          );
          final companionCards = _HiddenCards(
            count: cardsRemaining,
            horizontal: true,
            cardWidth: metrics.remotePlayer.cardWidth,
            gap: metrics.remotePlayer.cardGap,
          );
          final visibleMessage = _visibleMessageFrom(message);
          final remoteAvatarWidth = metrics.portrait
              ? metrics.companionCardWidth
              : min(
                  metrics.remotePlayer.avatarWidth,
                  constraints.maxWidth,
                );
          final hiddenCardsWidth = metrics.remotePlayer.cardWidth * 3 +
              metrics.remotePlayer.cardGap * 2;
          final contentWidth = remoteAvatarWidth +
              metrics.remotePlayer.avatarCardGap +
              hiddenCardsWidth;
          final contentLeft = (constraints.maxWidth - contentWidth) / 2;
          final firstCardLeft = contentLeft +
              remoteAvatarWidth +
              metrics.remotePlayer.avatarCardGap;
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        avatarFor(
                          avatarHeight,
                          width: remoteAvatarWidth,
                          showBubble: false,
                        ),
                        SizedBox(width: metrics.remotePlayer.avatarCardGap),
                        companionCards,
                      ],
                    ),
                  ),
                ),
                if (visibleMessage != null)
                  Positioned(
                    left: firstCardLeft,
                    top: max(0.0, avatarHeight * 0.04),
                    child: ZapitiSpeechBubble(
                      text: visibleMessage,
                      alignment: TextAlign.center,
                      scale: _bubbleScaleForAvatarHeight(avatarHeight),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final avatarHeight =
            min(metrics.remotePlayer.avatarHeight, constraints.maxHeight);
        final avatarWidth = metrics.portrait
            ? min(metrics.opponentCardWidth, constraints.maxWidth)
            : min(
                metrics.remotePlayer.avatarWidth,
                constraints.maxWidth,
              );
        final sideCards = _HiddenCards(
          count: cardsRemaining,
          horizontal: !metrics.portrait,
          cardWidth: min(
            metrics.remotePlayer.cardWidth,
            constraints.maxWidth,
          ),
          gap: metrics.remotePlayer.cardGap,
        );
        final avatar = avatarFor(
          avatarHeight,
          width: avatarWidth,
        );
        final child = metrics.portrait
            ? switch (position) {
                _SeatPosition.right => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: metrics.gap * 0.7),
                      avatar,
                      SizedBox(height: metrics.gap * 0.7),
                      sideCards,
                    ],
                  ),
                _SeatPosition.left => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      sideCards,
                      SizedBox(height: metrics.gap * 0.7),
                      avatar,
                      SizedBox(height: metrics.gap * 0.7),
                    ],
                  ),
                _ => const SizedBox.shrink(),
              }
            : switch (position) {
                _SeatPosition.right => Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      avatar,
                      SizedBox(width: metrics.remotePlayer.avatarCardGap),
                      sideCards,
                    ],
                  ),
                _SeatPosition.left => Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      sideCards,
                      SizedBox(width: metrics.remotePlayer.avatarCardGap),
                      avatar,
                    ],
                  ),
                _ => const SizedBox.shrink(),
              };

        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          alignment: position == _SeatPosition.left
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: FittedBox(
            alignment: position == _SeatPosition.left
                ? Alignment.centerRight
                : Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: child,
          ),
        );
      },
    );
  }

  String? _visibleMessageFrom(String? value) {
    if (value == null) return null;
    if (_extractSignalMessage(value) != null) return null;
    return value;
  }
}

class _HumanSeat extends StatelessWidget {
  final String playerName;
  final bool isCurrent;
  final int? turnSecondsRemaining;
  final String? message;
  final String characterId;
  final List<SpanishCard> cards;
  final bool enabled;
  final _BoardMetrics metrics;
  final ValueChanged<SpanishCard> onPlayCard;

  const _HumanSeat({
    required this.playerName,
    required this.isCurrent,
    required this.turnSecondsRemaining,
    required this.message,
    required this.characterId,
    required this.cards,
    required this.enabled,
    required this.metrics,
    required this.onPlayCard,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = min(
          metrics.humanCardWidth,
          max(0.0, (constraints.maxWidth - metrics.gap * 3.6) / 4.35),
        );
        final cardHeight = cardWidth * 122 / 80;
        final contentWidth = cardWidth * 4 + metrics.gap * 3.2;
        final avatar = _SeatAvatar(
          isCurrent: isCurrent,
          turnSecondsRemaining: turnSecondsRemaining,
          playerName: playerName,
          message: message,
          characterId: characterId,
          height: cardHeight,
          width: cardWidth,
          gap: metrics.gap,
          compact: true,
        );
        final hand = _HumanHand(
          cards: cards,
          enabled: enabled,
          cardWidth: cardWidth,
          gap: metrics.gap,
          onPlayCard: onPlayCard,
        );

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: contentWidth,
              height: cardHeight,
              child: Row(
                children: [
                  hand,
                  SizedBox(width: metrics.gap * 1.2),
                  SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: avatar,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HumanHand extends StatelessWidget {
  final List<SpanishCard> cards;
  final bool enabled;
  final double cardWidth;
  final double gap;
  final ValueChanged<SpanishCard> onPlayCard;

  const _HumanHand({
    required this.cards,
    required this.enabled,
    required this.cardWidth,
    required this.gap,
    required this.onPlayCard,
  });

  @override
  Widget build(BuildContext context) {
    const slots = 3;
    final cardHeight = cardWidth * 122 / 80;

    return SizedBox(
      width: cardWidth * slots + gap * (slots - 1),
      height: cardHeight,
      child: Row(
        children: [
          for (var index = 0; index < slots; index++) ...[
            SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: index < cards.length
                  ? ZapitiCardWidget(
                      card: cards[index],
                      width: cardWidth,
                      enabled: enabled,
                      onTap: () => onPlayCard(cards[index]),
                    )
                  : ZapitiCardWidget(
                      card: null,
                      width: cardWidth,
                      enabled: false,
                    ),
            ),
            if (index != slots - 1) SizedBox(width: gap),
          ],
        ],
      ),
    );
  }
}

class _HiddenCards extends StatelessWidget {
  final int count;
  final bool horizontal;
  final double cardWidth;
  final double gap;

  const _HiddenCards({
    required this.count,
    required this.horizontal,
    required this.cardWidth,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    final visibleCount = count.clamp(0, 3);
    const slots = 3;
    final cardHeight = cardWidth * 122 / 80;
    final spacing = gap;

    if (horizontal) {
      if (spacing < 0) {
        final cardStride = cardWidth + spacing;
        final totalWidth = cardWidth + cardStride * (slots - 1);

        return SizedBox(
          width: totalWidth,
          height: cardHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var index = 0; index < slots; index++)
                Positioned(
                  left: cardStride * index,
                  top: 0,
                  child: index < visibleCount
                      ? ZapitiCardWidget(
                          card: null,
                          hidden: true,
                          width: cardWidth,
                        )
                      : ZapitiCardWidget(card: null, width: cardWidth),
                ),
            ],
          ),
        );
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < slots; index++) ...[
            if (index < visibleCount)
              ZapitiCardWidget(card: null, hidden: true, width: cardWidth)
            else
              ZapitiCardWidget(card: null, width: cardWidth),
            if (index != slots - 1) SizedBox(width: spacing),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < slots; index++) ...[
          SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: index < visibleCount
                ? ZapitiCardWidget(card: null, hidden: true, width: cardWidth)
                : ZapitiCardWidget(card: null, width: cardWidth),
          ),
          if (index != slots - 1) SizedBox(height: spacing),
        ],
      ],
    );
  }
}

class _SeatAvatar extends StatelessWidget {
  final bool isCurrent;
  final int? turnSecondsRemaining;
  final String playerName;
  final String? message;
  final String characterId;
  final double height;
  final double? width;
  final double gap;
  final bool compact;
  final _BubblePosition bubblePosition;
  final bool showBubble;
  final bool teammateAccent;

  const _SeatAvatar({
    required this.isCurrent,
    required this.turnSecondsRemaining,
    required this.playerName,
    required this.message,
    required this.characterId,
    required this.height,
    this.width,
    required this.gap,
    this.compact = false,
    this.bubblePosition = _BubblePosition.above,
    this.showBubble = true,
    this.teammateAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final signal = _signalFromMessage(message);
    final avatarPath = CharacterAssets.frontForSignal(characterId, signal);
    final visibleMessage = signal == null ? message : null;
    final mirrorAvatar = signal == '7 Oros';
    final effectiveWidth = width ?? height * 80 / 122;
    final avatarVerticalOffset = height * _signalVerticalOffset(signal);

    if (compact) {
      return SizedBox(
        width: effectiveWidth,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(
              child: _PlayerAvatar(
                assetPath: avatarPath,
                highlighted: isCurrent,
                width: effectiveWidth,
                height: height,
                mirror: mirrorAvatar,
                verticalOffset: avatarVerticalOffset,
                radius: gap * 0.9,
                teammateAccent: teammateAccent,
              ),
            ),
            if (showBubble && visibleMessage != null)
              _PositionedBubble(
                position: bubblePosition,
                avatarHeight: height,
                avatarWidth: effectiveWidth,
                gap: gap,
                text: visibleMessage,
              ),
            if (turnSecondsRemaining != null)
              _PositionedTurnTimer(
                seconds: turnSecondsRemaining!,
                avatarWidth: effectiveWidth,
                gap: gap,
                compact: true,
              ),
            ZapitiPlayerNameBadge(
              playerName: playerName,
              avatarWidth: effectiveWidth,
              gap: gap,
              compact: true,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: effectiveWidth,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: _PlayerAvatar(
              assetPath: avatarPath,
              highlighted: isCurrent,
              width: effectiveWidth,
              height: height,
              mirror: mirrorAvatar,
              verticalOffset: avatarVerticalOffset,
              radius: gap * 0.9,
              teammateAccent: teammateAccent,
            ),
          ),
          if (showBubble && visibleMessage != null)
            _PositionedBubble(
              position: bubblePosition,
              avatarHeight: height,
              avatarWidth: effectiveWidth,
              gap: gap,
              text: visibleMessage,
            ),
          if (turnSecondsRemaining != null)
            _PositionedTurnTimer(
              seconds: turnSecondsRemaining!,
              avatarWidth: effectiveWidth,
              gap: gap,
            ),
          ZapitiPlayerNameBadge(
            playerName: playerName,
            avatarWidth: effectiveWidth,
            gap: gap,
          ),
        ],
      ),
    );
  }

  String? _signalFromMessage(String? message) {
    return _extractSignalMessage(message);
  }

  double _signalVerticalOffset(String? signal) {
    return switch (signal) {
      null => 0,
      '4 Bastos' => 0,
      '7 Copas' => 0,
      '7 Oros' => 0,
      'As Espadas' => 0.13,
      'Treses' => 0.15,
      'Doses' => 0.15,
      'Ases' => 0,
      'Mala' => 0.13,
      _ => 0,
    };
  }
}

class ZapitiPlayerNameBadge extends StatelessWidget {
  final String playerName;
  final double avatarWidth;
  final double gap;
  final bool compact;

  const ZapitiPlayerNameBadge({
    super.key,
    required this.playerName,
    required this.avatarWidth,
    required this.gap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = (avatarWidth * (compact ? 0.14 : 0.13))
        .clamp(8.0, compact ? 11.0 : 12.0)
        .toDouble();
    return Positioned(
      left: max(2.0, gap * 0.38),
      right: max(2.0, gap * 0.38),
      top: max(2.0, gap * 0.38),
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xDD2A170F),
            borderRadius: BorderRadius.circular(max(4.0, gap * 0.7)),
            border: Border.all(
              color: ZapitiColors.oldGold.withValues(alpha: 0.58),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: max(3.0, gap * 0.7),
              vertical: max(1.5, gap * 0.24),
            ),
            child: Text(
              playerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ZapitiColors.cardCream,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PositionedTurnTimer extends StatelessWidget {
  final int seconds;
  final double avatarWidth;
  final double gap;
  final bool compact;

  const _PositionedTurnTimer({
    required this.seconds,
    required this.avatarWidth,
    required this.gap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final urgent = seconds <= 5;
    final fontSize = (avatarWidth * (compact ? 0.16 : 0.15))
        .clamp(9.0, compact ? 12.0 : 13.0)
        .toDouble();
    final iconSize = (fontSize + 2).clamp(11.0, 16.0).toDouble();

    return Positioned(
      right: -max(4.0, gap * 0.35),
      bottom: max(4.0, gap * 0.45),
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: urgent
                ? ZapitiColors.wineRed.withValues(alpha: 0.94)
                : const Color(0xE62A170F),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: urgent ? ZapitiColors.oldGold : ZapitiColors.cardCream,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: max(4.0, gap * 0.8),
                offset: Offset(0, max(1.0, gap * 0.25)),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: max(5.0, gap * 0.75),
              vertical: max(2.5, gap * 0.35),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: iconSize,
                  color: ZapitiColors.cardCream,
                ),
                SizedBox(width: max(2.0, gap * 0.28)),
                Text(
                  '${seconds}s',
                  maxLines: 1,
                  style: TextStyle(
                    color: ZapitiColors.cardCream,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PositionedBubble extends StatelessWidget {
  final _BubblePosition position;
  final double avatarHeight;
  final double avatarWidth;
  final double gap;
  final String text;

  const _PositionedBubble({
    required this.position,
    required this.avatarHeight,
    required this.avatarWidth,
    required this.gap,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = ZapitiSpeechBubble(
      text: text,
      alignment: TextAlign.center,
      scale: _bubbleScaleForAvatarHeight(avatarHeight),
    );

    return switch (position) {
      _BubblePosition.above => Positioned(
          bottom: avatarHeight + gap * 0.45,
          child: bubble,
        ),
      _BubblePosition.right => Positioned(
          left: avatarWidth + gap * 0.8,
          top: -avatarHeight * 0.58,
          child: bubble,
        ),
    };
  }
}

class _PlayerAvatar extends StatelessWidget {
  final String assetPath;
  final bool highlighted;
  final double width;
  final double height;
  final bool mirror;
  final double verticalOffset;
  final double radius;
  final bool teammateAccent;

  const _PlayerAvatar({
    required this.assetPath,
    required this.highlighted,
    required this.width,
    required this.height,
    required this.mirror,
    required this.verticalOffset,
    required this.radius,
    this.teammateAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: highlighted ? 1.04 : 1,
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xCC2A170F),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: teammateAccent
                  ? Colors.lightBlueAccent.withValues(alpha: 0.78)
                  : ZapitiColors.oldGold.withValues(alpha: 0.54),
              width: teammateAccent
                  ? max(1.4, radius * 0.16)
                  : max(1.0, radius * 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: radius,
                offset: Offset(0, radius * 0.45),
              ),
              if (teammateAccent)
                BoxShadow(
                  color: Colors.lightBlueAccent.withValues(alpha: 0.32),
                  blurRadius: radius * 1.7,
                ),
            ],
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AvatarWithSilhouette(
              assetPath: assetPath,
              width: width,
              height: height,
              mirror: mirror,
              offset: Offset(0, verticalOffset),
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, __, ___) {
                return Icon(
                  Icons.person,
                  color: ZapitiColors.cardCream.withValues(alpha: 0.82),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
