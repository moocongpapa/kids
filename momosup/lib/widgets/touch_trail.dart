import 'dart:math' as math;
import 'package:flutter/material.dart';

enum TrailShape { star, sparkle, circle, heart }

class _TrailParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double maxLife;
  double life;
  Color color;
  TrailShape shape;
  double rotation;
  double rotationSpeed;

  _TrailParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.maxLife,
    required this.life,
    required this.color,
    required this.shape,
    required this.rotation,
    required this.rotationSpeed,
  });

  bool update(double dt) {
    life -= dt;
    if (life <= 0) return false;
    x += vx * dt;
    y += vy * dt;
    // Gentle upward floating + drag
    vy -= 18.0 * dt;
    vx *= 0.96;
    vy *= 0.96;
    rotation += rotationSpeed * dt;
    return true;
  }

  double get progress => (life / maxLife).clamp(0.0, 1.0);
}

/// A magical, sensory-friendly touch trail that spawns soft sparkling stars,
/// hearts, and circles following tiny fingers across the screen.
class ForestTouchTrail extends StatefulWidget {
  const ForestTouchTrail({
    required this.child,
    this.enabled = true,
    this.maxParticles = 36,
    super.key,
  });

  final Widget child;
  final bool enabled;
  final int maxParticles;

  @override
  State<ForestTouchTrail> createState() => _ForestTouchTrailState();
}

class _ForestTouchTrailState extends State<ForestTouchTrail>
    with SingleTickerProviderStateMixin {
  final List<_TrailParticle> _particles = [];
  late final AnimationController _ticker;
  final math.Random _random = math.Random();
  DateTime _lastSpawnTime = DateTime.fromMillisecondsSinceEpoch(0);

  static const List<Color> _palette = [
    Color(0xFFFFD54F), // Gold star
    Color(0xFFFF94A6), // Sweet blossom pink
    Color(0xFF81D4FA), // Sky blue
    Color(0xFFA5D6A7), // Forest sprout green
    Color(0xFFCE93D8), // Soft lavender
    Color(0xFFFFB74D), // Warm apricot
  ];

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController.unbounded(vsync: this)
      ..addListener(_onTick);
  }

  @override
  void dispose() {
    _ticker.removeListener(_onTick);
    _ticker.dispose();
    super.dispose();
  }

  void _onTick() {
    if (_particles.isEmpty) {
      if (_ticker.isAnimating) _ticker.stop();
      return;
    }
    // Update particles (assuming ~16ms frame)
    setState(() {
      _particles.removeWhere((p) => !p.update(0.016));
    });
  }

  void _spawnAt(Offset pos) {
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) return;

    final now = DateTime.now();
    // Throttle particle emission slightly to keep performance silky smooth
    if (now.difference(_lastSpawnTime).inMilliseconds < 25) return;
    _lastSpawnTime = now;

    if (_particles.length >= widget.maxParticles) {
      _particles.removeRange(0, _particles.length - widget.maxParticles + 1);
    }

    final shapeIndex = _random.nextInt(TrailShape.values.length);
    final shape = TrailShape.values[shapeIndex];
    final color = _palette[_random.nextInt(_palette.length)];
    final angle = _random.nextDouble() * 2 * math.pi;
    final speed = 15.0 + _random.nextDouble() * 40.0;

    _particles.add(
      _TrailParticle(
        x: pos.dx + (_random.nextDouble() - 0.5) * 12.0,
        y: pos.dy + (_random.nextDouble() - 0.5) * 12.0,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 15.0,
        size: 10.0 + _random.nextDouble() * 12.0,
        maxLife: 0.55 + _random.nextDouble() * 0.35,
        life: 0.55 + _random.nextDouble() * 0.35,
        color: color,
        shape: shape,
        rotation: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 6.0,
      ),
    );

    if (!_ticker.isAnimating) {
      _ticker.repeat(min: 0.0, max: 1.0, period: const Duration(seconds: 1));
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    _spawnAt(event.localPosition);
  }

  void _onPointerMove(PointerMoveEvent event) {
    _spawnAt(event.localPosition);
  }

  void _onPointerUp(PointerUpEvent event) {}

  void _onPointerCancel(PointerCancelEvent event) {}

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (widget.enabled && _particles.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _TouchTrailPainter(particles: _particles),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TouchTrailPainter extends CustomPainter {
  final List<_TrailParticle> particles;

  _TouchTrailPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final alpha = (p.progress * 255).round().clamp(0, 255);
      if (alpha <= 0) continue;

      final paint = Paint()
        ..color = p.color.withAlpha(alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      final currentSize = p.size * (0.4 + 0.6 * p.progress);

      switch (p.shape) {
        case TrailShape.star:
          _drawStar(canvas, currentSize, paint);
          break;
        case TrailShape.sparkle:
          _drawSparkle(canvas, currentSize, paint);
          break;
        case TrailShape.heart:
          _drawHeart(canvas, currentSize, paint);
          break;
        case TrailShape.circle:
          canvas.drawCircle(Offset.zero, currentSize * 0.45, paint);
          break;
      }

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final half = size / 2;
    for (int i = 0; i < 5; i++) {
      final outerAngle = -math.pi / 2 + (i * 2 * math.pi / 5);
      final innerAngle = outerAngle + math.pi / 5;
      final outerPoint = Offset(
        math.cos(outerAngle) * half,
        math.sin(outerAngle) * half,
      );
      final innerPoint = Offset(
        math.cos(innerAngle) * (half * 0.45),
        math.sin(innerAngle) * (half * 0.45),
      );
      if (i == 0) {
        path.moveTo(outerPoint.dx, outerPoint.dy);
      } else {
        path.lineTo(outerPoint.dx, outerPoint.dy);
      }
      path.lineTo(innerPoint.dx, innerPoint.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawSparkle(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final half = size / 2;
    final r = half * 0.22;
    path.moveTo(0, -half);
    path.quadraticBezierTo(0, -r, r, 0);
    path.quadraticBezierTo(0, r, 0, half);
    path.quadraticBezierTo(0, r, -r, 0);
    path.quadraticBezierTo(0, -r, 0, -half);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final w = size * 0.8;
    final h = size * 0.8;
    path.moveTo(0, h * 0.3);
    path.cubicTo(-w * 0.5, -h * 0.2, -w * 0.5, h * 0.4, 0, h * 0.5);
    path.cubicTo(w * 0.5, h * 0.4, w * 0.5, -h * 0.2, 0, h * 0.3);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TouchTrailPainter oldDelegate) => true;
}
