import 'package:flutter/material.dart';

/// All scenes share these painted sheets; Flutter decodes each atlas once.
const woodlandArtAssets = [
  'assets/images/woodland_props_v3.png',
  'assets/images/momo_poses_v3.png',
  'assets/images/friends_poses_v3.png',
  'assets/images/woodland_ground_v3.png',
  'assets/images/woodland_activity_v3.png',
];

enum WoodlandMood { idle, lookLeft, lookRight, open, chew, blink, happy, wave }

/// Draw a single cell without modifying the source art or leaking its neighbours.
class WoodlandSprite extends StatelessWidget {
  const WoodlandSprite({
    required this.asset,
    required this.frame,
    required this.columns,
    required this.rows,
    required this.size,
    this.height,
    super.key,
  });
  final String asset;
  final int frame, columns, rows;
  final double size;
  final double? height;

  @override
  Widget build(BuildContext context) {
    // Painted rows have unequal transparent gutters. These observed bounds keep
    // feet and tufts intact; the original RGBA sheets remain unchanged.
    final stops = asset == woodlandArtAssets[4]
        ? const [0.0, .35, .63, 1.0]
        : asset == woodlandArtAssets[2]
        ? const [0.0, .53, 1.0]
        : null;
    final row = frame ~/ columns;
    final top = stops == null ? row / rows : stops[row];
    final bottom = asset == woodlandArtAssets[4] && row == 1
        ? .625
        : stops?[row + 1];
    final extent = stops == null ? 1 / rows : bottom! - top;
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: height ?? size,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: size * columns,
            maxWidth: size * columns,
            minHeight: (height ?? size) / extent,
            maxHeight: (height ?? size) / extent,
            child: FractionalTranslation(
              translation: Offset(-(frame % columns) / columns, -top),
              child: Image.asset(
                asset,
                width: size * columns,
                height: (height ?? size) / extent,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WoodlandCharacter extends StatelessWidget {
  const WoodlandCharacter({
    required this.avatar,
    required this.size,
    this.mood = WoodlandMood.idle,
    super.key,
  });
  final String avatar;
  final double size;
  final WoodlandMood mood;

  @override
  Widget build(BuildContext context) {
    final momoFrame = switch (mood) {
      WoodlandMood.lookLeft => 2,
      WoodlandMood.lookRight => 1,
      _ => mood.index,
    };
    final friendFrame = switch (mood) {
      WoodlandMood.blink => 2,
      WoodlandMood.happy || WoodlandMood.wave => 3,
      WoodlandMood.lookLeft || WoodlandMood.lookRight || WoodlandMood.open => 1,
      _ => 0,
    };
    return WoodlandSprite(
      asset: woodlandArtAssets[avatar == 'momo' ? 1 : 2],
      frame: avatar == 'momo'
          ? momoFrame
          : (avatar == 'nuri' ? 4 : 0) + friendFrame,
      columns: 4,
      rows: 2,
      size: size,
    );
  }
}

/// Soft contact, not an outline or reward glow. Never receives input.
class WoodlandContactShadow extends StatelessWidget {
  const WoodlandContactShadow({
    required this.width,
    this.height = 14,
    this.lift = 0,
    super.key,
  });
  final double width, height, lift;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color.fromRGBO(61, 76, 40, .23 * (1 - lift.clamp(0.0, .7))),
              const Color(0x00515D38),
            ],
          ),
          borderRadius: BorderRadius.circular(width),
        ),
      ),
    ),
  );
}

/// The same ground art anchors both Flame-backed journeys and widget toys.
class WoodlandGround extends StatelessWidget {
  const WoodlandGround({this.frame = 0, this.night = false, super.key});
  final int frame;
  final bool night;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (_, box) => Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  night ? const Color(0x70516B8B) : Colors.transparent,
                  BlendMode.srcATop,
                ),
                child: WoodlandSprite(
                  asset: woodlandArtAssets[3],
                  frame: frame,
                  columns: 2,
                  rows: 2,
                  size: box.maxWidth,
                  height: box.maxHeight * .74,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Quiet material detail for objects whose geometry changes while playing.
class WoodlandGrainPainter extends CustomPainter {
  const WoodlandGrainPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
    );
    for (var i = 0; i < 7; i++) {
      final x = size.width * (.08 + i * .145);
      final path = Path()
        ..moveTo(x, 0)
        ..cubicTo(
          x + 7,
          size.height * .28,
          x - 9,
          size.height * .68,
          x + 2,
          size.height,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = i.isEven ? const Color(0x24FFF5D6) : const Color(0x187C583A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = i.isEven ? 1.4 : .8,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(WoodlandGrainPainter oldDelegate) => false;
}
