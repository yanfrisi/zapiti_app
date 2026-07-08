part of 'zapiti_game_table.dart';

enum _BubblePosition { above, right }

double _bubbleScaleForAvatarHeight(double avatarHeight) {
  return (avatarHeight / 180).clamp(0.46, 0.9).toDouble();
}

class _OpponentSeat extends StatelessWidget {
  final _SeatPosition position;
  final bool isCurrent;
  final int cardsRemaining;
  final String? message;
  final String characterId;
  final _BoardMetrics metrics;

  const _OpponentSeat({
    required this.position,
    required this.isCurrent,
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
        message: message,
        characterId: characterId,
        height: height,
        width: width,
        gap: metrics.gap,
        compact: compact,
        bubblePosition:
            position == _SeatPosition.top ? _BubblePosition.right : _BubblePosition.above,
        showBubble: showBubble,
      );
    }

    if (position == _SeatPosition.top) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final avatarHeight = min(
            metrics.companionAvatarHeight,
            constraints.maxHeight * 0.94,
          );
          final verticalLift =
              metrics.portrait ? 0.0 : metrics.companionAvatarHeight * 0.22;
          final companionCards = _HiddenCards(
            count: cardsRemaining,
            horizontal: true,
            cardWidth: metrics.companionCardWidth,
            gap: metrics.gap,
          );
          final visibleMessage = _visibleMessageFrom(message);
          final hiddenCardsWidth =
              metrics.companionCardWidth * 3 + metrics.gap * 0.8 * 2;
          final contentWidth = metrics.companionCardWidth +
              metrics.gap * 1.4 +
              hiddenCardsWidth;
          final contentLeft = (constraints.maxWidth - contentWidth) / 2;
          final firstCardLeft =
              contentLeft + metrics.companionCardWidth + metrics.gap * 1.4;
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: Offset(0, -verticalLift),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          avatarFor(
                            avatarHeight,
                            width: metrics.companionCardWidth,
                            showBubble: false,
                          ),
                          SizedBox(width: metrics.gap * 1.4),
                          companionCards,
                        ],
                      ),
                    ),
                  ),
                ),
                if (visibleMessage != null)
                  Positioned(
                    left: firstCardLeft,
                    top: max(0.0, -verticalLift + avatarHeight * 0.04),
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
        final avatarHeight = min(metrics.avatarHeight, constraints.maxHeight);
        final avatarWidth =
            min(metrics.opponentCardWidth, constraints.maxWidth);
        final sideCards = _HiddenCards(
          count: cardsRemaining,
          horizontal: !metrics.portrait,
          cardWidth: min(
            metrics.opponentCardWidth,
            constraints.maxWidth,
          ),
          gap: metrics.gap,
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
                      SizedBox(width: metrics.gap * 1.2),
                      avatar,
                      SizedBox(width: metrics.gap * 1.2),
                      sideCards,
                    ],
                  ),
                _SeatPosition.left => Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      sideCards,
                      SizedBox(width: metrics.gap * 1.2),
                      avatar,
                      SizedBox(width: metrics.gap * 1.2),
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
    if (value.startsWith('Sena: ')) return null;
    return value;
  }
}

class _HumanSeat extends StatelessWidget {
  final bool isCurrent;
  final String? message;
  final String characterId;
  final List<SpanishCard> cards;
  final bool enabled;
  final _BoardMetrics metrics;
  final ValueChanged<SpanishCard> onPlayCard;

  const _HumanSeat({
    required this.isCurrent,
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
    final spacing = gap * 0.8;

    if (horizontal) {
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
  final String? message;
  final String characterId;
  final double height;
  final double? width;
  final double gap;
  final bool compact;
  final _BubblePosition bubblePosition;
  final bool showBubble;

  const _SeatAvatar({
    required this.isCurrent,
    required this.message,
    required this.characterId,
    required this.height,
    this.width,
    required this.gap,
    this.compact = false,
    this.bubblePosition = _BubblePosition.above,
    this.showBubble = true,
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
          ],
        ),
      );
    }

    return SizedBox(
      width: effectiveWidth * 1.45,
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
        ],
      ),
    );
  }

  String? _signalFromMessage(String? message) {
    const prefix = 'Sena: ';
    if (message == null) return null;
    if (message.startsWith(prefix)) return message.substring(prefix.length);

    final separatorIndex = message.indexOf(': ');
    if (separatorIndex == -1 || !message.toLowerCase().startsWith('se')) {
      return null;
    }
    return message.substring(separatorIndex + 2);
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
      'Mala' => 0.13,
      _ => 0,
    };
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

  const _PlayerAvatar({
    required this.assetPath,
    required this.highlighted,
    required this.width,
    required this.height,
    required this.mirror,
    required this.verticalOffset,
    required this.radius,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: radius,
                offset: Offset(0, radius * 0.45),
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(mirror ? -1 : 1, 1, 1),
              child: Transform.translate(
                offset: Offset(0, verticalOffset),
                child: Image.asset(
                  assetPath,
                  key: ValueKey(assetPath),
                  width: width,
                  height: height,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (_, __, ___) {
                    return Icon(
                      Icons.person,
                      color: ZapitiColors.darkBrown.withValues(alpha: 0.7),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
