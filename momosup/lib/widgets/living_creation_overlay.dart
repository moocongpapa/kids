import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../utils/sound_effects.dart';
import 'coloring_templates.dart';
import 'forest_game_ui.dart';
import 'game_particles.dart';

/// A magical celebration overlay where the child's coloring artwork
/// actually comes alive—driving, flying, jumping, and dancing!
class LivingCreationOverlay extends StatefulWidget {
  const LivingCreationOverlay({
    required this.template,
    required this.segments,
    required this.onClose,
    this.quiet = false,
    super.key,
  });

  final ColoringTemplate template;
  final List<ColoringSegment> segments;
  final VoidCallback onClose;
  final bool quiet;

  @override
  State<LivingCreationOverlay> createState() => _LivingCreationOverlayState();
}

class _LivingCreationOverlayState extends State<LivingCreationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _motionController;
  late final AnimationController _tapReactionController;
  final GlobalKey<GameParticlesState> _particlesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _tapReactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.quiet) {
        SoundEffects.instance.tada();
      }
    });
  }

  @override
  void dispose() {
    _motionController.dispose();
    _tapReactionController.dispose();
    super.dispose();
  }

  void _handleArtworkTap() {
    _tapReactionController.forward(from: 0.0);
    if (!widget.quiet) {
      SoundEffects.instance.musicalTap();
      _particlesKey.currentState?.celebrate(const Offset(160, 160));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.template.category;

    return Material(
      color: Colors.black.withAlpha(160),
      child: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Floating background particles
            Positioned.fill(
              child: IgnorePointer(
                child: GameParticles(key: _particlesKey),
              ),
            ),

            // Main living presentation card
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                constraints: const BoxConstraints(maxWidth: 420, maxHeight: 540),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFF9E6),
                      Color(0xFFF7ECC8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFFD4B57D), width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header title with badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.template.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '내가 칠한 ${widget.template.title}!',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: forestInk,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _actionSubtitle(cat),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7A6B4E),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Living animated artwork stage
                    Expanded(
                      child: Center(
                        child: BouncyTap(
                          onTap: _handleArtworkTap,
                          musicalSound: true,
                          child: Container(
                            width: 280,
                            height: 290,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFDF5),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFE5D2A6),
                                width: 2.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x226B5234),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: AnimatedBuilder(
                                animation: Listenable.merge([
                                  _motionController,
                                  _tapReactionController,
                                ]),
                                builder: (context, _) => _buildAnimatedArtwork(cat),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Bottom action controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ForestAction(
                          label: '다시 칠하기',
                          caption: '다시 칠하기',
                          icon: Icons.palette_rounded,
                          size: 58,
                          quiet: widget.quiet,
                          onPressed: widget.onClose,
                        ),
                        ForestAction(
                          label: '톡톡 건드리기',
                          caption: '건드리기',
                          icon: Icons.touch_app_rounded,
                          size: 64,
                          quiet: widget.quiet,
                          onPressed: _handleArtworkTap,
                        ),
                        ForestAction(
                          label: '숲으로 쏙!',
                          caption: '숲으로 쏙!',
                          icon: Icons.check_rounded,
                          size: 58,
                          leaf: true,
                          quiet: widget.quiet,
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _actionSubtitle(ColoringCategory cat) {
    switch (cat) {
      case ColoringCategory.vehicle:
        return '부릉부릉~ 살아서 신나게 달려요! 🚗';
      case ColoringCategory.animal:
        return '깡충깡충~ 살아서 춤을 춰요! 🐾';
      case ColoringCategory.object:
      case ColoringCategory.all:
        return '반짝반짝~ 두둥실 살아 움직여요! ✨';
    }
  }

  Widget _buildAnimatedArtwork(ColoringCategory cat) {
    final t = _motionController.value;
    final tapVal = _tapReactionController.value;
    final tapBounce = math.sin(tapVal * math.pi) * 16.0;

    double dx = 0.0;
    double dy = -tapBounce;
    double scaleX = 1.0;
    double scaleY = 1.0;
    double angle = 0.0;

    if (cat == ColoringCategory.vehicle) {
      // 🚗 Vehicles: driving back and forth with suspension wobble
      final isAir = widget.template.id == 'airplane' ||
          widget.template.id == 'helicopter' ||
          widget.template.id == 'rocket' ||
          widget.template.id == 'hot_air_balloon' ||
          widget.template.id == 'ufo';

      if (isAir) {
        // Floating / soaring path
        dx = math.sin(t * 2 * math.pi) * 25.0;
        dy += math.cos(t * 2 * math.pi) * 18.0;
        angle = math.sin(t * 2 * math.pi) * 0.08;
      } else {
        // Ground vehicle driving rumble
        dx = math.sin(t * 2 * math.pi) * 20.0;
        dy += math.sin(t * 8 * math.pi) * 4.0;
        angle = math.sin(t * 2 * math.pi) * 0.04;
        scaleY = 1.0 + math.sin(t * 8 * math.pi) * 0.04;
      }
    } else if (cat == ColoringCategory.animal) {
      // 🐾 Animals: playful jumping with squash & stretch
      final jumpPhase = (t * 2) % 1.0; // Two jumps per loop
      final jumpHeight = math.sin(jumpPhase * math.pi) * 26.0;
      dy -= jumpHeight;
      if (jumpPhase < 0.2 || jumpPhase > 0.8) {
        // Squash on ground
        scaleX = 1.08;
        scaleY = 0.92;
      } else {
        // Stretch in air
        scaleX = 0.94;
        scaleY = 1.06;
      }
      angle = math.sin(t * 2 * math.pi) * 0.08;
    } else {
      // 🎈 Objects: gentle floating + breathing
      dy += math.sin(t * 2 * math.pi) * 14.0;
      angle = math.sin(t * 2 * math.pi) * 0.06;
      final breathe = math.sin(t * 4 * math.pi) * 0.04;
      scaleX = 1.0 + breathe;
      scaleY = 1.0 + breathe;
    }

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(
          scaleX: scaleX,
          scaleY: scaleY,
          child: CustomPaint(
            size: const Size(280, 290),
            painter: _LivingPainter(segments: widget.segments),
          ),
        ),
      ),
    );
  }
}

class _LivingPainter extends CustomPainter {
  const _LivingPainter({required this.segments});

  final List<ColoringSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    // Scale canvas from normalized reference coordinates 280 x 290
    final scaleX = size.width / 280;
    final scaleY = size.height / 290;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    final borderPaint = Paint()
      ..color = const Color(0xFF2C1E11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    for (final seg in segments) {
      if (seg.color != null && !seg.isBorderOnly) {
        fillPaint.color = seg.color!;
        canvas.drawPath(seg.path, fillPaint);
      }
      canvas.drawPath(seg.path, borderPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LivingPainter oldDelegate) => true;
}
