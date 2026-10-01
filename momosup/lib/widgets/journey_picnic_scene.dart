import 'forest_landscape.dart';

import 'package:flutter/material.dart';

import 'avatar_image.dart';
import 'forest_game_ui.dart';
import 'journey_garden_scene.dart';

/// Each gift changes the place or the friend's action. All choices are welcome.
class JourneyPicnicScene extends StatelessWidget {
  const JourneyPicnicScene({
    required this.step,
    required this.gift,
    required this.quiet,
    super.key,
  });
  final int step;
  final String? gift;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final indoors = gift == 'home';
    final resting = step == 1 && gift != null;
    final shelter = gift == 'leaf' || indoors;
    final friend = ['duri', 'nuri', 'momo'][step];
    final response = switch (gift) {
      'leaf' => step == 1 ? '누리가 나뭇잎 자리에 앉았어요' : '두리가 잎 우산 아래로 들어왔어요',
      'home' => '친구가 비를 피해 숲집에서 쉬어요',
      'cloud' => '누리가 폭신한 구름 자리에서 쉬어요',
      'basket' => '친구가 바구니를 열어 소풍을 준비해요',
      'berry' => '모모가 건네받은 열매를 먹어요',
      'heart' => '친구들이 모모 곁에 모여요',
      _ => '비 오는 숲에서 친구가 기다려요',
    };
    return Semantics(
      label: response,
      excludeSemantics: true,
      liveRegion: true,
      child: SizedBox(
        height: ForestSceneViewport.heightOf(context, 300),
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 340,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: GardenGround()),
                ),
                Positioned(
                  top: 16,
                  left: 5,
                  right: 5,
                  height: 200,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('rain-$step-$gift'),
                    tween: Tween(begin: 0, end: 1),
                    duration: quiet
                        ? Duration.zero
                        : const Duration(milliseconds: 1200),
                    builder: (_, t, _) =>
                        CustomPaint(painter: GentleRain(t, sheltered: shelter)),
                  ),
                ),
                const Positioned(
                  top: 0,
                  left: 20,
                  child: ForestProp(ForestObject.cloud, size: 88),
                ),
                const Positioned(
                  top: 14,
                  right: 5,
                  child: ForestProp(ForestObject.cloud, size: 62),
                ),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _PicnicBlanket()),
                  ),
                ),
                if (indoors)
                  const Positioned(
                    right: 20,
                    bottom: 48,
                    child: ForestProp(ForestObject.home, size: 205),
                  ),
                if (gift == 'leaf')
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _PicnicLeaf(resting)),
                    ),
                  ),
                if (gift == 'cloud')
                  const Positioned(
                    bottom: 53,
                    child: ForestProp(ForestObject.cloud, size: 210),
                  ),
                AnimatedPositioned(
                  duration: quiet
                      ? Duration.zero
                      : const Duration(milliseconds: 750),
                  curve: Curves.easeInOutCubic,
                  left: indoors
                      ? 140
                      : gift == 'basket'
                      ? 60
                      : 97,
                  bottom: resting ? 63 : 65,
                  child: AnimatedRotation(
                    turns: resting ? -.035 : 0,
                    duration: quiet
                        ? Duration.zero
                        : const Duration(milliseconds: 700),
                    child: AvatarImage(
                      avatar: friend,
                      size: resting ? 130 : 145,
                      interactive: false,
                      lowStimulation: quiet,
                      showBlush: gift != null,
                    ),
                  ),
                ),
                if (gift == 'basket') ...[
                  const Positioned(
                    right: 44,
                    bottom: 43,
                    child: ForestProp(ForestObject.basket, size: 107),
                  ),
                  const Positioned(
                    right: 67,
                    bottom: 104,
                    child: ForestProp(ForestObject.berry, size: 48),
                  ),
                ],
                if (gift == 'berry')
                  Positioned(
                    left: 151,
                    bottom: 101,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1, end: .55),
                      duration: quiet
                          ? Duration.zero
                          : const Duration(milliseconds: 900),
                      builder: (_, t, child) =>
                          Transform.scale(scale: t, child: child),
                      child: const ForestProp(ForestObject.berry, size: 54),
                    ),
                  ),
                if (gift == 'heart') ...[
                  const Positioned(
                    left: 0,
                    bottom: 49,
                    child: AvatarImage(
                      avatar: 'duri',
                      size: 102,
                      interactive: false,
                    ),
                  ),
                  const Positioned(
                    right: 0,
                    bottom: 49,
                    child: AvatarImage(
                      avatar: 'nuri',
                      size: 102,
                      interactive: false,
                    ),
                  ),
                ],
                if (gift != null)
                  Positioned(
                    top: 25,
                    right: 58,
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey('response-$step-$gift'),
                      tween: Tween(begin: .65, end: 1),
                      duration: quiet
                          ? Duration.zero
                          : const Duration(milliseconds: 600),
                      builder: (_, t, child) =>
                          Transform.scale(scale: t, child: child),
                      child: const ForestProp(ForestObject.heart, size: 43),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PicnicBlanket extends CustomPainter {
  const _PicnicBlanket();
  @override
  void paint(Canvas c, Size s) {
    final rug = Path()
      ..moveTo(68, 218)
      ..lineTo(268, 214)
      ..quadraticBezierTo(279, 215, 286, 223)
      ..lineTo(318, 264)
      ..quadraticBezierTo(318, 272, 304, 273)
      ..lineTo(34, 273)
      ..quadraticBezierTo(22, 271, 28, 263)
      ..lineTo(58, 224)
      ..close();
    c.save();
    c.clipPath(rug);
    c.drawPath(rug, Paint()..color = const Color(0xFFFFE5BE));
    final stripe = Paint()
      ..color = const Color(0xFFC68F69).withValues(alpha: .3);
    for (var x = 22.0; x < 320; x += 36) {
      c.drawRect(Rect.fromLTWH(x, 213, 15, 62), stripe);
    }
    for (var y = 215.0; y < 274; y += 22) {
      c.drawRect(Rect.fromLTWH(20, y, 302, 9), stripe);
    }
    c.restore();
    c.drawPath(
      rug,
      Paint()
        ..color = const Color(0xFFF3D7A7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_PicnicBlanket old) => false;
}

class _PicnicLeaf extends CustomPainter {
  const _PicnicLeaf(this.resting);
  final bool resting;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    if (resting) {
      c.translate(0, 169);
      c.scale(1, .65);
    }
    final leaf = Path()
      ..moveTo(52, 117)
      ..cubicTo(80, 46, 207, 29, 294, 99)
      ..cubicTo(227, 85, 142, 153, 52, 117)
      ..close();
    c.drawPath(
      leaf,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF99BC68), Color(0xFF548C55)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(const Rect.fromLTWH(52, 45, 242, 95)),
    );
    final vein = Paint()
      ..color = const Color(0xFFCEE09A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    c.drawPath(
      Path()
        ..moveTo(59, 115)
        ..quadraticBezierTo(171, 77, 285, 98),
      vein,
    );
    for (var i = 0; i < 4; i++) {
      final x = 96.0 + i * 37;
      c.drawPath(
        Path()
          ..moveTo(x, 99 - i * 2)
          ..lineTo(x + 13, 67 + i * 3),
        vein,
      );
    }
    if (!resting) {
      c.drawPath(
        Path()
          ..moveTo(206, 91)
          ..lineTo(206, 187)
          ..quadraticBezierTo(206, 201, 193, 195),
        Paint()
          ..color = const Color(0xFF6B8750)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_PicnicLeaf old) => old.resting != resting;
}
