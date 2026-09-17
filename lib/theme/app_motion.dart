import 'package:flutter/material.dart';

class AppMotion {
  static const Duration press = Duration(milliseconds: 120);
  static const Duration cardEnter = Duration(milliseconds: 280);
  static const Duration page = Duration(milliseconds: 320);

  static const Curve spring = Curves.easeOutCubic;

  static const PageTransitionsTheme pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeThroughPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeThroughPageTransitionsBuilder(),
      TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
      TargetPlatform.linux: FadeThroughPageTransitionsBuilder(),
      TargetPlatform.fuchsia: FadeThroughPageTransitionsBuilder(),
    },
  );

  static bool reducedMotion(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }
}

class FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeThroughPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    final fadeIn = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.22, 1, curve: Curves.easeOutCubic),
    );
    final fadeOut = CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Interval(0, 0.28, curve: Curves.easeInCubic),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: AppMotion.spring));

    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0).animate(fadeOut),
      child: FadeTransition(
        opacity: fadeIn,
        child: SlideTransition(position: slide, child: child),
      ),
    );
  }
}

class PressableScale extends StatefulWidget {
  final Widget child;
  final double scale;

  const PressableScale({super.key, required this.child, this.scale = 0.97});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reducedMotion(context)) {
      return widget.child;
    }

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: AppMotion.press,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset beginOffset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.beginOffset = const Offset(0, 0.04),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.cardEnter,
    );
    _fade = CurvedAnimation(parent: _controller, curve: AppMotion.spring);
    _slide = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(_fade);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reducedMotion(context)) {
      _controller.value = 1;
      return;
    }
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reducedMotion(context)) {
      return widget.child;
    }
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class MotionCard extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const MotionCard({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delay: delay,
      child: PressableScale(child: child),
    );
  }
}
