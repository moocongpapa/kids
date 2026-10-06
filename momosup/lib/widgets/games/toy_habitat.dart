import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../forest_game_ui.dart';
import '../woodland_art.dart';

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
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      Positioned.fill(child: WoodlandGround(
        frame: kind == ToyHabitatKind.picnic
            ? 2
            : kind == ToyHabitatKind.music
            ? 3
            : 0,
      )),
      child,
    ],
  );
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
