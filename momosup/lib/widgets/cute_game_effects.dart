import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/sound_effects.dart';
import 'game_particles.dart';

enum FaceMood {
  idle,
  happy,
  surprised,
  dizzy,
  singing,
}

/// An adorable vector face overlay (eyes, blush, mouth) that brings fruits,
/// acorns, notes, and props to life with blinking and varied moods.
class CuteFace extends StatefulWidget {
  final FaceMood mood;
  final double size;
  final bool animateBlink;
  final Color? blushColor;

  const CuteFace({
    super.key,
    this.mood = FaceMood.idle,
    this.size = 60,
    this.animateBlink = true,
    this.blushColor,
  });

  @override
  State<CuteFace> createState() => _CuteFaceState();
}

class _CuteFaceState extends State<CuteFace> {
  Timer? _blinkTimer;
  bool _isBlinking = false;

  @override
  void initState() {
    super.initState();
    if (widget.animateBlink) {
      _scheduleNextBlink();
    }
  }

  void _scheduleNextBlink() {
    _blinkTimer?.cancel();
    final delayMs = 2500 + math.Random().nextInt(3000);
    _blinkTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      setState(() => _isBlinking = true);
      Timer(const Duration(milliseconds: 140), () {
        if (!mounted) return;
        setState(() => _isBlinking = false);
        _scheduleNextBlink();
      });
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _CuteFacePainter(
          mood: widget.mood,
          isBlinking: _isBlinking,
          blushColor: widget.blushColor ?? const Color(0xFFFF8DA1),
        ),
      ),
    );
  }
}

class _CuteFacePainter extends CustomPainter {
  final FaceMood mood;
  final bool isBlinking;
  final Color blushColor;

  _CuteFacePainter({
    required this.mood,
    required this.isBlinking,
    required this.blushColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 60.0;
    canvas.save();
    canvas.scale(scale, scale);

    final eyePaint = Paint()
      ..color = const Color(0xFF2B2118)
      ..style = PaintingStyle.fill;

    final mouthPaint = Paint()
      ..color = const Color(0xFF2B2118)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final blushPaint = Paint()
      ..color = blushColor.withAlpha(160)
      ..style = PaintingStyle.fill;

    // Cheeks (blush)
    canvas.drawOval(const Rect.fromLTWH(10, 32, 10, 7), blushPaint);
    canvas.drawOval(const Rect.fromLTWH(40, 32, 10, 7), blushPaint);

    // Eyes
    if (isBlinking || mood == FaceMood.happy) {
      // Happy curved closed eyes ^ ^
      final leftEye = Path()
        ..moveTo(14, 28)
        ..quadraticBezierTo(18, 22, 22, 28);
      final rightEye = Path()
        ..moveTo(38, 28)
        ..quadraticBezierTo(42, 22, 46, 28);
      canvas.drawPath(leftEye, mouthPaint);
      canvas.drawPath(rightEye, mouthPaint);
    } else if (mood == FaceMood.surprised) {
      // Big open eyes O O
      canvas.drawCircle(const Offset(18, 26), 4.5, eyePaint);
      canvas.drawCircle(const Offset(42, 26), 4.5, eyePaint);
      // Highlights
      canvas.drawCircle(const Offset(16.5, 24.5), 1.6, Paint()..color = Colors.white);
      canvas.drawCircle(const Offset(40.5, 24.5), 1.6, Paint()..color = Colors.white);
    } else if (mood == FaceMood.dizzy) {
      // Swirly dizzy eyes x x
      canvas.drawLine(const Offset(14, 23), const Offset(22, 29), mouthPaint);
      canvas.drawLine(const Offset(22, 23), const Offset(14, 29), mouthPaint);
      canvas.drawLine(const Offset(38, 23), const Offset(46, 29), mouthPaint);
      canvas.drawLine(const Offset(46, 23), const Offset(38, 29), mouthPaint);
    } else {
      // Normal friendly eyes with cute sparkle highlight
      canvas.drawCircle(const Offset(18, 26), 3.4, eyePaint);
      canvas.drawCircle(const Offset(42, 26), 3.4, eyePaint);
      canvas.drawCircle(const Offset(17, 24.5), 1.3, Paint()..color = Colors.white);
      canvas.drawCircle(const Offset(41, 24.5), 1.3, Paint()..color = Colors.white);
    }

    // Mouth
    if (mood == FaceMood.surprised) {
      // Cute round mouth 'o'
      canvas.drawOval(
        const Rect.fromLTWH(26, 32, 8, 9),
        Paint()..color = const Color(0xFFC95B5B),
      );
    } else if (mood == FaceMood.happy || mood == FaceMood.singing) {
      // Big open smiling mouth
      final mouthPath = Path()
        ..moveTo(24, 32)
        ..quadraticBezierTo(30, 42, 36, 32)
        ..close();
      canvas.drawPath(
        mouthPath,
        Paint()..color = const Color(0xFFE56A70),
      );
      // Tiny tongue
      canvas.save();
      canvas.clipPath(mouthPath);
      canvas.drawCircle(const Offset(30, 39), 5, Paint()..color = const Color(0xFFFF9BA2));
      canvas.restore();
    } else if (mood == FaceMood.dizzy) {
      // Wobbly mouth ~
      final wobbly = Path()
        ..moveTo(23, 35)
        ..quadraticBezierTo(26, 32, 30, 35)
        ..quadraticBezierTo(34, 38, 37, 35);
      canvas.drawPath(wobbly, mouthPaint);
    } else {
      // Gentle smile
      final smile = Path()
        ..moveTo(25, 33)
        ..quadraticBezierTo(30, 38, 35, 33);
      canvas.drawPath(smile, mouthPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CuteFacePainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.isBlinking != isBlinking ||
        oldDelegate.blushColor != blushColor;
  }
}

/// An interactive floating bubbles system. Toddlers can tap floating bubbles
/// to pop them with a satisfying 'pop' sound and star sparkle.
class CuteBubblesLayer extends StatefulWidget {
  final GlobalKey<GameParticlesState>? particlesKey;
  final bool enabled;

  const CuteBubblesLayer({
    super.key,
    this.particlesKey,
    this.enabled = true,
  });

  @override
  State<CuteBubblesLayer> createState() => _CuteBubblesLayerState();
}

class _BubbleItem {
  final int id;
  double x; // 0.0 .. 1.0 (relative to width)
  double y; // pixels
  double size;
  double speed;
  double swayOffset;
  Color color;

  _BubbleItem({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.swayOffset,
    required this.color,
  });
}

class _CuteBubblesLayerState extends State<CuteBubblesLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  final List<_BubbleItem> _bubbles = [];
  final math.Random _rng = math.Random();
  int _nextId = 0;
  double _elapsed = 0.0;

  static const _bubbleColors = [
    Color(0x55B3E5FC), // Sky blue
    Color(0x55F8BBD0), // Soft pink
    Color(0x55C8E6C9), // Mint green
    Color(0x55FFF9C4), // Pale yellow
    Color(0x55E1BEE7), // Soft purple
  ];

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..addListener(_tick);
    if (widget.enabled) {
      _ticker.repeat();
    }
  }

  @override
  void didUpdateWidget(CuteBubblesLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_ticker.isAnimating) {
      _ticker.repeat();
    } else if (!widget.enabled && _ticker.isAnimating) {
      _ticker.stop();
      _bubbles.clear();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick() {
    if (!mounted || !widget.enabled) return;
    final size = MediaQuery.sizeOf(context);
    if (size.width == 0 || size.height == 0) return;

    _elapsed += 0.016;

    // Spawn new bubble occasionally (max 6 active bubbles at a time)
    if (_bubbles.length < 6 && _rng.nextDouble() < 0.03) {
      _bubbles.add(_BubbleItem(
        id: _nextId++,
        x: 0.1 + _rng.nextDouble() * 0.8,
        y: size.height + 40,
        size: 38 + _rng.nextDouble() * 26,
        speed: 35 + _rng.nextDouble() * 30,
        swayOffset: _rng.nextDouble() * math.pi * 2,
        color: _bubbleColors[_rng.nextInt(_bubbleColors.length)],
      ));
    }

    // Move bubbles up
    for (int i = _bubbles.length - 1; i >= 0; i--) {
      final b = _bubbles[i];
      b.y -= b.speed * 0.016;
      if (b.y < -60) {
        _bubbles.removeAt(i);
      }
    }

    setState(() {});
  }

  void _popBubble(_BubbleItem bubble, Offset globalPos) {
    SoundEffects.instance.pop();
    widget.particlesKey?.currentState?.burst(
      origin: globalPos,
      count: 8,
      style: ParticleStyle.sparkles,
      spread: 60,
    );
    setState(() {
      _bubbles.removeWhere((b) => b.id == bubble.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _bubbles.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.sizeOf(context).width;

    return Stack(
      children: _bubbles.map((b) {
        final xPos = (b.x * screenWidth) + math.sin(_elapsed * 2.0 + b.swayOffset) * 16.0;
        return Positioned(
          left: xPos - b.size / 2,
          top: b.y - b.size / 2,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              _popBubble(b, details.globalPosition);
            },
            child: Container(
              width: b.size,
              height: b.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.3),
                  radius: 0.8,
                  colors: [
                    Colors.white.withAlpha(180),
                    b.color,
                    b.color.withAlpha(220),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: b.color.withAlpha(80),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withAlpha(140),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  // Little shine dot
                  Positioned(
                    top: b.size * 0.2,
                    left: b.size * 0.25,
                    child: Container(
                      width: b.size * 0.22,
                      height: b.size * 0.14,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(220),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Rosy cheek blush puff animation that makes character avatar images
/// feel warm, happy, and reactive.
class CharacterBlushOverlay extends StatelessWidget {
  final bool isBlushing;
  final double size;

  const CharacterBlushOverlay({
    super.key,
    required this.isBlushing,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isBlushing ? 0.85 : 0.0,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              // Left cheek blush
              Positioned(
                left: size * 0.22,
                top: size * 0.54,
                child: Container(
                  width: size * 0.18,
                  height: size * 0.11,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6584).withAlpha(160),
                    borderRadius: BorderRadius.all(Radius.elliptical(size * 0.18, size * 0.11)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6584).withAlpha(120),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              // Right cheek blush
              Positioned(
                right: size * 0.22,
                top: size * 0.54,
                child: Container(
                  width: size * 0.18,
                  height: size * 0.11,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6584).withAlpha(160),
                    borderRadius: BorderRadius.all(Radius.elliptical(size * 0.18, size * 0.11)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6584).withAlpha(120),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
