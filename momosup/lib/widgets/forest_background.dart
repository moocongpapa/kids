import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Immersive forest atmosphere with organic canopy gradients,
/// softly pulsing dappled sunbeams (Komorebi), and drifting forest particles.
class ForestBackground extends StatefulWidget {
  const ForestBackground({
    required this.child,
    this.lowStimulation = false,
    super.key,
  });

  final Widget child;
  final bool lowStimulation;

  @override
  State<ForestBackground> createState() => _ForestBackgroundState();
}

class _ForestBackgroundState extends State<ForestBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final List<_DriftingParticle> _particles = [];
  final math.Random _random = math.Random(12345);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Initialize 16 gentle drifting particles (leaves, golden fireflies)
    for (int i = 0; i < 16; i++) {
      _particles.add(
        _DriftingParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          speed: 0.08 + _random.nextDouble() * 0.12,
          size: 10 + _random.nextDouble() * 12,
          isLeaf: i % 2 == 0,
          driftOffset: _random.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lowStimulation) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3F8F1), Color(0xFFE5EFE2)],
          ),
        ),
        child: widget.child,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Lush multi-stop forest ambient gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.35, 0.75, 1.0],
              colors: [
                Color(0xFFFCFDF9), // Sunlit canopy top
                Color(0xFFEEF7EC), // Fresh leaf green
                Color(0xFFE2F0DE), // Deep mossy glade
                Color(0xFFD6EAD2), // Earthy forest base
              ],
            ),
          ),
        ),

        // 2. Dappled Sunbeams (Komorebi - sunlight filtering through treetops)
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SunbeamsPainter(progress: _animController.value),
                );
              },
            ),
          ),
        ),

        // 3. Floating forest particles (gentle leaves & golden firefly glimmers)
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ParticlesPainter(
                    progress: _animController.value,
                    particles: _particles,
                  ),
                );
              },
            ),
          ),
        ),

        // 4. Main content layer
        widget.child,
      ],
    );
  }
}

class _DriftingParticle {
  _DriftingParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.isLeaf,
    required this.driftOffset,
  });

  double x;
  double y;
  final double speed;
  final double size;
  final bool isLeaf;
  final double driftOffset;
}

class _SunbeamsPainter extends CustomPainter {
  const _SunbeamsPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final double pulse = 0.5 + 0.5 * math.sin(progress * 2 * math.pi);
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.6, -0.9),
        radius: 1.4,
        colors: [
          Colors.amber.shade100.withAlpha((45 + pulse * 25).toInt()),
          Colors.white.withAlpha((30 + pulse * 15).toInt()),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);

    // Diagonal subtle light ray band
    final rayPaint = Paint()
      ..color = Colors.white.withAlpha((18 + pulse * 14).toInt())
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.05, 0)
      ..lineTo(size.width * 0.35, 0)
      ..lineTo(size.width * 0.75, size.height)
      ..lineTo(size.width * 0.45, size.height)
      ..close();

    canvas.drawPath(path, rayPaint);
  }

  @override
  bool shouldRepaint(covariant _SunbeamsPainter oldDelegate) => true;
}

class _ParticlesPainter extends CustomPainter {
  const _ParticlesPainter({
    required this.progress,
    required this.particles,
  });

  final double progress;
  final List<_DriftingParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final currentY = (p.y + progress * p.speed * 2.5) % 1.0;
      final wave = math.sin(progress * 2 * math.pi + p.driftOffset) * 0.04;
      final currentX = (p.x + wave).clamp(0.02, 0.98);

      final px = currentX * size.width;
      final py = currentY * size.height;

      if (p.isLeaf) {
        // Falling gentle leaf
        final leafPaint = Paint()
          ..color = const Color(0xFF7FA97B).withAlpha(110)
          ..style = PaintingStyle.fill;

        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(progress * 2 * math.pi + p.driftOffset);
        final leafPath = Path()
          ..moveTo(0, -p.size * 0.5)
          ..quadraticBezierTo(p.size * 0.4, 0, 0, p.size * 0.5)
          ..quadraticBezierTo(-p.size * 0.4, 0, 0, -p.size * 0.5)
          ..close();
        canvas.drawPath(leafPath, leafPaint);
        canvas.restore();
      } else {
        // Glowing warm firefly / spore
        final glowPaint = Paint()
          ..color = const Color(0xFFFFE082).withAlpha(130)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset(px, py), p.size * 0.28, glowPaint);

        final corePaint = Paint()..color = Colors.white.withAlpha(200);
        canvas.drawCircle(Offset(px, py), p.size * 0.12, corePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}
