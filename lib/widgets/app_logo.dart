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

  static const assetPath = 'assets/branding/header_logo.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      height: height,
      width: maxWidth ?? height * 2.7,
      fit: BoxFit.contain,
      alignment: alignment,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );
  }
}

