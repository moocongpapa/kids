import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../forest_game_ui.dart';

enum ToyHabitatKind { picnic, gathering, hideaway, music, shadows }

/// Quiet, continuous scenery behind the actual objects children manipulate.
/// It never intercepts a gesture, schedules a timer, or produces a sound.
class ToyHabitat extends StatelessWidget {
  const ToyHabitat({
    required this.kind,
    required this.child,
    this.discoveries = 0,
    super.key,
  });

  final ToyHabitatKind kind;
  final Widget child;
  final int discoveries;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _HabitatPainter(kind, discoveries), child: child);
}

/// A growing sprig records discoveries without scores, stars or countdowns.
class ToyDiscoverySprig extends StatelessWidget {
  const ToyDiscoverySprig({
    required this.count,
    required this.total,
    super.key,
  });
  final int count, total;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '전체 $total개 중 $count개',
    child: ExcludeSemantics(
      child: SizedBox(
        width: math.min(180.0, total * 23.0 + 20),
        height: 36,
        child: CustomPaint(painter: _SprigPainter(count, total)),
      ),
    ),
  );
}

/// Selection is represented by a soft, visible ring. This also works with
/// motion disabled and does not depend on reading or hearing a prompt.
class ToySelectionGlow extends StatelessWidget {
  const ToySelectionGlow({
    required this.selected,
    required this.child,
    super.key,
  });
  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected ? const Color(0x40FFE5A5) : Colors.transparent,
      border: Border.all(
        color: selected ? const Color(0xFFD5AA52) : Colors.transparent,
        width: 3,
      ),
    ),
    child: child,
  );
}

class _HabitatPainter extends CustomPainter {
  const _HabitatPainter(this.kind, this.discoveries);
  final ToyHabitatKind kind;
  final int discoveries;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final paint = Paint();
    final ground = Rect.fromLTWH(-w * .12, h * .62, w * 1.24, h * .5);
    paint.shader = const RadialGradient(
      colors: [Color(0xFFD4DDA8), Color(0x70AFC78B), Color(0x009CB779)],
      stops: [0, .67, 1],
    ).createShader(ground);
    canvas.drawOval(ground, paint);
    paint.shader = null;

    // A warm shaft of light and two translucent distant trunks make the
    // landscape read as a clearing, while leaving the center uncluttered.
    final light = Path()
      ..moveTo(w * .65, 0)
      ..lineTo(w * .9, 0)
      ..lineTo(w * .55, h)
      ..lineTo(w * .1, h)
      ..close();
    canvas.drawPath(light, paint..color = const Color(0x16FFF6C8));
    for (final (x, width) in [(w * .04, w * .026), (w * .94, w * .034)]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, -12, width, h * .77),
          const Radius.circular(12),
        ),
        paint..color = const Color(0x18748756),
      );
    }

    if (kind == ToyHabitatKind.picnic) {
      final cloth = Path()
        ..moveTo(w * .16, h * .73)
        ..quadraticBezierTo(w * .48, h * .67, w * .80, h * .75)
        ..lineTo(w * .92, h * .93)
        ..quadraticBezierTo(w * .5, h * 1.02, w * .08, h * .91)
        ..close();
      canvas.drawPath(
        cloth.shift(const Offset(0, 4)),
        paint..color = const Color(0x3078874D),
      );
      canvas.drawPath(cloth, paint..color = const Color(0xFFF0DFC2));
      canvas.save();
      canvas.clipPath(cloth);
      paint
        ..color = const Color(0x40CE8C77)
        ..strokeWidth = 9;
      for (var i = 0; i < 8; i++) {
        final x = w * (.12 + i * .11);
        canvas.drawLine(Offset(x, h * .67), Offset(x - w * .06, h), paint);
      }
      for (var i = 0; i < 4; i++) {
        final y = h * (.76 + i * .065);
        canvas.drawLine(Offset(0, y), Offset(w, y + h * .035), paint);
      }
      canvas.restore();
    } else if (kind == ToyHabitatKind.gathering) {
      _stump(canvas, Offset(w * .26, h * .82), w * .2, h * .09);
      _stump(canvas, Offset(w * .73, h * .84), w * .16, h * .07);
    } else if (kind == ToyHabitatKind.music) {
      final log = Rect.fromLTWH(w * .04, h * .73, w * .92, h * .16);
      canvas.drawRRect(
        RRect.fromRectAndRadius(log, Radius.circular(h * .05)),
        paint..color = const Color(0xB59B744C),
      );
      paint
        ..color = const Color(0x50735939)
        ..strokeWidth = 2;
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(
          Offset(log.left + 12, log.top + 10 + i * log.height / 5),
          Offset(log.right - 12, log.top + 7 + i * log.height / 5),
          paint,
        );
      }
    } else if (kind == ToyHabitatKind.shadows) {
      final beam = Path()
        ..moveTo(w * .5, h * .02)
        ..lineTo(w * .96, h * .86)
        ..quadraticBezierTo(w * .5, h * .95, w * .04, h * .86)
        ..close();
      canvas.drawPath(beam, paint..color = const Color(0x22FFF0B6));
    }

    // Hand drawn tufts and tiny flowers occupy only the edges of the stage.
    for (var i = 0; i < 9; i++) {
      final x = w * (.015 + i * .121);
      final y = h * (.89 + .04 * math.sin(i * 2.4));
      _grass(canvas, Offset(x, y), 11 + i % 3 * 3.0);
      if (i < discoveries.clamp(0, 8)) {
        _flower(canvas, Offset(x + 6, y - 20), 4.2);
      }
    }
    if (kind == ToyHabitatKind.hideaway) {
      for (final p in [Offset(w * .07, h * .48), Offset(w * .90, h * .56)]) {
        _flower(canvas, p, 6);
        _grass(canvas, p + const Offset(0, 20), 18);
      }
    }
    canvas.restore();
  }

  void _stump(Canvas canvas, Offset center, double rx, double depth) {
    final paint = Paint()..color = const Color(0xFFBA9569);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          center.dx - rx,
          center.dy - depth,
          center.dx + rx,
          center.dy + depth,
        ),
        const Radius.circular(14),
      ),
      paint,
    );
    final top = Rect.fromCenter(
      center: center - Offset(0, depth),
      width: rx * 2,
      height: depth * 1.6,
    );
    canvas.drawOval(top, paint..color = const Color(0xFFE7CA94));
    paint
      ..color = const Color(0x60A88257)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(top.deflate(5), paint);
    canvas.drawOval(top.deflate(10), paint);
  }

  void _grass(Canvas canvas, Offset base, double height) {
    final paint = Paint()
      ..color = const Color(0xA177985A)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    for (var i = -1; i <= 1; i++) {
      canvas.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(
            base.dx + i * 3,
            base.dy - height * .6,
            base.dx + i * 7,
            base.dy - height,
          ),
        paint,
      );
    }
  }

  void _flower(Canvas canvas, Offset center, double radius) {
    final paint = Paint()..color = const Color(0xFFECC7A5);
    for (var i = 0; i < 5; i++) {
      final angle = i * math.pi * 2 / 5;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        radius * .7,
        paint,
      );
    }
    canvas.drawCircle(
      center,
      radius * .5,
      paint..color = const Color(0xFFC29953),
    );
  }

  @override
  bool shouldRepaint(_HabitatPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.discoveries != discoveries;
}

class _SprigPainter extends CustomPainter {
  const _SprigPainter(this.count, this.total);
  final int count, total;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9EB281)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(10, size.height * .62),
      Offset(size.width - 10, size.height * .62),
      paint,
    );
    for (var i = 0; i < total; i++) {
      final x = 12 + (size.width - 24) * (i + .5) / total;
      final center = Offset(x, size.height * .45);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i.isEven ? -.55 : .55);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 11, height: 19),
        paint..color = i < count ? forestInk : const Color(0x60A9BC8D),
      );
      canvas.drawLine(
        const Offset(0, -5),
        const Offset(0, 6),
        Paint()
          ..color = const Color(0x50F9F0C5)
          ..strokeWidth = 1,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SprigPainter oldDelegate) =>
      oldDelegate.count != count || oldDelegate.total != total;
}
