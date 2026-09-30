import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'forest_game_ui.dart';
import 'forest_play_stage.dart';

class ArtMark {
  ArtMark(this.color, this.points, {this.width = 15, this.stamp = 0});
  final Color color;
  final List<Offset> points;
  final double width;
  final int stamp;
  Map<String, dynamic> toJson() => {
    'color': color.toARGB32(),
    'width': width,
    'stamp': stamp,
    'points': points.map((p) => [p.dx, p.dy]).toList(),
  };
  factory ArtMark.fromJson(Map<String, dynamic> j) => ArtMark(
    Color(j['color'] as int),
    (j['points'] as List)
        .map((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList(),
    width: (j['width'] as num).toDouble(),
    stamp: j['stamp'] as int,
  );
}

/// Normalised strokes keep drawings intact when the device changes size.
class ForestArtStudio extends StatefulWidget {
  const ForestArtStudio({
    required this.theme,
    required this.marks,
    required this.onChanged,
    required this.quiet,
    this.captureKey,
    this.canvasKey,
    this.locked = false,
    this.simple = false,
    super.key,
  });
  final String theme;
  final List<ArtMark> marks;
  final VoidCallback onChanged;
  final bool quiet, locked, simple;
  final GlobalKey? captureKey;
  final Key? canvasKey;
  @override
  State<ForestArtStudio> createState() => _ForestArtStudioState();
}

class _ForestArtStudioState extends State<ForestArtStudio> {
  static const colors = [
    Color(0xFFD98179),
    Color(0xFFE9C35E),
    Color(0xFF78A976),
    Color(0xFF7CAEC8),
    Color(0xFFB397CB),
    Color(0xFF536E5B),
  ];
  int color = 0, stamp = 0, wiggle = 0;
  bool broad = true;
  ArtMark? current;
  int? drawingPointer;
  Offset point(Offset p, Size s) =>
      Offset((p.dx / s.width).clamp(0, 1), (p.dy / s.height).clamp(0, 1));
  void compactMarks() {
    if (widget.marks.fold<int>(0, (n, m) => n + m.points.length) < 12000) {
      return;
    }
    for (final mark in widget.marks.where(
      (m) => m.stamp == 0 && m.points.length > 8,
    )) {
      final reduced = [
        for (var i = 0; i < mark.points.length; i += 2) mark.points[i],
        mark.points.last,
      ];
      mark.points
        ..clear()
        ..addAll(reduced);
    }
  }

  void begin(Offset p, Size s) {
    if (widget.locked) return;
    compactMarks();
    setState(() {
      current = ArtMark(
        colors[color],
        [point(p, s)],
        width: broad ? 19 : 8,
        stamp: stamp,
      );
      widget.marks.add(current!);
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SceneReaction(
        event: wiggle,
        quiet: widget.quiet,
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFD4B57D),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: const Color(0xFFAF8C57), width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x447B744B),
                offset: Offset(0, 7),
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: RepaintBoundary(
              key: widget.captureKey,
              child: AspectRatio(
                aspectRatio: 1.08,
                child: LayoutBuilder(
                  builder: (_, box) => RawGestureDetector(
                    key: widget.canvasKey,
                    behavior: HitTestBehavior.opaque,
                    // Own a stroke from pointer down so a scrolling parent
                    // cannot steal diagonal or mostly vertical drawing strokes.
                    gestures: widget.locked
                        ? {}
                        : {
                            EagerGestureRecognizer:
                                GestureRecognizerFactoryWithHandlers<
                                  EagerGestureRecognizer
                                >(EagerGestureRecognizer.new, (_) {}),
                          },
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (d) {
                        if (widget.locked || drawingPointer != null) return;
                        drawingPointer = d.pointer;
                        begin(d.localPosition, box.biggest);
                      },
                      onPointerMove: (d) {
                        if (widget.locked ||
                            current == null ||
                            drawingPointer != d.pointer) {
                          return;
                        }
                        compactMarks();
                        final p = point(d.localPosition, box.biggest);
                        if (stamp != 0 &&
                            (current!.points.last - p).distance < .12) {
                          return;
                        }
                        setState(() => current!.points.add(p));
                        widget.onChanged();
                      },
                      onPointerUp: (d) {
                        if (drawingPointer == d.pointer) {
                          drawingPointer = null;
                          current = null;
                        }
                      },
                      onPointerCancel: (d) {
                        if (drawingPointer == d.pointer) {
                          drawingPointer = null;
                          current = null;
                        }
                      },
                      child: CustomPaint(
                        painter: ForestArtPainter(widget.theme, widget.marks),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 18),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 2,
        runSpacing: 5,
        children: [
          for (var i = 0; i < (widget.simple ? 3 : colors.length); i++)
            PlayPiece(
              label: '${['분홍', '노랑', '초록', '파랑', '보라', '짙은 초록'][i]} 크레용',
              size: 56,
              quiet: widget.quiet,
              selected: color == i,
              enabled: !widget.locked,
              onTap: () => setState(() => color = i),
              child: CustomPaint(
                painter: _Crayon(colors[i]),
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 5,
        runSpacing: 5,
        children: [
          for (var i = 0; i < 4; i++)
            PlayPiece(
              label: ['붓으로 그리기', '꽃 도장', '나뭇잎 도장', '반짝 도장'][i],
              size: 61,
              selected: stamp == i,
              quiet: widget.quiet,
              enabled: !widget.locked,
              onTap: () => setState(() => stamp = i),
              child: i == 0
                  ? const ForestProp(ForestObject.paint, size: 46)
                  : CustomPaint(
                      painter: _StampPreview(i, colors[color]),
                      child: const SizedBox.expand(),
                    ),
            ),
          PlayPiece(
            label: '마지막 선 지우기',
            size: 61,
            quiet: widget.quiet,
            enabled: widget.marks.isNotEmpty && !widget.locked,
            onTap: () {
              setState(() => widget.marks.removeLast());
              widget.onChanged();
            },
            child: const Icon(Icons.undo_rounded, color: forestInk, size: 31),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PlayPiece(
            label: broad ? '가는 붓으로 바꾸기' : '굵은 붓으로 바꾸기',
            size: 62,
            quiet: widget.quiet,
            onTap: () => setState(() => broad = !broad),
            child: Center(
              child: Container(
                width: broad ? 25 : 10,
                height: broad ? 25 : 10,
                decoration: BoxDecoration(
                  color: colors[color],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          PlayPiece(
            label: '그림 흔들어 보기',
            size: 62,
            quiet: widget.quiet,
            enabled: widget.marks.isNotEmpty,
            onTap: () => setState(() => wiggle++),
            child: const ForestProp(ForestObject.heart, size: 46),
          ),
        ],
      ),
    ],
  );
}

class ForestArtPainter extends CustomPainter {
  const ForestArtPainter(this.theme, this.marks);
  final String theme;
  final List<ArtMark> marks;
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFFFF9E9));
    for (var i = 0; i < 45; i++) {
      c.drawCircle(
        Offset((i * 79.0) % s.width, (i * 43.0) % s.height),
        1.5,
        Paint()..color = const Color(0x147B976B),
      );
    }
    for (final mark in marks) {
      Offset scale(Offset p) => Offset(p.dx * s.width, p.dy * s.height);
      if (mark.stamp != 0) {
        for (final p in mark.points) {
          c.save();
          c.translate(scale(p).dx, scale(p).dy);
          drawArtStamp(c, mark.stamp, mark.color, mark.width * 1.6);
          c.restore();
        }
      } else if (mark.points.length == 1) {
        c.drawCircle(
          scale(mark.points.first),
          mark.width / 2,
          Paint()..color = mark.color,
        );
      } else {
        final path = Path()
          ..moveTo(scale(mark.points.first).dx, scale(mark.points.first).dy);
        for (final p in mark.points.skip(1)) {
          final q = scale(p);
          path.lineTo(q.dx, q.dy);
        }
        c.drawPath(
          path,
          Paint()
            ..color = mark.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = mark.width
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
    c.save();
    c.scale(s.width / 320, s.height / 300);
    final ink = Paint()
      ..color = const Color(0x997B9476)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (theme == 'my_bus' || theme == 'age_30_05') {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(25, 78, 270, 142),
          const Radius.circular(32),
        ),
        ink,
      );
      for (final x in [48.0, 127.0, 206.0]) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 96, 60, 60),
            const Radius.circular(12),
          ),
          ink,
        );
      }
      for (final x in [80.0, 243.0]) {
        c.drawCircle(Offset(x, 226), 25, ink);
        c.drawCircle(Offset(x, 226), 10, ink);
      }
      c.drawLine(const Offset(39, 182), const Offset(280, 182), ink);
    } else if (theme == 'feeling_cloud' || theme == 'age_36_05') {
      final cloud = Path()
        ..moveTo(60, 197)
        ..cubicTo(0, 185, 19, 102, 76, 121)
        ..cubicTo(72, 57, 163, 32, 190, 102)
        ..cubicTo(235, 57, 294, 100, 267, 142)
        ..cubicTo(324, 163, 288, 218, 253, 198)
        ..close();
      c.drawPath(cloud, ink);
      c.drawArc(const Rect.fromLTWH(124, 155, 70, 29), 0, math.pi, false, ink);
      c.drawCircle(const Offset(133, 143), 4, ink);
      c.drawCircle(const Offset(187, 143), 4, ink);
    } else if (theme == 'hand_shapes') {
      c.drawPath(
        Path()
          ..moveTo(111, 242)
          ..lineTo(61, 156)
          ..quadraticBezierTo(41, 113, 73, 126)
          ..lineTo(106, 159)
          ..lineTo(93, 66)
          ..quadraticBezierTo(97, 39, 115, 65)
          ..lineTo(136, 140)
          ..lineTo(138, 40)
          ..quadraticBezierTo(151, 18, 162, 42)
          ..lineTo(166, 134)
          ..lineTo(190, 57)
          ..quadraticBezierTo(209, 37, 213, 63)
          ..lineTo(195, 151)
          ..lineTo(226, 98)
          ..quadraticBezierTo(250, 84, 248, 112)
          ..lineTo(215, 240)
          ..close(),
        ink,
      );
    } else {
      c.drawPath(
        Path()
          ..moveTo(15, 260)
          ..quadraticBezierTo(140, 238, 307, 265),
        ink,
      );
      for (var i = 0; i < 3; i++) {
        final x = 64.0 + i * 96;
        final y = 111.0 + (i % 2) * 28;
        c.drawPath(
          Path()
            ..moveTo(x, 251)
            ..quadraticBezierTo(x + 12, 185, x, y),
          ink,
        );
        for (var j = 0; j < 6; j++) {
          final a = j * math.pi / 3;
          c.drawCircle(
            Offset(x + math.cos(a) * 27, y + math.sin(a) * 27),
            17,
            ink,
          );
        }
        c.drawCircle(Offset(x, y), 14, ink);
        c.drawOval(Rect.fromLTWH(x, 201, 35, 15), ink);
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(ForestArtPainter old) => true;
}

void drawArtStamp(Canvas c, int stamp, Color color, double radius) {
  final p = Paint()..color = color;
  if (stamp == 1) {
    for (var i = 0; i < 5; i++) {
      final a = i * math.pi * 2 / 5;
      c.drawCircle(
        Offset(math.cos(a) * radius * .5, math.sin(a) * radius * .5),
        radius * .4,
        p,
      );
    }
    c.drawCircle(
      Offset.zero,
      radius * .25,
      Paint()..color = const Color(0xFFFFE9A1),
    );
  } else if (stamp == 2) {
    c.drawPath(
      Path()
        ..moveTo(-radius, radius * .5)
        ..quadraticBezierTo(-radius, -radius, radius, -radius * .6)
        ..quadraticBezierTo(radius, radius, -radius, radius * .5),
      p,
    );
    c.drawLine(
      Offset(-radius * .65, radius * .3),
      Offset(radius * .7, -radius * .4),
      Paint()
        ..color = const Color(0x99FFF5CE)
        ..strokeWidth = 2,
    );
  } else {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * .45;
      final a = i * math.pi / 5 - math.pi / 2;
      final q = Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        path.moveTo(q.dx, q.dy);
      } else {
        path.lineTo(q.dx, q.dy);
      }
    }
    c.drawPath(path..close(), p);
  }
}

class _StampPreview extends CustomPainter {
  const _StampPreview(this.stamp, this.color);
  final int stamp;
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.translate(s.width / 2, s.height / 2);
    drawArtStamp(c, stamp, color, s.width * .4);
    c.restore();
  }

  @override
  bool shouldRepaint(_StampPreview old) =>
      old.color != color || old.stamp != stamp;
}

class _Crayon extends CustomPainter {
  const _Crayon(this.color);
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          s.width * .23,
          s.height * .23,
          s.width * .54,
          s.height * .7,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = color,
    );
    c.drawPath(
      Path()
        ..moveTo(s.width * .23, s.height * .27)
        ..lineTo(s.width / 2, 1)
        ..lineTo(s.width * .77, s.height * .27)
        ..close(),
      Paint()..color = color,
    );
    c.drawRect(
      Rect.fromLTWH(
        s.width * .23,
        s.height * .48,
        s.width * .54,
        s.height * .23,
      ),
      Paint()..color = const Color(0x66FFF4D6),
    );
  }

  @override
  bool shouldRepaint(_Crayon old) => old.color != color;
}
