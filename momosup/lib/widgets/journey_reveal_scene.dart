import 'package:flutter/material.dart';

import 'avatar_image.dart';
import 'forest_game_ui.dart';

class JourneyRevealScene extends StatelessWidget {
  const JourneyRevealScene({
    required this.id,
    required this.avatar,
    required this.options,
    required this.selected,
    required this.revealed,
    required this.quiet,
    required this.onChoose,
    super.key,
  });
  final String id, avatar;
  final List<ForestObject> options;
  final int selected;
  final bool revealed, quiet;
  final ValueChanged<int> onChoose;
  @override
  Widget build(BuildContext context) {
    if (id == 'age_24_01') {
      return SizedBox(
        height: 300,
        child: Center(
          child: Semantics(
            label: '꽃',
            button: true,
            child: Tooltip(
              message: '꽃',
              child: GestureDetector(
                onTap: () => onChoose(0),
                child: AnimatedScale(
                  scale: revealed ? 1.25 : .78,
                  duration: quiet
                      ? Duration.zero
                      : const Duration(milliseconds: 850),
                  curve: Curves.easeOutBack,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedOpacity(
                        opacity: revealed ? 1 : .3,
                        duration: quiet
                            ? Duration.zero
                            : const Duration(milliseconds: 700),
                        child: const ForestProp(ForestObject.flower, size: 200),
                      ),
                      if (!revealed)
                        const ForestProp(ForestObject.leaf, size: 140),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (id == 'age_24_06') {
      return SizedBox(
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              child: Tooltip(
                message: '구름',
                child: GestureDetector(
                  onTap: () => onChoose(0),
                  child: const ForestProp(ForestObject.cloud, size: 140),
                ),
              ),
            ),
            if (revealed)
              Positioned(
                top: 100,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: quiet
                      ? Duration.zero
                      : const Duration(milliseconds: 900),
                  builder: (context, t, _) => CustomPaint(
                    size: const Size(180, 125),
                    painter: _RainDrops(t),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              child: AnimatedScale(
                scale: revealed ? 1.2 : .8,
                duration: quiet
                    ? Duration.zero
                    : const Duration(milliseconds: 900),
                child: const ForestProp(ForestObject.flower, size: 140),
              ),
            ),
          ],
        ),
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 10,
      children: [
        for (var i = 0; i < options.length; i++)
          SizedBox(
            width: options.length == 1 ? 200 : 136,
            height: 225,
            child: Semantics(
              button: true,
              label: '${i + 1}번째 숨은 곳',
              child: GestureDetector(
                onTap: () => onChoose(i),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    AnimatedPositioned(
                      duration: quiet
                          ? Duration.zero
                          : const Duration(milliseconds: 550),
                      curve: Curves.easeOutBack,
                      bottom: revealed && selected == i ? 90 : 15,
                      child: AnimatedOpacity(
                        opacity: revealed && selected == i ? 1 : 0,
                        duration: quiet
                            ? Duration.zero
                            : const Duration(milliseconds: 350),
                        child: AvatarImage(
                          avatar: [
                            'momo',
                            'duri',
                            'nuri',
                          ][(i + (id.hashCode % 3).abs()) % 3],
                          size: 110,
                          interactive: false,
                          lowStimulation: quiet,
                        ),
                      ),
                    ),
                    ForestProp(
                      options[i] == ForestObject.cloud
                          ? ForestObject.cloud
                          : ForestObject.bush,
                      size: 135,
                    ),
                    if (revealed && selected == i)
                      const Positioned(
                        bottom: 8,
                        right: 0,
                        child: ForestProp(ForestObject.heart, size: 40),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RainDrops extends CustomPainter {
  _RainDrops(this.t);
  final double t;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0xFF709CB8)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final x = (i % 4 + .5) * s.width / 4;
      final y = ((i ~/ 4) * .33 + t * .7) % 1 * s.height;
      c.drawLine(Offset(x, y), Offset(x - 2, y + 9), p);
    }
  }

  @override
  bool shouldRepaint(covariant _RainDrops old) => old.t != t;
}
