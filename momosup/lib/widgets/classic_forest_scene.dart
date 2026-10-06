import 'forest_landscape.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'avatar_image.dart';
import 'forest_game_ui.dart';
import 'forest_play_stage.dart';
import 'journey_garden_scene.dart';
import 'touch_invitation.dart';
import 'woodland_art.dart';
import '../utils/sound_effects.dart';

class ClassicForestScene extends StatelessWidget {
  const ClassicForestScene({
    required this.id,
    this.reaction = 0,
    required this.choices,
    required this.selected,
    required this.visited,
    required this.quiet,
    required this.onChoose,
    super.key,
  });
  final String id;
  final int reaction;
  final List<String> choices;
  final int? selected;
  final Set<int> visited;
  final bool quiet;
  final ValueChanged<int> onChoose;
  bool get bus => id == 'bus_stop';
  bool get tracks => id == 'animal_tracks';
  bool get weather => id == 'forest_weather';
  String get asset => tracks
      ? 'assets/images/forest_tracks.png'
      : weather && selected == 1
      ? 'assets/images/forest_weather_rain.png'
      : weather && selected == 2
      ? 'assets/images/forest_weather_wind.png'
      : 'assets/images/forest_weather.png';
  Widget piece(int i) => weather
      ? ForestProp(
          [ForestObject.sun, ForestObject.cloud, ForestObject.leaf][i],
          size: 82,
        )
      : tracks
      ? CustomPaint(painter: _Paw(i), child: const SizedBox.expand())
      : AvatarImage(
          avatar: bus
              ? ['momo', 'duri', 'nuri'][i]
              : ['momo', 'momo_quiet', 'momo_upset'][i],
          size: 84,
          interactive: false,
          lowStimulation: quiet,
        );
  @override
  Widget build(BuildContext context) => ForestSceneComposition(
    children: [
      DragTarget<int>(
        onWillAcceptWithDetails: (d) => d.data >= 0 && d.data < choices.length,
        onAcceptWithDetails: (d) => onChoose(d.data),
        builder: (_, candidates, _) => ForestPlayStage(
          height: 350,
          quiet: quiet,
          child: LayoutBuilder(
            builder: (_, box) => Stack(
              alignment: Alignment.center,
              children: [
                if (tracks || weather)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 38,
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (r) => const RadialGradient(
                        radius: .78,
                        colors: [
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                        ],
                        stops: [0, .6, 1],
                      ).createShader(r),
                      child: AnimatedSwitcher(
                        duration: quiet
                            ? Duration.zero
                            : const Duration(milliseconds: 450),
                        child: Image.asset(
                          asset,
                          key: ValueKey(asset),
                          fit: BoxFit.cover,
                          width: box.maxWidth,
                          height: 312,
                        ),
                      ),
                    ),
                  ),
                if (bus)
                  Positioned(
                    top: 67,
                    child: SceneReaction(
                      event: reaction,
                      quiet: quiet,
                      child: WoodlandBus(
                        width: box.maxWidth * .96,
                        quiet: quiet,
                        passengers: [
                          for (final i in visited) ['momo', 'duri', 'nuri'][i],
                        ],
                      ),
                    ),
                  ),
                if (tracks)
                  for (var i = 0; i < 3; i++)
                    Positioned(
                      left: box.maxWidth * (.02 + i * .31),
                      top: 145 - (i % 2) * 45,
                      child: GestureDetector(
                        onTap: () => onChoose(i),
                        child: SceneReaction(
                          event: '$i-${visited.contains(i)}-$reaction',
                          quiet: quiet,
                          child: visited.contains(i)
                              ? AvatarImage(
                                  avatar: ['duri', 'momo', 'nuri'][i],
                                  size: box.maxWidth * .3,
                                  interactive: false,
                                  lowStimulation: quiet,
                                  showBlush: true,
                                )
                              : const ForestProp(ForestObject.bush, size: 98),
                        ),
                      ),
                    ),
                if (weather) ...[
                  Positioned(
                    bottom: 52,
                    child: SceneReaction(
                      event: reaction,
                      quiet: quiet,
                      child: AvatarImage(
                        avatar: 'nuri',
                        size: 119,
                        interactive: false,
                        lowStimulation: quiet,
                        showBlush: selected != null,
                      ),
                    ),
                  ),
                  if (selected == 1)
                    Positioned(
                      left: 15,
                      right: 15,
                      top: 12,
                      height: 172,
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey('rain-$selected'),
                        tween: Tween(begin: 0, end: 1),
                        duration: quiet
                            ? Duration.zero
                            : const Duration(seconds: 2),
                        builder: (_, t, _) => IgnorePointer(
                          child: CustomPaint(painter: GentleRain(t)),
                        ),
                      ),
                    ),
                  if (selected == 2)
                    for (var i = 0; i < 4; i++)
                      Positioned(
                        left: box.maxWidth * (.08 + i * .23),
                        top: 36 + i * 23.0,
                        child: SceneReaction(
                          event: 'leaf-$selected-$i',
                          quiet: quiet,
                          child: const ForestProp(ForestObject.leaf, size: 49),
                        ),
                      ),
                  if (selected == 0)
                    const Positioned(
                      top: 6,
                      right: 12,
                      child: ForestProp(ForestObject.sun, size: 100),
                    ),
                ],
                if (!bus && !tracks && !weather) ...[
                  Positioned(
                    top: 30,
                    child: SceneReaction(
                      event: reaction,
                      quiet: quiet,
                      child: AvatarImage(
                        avatar: [
                          'momo',
                          'momo_quiet',
                          'momo_upset',
                        ][selected ?? 0],
                        size: 205,
                        interactive: false,
                        lowStimulation: quiet,
                        showBlush: selected == 0,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 19,
                    right: 10,
                    child: ForestProp(
                      selected == 2
                          ? ForestObject.cloud
                          : selected == 1
                          ? ForestObject.leaf
                          : ForestObject.heart,
                      size: 68,
                    ),
                  ),
                  const Positioned(
                    left: 8,
                    bottom: 39,
                    child: GardenFlower(variant: 0, open: true, size: 92),
                  ),
                ],
                Positioned(
                  bottom: 8,
                  child: ForestProgress(
                    count: visited.length,
                    total: choices.length,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      LayoutBuilder(
        builder: (_, box) => ForestChoiceTray(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < choices.length; i++)
              TouchInvitation(
                visible: visited.isEmpty && i == 0,
                quiet: quiet,
                child: PlayPiece(
                  label: choices[i],
                  size: ((box.maxWidth - 16) / 3).clamp(80.0, 116.0),
                  quiet: quiet,
                  dragValue: i,
                  selected: selected == i,
                  onTap: () => onChoose(i),
                  child: piece(i),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

class _Paw extends CustomPainter {
  const _Paw(this.type);
  final int type;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.translate(s.width / 2, s.height / 2);
    final p = Paint()..color = const Color(0xFFA67E53);
    if (type == 1) {
      p
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      for (final x in [-18.0, 0.0, 18.0]) {
        c.drawLine(const Offset(0, 19), Offset(x, -20), p);
      }
      c.drawLine(const Offset(0, 19), const Offset(0, 30), p);
    } else {
      c.drawOval(
        Rect.fromCenter(
          center: const Offset(0, 12),
          width: type == 2 ? 25 : 41,
          height: type == 2 ? 45 : 31,
        ),
        p,
      );
      for (var i = 0; i < 3; i++) {
        c.drawOval(
          Rect.fromCenter(
            center: Offset(-19.0 + i * 19, -18 - (i == 1 ? 7 : 0)),
            width: 12,
            height: type == 2 ? 23 : 15,
          ),
          p,
        );
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_Paw old) => old.type != type;
}

class ForestMovementScene extends StatefulWidget {
  const ForestMovementScene({
    required this.id,
    required this.step,
    required this.quiet,
    this.onReplay,
    super.key,
  });
  final String id;
  final int step;
  final bool quiet;
  final VoidCallback? onReplay;
  @override
  State<ForestMovementScene> createState() => _ForestMovementSceneState();
}

class _ForestMovementSceneState extends State<ForestMovementScene> {
  int replay = 0;
  @override
  Widget build(BuildContext context) => ForestPlayStage(
    height: 350,
    quiet: widget.quiet,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SoundEffects.instance.pop();
        setState(() => replay++);
        widget.onReplay?.call();
      },
      child: Tooltip(
        message: '동작 다시 보기',
        child: Semantics(
          button: true,
          label: '동작 다시 보기',
          child: SceneReaction(
            event: 'buddy-$replay',
            quiet: widget.quiet,
            child: TweenAnimationBuilder<double>(
              key: ValueKey('${widget.step}-$replay'),
              tween: Tween(begin: 0, end: 1),
              duration: widget.quiet
                  ? Duration.zero
                  : const Duration(milliseconds: 2400),
              builder: (_, t, _) => LayoutBuilder(
                builder: (_, box) {
                  final rest = widget.step == 2;
                  final frame = rest
                      ? 11
                      : widget.id == 'animal_steps_song' && widget.step == 0
                      ? 10
                      : (widget.quiet || t >= 1
                                ? widget.step % 2
                                : (t * 4).floor() % 2) +
                            8;
                  final extent = math.min(
                    box.maxWidth * .7,
                    box.maxHeight * .85,
                  );
                  return Center(
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        widget.quiet || rest
                            ? 0
                            : -math.sin(t * math.pi * 4).abs() * 4,
                      ),
                      child: WoodlandSprite(
                        asset: woodlandArtAssets[4],
                        frame: frame,
                        columns: 4,
                        rows: 3,
                        size: extent,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
