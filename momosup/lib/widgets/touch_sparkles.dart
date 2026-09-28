import 'dart:math' as math;
import 'package:flutter/material.dart';

class TouchSparkles extends StatefulWidget {
  const TouchSparkles({
    required this.child,
    this.lowStimulation = false,
    super.key,
  });

  final Widget child;
  final bool lowStimulation;

  @override
  State<TouchSparkles> createState() => _TouchSparklesState();
}

class _Sparkle {
  _Sparkle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.type,
  }) : life = 1.0;

  double x;
  double y;
  final double vx;
  final double vy;
  final Color color;
  final double size;
  final int type; // 0: star, 1: bubble, 2: heart, 3: leaf
  double life;
}

class _TouchSparklesState extends State<TouchSparkles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Sparkle> _sparkles = [];
  final math.Random _random = math.Random();

  final List<Color> _palette = const [
    Color(0xFFFFB300), // warm golden star
    Color(0xFFFF8A80), // gentle coral pink
    Color(0xFF81C784), // fresh meadow green
    Color(0xFF64B5F6), // sky blue
    Color(0xFFBA68C8), // soft lavender
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateSparkles);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addSparkles(Offset position, {int count = 5}) {
    for (var i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 1.5 + _random.nextDouble() * 3.5;
      _sparkles.add(
        _Sparkle(
          x: position.dx,
          y: position.dy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 1.5, // slight upward float
          color: _palette[_random.nextInt(_palette.length)],
          size: 10.0 + _random.nextDouble() * 14.0,
          type: _random.nextInt(4),
        ),
      );
    }
    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  void _updateSparkles() {
    if (_sparkles.isEmpty) {
      if (_controller.isAnimating) _controller.stop();
      return;
    }

    setState(() {
      for (var i = _sparkles.length - 1; i >= 0; i--) {
        final s = _sparkles[i];
        s.x += s.vx;
        s.y += s.vy;
        s.life -= 0.035; // ~30 frames lifespan (~0.5s)
        if (s.life <= 0) {
          _sparkles.removeAt(i);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lowStimulation) {
      return widget.child;
    }
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _addSparkles(e.localPosition, count: 6),
      onPointerMove: (e) {
        if (_random.nextDouble() < 0.3) {
          _addSparkles(e.localPosition, count: 2);
        }
      },
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (_sparkles.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SparklePainter(sparkles: _sparkles),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.sparkles});
  final List<_Sparkle> sparkles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparkles) {
      final alpha = (s.life * 255).clamp(0, 255).toInt();
      final paint = Paint()
        ..color = s.color.withAlpha(alpha)
        ..style = PaintingStyle.fill;

      final currentSize = s.size * s.life;

      switch (s.type) {
        case 0: // 4-point star
          _drawStar(canvas, Offset(s.x, s.y), currentSize, paint);
          break;
        case 1: // soft bubble
          canvas.drawCircle(Offset(s.x, s.y), currentSize * 0.5, paint);
          break;
        case 2: // little heart
          _drawHeart(canvas, Offset(s.x, s.y), currentSize, paint);
          break;
        default: // little petal / leaf
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(s.x, s.y),
              width: currentSize * 0.8,
              height: currentSize * 0.4,
            ),
            paint,
          );
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final half = size / 2;
    path.moveTo(center.dx, center.dy - half);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + half, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + half);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - half, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - half);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final w = size * 0.7;
    final h = size * 0.7;
    path.moveTo(center.dx, center.dy + h / 4);
    path.cubicTo(
      center.dx + w / 2,
      center.dy - h / 3,
      center.dx + w,
      center.dy + h / 3,
      center.dx,
      center.dy + h,
    );
    path.cubicTo(
      center.dx - w,
      center.dy + h / 3,
      center.dx - w / 2,
      center.dy - h / 3,
      center.dx,
      center.dy + h / 4,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => true;
}
