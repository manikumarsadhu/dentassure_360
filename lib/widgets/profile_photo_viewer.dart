import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'user_avatar.dart';

/// Full-screen, pinch-to-zoom profile photo viewer.
class ProfilePhotoViewer extends StatefulWidget {
  final String avatarUrl;
  final String name;

  const ProfilePhotoViewer({
    super.key,
    required this.avatarUrl,
    required this.name,
  });

  /// Opens the enlarge screen when a photo exists.
  /// Shows a snackbar instead when [avatarUrl] cannot be decoded.
  static Future<void> open(
    BuildContext context, {
    required String avatarUrl,
    required String name,
  }) {
    final provider = getUserAvatarImageProvider(avatarUrl);
    if (provider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No profile photo to view.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return Future.value();
    }

    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ProfilePhotoViewer(avatarUrl: avatarUrl, name: name);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<ProfilePhotoViewer> createState() => _ProfilePhotoViewerState();
}

class _ProfilePhotoViewerState extends State<ProfilePhotoViewer> {
  static const _zoomedScale = 2.5;

  final TransformationController _transform = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final position = _doubleTapDetails?.localPosition;
    final currentScale = _transform.value.getMaxScaleOnAxis();
    if (currentScale > 1.05 || position == null) {
      _transform.value = Matrix4.identity();
      return;
    }

    _transform.value = Matrix4.identity()
      ..translate(position.dx, position.dy)
      ..scale(_zoomedScale)
      ..translate(-position.dx, -position.dy);
  }

  void _close() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = getUserAvatarImageProvider(widget.avatarUrl);
    final displayName = widget.name.trim().isEmpty
        ? 'Profile photo'
        : widget.name.trim();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Close',
                      onPressed: _close,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: imageProvider == null
                    ? _MissingPhoto(name: displayName)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            onDoubleTapDown: (details) {
                              _doubleTapDetails = details;
                            },
                            onDoubleTap: _handleDoubleTap,
                            child: InteractiveViewer(
                              transformationController: _transform,
                              minScale: 1,
                              maxScale: 5,
                              child: SizedBox(
                                width: constraints.maxWidth,
                                height: constraints.maxHeight,
                                child: Image(
                                  image: imageProvider,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return _MissingPhoto(name: displayName);
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  'Pinch or double-tap to zoom',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingPhoto extends StatelessWidget {
  final String name;

  const _MissingPhoto({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 56,
            backgroundColor: Colors.white24,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Photo could not be loaded',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
