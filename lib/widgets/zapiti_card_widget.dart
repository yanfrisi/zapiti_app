import 'package:flutter/material.dart';

import '../domain/spanish_card.dart';
import '../domain/suit.dart';
import '../theme/zapiti_theme.dart';

class ZapitiCardWidget extends StatelessWidget {
  final SpanishCard? card;
  final bool hidden;
  final VoidCallback? onTap;
  final bool enabled;
  final double width;
  final double? height;

  const ZapitiCardWidget({
    super.key,
    required this.card,
    this.hidden = false,
    this.onTap,
    this.enabled = true,
    this.width = 82,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && onTap != null;
    final assetPath = _assetPath;
    final fallbackCard = _FallbackCardFace(card: card, hidden: hidden);

    return Semantics(
      button: canTap,
      label: hidden ? 'Carta tapada' : card?.toString() ?? 'Hueco vacio',
      child: InkWell(
        onTap: canTap ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: enabled ? 1 : 0.55,
          child: SizedBox(
            width: width,
            height: height,
            child: AspectRatio(
              aspectRatio: 80 / 122,
              child: Container(
                decoration: BoxDecoration(
                  color: card == null && !hidden
                      ? Colors.white.withValues(alpha: 0.08)
                      : ZapitiColors.cardCream,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ZapitiColors.darkBrown.withValues(alpha: 0.35),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: assetPath == null
                      ? const _EmptyCardContent()
                      : Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, __, ___) => fallbackCard,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? get _assetPath {
    if (hidden) return 'assets/cards/back.png';
    final visibleCard = card;
    if (visibleCard == null) return null;
    return 'assets/cards/${visibleCard.value}_${visibleCard.suit.label}.png';
  }
}

class _FallbackCardFace extends StatelessWidget {
  final SpanishCard? card;
  final bool hidden;

  const _FallbackCardFace({
    required this.card,
    required this.hidden,
  });

  @override
  Widget build(BuildContext context) {
    if (hidden) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: ZapitiColors.wineRed,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Center(
          child: Icon(
            Icons.style,
            color: ZapitiColors.cardCream.withValues(alpha: 0.86),
            size: 28,
          ),
        ),
      );
    }

    final visibleCard = card;
    if (visibleCard == null) {
      return const _EmptyCardContent();
    }

    return Container(
      color: ZapitiColors.cardCream,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                visibleCard.rankLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: ZapitiColors.wineRed,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Icon(
                _iconForSuit(visibleCard.suit),
                color: ZapitiColors.darkBrown,
                size: 26,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                visibleCard.suit.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ZapitiColors.darkBrown,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForSuit(Suit suit) {
    switch (suit) {
      case Suit.copas:
        return Icons.favorite;
      case Suit.oros:
        return Icons.circle;
      case Suit.espadas:
        return Icons.flash_on;
      case Suit.bastos:
        return Icons.grass;
    }
  }
}

class _EmptyCardContent extends StatelessWidget {
  const _EmptyCardContent();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.style_outlined,
        color: ZapitiColors.cardCream.withValues(alpha: 0.42),
      ),
    );
  }
}
