import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// The map uses real-sized controls over one continuous clearing. Nothing on
/// the map counts as a reward, advances a game, or starts the next activity.
class ForestWorldLayout {
  ForestWorldLayout(Size size, int count) {
    final wide = size.width > size.height * 1.2;
    final columns = wide ? count : math.min(2, count);
    final rows = (count / columns).ceil();
    final cellWidth = (size.width - 20) / columns;
    final cellHeight = (size.height - 12) / rows;
    final width = math.min(176.0, math.min(cellWidth - 8, cellHeight / 1.12));
    final height = width * 1.12;
    portals = List.generate(count, (i) {
      final row = i ~/ columns;
      final column = i % columns;
      final rowCount = math.min(columns, count - row * columns);
      final rowWidth = cellWidth * rowCount;
      final x = (size.width - rowWidth) / 2 + cellWidth * (column + .5);
      final y =
          6 +
          cellHeight * (row + .5) +
          (wide ? (i.isEven ? -1 : 1) * math.min(10.0, size.height * .035) : 0);
      return Rect.fromCenter(
        center: Offset(x, y.clamp(height / 2, size.height - height / 2)),
        width: width,
        height: height,
      );
    });
  }
  late final List<Rect> portals;
}

/// Flame draws the stream, butterflies, moving grass and a continuous path.
/// It pauses when the route is hidden, the app is away, or motion is reduced.
class ForestWorldGame extends FlameGame {
  ForestWorldGame({required this.count, required this.area});
  int count, area;
  double elapsed = 0;
  bool motion = true, visible = true;

  @override
  Color backgroundColor() => Colors.transparent;

  void configure({
    required bool animate,
    required bool active,
    required int places,
    required int world,
  }) {
    final redraw = motion != animate || count != places || area != world;
    motion = animate;
    visible = active;
    count = places;
    area = world;
    if (motion && visible) {
      resumeEngine();
    } else {
      pauseEngine();
      if (redraw) stepEngine(stepTime: 0);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt.clamp(0, .05);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0 || count == 0) return;
    paintForestWorld(
      canvas,
      Size(size.x, size.y),
      count,
      area,
      motion ? elapsed : 0,
    );
  }
}

class ForestWorldScene extends StatefulWidget {
  const ForestWorldScene({
    required this.count,
    required this.area,
    required this.quiet,
    required this.child,
    super.key,
  });
  final int count, area;
  final bool quiet;
  final Widget child;
  @override
  State<ForestWorldScene> createState() => _ForestWorldSceneState();
}

class _ForestWorldSceneState extends State<ForestWorldScene>
    with WidgetsBindingObserver {
  late final game = ForestWorldGame(count: widget.count, area: widget.area);
  bool away = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void sync() => game.configure(
    animate: !widget.quiet && !MediaQuery.disableAnimationsOf(context),
    active: !away && TickerMode.valuesOf(context).enabled,
    places: widget.count,
    world: widget.area,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sync();
  }

  @override
  void didUpdateWidget(ForestWorldScene old) {
    super.didUpdateWidget(old);
    sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    away = state != AppLifecycleState.resumed;
    if (mounted) sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    game.pauseEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      IgnorePointer(
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: GameWidget(
              game: game,
              autofocus: false,
              loadingBuilder: (_) =>
                  CustomPaint(painter: _StillWorld(widget.count, widget.area)),
            ),
          ),
        ),
      ),
      widget.child,
    ],
  );
}

class _StillWorld extends CustomPainter {
  const _StillWorld(this.count, this.area);
  final int count, area;
  @override
  void paint(Canvas canvas, Size size) =>
      paintForestWorld(canvas, size, count, area, 0);
  @override
  bool shouldRepaint(_StillWorld old) => old.count != count || old.area != area;
}

void paintForestWorld(Canvas c, Size s, int count, int area, double time) {
  final p = Paint();
  final w = s.width, h = s.height;
  final portals = ForestWorldLayout(s, count).portals;
  final wide = w > h * 1.2;
  final meadow = Path()
    ..moveTo(0, h * .60)
    ..cubicTo(w * .2, h * .34, w * .32, h * .81, w * .57, h * .54)
    ..cubicTo(w * .76, h * .34, w * .9, h * .61, w, h * .45)
    ..lineTo(w, h)
    ..lineTo(0, h)
    ..close();
  c.drawPath(
    meadow,
    p
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x00B9CF86), Color(0x607EAB70)],
      ).createShader(Offset.zero & s),
  );
  p.shader = null;

  // Every destination is grounded on the same sandy woodland trail.
  final trail = Path()..moveTo(w * .5, h + 16);
  final first = portals.first;
  trail.quadraticBezierTo(w * .33, h * .82, first.center.dx, first.bottom - 15);
  for (final r in portals.skip(1)) {
    trail.quadraticBezierTo(
      r.left - 12,
      r.bottom + 14,
      r.center.dx,
      r.bottom - 15,
    );
  }
  c.drawPath(
    trail,
    p
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = (wide ? h * .13 : 28.0).clamp(18.0, 42.0)
      ..color = const Color(0x4097A46A),
  );
  c.drawPath(
    trail,
    p
      ..strokeWidth = (wide ? h * .1 : 22.0).clamp(14.0, 34.0)
      ..color = const Color(0xA0EAD9AC),
  );
  p.style = PaintingStyle.fill;

  for (var i = 0; i < 32; i++) {
    final x = 8 + ((i * 87.17) % (w - 16));
    final y = h * (.75 + (i % 5) * .055);
    final lean = math.sin(time * .65 + i) * 2;
    p
      ..color = i.isEven ? const Color(0xC65C8F58) : const Color(0xB582A866)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(x, y), Offset(x + lean - 3, y - 7), p);
    c.drawLine(Offset(x, y), Offset(x + lean + 4, y - 10), p);
    if (i % 4 == 0) {
      for (var petal = 0; petal < 5; petal++) {
        final a = petal * math.pi * 2 / 5;
        c.drawCircle(
          Offset(x + math.cos(a) * 3, y - 11 + math.sin(a) * 3),
          2.4,
          p
            ..color = area == 2
                ? const Color(0xFFF2B5A7)
                : const Color(0xFFFFF4D0),
        );
      }
      c.drawCircle(Offset(x, y - 11), 1.8, p..color = const Color(0xFFDDBB66));
    }
  }
  // A small pond and two slow ripples create depth without covering controls.
  final pond = Rect.fromCenter(
    center: Offset(w * .88, h * .93),
    width: w * .17,
    height: math.min(38, h * .14),
  );
  c.drawOval(pond.inflate(4), p..color = const Color(0xD2C4D498));
  c.drawOval(
    pond,
    p
      ..shader = const LinearGradient(
        colors: [Color(0xFF9BCBD0), Color(0xFF6AAAB5)],
      ).createShader(pond),
  );
  p.shader = null;
  for (var i = 0; i < 2; i++) {
    final progress = ((time * .18 + i * .5) % 1);
    c.drawOval(
      Rect.fromCenter(
        center: pond.center,
        width: pond.width * (.25 + progress * .5),
        height: pond.height * (.2 + progress * .5),
      ),
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFE6F0D9)
            .withValues(alpha: .6 * (1 - progress)),
    );
  }
  p.style = PaintingStyle.fill;
  // Butterflies move on long arcs, with no flashing or sudden camera motion.
  for (var i = 0; i < 2; i++) {
    final x = w * (.16 + i * .65) + math.sin(time * .23 + i * 2) * 18;
    final y = h * (.14 + i * .08) + math.cos(time * .4 + i) * 7;
    final wing = 3 + math.sin(time * 2 + i).abs() * 3;
    c.save();
    c.translate(x, y);
    c.rotate(-.15);
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(-3, -1),
        width: wing * 1.4,
        height: 8,
      ),
      p..color = const Color(0xE6EFC793),
    );
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(3, -1),
        width: wing * 1.4,
        height: 8,
      ),
      p..color = const Color(0xE6EFAF93),
    );
    c.drawLine(
      const Offset(0, -3),
      const Offset(0, 4),
      p
        ..strokeWidth = 1.5
        ..color = const Color(0xFF886946),
    );
    c.restore();
  }
}
