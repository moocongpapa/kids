import 'package:flutter/material.dart';

import 'avatar_image.dart';
import 'forest_game_ui.dart';
import 'forest_play_stage.dart';
import 'journey_garden_scene.dart';
import 'journey_picnic_scene.dart';
import 'touch_invitation.dart';

class JourneyStoryScene extends StatelessWidget {
  const JourneyStoryScene({
    required this.id,
    this.reaction = 0,
    required this.step,
    required this.avatar,
    required this.options,
    required this.labels,
    required this.history,
    required this.selected,
    required this.ready,
    required this.quiet,
    required this.onChoose,
    super.key,
  });
  final String id, avatar;
  final int step, selected;
  final int reaction;
  final List<ForestObject> options, history;
  final List<String> labels;
  final bool ready, quiet;
  final ValueChanged<int> onChoose;
  bool get weather =>
      const ['age_30_04', 'age_36_04', 'age_72_02'].contains(id);
  bool get comfort => id == 'age_48_04' || id == 'age_72_06';
  bool get bus => id == 'age_24_04';
  bool get picnic => id == 'age_30_02' || id == 'age_36_02';
  bool get festival => id == 'age_84_01';
  bool get travelling =>
      !bus &&
      !picnic &&
      !weather &&
      !comfort &&
      !festival &&
      history.firstOrNull == ForestObject.bus;
  ForestObject? get gift => ready ? options[selected] : null;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      DragTarget<int>(
        onWillAcceptWithDetails: (d) => d.data >= 0 && d.data < options.length,
        onAcceptWithDetails: (d) => onChoose(d.data),
        builder: (_, candidates, _) => AnimatedScale(
          scale: candidates.isNotEmpty && !quiet ? 1.025 : 1,
          duration: const Duration(milliseconds: 180),
          child: id == 'age_48_01'
              ? JourneyPicnicScene(step: step, gift: gift?.name, quiet: quiet)
              : ForestPlayStage(
                  height: 320,
                  night: comfort,
                  quiet: quiet,
                  child: LayoutBuilder(
                    builder: (_, box) => Stack(
                      alignment: Alignment.center,
                      children: [
                        if (weather) ...[
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 185,
                            child: ShaderMask(
                              blendMode: BlendMode.dstIn,
                              shaderCallback: (r) => const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white,
                                  Colors.white,
                                  Colors.transparent,
                                ],
                                stops: [0, .5, 1],
                              ).createShader(r),
                              child: Image.asset(
                                history.contains(ForestObject.cloud)
                                    ? 'assets/images/forest_weather_rain.png'
                                    : 'assets/images/forest_weather.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 15,
                            child: SceneReaction(
                              event: 'weather-$step-$selected',
                              quiet: quiet,
                              child: ForestProp(
                                history.isEmpty
                                    ? ForestObject.sun
                                    : history.first,
                                size: 90,
                              ),
                            ),
                          ),
                        ],
                        if (bus || travelling)
                          Positioned(
                            top: 45,
                            child: SceneReaction(
                              event: 'bus-$step-$ready-$reaction',
                              quiet: quiet,
                              child: WoodlandBus(
                                width: box.maxWidth * .94,
                                quiet: quiet,
                                passengers: [
                                  for (var i = 0; i < history.length; i++)
                                    ['momo', 'duri', 'nuri'][(i +
                                            (history[i] == ForestObject.paw
                                                ? 1
                                                : 0)) %
                                        3],
                                ],
                              ),
                            ),
                          )
                        else if (picnic) ...[
                          Positioned(
                            bottom: 43,
                            child: Container(
                              width: box.maxWidth * .8,
                              height: 84,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0D5B0),
                                borderRadius: BorderRadius.circular(60),
                                border: Border.all(
                                  color: const Color(0xFFB59A72),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                          const Positioned(
                            left: 16,
                            bottom: 48,
                            child: ForestProp(ForestObject.basket, size: 112),
                          ),
                          for (var i = 0; i < history.length; i++)
                            Positioned(
                              left: 65 + i * 57.0,
                              bottom: 36,
                              child: SceneReaction(
                                event: 'picnic-keepsake-$i-${history[i]}',
                                quiet: quiet,
                                child: ForestProp(history[i], size: 55),
                              ),
                            ),
                        ] else if (festival) ...[
                          Positioned(
                            top: 15,
                            left: 10,
                            right: 10,
                            child: CustomPaint(
                              size: Size(box.maxWidth - 20, 70),
                              painter: FestivalFlags(),
                            ),
                          ),
                          const Positioned(
                            left: 4,
                            bottom: 45,
                            child: ForestProp(ForestObject.home, size: 114),
                          ),
                          const Positioned(
                            right: 2,
                            bottom: 37,
                            child: GardenFlower(
                              variant: 2,
                              open: true,
                              size: 93,
                            ),
                          ),
                        ] else if (!weather && !comfort) ...[
                          Positioned(
                            left: 10,
                            bottom: 67,
                            child: ForestProp(
                              history.isEmpty
                                  ? ForestObject.bush
                                  : history.first,
                              size: 132,
                            ),
                          ),
                          const Positioned(
                            right: 8,
                            bottom: 70,
                            child: ForestProp(ForestObject.home, size: 117),
                          ),
                        ],
                        if (!bus && !travelling)
                          AnimatedPositioned(
                            duration: quiet
                                ? Duration.zero
                                : const Duration(milliseconds: 550),
                            bottom: ready ? 69 : 61,
                            left: box.maxWidth * (picnic ? .47 : .32),
                            child: SceneReaction(
                              event: 'friend-$step-$selected-$ready-$reaction',
                              quiet: quiet,
                              child: AvatarImage(
                                avatar: comfort && !ready && avatar == 'momo'
                                    ? 'momo_upset'
                                    : avatar,
                                size: 132,
                                interactive: false,
                                lowStimulation: quiet,
                                showBlush: ready,
                              ),
                            ),
                          ),
                        if (comfort &&
                            (step > 0 ||
                                gift == ForestObject.heart ||
                                gift == ForestObject.paw))
                          Positioned(
                            left: 8,
                            bottom: 52,
                            child: AvatarImage(
                              avatar: 'momo',
                              size: 92,
                              interactive: false,
                              lowStimulation: quiet,
                              showBlush: ready,
                            ),
                          ),
                        if (gift != null && !bus && !travelling)
                          Positioned(
                            right: 9,
                            bottom: 28,
                            child: SceneReaction(
                              event: 'gift-$step-$selected-$reaction',
                              quiet: quiet,
                              child: ForestProp(
                                gift!,
                                size:
                                    gift == ForestObject.home ||
                                        gift == ForestObject.leaf
                                    ? 117
                                    : 93,
                              ),
                            ),
                          ),
                        if (weather && ready && gift == ForestObject.leaf)
                          Positioned(
                            left: box.maxWidth * .22,
                            top: 41,
                            child: Transform.rotate(
                              angle: -.2,
                              child: const ForestProp(
                                ForestObject.leaf,
                                size: 163,
                              ),
                            ),
                          ),
                        if (comfort &&
                            ready &&
                            (gift == ForestObject.home ||
                                gift == ForestObject.leaf))
                          Positioned(
                            left: box.maxWidth * .24,
                            bottom: 18,
                            child: Semantics(
                              label: '친구를 위한 조용한 쉼터',
                              child: Container(
                                width: 154,
                                height: 17,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCDAA73),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                            ),
                          ),
                        if (ready)
                          Positioned(
                            top: bus ? 4 : 61,
                            left: box.maxWidth * .44,
                            child: SceneReaction(
                              event: 'heart-$step-$selected-$reaction',
                              quiet: quiet,
                              child: const ForestProp(
                                ForestObject.heart,
                                size: 46,
                              ),
                            ),
                          ),
                        if (!ready && !bus)
                          Positioned(
                            right: 12,
                            top: 43,
                            child: Opacity(
                              opacity: .55,
                              child: ForestProp(options.first, size: 60),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
      if (history.isNotEmpty) StoryKeepsakes(items: history),
      const SizedBox(height: 12),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < options.length; i++)
            TouchInvitation(
              visible: !ready && i == 0,
              quiet: quiet,
              key: ValueKey('story-cue-$step-$i'),
              child: PlayPiece(
                label: labels[i],
                dragValue: i,
                selected: ready && selected == i,
                quiet: quiet,
                size: 88,
                onTap: () => onChoose(i),
                child: ForestProp(options[i], size: 74),
              ),
            ),
        ],
      ),
    ],
  );
}

class FestivalFlags extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.drawPath(
      Path()
        ..moveTo(0, 4)
        ..quadraticBezierTo(s.width / 2, 60, s.width, 4),
      Paint()
        ..color = const Color(0xFF8B7952)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    const colors = [
      Color(0xFFE7A398),
      Color(0xFFF2D685),
      Color(0xFF91BFA0),
      Color(0xFF9AB8D0),
    ];
    for (var i = 0; i < 7; i++) {
      final x = s.width * (i + .5) / 7;
      final t = x / s.width;
      final y = 4 + 100 * t * (1 - t);
      c.drawPath(
        Path()
          ..moveTo(x - 12, y)
          ..lineTo(x + 12, y + 2)
          ..lineTo(x, y + 25)
          ..close(),
        Paint()..color = colors[i % 4],
      );
    }
  }

  @override
  bool shouldRepaint(FestivalFlags old) => false;
}
