import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

const int _avatarCacheLimit = 48;
final LinkedHashMap<String, ImageProvider> _avatarImageCache = LinkedHashMap();

/// Helper to decode either a Base64 data URL (`data:image/...`) or an HTTP(S) URL
/// into a Flutter [ImageProvider].
///
/// Providers are cached by URL so parent rebuilds (live clocks, streams) reuse
/// the same [MemoryImage] instance. A new decode each time misses the image
/// cache and makes avatars flash.
ImageProvider? getUserAvatarImageProvider(String? avatarUrl) {
  if (avatarUrl == null) return null;
  final cleanUrl = avatarUrl.trim();
  if (cleanUrl.isEmpty) return null;

  final cached = _avatarImageCache.remove(cleanUrl);
  if (cached != null) {
    _avatarImageCache[cleanUrl] = cached;
    return cached;
  }

  final provider = _decodeAvatarProvider(cleanUrl);
  if (provider == null) return null;

  if (_avatarImageCache.length >= _avatarCacheLimit) {
    _avatarImageCache.remove(_avatarImageCache.keys.first);
  }
  _avatarImageCache[cleanUrl] = provider;
  return provider;
}

ImageProvider? _decodeAvatarProvider(String cleanUrl) {
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

  try {
    final Uint8List bytes = base64Decode(cleanUrl);
    if (bytes.isNotEmpty) {
      return MemoryImage(bytes);
    }
  } catch (_) {}

  return null;
}

class UserAvatar extends StatefulWidget {
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
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();
    _imageProvider = getUserAvatarImageProvider(widget.avatarUrl);
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarUrl != widget.avatarUrl) {
      _imageProvider = getUserAvatarImageProvider(widget.avatarUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial =
        widget.name.trim().isNotEmpty ? widget.name.trim()[0].toUpperCase() : 'U';
    final size = widget.radius * 2;

    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: widget.child ??
          Text(
            initial,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
              color: widget.textColor ?? theme.colorScheme.primary,
            ),
          ),
    );

    final imageProvider = _imageProvider;
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
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );

    if (widget.child == null) {
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
          widget.child!,
        ],
      ),
    );
  }
}
