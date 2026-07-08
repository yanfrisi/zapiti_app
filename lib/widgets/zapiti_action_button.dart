import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/zapiti_theme.dart';

class ZapitiActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool circular;

  const ZapitiActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.circular = false,
  });

  @override
  Widget build(BuildContext context) {
    ButtonStyle style({
      EdgeInsetsGeometry? padding,
      OutlinedBorder? shape,
    }) {
      return FilledButton.styleFrom(
        backgroundColor: primary ? ZapitiColors.wineRed : ZapitiColors.oldGold,
        foregroundColor:
            primary ? ZapitiColors.cardCream : ZapitiColors.darkBrown,
        disabledBackgroundColor: ZapitiColors.cardCream.withValues(alpha: 0.32),
        disabledForegroundColor: ZapitiColors.darkBrown.withValues(alpha: 0.45),
        padding: padding,
        shape: shape,
      );
    }

    if (circular) {
      return Tooltip(
        message: label,
        child: SizedBox.square(
          dimension: 52,
          child: FilledButton(
            onPressed: onPressed,
            style: style(
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
            child: Icon(icon, size: 22),
          ),
        ),
      );
    }

    return Tooltip(
      message: label,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final finiteWidth = constraints.maxWidth.isFinite;
          final finiteHeight = constraints.maxHeight.isFinite;
          final width = finiteWidth ? constraints.maxWidth : 160.0;
          final height = finiteHeight ? constraints.maxHeight : 48.0;
          final shortest = min(width, height);
          final textOnly = finiteWidth && width < 72;
          final iconSize = shortest.clamp(16.0, 22.0).toDouble();
          final horizontalPadding =
              finiteWidth ? (width * 0.09).clamp(4.0, 16.0).toDouble() : 16.0;
          final verticalPadding =
              finiteHeight ? (height * 0.12).clamp(2.0, 14.0).toDouble() : 14.0;

          return FilledButton(
            onPressed: onPressed,
            style: style(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: textOnly
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: iconSize),
                      SizedBox(width: shortest * 0.16),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
