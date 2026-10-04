import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../utils/audio_policy.dart';

/// Gentle feedback belongs to an actual action: finding, placing, drawing or
/// playing a note. Its engine sleeps once the short response has settled.
enum ForestResponse { discovery, belonging, building, music, painting }

class ForestResponseGame extends FlameGame {
  ForestResponseGame();

  ForestResponse response = ForestResponse.discovery;
  Offset origin = const Offset(.5, .55);
  double elapsed = 2;
  int variation = 0;
  bool get responding => elapsed < 1.35;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  void onMount() {
    super.onMount();
    AudioPolicy.instance.addListener(syncPause);
    syncPause();
  }

  void respond(ForestResponse kind, Offset point) {
    response = kind;
    origin = Offset(point.dx.clamp(.08, .92), point.dy.clamp(.12, .88));
    elapsed = 0;
    variation++;
    syncPause();
  }

  void clear() {
    elapsed = 2;
    pauseEngine();
    stepEngine(stepTime: 0);
  }

  void syncPause() {
    if (AudioPolicy.instance.suspended || !responding) {
      pauseEngine();
    } else {
      resumeEngine();
    }
  }

  @override
  void update(double dt) {
    if (AudioPolicy.instance.suspended) {
      pauseEngine();
      return;
    }
    super.update(dt);
    elapsed += dt.clamp(0, .05);
    if (!responding) pauseEngine();
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    if (!responding || size.x <= 0 || size.y <= 0) return;
    final t = (elapsed / 1.35).clamp(0.0, 1.0);
    final ease = Curves.easeOutCubic.transform(t);
    final fade = (1 - t) * .72;
    final center = Offset(size.x * origin.dx, size.y * origin.dy);
    final radius = math.min(size.x, size.y) * .17;
    const palette = [
      Color(0xFFDFAC76),
      Color(0xFFB2C87F),
      Color(0xFF87B7AA),
      Color(0xFFE8BAAE),
      Color(0xFFE9D399),
    ];
    final tint = palette[response.index];
    if (response == ForestResponse.music ||
        response == ForestResponse.building) {
      for (var ring = 0; ring < 2; ring++) {
        final r = (radius * ease - ring * 15).clamp(0.0, radius);
        canvas.drawOval(
          Rect.fromCenter(center: center, width: r * 2, height: r * .75),
          Paint()
            ..color = tint.withValues(alpha: fade * .7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
    }
    for (var i = 0; i < 9; i++) {
      final angle = i * math.pi * 2 / 9 + variation * .51;
      final spread = radius * (.3 + (i % 3) * .18) * ease;
      final p =
          center +
          Offset(
            math.cos(angle) * spread,
            math.sin(angle) * spread - 26 * ease,
          );
      final paint = Paint()
        ..color = palette[(i + response.index) % palette.length].withValues(
          alpha: fade,
        );
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(angle + t * .65);
      if (response == ForestResponse.music) {
        canvas.drawOval(const Rect.fromLTWH(-5, -2, 10, 7), paint);
        canvas.drawLine(
          const Offset(4, 0),
          const Offset(4, -14),
          paint..strokeWidth = 2,
        );
        canvas.drawLine(const Offset(4, -14), const Offset(10, -11), paint);
      } else if (response == ForestResponse.painting) {
        for (var petal = 0; petal < 5; petal++) {
          final a = petal * math.pi * 2 / 5;
          canvas.drawCircle(
            Offset(math.cos(a) * 4, math.sin(a) * 4),
            3.2,
            paint,
          );
        }
      } else {
        canvas.drawPath(
          Path()
            ..moveTo(-7, 2)
            ..quadraticBezierTo(-3, -8, 8, -3)
            ..quadraticBezierTo(4, 7, -7, 2),
          paint,
        );
        canvas.drawLine(
          const Offset(-5, 2),
          const Offset(6, -2),
          Paint()
            ..color = const Color(0xFFFFF1CE).withValues(alpha: fade)
            ..strokeWidth = 1,
        );
      }
      canvas.restore();
    }
  }

  @override
  void onRemove() {
    AudioPolicy.instance.removeListener(syncPause);
    super.onRemove();
  }
}

class ForestResponseScene extends StatefulWidget {
  const ForestResponseScene({
    required this.event,
    required this.response,
    required this.quiet,
    required this.child,
    super.key,
  });
  final int event;
  final ForestResponse response;
  final bool quiet;
  final Widget child;

  @override
  State<ForestResponseScene> createState() => _ForestResponseSceneState();
}

class _ForestResponseSceneState extends State<ForestResponseScene> {
  final game = ForestResponseGame();
  Offset origin = const Offset(.5, .55);

  @override
  void didUpdateWidget(ForestResponseScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quiet) {
      game.clear();
    } else if (oldWidget.event != widget.event) {
      game.respond(widget.response, origin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize || box.size.isEmpty) return;
        origin = Offset(
          event.localPosition.dx / box.size.width,
          event.localPosition.dy / box.size.height,
        );
      },
      child: Stack(
        children: [
          widget.child,
          if (!widget.quiet)
            Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: GameWidget<ForestResponseGame>(
                    game: game,
                    autofocus: false,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
