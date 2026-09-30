import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'avatar_image.dart';
import 'cute_game_effects.dart';

const forestInk = Color(0xFF284E3D);
const forestCream = Color(0xFFFFF4D6);

enum ForestObject {
  berry,
  raspberry,
  blueberry,
  basket,
  bush,
  music,
  puzzle,
  paint,
  paw,
  sun,
  bus,
  flower,
  cloud,
  leaf,
  home,
  acorn,
  heart,
}

/// Original vector play objects, kept crisp on every phone and tablet.
class ForestProp extends StatelessWidget {
  const ForestProp(this.object, {this.size = 84, super.key});
  final ForestObject object;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: _PropPainter(object)),
  );
}

class ForestFloat extends StatefulWidget {
  const ForestFloat({
    required this.child,
    this.still = false,
    this.offset = 0,
    super.key,
  });
  final Widget child;
  final bool still;
  final double offset;
  @override
  State<ForestFloat> createState() => _ForestFloatState();
}

class _ForestFloatState extends State<ForestFloat>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(ForestFloat oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.still || MediaQuery.disableAnimationsOf(context)) {
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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    child: widget.child,
    builder: (_, child) => Transform.translate(
      offset: Offset(
        0,
        widget.still || MediaQuery.disableAnimationsOf(context)
            ? 0
            : math.sin(controller.value * math.pi * 2 + widget.offset) * 4,
      ),
      child: child,
    ),
  );
}

/// A large tactile wood / leaf control with a spoken accessibility label.
class ForestAction extends StatefulWidget {
  const ForestAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.child,
    this.size = 68,
    this.caption,
    this.leaf = false,
    this.selected = false,
    this.quiet = false,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? child;
  final double size;
  final String? caption;
  final bool leaf, selected, quiet;
  @override
  State<ForestAction> createState() => _ForestActionState();
}

class _ForestActionState extends State<ForestAction> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: widget.label,
    child: Semantics(
      button: true,
      label: widget.label,
      enabled: widget.onPressed != null,
      selected: widget.selected,
      onTap: widget.onPressed,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.onPressed == null
              ? null
              : (_) => setState(() => pressed = true),
          onTapCancel: () => setState(() => pressed = false),
          onTapUp: (_) => setState(() => pressed = false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale:
                pressed &&
                    !widget.quiet &&
                    !MediaQuery.disableAnimationsOf(context)
                ? .92
                : 1,
            duration: const Duration(milliseconds: 120),
            child: Opacity(
              opacity: widget.onPressed == null ? .4 : 1,
              child: SizedBox(
                width: widget.size,
                height: widget.size + (widget.caption == null ? 0 : 22),
                child: Column(
                  children: [
                    SizedBox.square(
                      dimension: widget.size,
                      child: CustomPaint(
                        painter: _ButtonPainter(
                          leaf: widget.leaf,
                          selected: widget.selected,
                        ),
                        child: Center(
                          child:
                              widget.child ??
                              Icon(
                                widget.icon,
                                size: widget.size * .45,
                                color: widget.leaf
                                    ? forestCream
                                    : const Color(0xFF6E482C),
                              ),
                        ),
                      ),
                    ),
                    if (widget.caption != null)
                      Text(
                        widget.caption!,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: forestInk,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class ForestSign extends StatelessWidget {
  const ForestSign(this.text, {this.large = false, super.key});
  final String text;
  final bool large;
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const _WoodSignPainter(),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 34 : 22,
        vertical: large ? 16 : 9,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFF694429),
          fontSize: large ? 29 : 15,
          letterSpacing: large ? 5 : .5,
          fontWeight: FontWeight.w900,
          shadows: const [
            Shadow(color: Color(0xFFFFF3CE), offset: Offset(0, 1)),
          ],
        ),
      ),
    ),
  );
}

class ForestHeader extends StatelessWidget {
  const ForestHeader({
    required this.title,
    required this.onExit,
    this.onReplay,
    this.preview = false,
    super.key,
  });
  final String title;
  final VoidCallback onExit;
  final VoidCallback? onReplay;
  final bool preview;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
    child: Row(
      children: [
        ForestAction(
          label: '놀이 마치기',
          icon: Icons.close_rounded,
          size: 60,
          onPressed: onExit,
        ),
        const Spacer(),
        Flexible(
          flex: 5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ForestSign(title),
              if (preview)
                const Text(
                  '보호자 미리보기',
                  style: TextStyle(fontSize: 11, color: forestInk),
                ),
            ],
          ),
        ),
        const Spacer(),
        if (onReplay != null)
          ForestAction(
            label: '안내 다시 듣기',
            icon: Icons.volume_up_rounded,
            size: 60,
            onPressed: onReplay,
          )
        else
          const SizedBox(width: 60),
      ],
    ),
  );
}

class ForestProgress extends StatelessWidget {
  const ForestProgress({required this.count, required this.total, super.key});
  final int count, total;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '전체 $total개 중 $count개',
    child: ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          total,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: AnimatedScale(
              scale: i < count ? 1.12 : .86,
              duration: const Duration(milliseconds: 240),
              child: Opacity(
                opacity: i < count ? 1 : .25,
                child: const ForestProp(ForestObject.acorn, size: 28),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class ForestCompletion extends StatelessWidget {
  const ForestCompletion({
    required this.avatar,
    required this.onHome,
    required this.offscreen,
    this.quiet = false,
    this.preview = false,
    this.saved = false,
    this.sticker,
    super.key,
  });
  final String avatar, offscreen;
  final VoidCallback onHome;
  final bool quiet, preview, saved;
  final ForestSticker? sticker;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 700;
    final wreathSize = compact ? const Size(220, 174) : const Size(260, 240);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: compact ? 4 : 20),
        const Text(
          '즐거웠어!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: forestInk,
          ),
        ),
        if (sticker != null) ...[
          const SizedBox(height: 6),
          ForestStickerBadge(
            sticker: sticker!,
            size: compact ? 76 : 90,
            animate: !quiet,
          ),
          const SizedBox(height: 4),
          Text(
            '${sticker!.name} 획득!',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: forestInk,
            ),
          ),
        ],
        SizedBox(height: compact ? 8 : 20),
        ForestFloat(
          still: quiet,
          child: SizedBox(
            width: wreathSize.width,
            height: wreathSize.height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: wreathSize, painter: _WreathPainter()),
                AvatarImage(
                  avatar: avatar,
                  size: compact ? 140 : 180,
                  interactive: false,
                  lowStimulation: quiet,
                  showBlush: !quiet,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          label: offscreen,
          child: const ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.waving_hand_rounded, color: forestInk, size: 30),
                SizedBox(width: 12),
                Text(
                  '이제 쉬어요',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: forestInk,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (preview)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(offscreen, textAlign: TextAlign.center),
          ),
        if (saved)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Icon(
              Icons.collections_rounded,
              color: forestInk,
              semanticLabel: '그림이 기기에 저장됐어요',
            ),
          ),
        SizedBox(height: compact ? 12 : 24),
        ForestAction(
          label: '숲으로 돌아가기',
          onPressed: onHome,
          leaf: true,
          quiet: quiet,
          size: 88,
          caption: '우리 숲',
          child: const Icon(Icons.home_rounded, size: 42, color: forestCream),
        ),
        SizedBox(height: compact ? 8 : 24),
      ],
    );
  }
}

class _ButtonPainter extends CustomPainter {
  const _ButtonPainter({this.leaf = false, this.selected = false});
  final bool leaf, selected;
  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(5);
    final path = leaf
        ? (Path()
            ..moveTo(r.left, r.center.dy)
            ..cubicTo(r.left, r.top, r.right, r.top - 8, r.right, r.top + 8)
            ..cubicTo(
              r.right + 4,
              r.bottom,
              r.left + 8,
              r.bottom + 3,
              r.left,
              r.center.dy,
            )
            ..close())
        : (Path()..addRRect(
            RRect.fromRectAndRadius(r, Radius.circular(size.width * .37)),
          ));
    // Match Flutter's deterministic shadow behavior in screenshot tests.
    if (!debugDisableShadows) {
      canvas.drawShadow(path, const Color(0xFF233F2A), 4, false);
    }
    canvas.save();
    canvas.translate(0, 4);
    canvas.drawPath(
      path,
      Paint()..color = leaf ? const Color(0xFF245844) : const Color(0xFFAC7045),
    );
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: leaf
              ? [const Color(0xFF8BB763), const Color(0xFF447C50)]
              : [const Color(0xFFFFE8B0), const Color(0xFFECC281)],
        ).createShader(r),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = selected
            ? Colors.white
            : const Color(0xFFFFF9D9).withAlpha(130)
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 4 : 2,
    );
    if (!leaf) {
      canvas.drawArc(
        r.deflate(7),
        .3,
        1.0,
        false,
        Paint()
          ..color = const Color(0xFFB9864C).withAlpha(70)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_ButtonPainter old) =>
      old.leaf != leaf || old.selected != selected;
}

class _WoodSignPainter extends CustomPainter {
  const _WoodSignPainter();
  @override
  void paint(Canvas c, Size s) {
    final r = RRect.fromRectAndCorners(
      Offset.zero & s,
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(12),
      bottomLeft: const Radius.circular(11),
      bottomRight: const Radius.circular(18),
    );
    c.drawRRect(
      r.shift(const Offset(0, 4)),
      Paint()..color = const Color(0xFFA97548),
    );
    c.drawRRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFBE4AC), Color(0xFFE6BA7D)],
        ).createShader(Offset.zero & s),
    );
    c.drawRRect(
      r.deflate(3),
      Paint()
        ..color = const Color(0xFFFFEFC4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    for (final x in [9.0, s.width - 9]) {
      c.drawCircle(
        Offset(x, s.height / 2),
        2,
        Paint()..color = const Color(0xFF9C724B),
      );
    }
  }

  @override
  bool shouldRepaint(_WoodSignPainter old) => false;
}

class _WreathPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint();
    for (var i = 0; i < 15; i++) {
      final t = math.pi * .1 + i / 14 * math.pi * 1.8;
      c.save();
      c.translate(
        s.width / 2 + math.cos(t) * s.width * .427,
        s.height / 2 + math.sin(t) * s.height * .42,
      );
      c.rotate(t + .6);
      c.drawOval(
        const Rect.fromLTWH(-12, -5, 28, 13),
        p..color = i.isEven ? const Color(0xFF83AC61) : const Color(0xFFABC578),
      );
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_WreathPainter old) => false;
}

class _PropPainter extends CustomPainter {
  const _PropPainter(this.object);
  final ForestObject object;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final p = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void oval(double x, double y, double w, double h, Color color) =>
        canvas.drawOval(
          Rect.fromLTWH(x, y, w, h),
          p
            ..style = PaintingStyle.fill
            ..color = color,
        );
    void line(Offset a, Offset b, Color color, double width) => canvas.drawLine(
      a,
      b,
      p
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
    void leaf(double x, double y, double scale, Color color) {
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(scale);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-26, -24, 6, -38)
        ..quadraticBezierTo(24, -9, 0, 0)
        ..close();
      canvas.drawPath(
        path,
        p
          ..style = PaintingStyle.fill
          ..color = color,
      );
      line(
        const Offset(0, 0),
        const Offset(5, -26),
        color.withGreen((color.g * 255 * .8).round()),
        2,
      );
      canvas.restore();
    }

    const green = Color(0xFF5C934F),
        dark = Color(0xFF356847),
        cream = Color(0xFFFFF2CA);
    switch (object) {
      case ForestObject.berry:
        oval(23, 34, 58, 55, const Color(0xFFBE4F50));
        oval(19, 27, 60, 57, const Color(0xFFEE7B6A));
        oval(28, 35, 13, 6, const Color(0xFFFFB4A0));
        leaf(44, 32, .64, green);
        leaf(62, 34, .6, dark);
        for (var i = 0; i < 8; i++) {
          oval(31 + (i % 3) * 13, 49 + (i ~/ 3) * 11, 3, 5, cream);
        }
      case ForestObject.raspberry:
        for (final spot in [
          const Offset(34, 42),
          const Offset(56, 42),
          const Offset(22, 57),
          const Offset(45, 56),
          const Offset(66, 57),
          const Offset(34, 74),
          const Offset(56, 74),
          const Offset(46, 86),
        ]) {
          oval(spot.dx - 10, spot.dy - 10, 25, 23, const Color(0xFFBC4A62));
          oval(spot.dx - 10, spot.dy - 12, 20, 19, const Color(0xFFEC7D93));
        }
        leaf(42, 34, .65, green);
        leaf(62, 34, .60, dark);
      case ForestObject.blueberry:
        oval(23, 34, 58, 55, const Color(0xFF495B96));
        oval(20, 28, 58, 56, const Color(0xFF7489C4));
        oval(30, 37, 13, 7, const Color(0xFFB4C4EB));
        for (var i = 0; i < 5; i++) {
          final angle = i * math.pi * 2 / 5;
          line(
            const Offset(52, 54),
            Offset(52 + math.cos(angle) * 9, 54 + math.sin(angle) * 9),
            const Color(0xFF4F6095),
            4,
          );
        }
        leaf(51, 32, .65, green);
      case ForestObject.acorn:
        oval(28, 35, 44, 56, const Color(0xFFB77949));
        oval(30, 34, 37, 50, const Color(0xFFD6A467));
        oval(39, 47, 7, 25, const Color(0xFFE8BF80));
        line(const Offset(51, 27), const Offset(55, 16), dark, 6);
        oval(20, 26, 60, 29, const Color(0xFF785134));
        oval(23, 26, 52, 19, const Color(0xFF986840));
        for (var i = 0; i < 5; i++) {
          line(
            Offset(30 + i * 9, 31),
            Offset(27 + i * 9, 40),
            const Color(0xFFBC8A52),
            2,
          );
        }
      case ForestObject.basket:
        canvas.drawArc(
          const Rect.fromLTWH(26, 18, 48, 65),
          math.pi,
          math.pi,
          false,
          p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8
            ..color = const Color(0xFF9B683E),
        );
        final bowl = Path()
          ..moveTo(13, 45)
          ..lineTo(87, 45)
          ..lineTo(76, 88)
          ..quadraticBezierTo(50, 98, 24, 88)
          ..close();
        canvas.drawPath(
          bowl,
          p
            ..style = PaintingStyle.fill
            ..color = const Color(0xFFD1A064),
        );
        for (var i = 0; i < 4; i++) {
          line(
            Offset(20 + i * 2, 53 + i * 10),
            Offset(80 - i * 2, 53 + i * 10),
            const Color(0xFFE9BE7F),
            4,
          );
        }
        for (var i = 0; i < 5; i++) {
          line(
            Offset(25 + i * 12, 49),
            Offset(31 + i * 9, 88),
            const Color(0xFFAD7849),
            3,
          );
        }
        line(
          const Offset(12, 44),
          const Offset(88, 44),
          const Color(0xFFF2C987),
          8,
        );
      case ForestObject.bush:
        oval(8, 65, 85, 25, dark);
        oval(3, 40, 43, 43, green);
        oval(28, 22, 50, 58, const Color(0xFF89B55F));
        oval(58, 42, 39, 41, const Color(0xFF69A258));
        leaf(28, 58, .55, const Color(0xFFB2D077));
        leaf(67, 62, .6, const Color(0xFFA2C76B));
        oval(27, 69, 7, 7, const Color(0xFFDF8B76));
        oval(76, 57, 6, 6, cream);
      case ForestObject.music:
        line(
          const Offset(14, 77),
          const Offset(87, 77),
          const Color(0xFF875A3C),
          11,
        );
        final colors = [
          const Color(0xFFDA816E),
          const Color(0xFFE9B45F),
          const Color(0xFF91B966),
          const Color(0xFF67ABA9),
          const Color(0xFF9B99BD),
        ];
        for (var i = 0; i < 5; i++) {
          final r = RRect.fromRectAndRadius(
            Rect.fromLTWH(9 + i * 17, 28 + i * 5, 14, 50 - i * 4),
            const Radius.circular(7),
          );
          canvas.drawRRect(
            r.shift(const Offset(0, 4)),
            p
              ..style = PaintingStyle.fill
              ..color = const Color(0xFF6F6447),
          );
          canvas.drawRRect(r, p..color = colors[i]);
          oval(14 + i * 17, 35 + i * 5, 4, 4, cream);
        }
        line(
          const Offset(37, 19),
          const Offset(66, 45),
          const Color(0xFF8C653D),
          5,
        );
        oval(28, 9, 18, 18, const Color(0xFFF4D28A));
      case ForestObject.puzzle:
        oval(13, 17, 74, 74, const Color(0xFFC58D57));
        oval(14, 13, 72, 68, const Color(0xFFF0D3A0));
        final star = Path();
        for (var i = 0; i < 10; i++) {
          final a = -math.pi / 2 + i * math.pi / 5;
          final r = i.isEven ? 27.0 : 15.0;
          final x = 50 + math.cos(a) * r, y = 48 + math.sin(a) * r;
          if (i == 0) {
            star.moveTo(x, y);
          } else {
            star.lineTo(x, y);
          }
        }
        star.close();
        canvas.drawPath(star, p..color = const Color(0xFF79A983));
      case ForestObject.paint:
        oval(10, 25, 78, 60, const Color(0xFFAF8056));
        oval(10, 20, 78, 60, const Color(0xFFF0D8A9));
        oval(25, 31, 17, 16, const Color(0xFFDF8373));
        oval(50, 27, 17, 16, const Color(0xFFF0C45F));
        oval(64, 46, 17, 16, const Color(0xFF80B181));
        oval(38, 56, 17, 16, const Color(0xFF77AEBE));
        line(
          const Offset(22, 87),
          const Offset(61, 15),
          const Color(0xFF875C43),
          7,
        );
        line(
          const Offset(60, 17),
          const Offset(67, 5),
          const Color(0xFF769DAB),
          10,
        );
      case ForestObject.paw:
        oval(27, 48, 48, 38, const Color(0xFFBA8657));
        oval(13, 31, 21, 27, const Color(0xFFD5AC78));
        oval(32, 17, 21, 29, const Color(0xFFD5AC78));
        oval(58, 19, 21, 29, const Color(0xFFD5AC78));
        oval(76, 39, 18, 25, const Color(0xFFD5AC78));
      case ForestObject.sun:
        for (var i = 0; i < 10; i++) {
          final a = i * math.pi / 5;
          line(
            Offset(50 + math.cos(a) * 35, 50 + math.sin(a) * 35),
            Offset(50 + math.cos(a) * 43, 50 + math.sin(a) * 43),
            const Color(0xFFE6AE52),
            5,
          );
        }
        oval(24, 24, 52, 52, const Color(0xFFF5CD6C));
        oval(37, 43, 4, 6, const Color(0xFF856749));
        oval(58, 43, 4, 6, const Color(0xFF856749));
        canvas.drawArc(
          const Rect.fromLTWH(43, 52, 14, 9),
          0,
          math.pi,
          false,
          p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const Color(0xFF856749),
        );
      case ForestObject.bus:
        final r = RRect.fromRectAndRadius(
          const Rect.fromLTWH(8, 23, 84, 54),
          const Radius.circular(13),
        );
        canvas.drawRRect(
          r,
          p
            ..style = PaintingStyle.fill
            ..color = const Color(0xFF83A778),
        );
        for (var i = 0; i < 3; i++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(18 + i * 23, 32, 18, 21),
              const Radius.circular(5),
            ),
            p..color = const Color(0xFFDCF0D2),
          );
        }
        line(
          const Offset(13, 63),
          const Offset(87, 63),
          const Color(0xFFE9CA86),
          5,
        );
        oval(20, 67, 20, 20, const Color(0xFF505C4D));
        oval(64, 67, 20, 20, const Color(0xFF505C4D));
        oval(26, 73, 8, 8, cream);
        oval(70, 73, 8, 8, cream);
      case ForestObject.flower:
        line(const Offset(50, 84), const Offset(50, 38), green, 6);
        leaf(50, 78, .65, green);
        leaf(52, 78, -.55, dark);
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          oval(
            40 + math.cos(a) * 17,
            25 + math.sin(a) * 17,
            23,
            23,
            const Color(0xFFF5B09A),
          );
        }
        oval(41, 26, 21, 21, const Color(0xFFF8D16C));
      case ForestObject.cloud:
        oval(9, 44, 82, 35, const Color(0xFFB2C8C1));
        oval(8, 38, 82, 35, const Color(0xFFFFF6D9));
        oval(24, 18, 44, 53, const Color(0xFFFFF6D9));
        oval(53, 33, 36, 36, const Color(0xFFFFF6D9));
      case ForestObject.leaf:
        leaf(39, 89, 2, green);
      case ForestObject.home:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(23, 36, 56, 52),
            const Radius.circular(9),
          ),
          p
            ..style = PaintingStyle.fill
            ..color = const Color(0xFFD7A16A),
        );
        final roof = Path()
          ..moveTo(10, 43)
          ..quadraticBezierTo(36, 17, 54, 12)
          ..quadraticBezierTo(65, 26, 93, 45)
          ..close();
        canvas.drawPath(roof, p..color = green);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(43, 53, 22, 36),
            const Radius.circular(12),
          ),
          p..color = const Color(0xFF876040),
        );
        oval(56, 71, 4, 4, cream);
      case ForestObject.heart:
        final heart = Path()
          ..moveTo(50, 84)
          ..cubicTo(3, 56, 11, 15, 36, 24)
          ..quadraticBezierTo(48, 27, 50, 38)
          ..cubicTo(69, 3, 111, 40, 50, 84)
          ..close();
        canvas.drawPath(
          heart,
          p
            ..style = PaintingStyle.fill
            ..color = const Color(0xFFDE8D7E),
        );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PropPainter old) => old.object != object;
}
