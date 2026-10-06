import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'touch_trail.dart';

/// Existing reviewed forest artwork, with gentle light and drifting leaves.
/// Reduced motion keeps the complete forest scene while stopping its ticker.
class ForestBackground extends StatefulWidget {
  const ForestBackground({
    required this.child,
    this.lowStimulation = false,
    this.clearing = false,
    super.key,
  });
  final Widget child;
  final bool lowStimulation;
  final bool clearing;
  @override
  State<ForestBackground> createState() => _ForestBackgroundState();
}

class _ForestBackgroundState extends State<ForestBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncMotion();
  }

  @override
  void didUpdateWidget(ForestBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncMotion();
  }

  void syncMotion() {
    if (widget.lowStimulation || MediaQuery.disableAnimationsOf(context)) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFFC0D69A),
            image: DecorationImage(
              image: AssetImage('assets/images/forest_weather.png'),
              fit: BoxFit.cover,
              alignment: Alignment(-.72, 0),
            ),
          ),
        ),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.clearing
                ? const [
                    Color(0x35C8D6A5),
                    Color(0xAAF4EDCF),
                    Color(0xAACFDDA9),
                  ]
                : const [
                    Color(0x123D6B46),
                    Color(0x30F9EFCE),
                    Color(0x609ABD78),
                  ],
            stops: const [0, .45, 1],
          ),
        ),
      ),
      RepaintBoundary(
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, _) => CustomPaint(
            painter: _ForestLightPainter(
              time:
                  widget.lowStimulation ||
                      MediaQuery.disableAnimationsOf(context)
                  ? 0
                  : controller.value,
            ),
          ),
        ),
      ),
      ForestTouchTrail(
        enabled: !widget.lowStimulation,
        child: widget.child,
      ),
    ],
  );
}

class _ForestLightPainter extends CustomPainter {
  const _ForestLightPainter({required this.time});
  final double time;
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final p = Paint();
    // Sunlight is atmospheric, with no abrupt flashes or visual rewards.
    final ray = Path()
      ..moveTo(w * .32, 0)
      ..lineTo(w * .49, 0)
      ..lineTo(w * .95, h * .8)
      ..lineTo(w * .64, h * .9)
      ..close();
    c.drawPath(
      ray,
      p
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x45FFF7CB), Color(0x00FFF7CB)],
        ).createShader(Offset.zero & s),
    );
    p.shader = null;
    for (var i = 0; i < 9; i++) {
      final x =
          w * ((i * .137 + .07) % 1) + math.sin(time * 2 * math.pi + i) * 9;
      final y = h * (.14 + i * .085) + math.cos(time * 2 * math.pi + i * 2) * 8;
      c.drawCircle(
        Offset(x, y),
        i.isEven ? 2.5 : 1.5,
        p..color = const Color(0xE6FFF5C7),
      );
    }
    // A few leaves at the screen edges create a foreground layer.
    for (var i = 0; i < 6; i++) {
      final right = i.isEven;
      c.save();
      c.translate(right ? w - 5 : 5, h * (.2 + i * .12));
      c.rotate((right ? -.8 : .8) + math.sin(time * math.pi * 2 + i) * .035);
      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-14, -25, 3, -43)
        ..quadraticBezierTo(25, -15, 0, 0)
        ..close();
      c.drawPath(
        leaf,
        p..color = i.isEven ? const Color(0xFF6A9557) : const Color(0xFF8AAA63),
      );
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_ForestLightPainter old) => old.time != time;
}
