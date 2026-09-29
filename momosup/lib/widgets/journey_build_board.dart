import 'package:flutter/material.dart';

import 'avatar_image.dart';
import 'forest_game_ui.dart';

/// Concrete play surfaces: house parts, a bus with seats, gardens, and a bridge.
class JourneyBuildBoard extends StatelessWidget {
  const JourneyBuildBoard({
    required this.id,
    required this.slots,
    required this.count,
    required this.active,
    required this.quiet,
    required this.onPlace,
    super.key,
  });
  final String id;
  final Map<int, int> slots;
  final int count, active;
  final bool quiet;
  final ValueChanged<int> onPlace;
  bool get house => id == 'age_36_06' || id == 'age_60_03';
  bool get bus => id == 'age_60_02';
  bool get garden => id == 'age_60_06' || id == 'age_84_02';
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = box.maxWidth;
      final positions = house
          ? [
              Offset(w / 2 - 48, 5),
              Offset(w / 2 - 95, 112),
              Offset(w / 2 + 3, 112),
              Offset(w / 2 - 48, 205),
            ]
          : garden
          ? [
              Offset(w * .12, 35),
              Offset(w * .62, 35),
              Offset(w * .12, 148),
              Offset(w * .62, 148),
            ]
          : [
              for (var i = 0; i < count; i++)
                Offset(8 + i * (w - 16) / count, 126),
            ];
      final extent = house || garden
          ? 90.0
          : ((w - 20) / count).clamp(62.0, 94.0);
      return SizedBox(
        height: house ? 300 : 270,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (!house && !garden)
              Positioned(
                left: 0,
                right: 0,
                top: 100,
                bottom: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: bus
                        ? const Color(0xFFE8BD67)
                        : const Color(0xFF88B9C5).withValues(alpha: .7),
                    borderRadius: BorderRadius.circular(bus ? 48 : 90),
                  ),
                  child: bus
                      ? const Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Icon(Icons.circle, size: 32, color: forestInk),
                                Icon(Icons.circle, size: 32, color: forestInk),
                              ],
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            if (house)
              Positioned(
                left: w / 2 - 120,
                top: 0,
                child: CustomPaint(
                  size: const Size(240, 245),
                  painter: _HouseOutline(),
                ),
              ),
            if (garden)
              Positioned.fill(child: CustomPaint(painter: _GardenBed())),
            for (var i = 0; i < count; i++)
              Positioned(
                left: positions[i].dx,
                top: positions[i].dy,
                width: extent,
                height: extent,
                child: Semantics(
                  label: '${i + 1}번째 빈 자리',
                  button: true,
                  child: Tooltip(
                    message: '${i + 1}번째 빈 자리',
                    child: GestureDetector(
                      onTap: () => onPlace(i),
                      child: AnimatedContainer(
                        duration: quiet
                            ? Duration.zero
                            : const Duration(milliseconds: 260),
                        decoration: BoxDecoration(
                          color: slots.containsKey(i)
                              ? forestCream.withValues(alpha: .2)
                              : forestCream.withValues(alpha: .6),
                          borderRadius: BorderRadius.circular(garden ? 48 : 18),
                          border: Border.all(
                            color: const Color(0xFF778B59),
                            width: slots.containsKey(i) ? 0 : 2,
                          ),
                        ),
                        child: slots.containsKey(i)
                            ? (bus
                                  ? AvatarImage(
                                      avatar: [
                                        'momo',
                                        'duri',
                                        'nuri',
                                      ][slots[i]! % 3],
                                      size: extent,
                                      interactive: false,
                                      lowStimulation: quiet,
                                    )
                                  : house
                                  ? CustomPaint(
                                      painter: _HousePart(i, slots[i]!),
                                    )
                                  : garden
                                  ? ForestProp(
                                      [
                                        ForestObject.flower,
                                        ForestObject.leaf,
                                        ForestObject.heart,
                                      ][slots[i]! % 3],
                                      size: extent * .8,
                                    )
                                  : CustomPaint(
                                      painter: _BridgePlank(slots[i]!),
                                    ))
                            : const Center(
                                child: Icon(
                                  Icons.touch_app_outlined,
                                  size: 32,
                                  color: forestInk,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            if (active >= 0)
              AnimatedPositioned(
                duration: quiet
                    ? Duration.zero
                    : const Duration(milliseconds: 330),
                curve: Curves.easeInOut,
                left: positions[active].dx,
                top: positions[active].dy - 65,
                width: 65,
                height: 65,
                child: AvatarImage(
                  avatar: 'duri',
                  size: 65,
                  lowStimulation: quiet,
                  interactive: false,
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _HouseOutline extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = forestCream.withValues(alpha: .55);
    final path = Path()
      ..moveTo(0, 95)
      ..lineTo(s.width / 2, 0)
      ..lineTo(s.width, 95)
      ..lineTo(s.width - 20, 95)
      ..lineTo(s.width - 20, s.height)
      ..lineTo(20, s.height)
      ..lineTo(20, 95)
      ..close();
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _HousePart extends CustomPainter {
  _HousePart(this.part, this.variant);
  final int part, variant;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = [
        const Color(0xFF568765),
        const Color(0xFFC98B57),
        const Color(0xFFBC7261),
      ][variant % 3];
    if (part == 0) {
      c.drawPath(
        Path()
          ..moveTo(0, s.height)
          ..lineTo(s.width / 2, 0)
          ..lineTo(s.width, s.height)
          ..close(),
        p,
      );
    } else {
      c.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(12)),
        p,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            s.width * .3,
            s.height * .35,
            s.width * .4,
            s.height * .65,
          ),
          const Radius.circular(18),
        ),
        Paint()..color = forestCream,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HousePart o) =>
      o.part != part || o.variant != variant;
}

class _GardenBed extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.drawOval(
      Rect.fromLTWH(0, 10, s.width, s.height - 10),
      Paint()..color = const Color(0xFF739957).withValues(alpha: .5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _BridgePlank extends CustomPainter {
  _BridgePlank(this.variant);
  final int variant;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = [
        const Color(0xFFCA965F),
        const Color(0xFFAD784B),
        const Color(0xFFE0B17B),
      ][variant % 3];
    for (var i = 0; i < 3; i++) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(3, 10 + i * 24, s.width - 6, 20),
          const Radius.circular(7),
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BridgePlank o) => o.variant != variant;
}
