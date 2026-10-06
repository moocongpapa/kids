import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'touch_trail.dart';
import 'woodland_art.dart';

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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _focus = ValueNotifier<Offset>(Offset.zero);
  bool _away = false;
  bool get _still =>
      widget.lowStimulation || MediaQuery.disableAnimationsOf(context);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _away = state != AppLifecycleState.resumed;
    if (mounted) syncMotion();
  }

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
    if (_still || _away || !TickerMode.valuesOf(context).enabled) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focus.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerMove: (event) {
      if (_still || _away) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || box.size.isEmpty) return;
      final next = Offset(
        (event.localPosition.dx / box.size.width - .5).clamp(-.5, .5),
        (event.localPosition.dy / box.size.height - .5).clamp(-.5, .5),
      );
      if ((next - _focus.value).distance > .035) _focus.value = next;
    },
    onPointerUp: (_) => _focus.value = Offset.zero,
    onPointerCancel: (_) => _focus.value = Offset.zero,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ValueListenableBuilder<Offset>(
          valueListenable: _focus,
          child: const RepaintBoundary(
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
          builder: (_, focus, child) => TweenAnimationBuilder<Offset>(
            tween: Tween(end: _still ? Offset.zero : focus * -6),
            duration: _still
                ? Duration.zero
                : const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            child: child,
            builder: (_, shift, child) => Transform.translate(
              offset: shift,
              child: Transform.scale(scale: 1.025, child: child),
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
                      Color(0xC0F4EDCF),
                      Color(0x80CFDDA9),
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
        ForestTouchTrail(enabled: !_still, child: widget.child),
        Positioned(
          left: -23,
          bottom: -28,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: -.45,
              child: WoodlandSprite(
                asset: woodlandArtAssets.first,
                frame: 13,
                columns: 4,
                rows: 4,
                size: 76,
              ),
            ),
          ),
        ),
        Positioned(
          right: -27,
          top: -30,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: 2.7,
              child: WoodlandSprite(
                asset: woodlandArtAssets.first,
                frame: 13,
                columns: 4,
                rows: 4,
                size: 72,
              ),
            ),
          ),
        ),
      ],
    ),
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
  }

  @override
  bool shouldRepaint(_ForestLightPainter old) => old.time != time;
}
