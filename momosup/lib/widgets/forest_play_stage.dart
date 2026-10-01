import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'avatar_image.dart';
import 'forest_game_ui.dart';
import 'forest_landscape.dart';

/// A little clearing shared by the games; controls live in the landscape.
class ForestPlayStage extends StatelessWidget {
  const ForestPlayStage({
    required this.child,
    this.river = false,
    this.night = false,
    this.height = 330,
    this.quiet = false,
    super.key,
  });
  final Widget child;
  final bool river, night, quiet;
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: ForestSceneViewport.heightOf(context, height),
    width: double.infinity,
    child: RepaintBoundary(
      child: CustomPaint(painter: _Clearing(river, night), child: child),
    ),
  );
}

class _Clearing extends CustomPainter {
  const _Clearing(this.river, this.night);
  final bool river, night;
  @override
  void paint(Canvas c, Size s) {
    final ground = Rect.fromLTWH(
      2,
      s.height * .46,
      s.width - 4,
      s.height * .51,
    );
    c.drawOval(
      ground.shift(const Offset(0, 7)),
      Paint()
        ..color = const Color(0x3372894D)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    c.drawOval(
      ground,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night
              ? const [Color(0xE6A6BCA7), Color(0xE6799B82)]
              : const [Color(0xE6D9E3B7), Color(0xE6A4BD82)],
        ).createShader(ground),
    );
    c.save();
    c.clipPath(Path()..addOval(ground));
    for (var i = 0; i < 115; i++) {
      final x = (i * 67.7) % s.width;
      final y = ground.top + (i * 41.3) % ground.height;
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 9 + i % 7 * 3,
          height: 3 + i % 4 * 2,
        ),
        Paint()
          ..color = i.isEven
              ? const Color(0x15F9F1C5)
              : const Color(0x0F61814B),
      );
    }
    c.restore();
    final path = Path()
      ..moveTo(s.width * .13, s.height * .7)
      ..cubicTo(
        s.width * .26,
        s.height * .47,
        s.width * .7,
        s.height * .9,
        s.width * .9,
        s.height * .6,
      );
    c.drawPath(
      path,
      Paint()
        ..color = river ? const Color(0xFF91C5D0) : const Color(0xFFE3D6AC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = river ? 64 : 28
        ..strokeCap = StrokeCap.round,
    );
    if (river) {
      for (var i = 0; i < 5; i++) {
        c.drawArc(
          Rect.fromLTWH(
            s.width * (.13 + i * .14),
            s.height * (.67 + math.sin(i) * .09),
            28,
            8,
          ),
          0,
          math.pi,
          false,
          Paint()
            ..color = const Color(0xAAEEF8E6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
    for (var i = 0; i < 17; i++) {
      final x = 15 + (i * 53.0) % (s.width - 30);
      final y = s.height * (.71 + (i % 4) * .065);
      final p = Paint()
        ..color = i.isEven ? const Color(0xFF658D58) : const Color(0xFFF4E7AA)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      c.drawLine(Offset(x, y), Offset(x - 3, y - 7), p);
      c.drawLine(Offset(x, y), Offset(x + 4, y - 6), p);
      if (i % 3 == 0) {
        c.drawCircle(
          Offset(x - 3, y - 8),
          3,
          Paint()..color = const Color(0xFFFFEFC1),
        );
      }
    }
    for (final x in [s.width * .04, s.width * .91]) {
      c.drawOval(
        Rect.fromLTWH(x - 14, s.height * .47, 32, 48),
        Paint()..color = const Color(0xFF7BA065),
      );
      c.drawOval(
        Rect.fromLTWH(x - 22, s.height * .52, 36, 26),
        Paint()..color = const Color(0xFF9DBD75),
      );
    }
  }

  @override
  bool shouldRepaint(_Clearing old) => old.river != river || old.night != night;
}

/// Large physical-looking play pieces, with a tap alternative to dragging.
class PlayPiece extends StatelessWidget {
  const PlayPiece({
    required this.label,
    required this.child,
    required this.onTap,
    this.size = 88,
    this.selected = false,
    this.quiet = false,
    this.dragValue,
    this.enabled = true,
    super.key,
  });
  final String label;
  final Widget child;
  final VoidCallback onTap;
  final double size;
  final bool selected, quiet, enabled;
  final int? dragValue;
  @override
  Widget build(BuildContext context) {
    final picture = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 3,
            child: Container(
              width: size * .72,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0x26708043),
                shape: BoxShape.circle,
              ),
            ),
          ),
          AnimatedScale(
            scale: selected && !quiet ? 1.08 : 1.0,
            duration: quiet ? Duration.zero : const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: quiet
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0x99FFF3B9) : Colors.transparent,
                border: selected
                    ? Border.all(color: const Color(0xFFD8AF56), width: 3)
                    : null,
                boxShadow: selected && !quiet
                    ? [
                        BoxShadow(
                          color: const Color(0xFFD8AF56).withAlpha(120),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.all(6),
              child: child,
            ),
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: dragValue == null || !enabled
              ? picture
              : Draggable<int>(
                  data: dragValue,
                  maxSimultaneousDrags: 1,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Transform.scale(
                      scale: 1.15,
                      child: SizedBox(width: size, height: size, child: child),
                    ),
                  ),
                  childWhenDragging: Opacity(opacity: .25, child: picture),
                  child: picture,
                ),
        ),
      ),
    );
  }
}

/// A bounded reaction: it settles, and reduced-motion mode has no bounce.
class SceneReaction extends StatelessWidget {
  const SceneReaction({
    required this.event,
    required this.quiet,
    required this.child,
    super.key,
  });
  final Object event;
  final bool quiet;
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(event),
    tween: Tween(begin: 0, end: 1),
    duration: quiet ? Duration.zero : const Duration(milliseconds: 850),
    builder: (_, t, child) => Transform.translate(
      offset: Offset(0, quiet ? 0 : -math.sin(t * math.pi) * 15),
      child: Transform.scale(
        scale: quiet ? 1 : 1 + math.sin(t * math.pi) * .07,
        child: child,
      ),
    ),
    child: child,
  );
}

class WoodlandBus extends StatelessWidget {
  const WoodlandBus({
    this.passengers = const [],
    this.quiet = false,
    this.width = 300,
    super.key,
  });
  final List<String> passengers;
  final bool quiet;
  final double width;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: width * .58,
    child: Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _Bus())),
        for (var i = 0; i < passengers.length && i < 3; i++)
          Positioned(
            left: width * (.12 + i * .24),
            top: width * .11,
            child: SceneReaction(
              event: '$i-${passengers[i]}',
              quiet: quiet,
              child: AvatarImage(
                avatar: passengers[i],
                size: width * .19,
                interactive: false,
                lowStimulation: quiet,
                showBlush: !quiet,
              ),
            ),
          ),
      ],
    ),
  );
}

class _Bus extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 300, s.height / 174);
    c.drawOval(
      const Rect.fromLTWH(10, 145, 280, 20),
      Paint()..color = const Color(0x33738656),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6, 20, 288, 125),
        const Radius.circular(35),
      ),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFDF91), Color(0xFFE5A954)],
        ).createShader(const Rect.fromLTWH(0, 20, 300, 125)),
    );
    for (var i = 0; i < 3; i++) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(30 + i * 72, 34, 60, 58),
          const Radius.circular(15),
        ),
        Paint()..color = const Color(0xFFD8ECE0),
      );
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(17, 102, 262, 14),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xFFBC834B),
    );
    for (final x in [65.0, 236.0]) {
      c.drawCircle(
        Offset(x, 142),
        25,
        Paint()..color = const Color(0xFF675F4E),
      );
      c.drawCircle(
        Offset(x, 142),
        13,
        Paint()..color = const Color(0xFFE8D6A3),
      );
      c.drawCircle(Offset(x, 142), 5, Paint()..color = const Color(0xFF8E9666));
    }
    c.drawCircle(
      const Offset(281, 114),
      9,
      Paint()..color = const Color(0xFFFFF1BC),
    );
    c.restore();
  }

  @override
  bool shouldRepaint(_Bus old) => false;
}

class StoryKeepsakes extends StatelessWidget {
  const StoryKeepsakes({required this.items, super.key});
  final List<ForestObject> items;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 12,
    children: [
      for (var i = 0; i < items.length; i++)
        Semantics(
          label: '${i + 1}번째 내가 고른 물건',
          child: SizedBox(
            width: 48,
            height: 48,
            child: ForestProp(items[i], size: 42),
          ),
        ),
    ],
  );
}
