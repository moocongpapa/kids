import 'forest_landscape.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'forest_game_ui.dart';
import 'forest_play_stage.dart';
import 'touch_invitation.dart';
import 'woodland_art.dart';

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
              const Positioned.fill(child: WoodlandGround()),
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
                      : IgnorePointer(
                          child: GardenFlower(
                            variant: 1,
                            open: step == 2,
                            size: 205,
                            quiet: quiet,
                          ),
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
      builder: (_, t, _) => SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            Opacity(
              opacity: 1 - t,
              child: WoodlandSprite(
                asset: woodlandArtAssets[4],
                frame: 3,
                columns: 4,
                rows: 3,
                size: size,
              ),
            ),
            Opacity(
              opacity: t,
              child: Transform.scale(
                scale: .92 + t * .08,
                alignment: Alignment.bottomCenter,
                child: WoodlandSprite(
                  asset: woodlandArtAssets[4],
                  frame: variant % 3,
                  columns: 4,
                  rows: 3,
                  size: size,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
