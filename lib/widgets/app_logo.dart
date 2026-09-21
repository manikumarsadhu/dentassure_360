import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final double radius;

  const AppLogo({super.key, this.size = 40, this.radius = 10});

  static const assetPath = 'assets/branding/app_icon.png';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    );
  }
}

/// Full wordmark for light headers. Uses a tightly cropped, transparent
/// asset so the artwork fills the bar instead of shrinking inside padding.
class AppHeaderLogo extends StatelessWidget {
  final double height;
  final double? maxWidth;
  final Alignment alignment;

  const AppHeaderLogo({
    super.key,
    this.height = 42,
    this.maxWidth,
    this.alignment = Alignment.centerLeft,
  });

  static const assetPath = 'assets/branding/header_logo_nav.png';

  @override
  Widget build(BuildContext context) {
    final width = maxWidth ?? height * 5.3;
    return Align(
      alignment: alignment,
      child: Image.asset(
        assetPath,
        height: height,
        width: width,
        fit: BoxFit.contain,
        alignment: alignment,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        isAntiAlias: true,
      ),
    );
  }
}
