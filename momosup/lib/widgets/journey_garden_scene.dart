import 'forest_landscape.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'forest_game_ui.dart';
import 'forest_play_stage.dart';
import 'touch_invitation.dart';

/// The same little garden persists across the three approved narrated scenes.
class JourneyGardenScene extends StatelessWidget {
  const JourneyGardenScene({
    required this.weather,
    required this.step,
    required this.revealed,
    required this.quiet,
    required this.onTap,
    super.key,
  });
  final bool weather, revealed, quiet;
  final int step;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = weather ? ['구름', '꽃', '해'][step] : '꽃';
    Widget target(Widget child) => Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: _GardenTouch(
          quiet: quiet,
          onTap: onTap,
          child: TouchInvitation(
            visible: !revealed,
            quiet: quiet,
            child: child,
          ),
        ),
      ),
    );
    return SizedBox(
      height: ForestSceneViewport.heightOf(context, 300),
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 340,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: GardenGround()),
              ),
              if (revealed)
                Positioned(
                  top: 28,
                  left: 0,
                  right: 0,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('garden-visitor-$weather-$step'),
                    tween: Tween(begin: 0, end: 1),
                    duration: quiet
                        ? Duration.zero
                        : const Duration(milliseconds: 1800),
                    builder: (_, t, _) => Transform.translate(
                      offset: Offset(
                        (t - .5) * 140,
                        -math.sin(t * math.pi) * 23,
                      ),
                      child: Center(
                        child: CustomPaint(
                          size: const Size(60, 46),
                          painter: _Butterfly(step),
                        ),
                      ),
                    ),
                  ),
                ),
              if (!weather) ...[
                for (var i = 0; i < step; i++)
                  Positioned(
                    left: 20 + i * 222,
                    bottom: 28,
                    child: GardenFlower(
                      variant: i,
                      open: true,
                      size: 95,
                      quiet: quiet,
                    ),
                  ),
                Positioned(
                  bottom: 28,
                  child: target(
                    GardenFlower(
                      key: ValueKey('flower-$step'),
                      variant: step,
                      open: revealed,
                      size: 220,
                      quiet: quiet,
                    ),
                  ),
                ),
                if (revealed)
                  Positioned(
                    right: 23,
                    top: 30,
                    child: ForestProp(
                      step == 2 ? ForestObject.paw : ForestObject.sun,
                      size: 58,
                    ),
                  ),
              ] else ...[
                Positioned(
                  top: 4,
                  left: 35,
                  child: step == 0
                      ? target(const ForestProp(ForestObject.cloud, size: 142))
                      : Opacity(
                          opacity: step == 2 ? .25 : .8,
                          child: const ForestProp(
                            ForestObject.cloud,
                            size: 100,
                          ),
                        ),
                ),
                if (step == 0 && revealed)
                  Positioned(
                    top: 98,
                    left: 55,
                    child: TweenAnimationBuilder<double>(
                      key: const ValueKey('garden-rain'),
                      tween: Tween(begin: 0, end: 1),
                      duration: quiet
                          ? Duration.zero
                          : const Duration(milliseconds: 1200),
                      builder: (_, t, _) => CustomPaint(
                        size: const Size(210, 130),
                        painter: GentleRain(t),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 27,
                  child: step == 1
                      ? target(
                          GardenFlower(
                            variant: 1,
                            open: revealed,
                            size: 205,
                            quiet: quiet,
                          ),
                        )
                      : GardenFlower(
                          variant: 1,
                          open: step == 2,
                          size: 205,
                          quiet: quiet,
                        ),
                ),
                if (step == 2)
                  Positioned(
                    right: 20,
                    top: 0,
                    child: target(
                      AnimatedScale(
                        scale: revealed ? 1.1 : .85,
                        duration: quiet
                            ? Duration.zero
                            : const Duration(milliseconds: 700),
                        child: const ForestProp(ForestObject.sun, size: 120),
                      ),
                    ),
                  ),
                if (step == 2 && revealed)
                  const Positioned(
                    bottom: 28,
                    left: 15,
                    child: ForestProp(ForestObject.paw, size: 58),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GardenTouch extends StatefulWidget {
  const _GardenTouch({
    required this.quiet,
    required this.onTap,
    required this.child,
  });
  final bool quiet;
  final VoidCallback onTap;
  final Widget child;
  @override
  State<_GardenTouch> createState() => _GardenTouchState();
}

class _GardenTouchState extends State<_GardenTouch> {
  int taps = 0;
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      setState(() => taps++);
      widget.onTap();
    },
    child: SceneReaction(event: taps, quiet: widget.quiet, child: widget.child),
  );
}

class GardenFlower extends StatelessWidget {
  const GardenFlower({
    required this.variant,
    required this.open,
    required this.size,
    this.quiet = true,
    super.key,
  });
  final int variant;
  final bool open, quiet;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${['분홍', '노랑', '보라'][variant % 3]} ${open ? '활짝 핀 꽃' : '꽃봉오리'}',
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: open ? 1 : 0),
      duration: quiet ? Duration.zero : const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (_, t, _) =>
          CustomPaint(size: Size(size, size), painter: _Flower(variant, t)),
    ),
  );
}

class _Flower extends CustomPainter {
  _Flower(this.variant, this.open);
  final int variant;
  final double open;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 220, s.height / 220);
    final stem = Paint()
      ..color = const Color(0xFF568C5D)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    c.drawPath(
      Path()
        ..moveTo(111, 207)
        ..quadraticBezierTo(119, 160, 110, 92),
      stem..style = PaintingStyle.stroke,
    );
    for (final flip in [-1.0, 1.0]) {
      c.save();
      c.translate(112, 164);
      c.scale(flip, 1);
      c.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(37, -42, 61, -27)
          ..quadraticBezierTo(37, 10, 0, 0),
        Paint()..color = const Color(0xFF7EAA63),
      );
      c.restore();
    }
    final colors = [
      const Color(0xFFEAA0AD),
      const Color(0xFFF2CD68),
      const Color(0xFFB6A3D3),
    ];
    final center = Offset(110, 91 + (1 - open) * 13);
    c.save();
    c.translate(center.dx, center.dy);
    final petals = [6, 9, 5][variant % 3];
    for (var i = 0; i < petals; i++) {
      c.save();
      c.rotate(i * math.pi * 2 / petals);
      c.drawOval(
        Rect.fromCenter(
          center: Offset(0, -13 - open * 28),
          width: 27 + open * 17,
          height: 47 + open * 25,
        ),
        Paint()..color = colors[variant % 3],
      );
      c.drawOval(
        Rect.fromCenter(
          center: Offset(-5, -27 - open * 25),
          width: 8,
          height: 14 + open * 13,
        ),
        Paint()..color = Colors.white.withValues(alpha: .2),
      );
      c.restore();
    }
    c.drawCircle(
      Offset.zero,
      15 + open * 14,
      Paint()..color = const Color(0xFFFFE3A0),
    );
    if (open > .5) {
      final face = Paint()
        ..color = const Color(0xFF69583F)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      c.drawCircle(const Offset(-8, -2), 2, face);
      c.drawCircle(const Offset(8, -2), 2, face);
      c.drawArc(
        const Rect.fromLTWH(-7, 0, 14, 10),
        0,
        math.pi,
        false,
        face..style = PaintingStyle.stroke,
      );
    } else {
      c.drawPath(
        Path()
          ..moveTo(-25, 11)
          ..quadraticBezierTo(0, 40, 25, 11)
          ..lineTo(12, 39)
          ..lineTo(-10, 40)
          ..close(),
        Paint()..color = const Color(0xFF85AA61),
      );
    }
    c.restore();
    c.restore();
  }

  @override
  bool? hitTest(Offset position) => false;
  @override
  bool shouldRepaint(_Flower old) => old.open != open || old.variant != variant;
}

class GardenGround extends CustomPainter {
  const GardenGround();
  @override
  void paint(Canvas c, Size s) {
    c.drawOval(
      Rect.fromLTWH(5, s.height - 72, s.width - 10, 67),
      Paint()..color = const Color(0xFF7B9D60),
    );
    c.drawOval(
      Rect.fromLTWH(5, s.height - 79, s.width - 10, 65),
      Paint()..color = const Color(0xFFB5C989),
    );
    final p = Paint()..color = const Color(0xFFEEE6AA);
    for (var i = 0; i < 12; i++) {
      c.drawCircle(
        Offset(28 + i * 25, s.height - 36 + math.sin(i * 2) * 15),
        2.5,
        p,
      );
    }
    for (var i = 0; i < 7; i++) {
      final x = 18.0 + i * 49;
      final y = s.height - 47 + math.sin(i) * 8;
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 15, height: 7),
        Paint()..color = const Color(0x88E9DDAC),
      );
      c.drawLine(
        Offset(x + 8, y),
        Offset(x + 12, y - 12),
        Paint()
          ..color = const Color(0xFF719154)
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(GardenGround old) => false;
}

class _Butterfly extends CustomPainter {
  const _Butterfly(this.variant);
  final int variant;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.translate(s.width / 2, s.height / 2);
    final p = Paint()
      ..color = [
        const Color(0xFFE7AF94),
        const Color(0xFFB1BADD),
        const Color(0xFFE9CA76),
      ][variant % 3];
    for (final side in [-1.0, 1.0]) {
      c.save();
      c.scale(side, 1);
      c.drawOval(const Rect.fromLTWH(0, -20, 25, 27), p);
      c.drawOval(const Rect.fromLTWH(0, 1, 18, 17), p);
      c.drawCircle(
        const Offset(14, -9),
        5,
        Paint()..color = const Color(0xFFFFF1C6),
      );
      c.restore();
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-3, -13, 6, 29),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF73784B),
    );
    c.restore();
  }

  @override
  bool shouldRepaint(_Butterfly old) => old.variant != variant;
}

class GentleRain extends CustomPainter {
  const GentleRain(this.progress, {this.sheltered = false});
  final double progress;
  final bool sheltered;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0xFF8EAFBC)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 20; i++) {
      final x = (i % 5 + .5) * s.width / 5;
      final y = ((i ~/ 5) * .25 + progress * .5) % 1 * s.height;
      if (sheltered &&
          x > s.width * .2 &&
          x < s.width * .8 &&
          y > s.height * .35) {
        continue;
      }
      c.drawLine(Offset(x, y), Offset(x - 3, y + 9), p);
    }
  }

  @override
  bool? hitTest(Offset position) => false;
  @override
  bool shouldRepaint(GentleRain old) =>
      old.progress != progress || old.sheltered != sheltered;
}
