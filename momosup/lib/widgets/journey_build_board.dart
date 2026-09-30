import '../game/build_experiment.dart';
import '../game/forest_experiment_scene.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'avatar_image.dart';
import 'forest_game_ui.dart';
import 'forest_play_stage.dart';
import 'journey_garden_scene.dart';

class JourneyBuildPiece extends StatelessWidget {
  const JourneyBuildPiece({
    required this.id,
    required this.value,
    required this.quiet,
    super.key,
  });
  final String id;
  final int value;
  final bool quiet;
  @override
  Widget build(BuildContext context) => id == 'age_60_02'
      ? AvatarImage(
          avatar: ['momo', 'duri', 'nuri'][value % 3],
          size: 74,
          interactive: false,
          lowStimulation: quiet,
          showBlush: !quiet,
        )
      : id == 'age_60_06' || id == 'age_84_02'
      ? value == (id == 'age_84_02' ? 1 : 2)
            ? const ForestProp(ForestObject.home, size: 72)
            : GardenFlower(variant: value, open: true, size: 72, quiet: quiet)
      : CustomPaint(
          painter: _BridgePlank(value),
          child: const SizedBox.expand(),
        );
}

/// Children place pieces into the world and send a friend through their creation.
class JourneyBuildBoard extends StatelessWidget {
  const JourneyBuildBoard({
    required this.id,
    required this.slots,
    required this.count,
    required this.active,
    required this.quiet,
    required this.onPlace,
    this.onDrop,
    this.trial,
    this.onTrialFinished,
    super.key,
  });
  final BuildTrial? trial;
  final VoidCallback? onTrialFinished;
  final String id;
  final Map<int, int> slots;
  final int count, active;
  final bool quiet;
  final ValueChanged<int> onPlace;
  final void Function(int index, int value)? onDrop;
  bool get house => id == 'age_36_06' || id == 'age_60_03';
  bool get bus => id == 'age_60_02';
  bool get garden => id == 'age_60_06' || id == 'age_84_02';
  @override
  Widget build(BuildContext context) => ForestPlayStage(
    height: 325,
    river: !house && !garden && !bus,
    quiet: quiet,
    child: LayoutBuilder(
      builder: (_, box) {
        final w = box.maxWidth;
        final positions = <Rect>[
          for (var i = 0; i < count; i++)
            if (house)
              i == 0
                  ? Rect.fromLTWH(w * .17, 17, w * .66, 90)
                  : Rect.fromLTWH(
                      w * .19 + (i - 1) * w * .62 / (count - 1),
                      108,
                      w * .62 / (count - 1),
                      121,
                    )
            else if (garden)
              Rect.fromLTWH(
                w * (.08 + (i % 2) * .48),
                35 + (i ~/ 2) * 118,
                w * .37,
                109,
              )
            else if (bus)
              Rect.fromLTWH(
                w * .09 + i * w * .78 / count,
                122,
                w * .75 / count,
                83,
              )
            else
              Rect.fromLTWH(
                i * (w - 12) / count + 6,
                166 + math.sin(i * 1.1) * 16,
                (w - 20) / count,
                88,
              ),
        ];
        return Stack(
          children: [
            if (bus)
              Positioned(
                left: 0,
                right: 0,
                top: 85,
                child: WoodlandBus(width: w, quiet: quiet),
              ),
            if (!house && !bus && !garden) ...[
              const Positioned(
                left: 0,
                top: 65,
                child: ForestProp(ForestObject.bush, size: 95),
              ),
              const Positioned(
                right: 0,
                top: 53,
                child: ForestProp(ForestObject.home, size: 104),
              ),
            ],
            for (var i = 0; i < count; i++)
              Positioned.fromRect(
                rect: positions[i],
                child: DragTarget<int>(
                  onWillAcceptWithDetails: (d) =>
                      active < 0 && d.data >= 0 && d.data < 3,
                  onAcceptWithDetails: (d) => onDrop?.call(i, d.data),
                  builder: (_, candidates, _) => Semantics(
                    label: '${i + 1}번째 빈 자리',
                    button: true,
                    child: Tooltip(
                      message: '${i + 1}번째 빈 자리',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: active < 0 ? () => onPlace(i) : null,
                        child: AnimatedScale(
                          scale: candidates.isNotEmpty && !quiet ? 1.06 : 1,
                          duration: const Duration(milliseconds: 180),
                          child: SceneReaction(
                            event: 'piece-$i-${slots[i]}',
                            quiet: quiet,
                            child: Opacity(
                              opacity: slots.containsKey(i) ? 1 : .27,
                              child: bus
                                  ? AvatarImage(
                                      avatar: [
                                        'momo',
                                        'duri',
                                        'nuri',
                                      ][(slots[i] ?? i) % 3],
                                      size: 85,
                                      interactive: false,
                                      lowStimulation: quiet,
                                      showBlush: slots.containsKey(i),
                                    )
                                  : house
                                  ? CustomPaint(
                                      painter: _HousePart(i, slots[i] ?? 0),
                                    )
                                  : garden
                                  ? (slots[i] == (id == 'age_84_02' ? 1 : 2)
                                        ? const ForestProp(
                                            ForestObject.home,
                                            size: 100,
                                          )
                                        : GardenFlower(
                                            variant: slots[i] ?? i,
                                            open: slots.containsKey(i),
                                            size: positions[i].width,
                                            quiet: quiet,
                                          ))
                                  : CustomPaint(
                                      painter: _BridgePlank(slots[i] ?? 0),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (trial == null)
              AnimatedPositioned(
                duration: quiet
                    ? Duration.zero
                    : const Duration(milliseconds: 370),
                curve: Curves.easeInOut,
                left: active < 0
                    ? 4
                    : positions[active.clamp(0, count - 1)].center.dx - 32,
                top: active < 0
                    ? (house || garden ? 228 : 97)
                    : (positions[active.clamp(0, count - 1)].top - 58).clamp(
                        0.0,
                        240.0,
                      ),
                width: 70,
                height: 70,
                child: AvatarImage(
                  avatar: 'duri',
                  size: 70,
                  interactive: false,
                  lowStimulation: quiet,
                ),
              ),
            Positioned.fill(
              key: const ValueKey('build_simulation'),
              child: ForestExperimentScene(
                trial: trial,
                quiet: quiet,
                onFinished: onTrialFinished ?? () {},
              ),
            ),
            if (trial != null && active < 0 && !trial!.evaluate().success)
              Positioned.fromRect(
                rect: positions[trial!.evaluate().problemSlot!],
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFE5B55E),
                        width: 5,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            if (trial != null && active < 0 && trial!.evaluate().success)
              const Positioned(
                right: 12,
                bottom: 13,
                child: ForestProp(ForestObject.heart, size: 46),
              ),
          ],
        );
      },
    ),
  );
}

class _HousePart extends CustomPainter {
  const _HousePart(this.part, this.variant);
  final int part, variant;
  @override
  void paint(Canvas c, Size s) {
    const woods = [Color(0xFFD2A26B), Color(0xFFC18D65), Color(0xFFE0BB80)];
    const roofs = [Color(0xFF79966A), Color(0xFFB47D65), Color(0xFF88A9A4)];
    if (part == 0) {
      final roof = Path()
        ..moveTo(2, s.height - 7)
        ..quadraticBezierTo(s.width * .2, s.height * .75, s.width / 2, 3)
        ..quadraticBezierTo(
          s.width * .8,
          s.height * .75,
          s.width - 2,
          s.height - 7,
        )
        ..close();
      c.drawShadow(roof, const Color(0x995F6843), 5, false);
      c.drawPath(
        roof,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(roofs[variant % 3], Colors.white, .25)!,
              roofs[variant % 3],
            ],
          ).createShader(Offset.zero & s),
      );
      c.save();
      c.clipPath(roof);
      for (var y = 23.0; y < s.height; y += 18) {
        c.drawPath(
          Path()
            ..moveTo(0, y)
            ..quadraticBezierTo(s.width / 2, y + 8, s.width, y),
          Paint()
            ..color = const Color(0x4470844D)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
      c.restore();
      c.drawLine(
        Offset(4, s.height - 7),
        Offset(s.width - 4, s.height - 7),
        Paint()
          ..color = const Color(0xFFE1CB99)
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
    } else {
      final body = RRect.fromRectAndRadius(
        Offset.zero & s,
        const Radius.circular(8),
      );
      c.drawRRect(
        body.shift(const Offset(0, 4)),
        Paint()..color = const Color(0xFF99704D),
      );
      c.drawRRect(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(woods[variant % 3], Colors.white, .14)!,
              woods[variant % 3],
            ],
          ).createShader(Offset.zero & s),
      );
      c.save();
      c.clipRRect(body);
      for (var y = 19.0; y < s.height; y += 23) {
        c.drawLine(
          Offset(0, y),
          Offset(s.width, y + 2),
          Paint()
            ..color = const Color(0x33876645)
            ..strokeWidth = 2,
        );
        c.drawLine(
          Offset(0, y + 3),
          Offset(s.width, y + 4),
          Paint()
            ..color = const Color(0x44FFF0BB)
            ..strokeWidth = 2,
        );
      }
      c.restore();
      if (part == 1) {
        final window = Rect.fromCenter(
          center: Offset(s.width / 2, s.height * .44),
          width: s.width * .49,
          height: 45,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(window.inflate(5), const Radius.circular(12)),
          Paint()..color = const Color(0xFF8F7250),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(window, const Radius.circular(9)),
          Paint()..color = const Color(0xFFD9EAC4),
        );
        c.drawLine(
          Offset(window.center.dx, window.top),
          Offset(window.center.dx, window.bottom),
          Paint()
            ..color = const Color(0xFFE7CD9E)
            ..strokeWidth = 4,
        );
        c.drawLine(
          Offset(window.left, window.center.dy),
          Offset(window.right, window.center.dy),
          Paint()
            ..color = const Color(0xFFE7CD9E)
            ..strokeWidth = 4,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              window.left - 7,
              window.bottom + 8,
              window.width + 14,
              11,
            ),
            const Radius.circular(5),
          ),
          Paint()..color = const Color(0xFF819D63),
        );
      } else {
        final door = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            s.width * .24,
            s.height * .32,
            s.width * .55,
            s.height * .68,
          ),
          const Radius.circular(24),
        );
        c.drawRRect(door, Paint()..color = const Color(0xFF8D7354));
        c.drawRRect(door.deflate(5), Paint()..color = const Color(0xFFAE9066));
        c.drawCircle(
          Offset(s.width * .65, s.height * .7),
          4,
          Paint()..color = const Color(0xFFFFE6A0),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HousePart old) =>
      old.part != part || old.variant != variant;
}

class _BridgePlank extends CustomPainter {
  const _BridgePlank(this.variant);
  final int variant;
  @override
  void paint(Canvas c, Size s) {
    if (variant == 2) {
      final leaf = Path()
        ..moveTo(5, s.height * .7)
        ..quadraticBezierTo(s.width * .2, 0, s.width - 5, s.height * .2)
        ..quadraticBezierTo(s.width * .9, s.height, s.width * .1, s.height * .9)
        ..close();
      c.drawShadow(leaf, const Color(0x66607142), 3, false);
      c.drawPath(leaf, Paint()..color = const Color(0xFF91B875));
      c.drawLine(
        Offset(8, s.height * .8),
        Offset(s.width - 14, s.height * .3),
        Paint()
          ..color = const Color(0xFFCCE2AA)
          ..strokeWidth = 3,
      );
      return;
    }
    final color = [
      const Color(0xFFD0A26A),
      const Color(0xFFB68C67),
      const Color(0xFFE0BA82),
    ][variant % 3];
    final h = s.height * (variant == 1 ? .32 : .18);
    for (var i = 0; i < (variant == 1 ? 2 : 3); i++) {
      final r = Rect.fromLTWH(
        3,
        5 + i * s.height * (variant == 1 ? .42 : .29),
        s.width - 6,
        h,
      );
      final plank = RRect.fromRectAndRadius(r, const Radius.circular(7));
      c.drawRRect(
        plank.shift(const Offset(0, 4)),
        Paint()..color = const Color(0xFF9F7B52),
      );
      c.drawRRect(
        plank,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(color, Colors.white, .18)!, color],
          ).createShader(r),
      );
      c.drawPath(
        Path()
          ..moveTo(12, r.top + h * .45)
          ..quadraticBezierTo(
            s.width * .5,
            r.top + h * .2,
            s.width - 13,
            r.top + h * .5,
          ),
        Paint()
          ..color = const Color(0x44856546)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );
      for (final x in [10.0, s.width - 10]) {
        c.drawCircle(
          Offset(x, r.top + h * .5),
          1.8,
          Paint()..color = const Color(0xFF9A8158),
        );
      }
      c.drawOval(
        Rect.fromCenter(
          center: Offset(s.width * .62, r.top + h * .65),
          width: 9,
          height: 3,
        ),
        Paint()..color = const Color(0x22836542),
      );
    }
  }

  @override
  bool shouldRepaint(_BridgePlank old) => old.variant != variant;
}
