import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lightweight particle system for toddler game celebrations.
///
/// Call [burst] to spawn particles at a position; the widget repaints at 60fps
/// while particles are alive, then automatically stops ticking.
class GameParticles extends StatefulWidget {
  const GameParticles({super.key});

  @override
  State<GameParticles> createState() => GameParticlesState();
}

class GameParticlesState extends State<GameParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  final _particles = <_Particle>[];
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ── public API ──────────────────────────────────────────────

  /// Spawn [count] particles at [origin] with the given [style].
  void burst({
    required Offset origin,
    int count = 12,
    ParticleStyle style = ParticleStyle.stars,
    double spread = 120,
    double gravity = 280,
  }) {
    final colors = switch (style) {
      ParticleStyle.stars => const [
        Color(0xFFF9D423),
        Color(0xFFFFE07D),
        Color(0xFFFFA726),
        Color(0xFFFFCC80),
      ],
      ParticleStyle.hearts => const [
        Color(0xFFEF5350),
        Color(0xFFF48FB1),
        Color(0xFFE57373),
        Color(0xFFFF8A80),
      ],
      ParticleStyle.sparkles => const [
        Color(0xFFE1F5FE),
        Color(0xFFFFF9C4),
        Color(0xFFE8F5E9),
        Color(0xFFFFFFFF),
      ],
      ParticleStyle.confetti => const [
        Color(0xFFEF5350),
        Color(0xFFFFA726),
        Color(0xFF66BB6A),
        Color(0xFF42A5F5),
        Color(0xFFAB47BC),
        Color(0xFFFDD835),
      ],
      ParticleStyle.drops => const [
        Color(0xFF4FC3F7),
        Color(0xFF81D4FA),
        Color(0xFFB3E5FC),
        Color(0xFF29B6F6),
      ],
    };
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = spread * (.4 + _rng.nextDouble() * .6);
      _particles.add(
        _Particle(
          x: origin.dx,
          y: origin.dy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - spread * .6,
          size: style == ParticleStyle.confetti
              ? 4 + _rng.nextDouble() * 6
              : 5 + _rng.nextDouble() * 8,
          color: colors[_rng.nextInt(colors.length)],
          life: .7 + _rng.nextDouble() * .5,
          rotation: _rng.nextDouble() * math.pi * 2,
          rotSpeed: (_rng.nextDouble() - .5) * 8,
          shape: style,
          gravity: gravity,
        ),
      );
    }
    if (!_ticker.isAnimating) {
      _lastT = null;
      _ticker.repeat();
    }
  }

  /// Convenience: small sparkle puff.
  void sparkle(Offset origin) => burst(
    origin: origin,
    count: 6,
    style: ParticleStyle.sparkles,
    spread: 60,
  );

  /// Convenience: big celebration.
  void celebrate(Offset origin) => burst(
    origin: origin,
    count: 24,
    style: ParticleStyle.confetti,
    spread: 160,
  );

  // ── internals ───────────────────────────────────────────────

  Duration? _lastT;

  void _tick() {
    final now = _ticker.lastElapsedDuration ?? Duration.zero;
    final dt = _lastT == null ? 0.016 : (now - _lastT!).inMicroseconds / 1e6;
    _lastT = now;
    var alive = false;
    for (final p in _particles) {
      p.age += dt;
      if (p.age >= p.life) continue;
      alive = true;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += p.gravity * dt;
      p.rotation += p.rotSpeed * dt;
      p.alpha = (1.0 - p.age / p.life).clamp(0.0, 1.0);
    }
    if (!alive) {
      _particles.clear();
      _ticker.stop();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _ParticlePainter(_particles),
      size: Size.infinite,
    ),
  );
}

enum ParticleStyle { stars, hearts, sparkles, confetti, drops }

class _Particle {
  double x, y, vx, vy, size, rotation, rotSpeed, life, age, alpha, gravity;
  Color color;
  ParticleStyle shape;
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.life,
    required this.rotation,
    required this.rotSpeed,
    required this.shape,
    required this.gravity,
  }) : age = 0,
       alpha = 1.0;
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter(this.particles);
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.alpha <= 0) continue;
      final paint = Paint()..color = p.color.withAlpha((p.alpha * 255).round());
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      switch (p.shape) {
        case ParticleStyle.stars:
          _drawStar(canvas, p.size, paint);
        case ParticleStyle.hearts:
          _drawHeart(canvas, p.size, paint);
        case ParticleStyle.sparkles:
          _drawSparkle(canvas, p.size, paint);
        case ParticleStyle.confetti:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: p.size,
                height: p.size * .55,
              ),
              Radius.circular(p.size * .15),
            ),
            paint,
          );
        case ParticleStyle.drops:
          _drawDrop(canvas, p.size, paint);
      }
      canvas.restore();
    }
  }

  void _drawStar(Canvas c, double s, Paint p) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? s : s * .45;
      final pt = Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    c.drawPath(path, p);
  }

  void _drawHeart(Canvas c, double s, Paint p) {
    final path = Path()
      ..moveTo(0, s * .35)
      ..cubicTo(-s, -s * .3, -s * .4, -s, 0, -s * .35)
      ..cubicTo(s * .4, -s, s, -s * .3, 0, s * .35)
      ..close();
    c.drawPath(path, p);
  }

  void _drawSparkle(Canvas c, double s, Paint p) {
    c.drawCircle(Offset.zero, s * .5, p);
    c.drawCircle(
      Offset.zero,
      s * .3,
      Paint()..color = Colors.white.withAlpha((p.color.a * 200).round()),
    );
  }

  void _drawDrop(Canvas c, double s, Paint p) {
    final path = Path()
      ..moveTo(0, -s)
      ..quadraticBezierTo(s * .7, -s * .2, 0, s * .5)
      ..quadraticBezierTo(-s * .7, -s * .2, 0, -s)
      ..close();
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
