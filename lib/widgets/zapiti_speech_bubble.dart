import 'package:flutter/material.dart';

class ZapitiSpeechBubble extends StatelessWidget {
  final String text;
  final TextAlign alignment;
  final double? scale;

  const ZapitiSpeechBubble({
    super.key,
    required this.text,
    required this.alignment,
    this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final responsiveScale = (shortestSide / 900).clamp(0.52, 1.0).toDouble();
    final effectiveScale = (scale ?? responsiveScale).clamp(0.46, 1.0);
    final horizontalPadding = 24 * effectiveScale;
    final topPadding = 22 * effectiveScale;
    final bottomPadding = 34 * effectiveScale;

    return Align(
      alignment: alignment == TextAlign.center
          ? Alignment.center
          : Alignment.centerLeft,
      child: CustomPaint(
        painter: const _ZapitiSpeechBubblePainter(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 270 * effectiveScale,
            minHeight: 135 * effectiveScale,
            maxWidth: 340 * effectiveScale,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding,
              horizontalPadding,
              bottomPadding,
            ),
            child: Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: alignment,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 24 * effectiveScale,
                    height: 1.02,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ZapitiSpeechBubblePainter extends CustomPainter {
  const _ZapitiSpeechBubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.save();
    canvas.translate(0, 3);
    canvas.drawPath(_bubblePath(size), shadowPaint);
    canvas.restore();

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(_bubblePath(size), fillPaint);

    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_bubblePath(size), borderPaint);
  }

  Path _bubblePath(Size size) {
    final width = size.width;
    final height = size.height;
    const tailHeight = 32.0;
    final bodyBottom = height - tailHeight;
    const left = 3.0;
    final right = width - 3.0;
    const top = 3.0;

    return Path()
      ..moveTo(left + 26, top)
      ..quadraticBezierTo(width * 0.48, 0, right - 22, top + 1)
      ..quadraticBezierTo(right - 3, top + 2, right, top + 24)
      ..quadraticBezierTo(
        width + 2,
        bodyBottom * 0.48,
        right - 6,
        bodyBottom - 20,
      )
      ..quadraticBezierTo(
        right - 11,
        bodyBottom - 4,
        right - 34,
        bodyBottom - 2,
      )
      ..quadraticBezierTo(
        width * 0.55,
        bodyBottom + 3,
        width * 0.42,
        bodyBottom - 1,
      )
      ..quadraticBezierTo(
        width * 0.31,
        bodyBottom + 6,
        width * 0.23,
        height - 2,
      )
      ..quadraticBezierTo(
        width * 0.28,
        bodyBottom - 7,
        width * 0.24,
        bodyBottom - 12,
      )
      ..quadraticBezierTo(left + 6, bodyBottom - 10, left + 3, bodyBottom - 34)
      ..quadraticBezierTo(0, bodyBottom * 0.45, left + 4, top + 25)
      ..quadraticBezierTo(left + 6, top + 7, left + 26, top)
      ..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
