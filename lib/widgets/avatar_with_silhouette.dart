import 'package:flutter/material.dart';

class AvatarWithSilhouette extends StatelessWidget {
  final String assetPath;
  final double width;
  final double height;
  final bool mirror;
  final Offset offset;
  final BoxFit fit;
  final Alignment alignment;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const AvatarWithSilhouette({
    super.key,
    required this.assetPath,
    required this.width,
    required this.height,
    this.mirror = false,
    this.offset = Offset.zero,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.bottomCenter,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(mirror ? -1 : 1, 1, 1),
        child: Transform.translate(
          offset: offset,
          child: Image.asset(
            assetPath,
            key: ValueKey(assetPath),
            width: width,
            height: height,
            fit: fit,
            gaplessPlayback: true,
            alignment: alignment,
            errorBuilder: errorBuilder,
          ),
        ),
      ),
    );
  }
}
