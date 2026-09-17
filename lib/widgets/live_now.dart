import 'dart:async';

import 'package:flutter/material.dart';

/// A single ticking [Text]. Its [setState] does not rebuild ancestors.
class LiveClockText extends StatefulWidget {
  final String Function(DateTime now) format;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const LiveClockText({
    super.key,
    required this.format,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  State<LiveClockText> createState() => _LiveClockTextState();
}

class _LiveClockTextState extends State<LiveClockText> {
  late final Timer _timer;
  late String _label;

  @override
  void initState() {
    super.initState();
    _label = widget.format(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = widget.format(DateTime.now());
      if (next == _label) return;
      setState(() => _label = next);
    });
  }

  @override
  void didUpdateWidget(LiveClockText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.format(DateTime.now());
    if (next != _label) {
      _label = next;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Text(
        _label,
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      ),
    );
  }
}
