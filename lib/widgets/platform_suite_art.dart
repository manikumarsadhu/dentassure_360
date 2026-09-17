import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

enum PlatformSuiteKind { onboard, directory, analytics, audit }

class PlatformSuiteArt extends StatefulWidget {
  final PlatformSuiteKind kind;
  final Color color;

  const PlatformSuiteArt({super.key, required this.kind, required this.color});

  @override
  State<PlatformSuiteArt> createState() => _PlatformSuiteArtState();
}

class _PlatformSuiteArtState extends State<PlatformSuiteArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reducedMotion(context)) {
      _controller.stop();
      _controller.value = 0.45;
      return;
    }
    if (!_controller.isAnimating && !_scheduled) {
      _scheduled = true;
      final delay = switch (widget.kind) {
        PlatformSuiteKind.onboard => 0,
        PlatformSuiteKind.directory => 180,
        PlatformSuiteKind.analytics => 320,
        PlatformSuiteKind.audit => 480,
      };
      Future<void>.delayed(Duration(milliseconds: delay), () {
        if (mounted && !AppMotion.reducedMotion(context)) {
          _controller.repeat();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _SuitePainter(
            kind: widget.kind,
            color: widget.color,
            t: _controller.value,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _SuitePainter extends CustomPainter {
  final PlatformSuiteKind kind;
  final Color color;
  final double t;

  _SuitePainter({required this.kind, required this.color, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case PlatformSuiteKind.onboard:
        _paintOnboard(canvas, size);
      case PlatformSuiteKind.directory:
        _paintDirectory(canvas, size);
      case PlatformSuiteKind.analytics:
        _paintAnalytics(canvas, size);
      case PlatformSuiteKind.audit:
        _paintAudit(canvas, size);
    }
  }

  double _wave(double speed, [double offset = 0]) {
    return (math.sin((t * speed + offset) * math.pi * 2) + 1) / 2;
  }

  void _paintOnboard(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final groundY = size.height * 0.82;
    final bounce = 6 * math.sin(t * math.pi * 2);

    final ground = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.12, groundY),
      Offset(size.width * 0.88, groundY),
      ground,
    );

    final buildingW = size.width * 0.34;
    final buildingH = size.height * 0.48 + bounce;
    final building = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, groundY - buildingH / 2),
        width: buildingW,
        height: buildingH,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(building, Paint()..color = color.withValues(alpha: 0.92));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, groundY - buildingH - 8),
          width: buildingW * 0.55,
          height: 14,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = color.withValues(alpha: 0.7),
    );

    const cols = 3;
    const rows = 4;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final lit = _wave(1.4, (r * 0.18) + (c * 0.27)) > 0.42;
        final wx = building.left + 12 + c * ((buildingW - 24) / cols);
        final wy = building.top + 14 + r * ((buildingH - 28) / rows);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(wx, wy, 12, 10),
            const Radius.circular(2),
          ),
          Paint()
            ..color = lit
                ? Colors.white.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.28),
        );
      }
    }

    final plusScale = 0.86 + 0.14 * _wave(2);
    final plusCenter = Offset(cx + buildingW * 0.52, groundY - buildingH + 8);
    canvas.save();
    canvas.translate(plusCenter.dx, plusCenter.dy);
    canvas.scale(plusScale);
    canvas.drawCircle(Offset.zero, 16, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset.zero,
      16,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final plus = Paint()
      ..color = color
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-7, 0), const Offset(7, 0), plus);
    canvas.drawLine(const Offset(0, -7), const Offset(0, 7), plus);
    canvas.restore();
  }

  void _paintDirectory(Canvas canvas, Size size) {
    final people = [
      Offset(size.width * 0.32, size.height * 0.58),
      Offset(size.width * 0.50, size.height * 0.38),
      Offset(size.width * 0.68, size.height * 0.58),
    ];
    final line = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 2;
    canvas.drawLine(people[0], people[1], line);
    canvas.drawLine(people[1], people[2], line);
    canvas.drawLine(people[0], people[2], line);

    for (var i = 0; i < people.length; i++) {
      final pulse = 18.0 + 8 * _wave(1.6, i * 0.22);
      canvas.drawCircle(
        people[i],
        pulse,
        Paint()..color = color.withValues(alpha: 0.12),
      );
      canvas.drawCircle(people[i], 18, Paint()..color = color);
      canvas.drawCircle(
        people[i] + const Offset(0, -4),
        6.5,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        people[i] + const Offset(0, 8),
        8,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );
    }

    final orbit = Offset(
      size.width * 0.50 + 42 * math.cos(t * math.pi * 2),
      size.height * 0.48 + 18 * math.sin(t * math.pi * 2),
    );
    canvas.drawCircle(orbit, 5, Paint()..color = color.withValues(alpha: 0.85));
  }

  void _paintAnalytics(Canvas canvas, Size size) {
    final bars = [0.42, 0.68, 0.52, 0.86, 0.61];
    final chart = Rect.fromLTWH(
      size.width * 0.16,
      size.height * 0.22,
      size.width * 0.68,
      size.height * 0.56,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(chart, const Radius.circular(12)),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    final gap = 8.0;
    final barW = (chart.width - 24 - gap * (bars.length - 1)) / bars.length;
    for (var i = 0; i < bars.length; i++) {
      final grow = 0.55 + 0.45 * _wave(1.3, i * 0.16);
      final h = chart.height * 0.72 * bars[i] * grow;
      final x = chart.left + 12 + i * (barW + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chart.bottom - 10 - h, barW, h),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: 0.9));
    }

    final path = Path();
    for (var i = 0; i < bars.length; i++) {
      final x = chart.left + 12 + i * (barW + gap) + barW / 2;
      final y =
          chart.bottom -
          10 -
          chart.height * 0.72 * bars[i] * (0.55 + 0.45 * _wave(1.3, i * 0.16)) -
          8;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintAudit(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final ringR = size.shortestSide * 0.32;
    canvas.drawCircle(
      center,
      ringR + 10 * _wave(1.8),
      Paint()..color = color.withValues(alpha: 0.12),
    );

    final dash = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    const dashes = 18;
    for (var i = 0; i < dashes; i++) {
      final a = (i / dashes + t) * math.pi * 2;
      final inner = ringR + 6;
      final outer = ringR + 14;
      canvas.drawLine(
        center + Offset(math.cos(a) * inner, math.sin(a) * inner),
        center + Offset(math.cos(a) * outer, math.sin(a) * outer),
        dash,
      );
    }

    final shield = Path()
      ..moveTo(center.dx, center.dy - 28)
      ..cubicTo(
        center.dx + 24,
        center.dy - 22,
        center.dx + 26,
        center.dy + 8,
        center.dx,
        center.dy + 30,
      )
      ..cubicTo(
        center.dx - 26,
        center.dy + 8,
        center.dx - 24,
        center.dy - 22,
        center.dx,
        center.dy - 28,
      )
      ..close();
    canvas.drawPath(shield, Paint()..color = color);
    canvas.drawPath(
      shield,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final check = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(center.dx - 9, center.dy + 1)
      ..lineTo(center.dx - 2, center.dy + 9)
      ..lineTo(center.dx + 12, center.dy - 8);
    canvas.drawPath(path, check);

    final scanY = center.dy - 22 + 44 * t;
    canvas.drawLine(
      Offset(center.dx - 14, scanY),
      Offset(center.dx + 14, scanY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant _SuitePainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.kind != kind ||
        oldDelegate.color != color;
  }
}
