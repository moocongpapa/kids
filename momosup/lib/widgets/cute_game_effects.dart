import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/sound_effects.dart';
import '../utils/audio_policy.dart';
import 'game_particles.dart';

enum FaceMood { idle, happy, surprised, dizzy, singing }

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.animateBlink && !MediaQuery.disableAnimationsOf(context)) {
      _scheduleNextBlink();
    } else {
      _blinkTimer?.cancel();
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
      canvas.drawCircle(
        const Offset(16.5, 24.5),
        1.6,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        const Offset(40.5, 24.5),
        1.6,
        Paint()..color = Colors.white,
      );
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
      canvas.drawCircle(
        const Offset(17, 24.5),
        1.3,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        const Offset(41, 24.5),
        1.3,
        Paint()..color = Colors.white,
      );
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
      canvas.drawPath(mouthPath, Paint()..color = const Color(0xFFE56A70));
      // Tiny tongue
      canvas.save();
      canvas.clipPath(mouthPath);
      canvas.drawCircle(
        const Offset(30, 39),
        5,
        Paint()..color = const Color(0xFFFF9BA2),
      );
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

  const CuteBubblesLayer({super.key, this.particlesKey, this.enabled = true});

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
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(CuteBubblesLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      if (_ticker.isAnimating) {
        _ticker.stop();
        _bubbles.clear();
      }
    } else if (!_ticker.isAnimating) {
      _ticker.repeat();
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
      _bubbles.add(
        _BubbleItem(
          id: _nextId++,
          x: 0.1 + _rng.nextDouble() * 0.8,
          y: size.height + 40,
          size: 38 + _rng.nextDouble() * 26,
          speed: 35 + _rng.nextDouble() * 30,
          swayOffset: _rng.nextDouble() * math.pi * 2,
          color: _bubbleColors[_rng.nextInt(_bubbleColors.length)],
        ),
      );
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
        final xPos =
            (b.x * screenWidth) +
            math.sin(_elapsed * 2.0 + b.swayOffset) * 16.0;
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
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(size * 0.18, size * 0.11),
                    ),
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
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(size * 0.18, size * 0.11),
                    ),
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

/// Tactile game feedback (Haptic impacts) wrapped safely for toddlers
/// and sensitive sound/touch settings.
class GameFeedback {
  /// Subtle tick for taps and drag pickup
  static void tap({bool lowStimulation = false}) {
    if (lowStimulation) return;
    HapticFeedback.selectionClick();
  }

  /// Light bump for snapping or touching targets
  static void light({bool lowStimulation = false}) {
    if (lowStimulation) return;
    HapticFeedback.lightImpact();
  }

  /// Satisfying bump on success (feeding, matching, sorting)
  static void success({bool lowStimulation = false}) {
    if (lowStimulation) return;
    HapticFeedback.mediumImpact();
  }

  /// Big celebration impact on round or game completion
  static void celebration({bool lowStimulation = false}) {
    if (lowStimulation) return;
    HapticFeedback.heavyImpact();
  }
}

/// Plays a playful hop-and-wobble motion when a toddler hesitates for 4+ seconds,
/// gently nudging their attention without disruptive overlay popups.
class IdleNudge extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final Duration idleDuration;
  final bool active;

  const IdleNudge({
    super.key,
    required this.child,
    this.enabled = true,
    this.idleDuration = const Duration(milliseconds: 4200),
    this.active = true,
  });

  @override
  State<IdleNudge> createState() => _IdleNudgeState();
}

class _IdleNudgeState extends State<IdleNudge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _hopAnimation;
  late final Animation<double> _wobbleAnimation;
  Timer? _idleTimer;
  bool _isNudging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _hopAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: -12.0,
        ).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -12.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 60,
      ),
    ]).animate(_controller);

    _wobbleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.09), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.09, end: 0.09), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.09, end: 0.0), weight: 25),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() => _isNudging = false);
          _resetIdleTimer();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resetIdleTimer();
  }

  @override
  void didUpdateWidget(IdleNudge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active || !widget.enabled) {
      _idleTimer?.cancel();
      if (_controller.isAnimating) _controller.stop();
      _isNudging = false;
    } else if (oldWidget.active != widget.active ||
        oldWidget.enabled != widget.enabled) {
      _resetIdleTimer();
    }
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (!widget.enabled || !widget.active) return;
    if (MediaQuery.disableAnimationsOf(context)) return;

    _idleTimer = Timer(widget.idleDuration, () {
      if (!mounted || !widget.active || !widget.enabled) return;
      if (MediaQuery.disableAnimationsOf(context)) return;
      setState(() => _isNudging = true);
      _controller.forward(from: 0.0);
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!_isNudging && !_controller.isAnimating) return child!;
        return Transform.translate(
          offset: Offset(0, _hopAnimation.value),
          child: Transform.rotate(angle: _wobbleAnimation.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Collectible shiny treasure stickers awarded to toddlers for completing games.
class ForestSticker {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color glowColor;
  final String badgeEmoji;

  const ForestSticker({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.glowColor,
    required this.badgeEmoji,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'badgeEmoji': badgeEmoji,
  };

  static const List<ForestSticker> catalog = [
    ForestSticker(
      id: 'golden_acorn',
      name: '황금 도토리',
      description: '숲속 다람쥐가 선물한 반짝이는 황금 도토리예요!',
      icon: Icons.eco_rounded,
      primaryColor: Color(0xFFF59E0B),
      glowColor: Color(0xFFFDE68A),
      badgeEmoji: '🌰',
    ),
    ForestSticker(
      id: 'rainbow_berry',
      name: '무지개 열매',
      description: '달콤한 꿀향기가 나는 알록달록 무지개 열매예요!',
      icon: Icons.bubble_chart_rounded,
      primaryColor: Color(0xFFEC4899),
      glowColor: Color(0xFFFBCFE8),
      badgeEmoji: '🍓',
    ),
    ForestSticker(
      id: 'star_clover',
      name: '별빛 네잎클로버',
      description: '밤하늘 별빛을 듬뿍 머금은 행운의 클로버예요!',
      icon: Icons.filter_vintage_rounded,
      primaryColor: Color(0xFF10B981),
      glowColor: Color(0xFFA7F3D0),
      badgeEmoji: '🍀',
    ),
    ForestSticker(
      id: 'musical_note',
      name: '노래하는 멜로디',
      description: '실로폰 소리를 닮아 맑고 고운 소리가 나요!',
      icon: Icons.music_note_rounded,
      primaryColor: Color(0xFF6366F1),
      glowColor: Color(0xFFC7D2FE),
      badgeEmoji: '🎵',
    ),
    ForestSticker(
      id: 'puzzle_crown',
      name: '숲속 영웅 왕관',
      description: '그림자를 멋지게 맞춘 숲속 작은 영웅의 왕관!',
      icon: Icons.auto_awesome_rounded,
      primaryColor: Color(0xFF8B5CF6),
      glowColor: Color(0xFFDDD6FE),
      badgeEmoji: '👑',
    ),
  ];

  static ForestSticker forToy(String toyName) {
    switch (toyName) {
      case 'feeding':
        return catalog[1];
      case 'sorting':
        return catalog[0];
      case 'peekaboo':
        return catalog[2];
      case 'xylophone':
        return catalog[3];
      case 'puzzle':
      default:
        return catalog[4];
    }
  }
}

/// Shiny collectible sticker badge with gold/star accents.
class ForestStickerBadge extends StatelessWidget {
  final ForestSticker sticker;
  final double size;
  final bool animate;

  const ForestStickerBadge({
    super.key,
    required this.sticker,
    this.size = 110,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [sticker.glowColor, sticker.primaryColor],
        ),
        boxShadow: [
          BoxShadow(
            color: sticker.primaryColor.withAlpha(120),
            blurRadius: 16,
            spreadRadius: 3,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: Colors.white70,
            blurRadius: 6,
            spreadRadius: -2,
            offset: Offset(-2, -2),
          ),
        ],
        border: Border.all(color: const Color(0xFFFFE082), width: 3.5),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(sticker.badgeEmoji, style: TextStyle(fontSize: size * 0.42)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(50),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  sticker.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.12,
                    letterSpacing: -0.3,
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

/// Celebration pop-up dialog that awards the ForestSticker on game completion.
class ForestStickerModal extends StatefulWidget {
  final ForestSticker sticker;
  final VoidCallback onDismiss;
  final bool lowStimulation;

  const ForestStickerModal({
    super.key,
    required this.sticker,
    required this.onDismiss,
    this.lowStimulation = false,
  });

  static Future<void> show(
    BuildContext context, {
    required ForestSticker sticker,
    bool lowStimulation = false,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '보물 스티커',
      barrierColor: Colors.black.withAlpha(140),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, anim1, anim2) => ForestStickerModal(
        sticker: sticker,
        onDismiss: () => Navigator.of(ctx).pop(),
        lowStimulation: lowStimulation,
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(scale: curve, child: child);
      },
    );
  }

  @override
  State<ForestStickerModal> createState() => _ForestStickerModalState();
}

class _ForestStickerModalState extends State<ForestStickerModal> {
  final GlobalKey<GameParticlesState> _particlesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (!widget.lowStimulation) {
      GameFeedback.celebration();
      if (!AudioPolicy.instance.speaking) {
        SoundEffects.instance.tada();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _particlesKey.currentState?.burst(
          origin: const Offset(160, 160),
          count: 24,
          style: ParticleStyle.confetti,
          spread: 220,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!widget.lowStimulation)
              Positioned.fill(
                child: IgnorePointer(child: GameParticles(key: _particlesKey)),
              ),
            Container(
              width: 310,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF5),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFD3BA99), width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '숲속 보물 발견! ✨',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2C1E14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ForestStickerBadge(
                    sticker: widget.sticker,
                    size: 110,
                    animate: !widget.lowStimulation,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.sticker.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D4037),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: widget.onDismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF388E3C),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      '가방에 담기 🎒',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
