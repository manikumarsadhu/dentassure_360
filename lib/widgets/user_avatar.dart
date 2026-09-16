import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Helper to decode either a Base64 data URL (`data:image/...`) or an HTTP(S) URL
/// into a Flutter [ImageProvider].
ImageProvider? getUserAvatarImageProvider(String? avatarUrl) {
  if (avatarUrl == null) return null;
  final cleanUrl = avatarUrl.trim();
  if (cleanUrl.isEmpty) return null;

  if (cleanUrl.startsWith('data:image')) {
    try {
      final commaIndex = cleanUrl.indexOf(',');
      if (commaIndex != -1) {
        final base64Data = cleanUrl.substring(commaIndex + 1);
        final Uint8List bytes = base64Decode(base64Data);
        if (bytes.isNotEmpty) {
          return MemoryImage(bytes);
        }
      }
    } catch (e) {
      debugPrint('[UserAvatar] Error decoding base64 image: $e');
    }
    return null;
  }

  if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
    return NetworkImage(cleanUrl);
  }

  // Raw base64 without a data: prefix
  try {
    final Uint8List bytes = base64Decode(cleanUrl);
    if (bytes.isNotEmpty) {
      return MemoryImage(bytes);
    }
  } catch (_) {}

  return null;
}

class UserAvatar extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final double fontSize;
  final Widget? child;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.radius = 24,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 18,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageProvider = getUserAvatarImageProvider(avatarUrl);
    final initial =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';
    final size = radius * 2;

    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: child ??
          Text(
            initial,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: textColor ?? theme.colorScheme.primary,
            ),
          ),
    );

    if (imageProvider == null) {
      return fallback;
    }

    final photo = ClipOval(
      child: Image(
        image: imageProvider,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => fallback,
        frameBuilder: (context, img, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return img;
          }
          return fallback;
        },
      ),
    );

    if (child == null) {
      return photo;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          photo,
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
          ),
          child!,
        ],
      ),
    );
  }
}
