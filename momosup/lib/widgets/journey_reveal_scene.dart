import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'avatar_image.dart';
import 'forest_game_ui.dart';
import 'forest_play_stage.dart';
import 'cute_game_effects.dart';
import 'journey_garden_scene.dart';
import 'touch_invitation.dart';

class JourneyRevealScene extends StatefulWidget {
  const JourneyRevealScene({
    required this.id,
    this.step = 0,
    required this.avatar,
    required this.options,
    required this.labels,
    required this.selected,
    required this.revealed,
    required this.quiet,
    required this.onChoose,
    this.stage = 1,
    this.seed = 0,
    this.initialFound = const {},
    this.hiddenHat,
    super.key,
  });
  final int stage, seed;
  final Set<int> initialFound;
  final int? hiddenHat;
  final String id, avatar;
  final int step, selected;
  final List<ForestObject> options;
  final List<String> labels;
  final bool revealed, quiet;
  final ValueChanged<int> onChoose;
  @override
  State<JourneyRevealScene> createState() => _JourneyRevealSceneState();
}

class _JourneyRevealSceneState extends State<JourneyRevealScene> {
  final found = <int>{};
  int taps = 0;
  @override
  void initState() {
    super.initState();
    found.addAll(widget.initialFound);
  }

  @override
  void didUpdateWidget(JourneyRevealScene old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id || old.step != widget.step) {
      found
        ..clear()
        ..addAll(widget.initialFound);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.id == 'age_24_01' || widget.id == 'age_24_06') {
      return JourneyGardenScene(
        weather: widget.id == 'age_24_06',
        step: widget.step,
        revealed: widget.revealed,
        quiet: widget.quiet,
        onTap: () => widget.onChoose(0),
      );
    }
    final detective =
        widget.id == 'age_30_03' ||
        widget.id == 'age_48_02' ||
        widget.id == 'age_84_05';
    final hat = widget.id == 'age_36_01';
    final positions = List.generate(widget.options.length, (i) => i);
    if (widget.stage > 0) {
      positions.shuffle(math.Random(widget.seed + widget.step * 37));
    }
    return ForestPlayStage(
      quiet: widget.quiet,
      height: 340,
      child: LayoutBuilder(
        builder: (_, box) {
          final extent = (box.maxWidth / widget.options.length).clamp(
            86.0,
            155.0,
          );
          return Stack(
            alignment: Alignment.center,
            children: [
              if (detective)
                Positioned(
                  top: 2,
                  left: 12,
                  right: 12,
                  child: CustomPaint(
                    size: Size(box.maxWidth - 24, 80),
                    painter: _Tracks(widget.step),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                top: detective ? 86 : 35,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final i in positions)
                      SizedBox(
                        width: extent,
                        height: 220,
                        child: Tooltip(
                          message: widget.labels[i],
                          child: Semantics(
                            button: true,
                            label: '${i + 1}번째 숨은 곳',
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  found.add(i);
                                  taps++;
                                });
                                widget.onChoose(i);
                              },
                              onHorizontalDragEnd: (_) {
                                setState(() {
                                  found.add(i);
                                  taps++;
                                });
                                widget.onChoose(i);
                              },
                              child: TouchInvitation(
                                visible:
                                    found.isEmpty && i == 0 && widget.stage < 2,
                                delay: widget.stage == 1
                                    ? const Duration(seconds: 8)
                                    : Duration.zero,
                                quiet: widget.quiet,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    const SizedBox.expand(),
                                    AnimatedPositioned(
                                      duration: widget.quiet
                                          ? Duration.zero
                                          : const Duration(milliseconds: 650),
                                      curve: Curves.easeOutCubic,
                                      bottom: found.contains(i) ? 81 : 5,
                                      child: AnimatedOpacity(
                                        opacity: found.contains(i) ? 1 : 0,
                                        duration: widget.quiet
                                            ? Duration.zero
                                            : const Duration(milliseconds: 350),
                                        child: SceneReaction(
                                          event:
                                              '${widget.step}-$i-${found.contains(i)}-$taps',
                                          quiet: widget.quiet,
                                          child: Stack(
                                            alignment: Alignment.topCenter,
                                            children: [
                                              AvatarImage(
                                                avatar: [
                                                  'momo',
                                                  'duri',
                                                  'nuri',
                                                ][(i + widget.step) % 3],
                                                size: extent * .86,
                                                interactive: false,
                                                lowStimulation: widget.quiet,
                                                showBlush: found.contains(i),
                                              ),
                                              if (hat && i == widget.hiddenHat)
                                                Transform.translate(
                                                  offset: const Offset(0, -23),
                                                  child: CustomPaint(
                                                    size: Size(
                                                      extent * .48,
                                                      45,
                                                    ),
                                                    painter: _Hat(),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    AnimatedSlide(
                                      offset: found.contains(i)
                                          ? const Offset(.12, .1)
                                          : Offset.zero,
                                      duration: widget.quiet
                                          ? Duration.zero
                                          : const Duration(milliseconds: 450),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          ForestProp(
                                            widget.options[i] ==
                                                    ForestObject.home
                                                ? ForestObject.home
                                                : widget.options[i] ==
                                                      ForestObject.cloud
                                                ? ForestObject.cloud
                                                : ForestObject.bush,
                                            size: extent,
                                          ),
                                          if (!widget.quiet &&
                                              !found.contains(i))
                                            Positioned(
                                              top: extent * 0.35,
                                              child: CuteFace(
                                                mood: FaceMood.idle,
                                                size: extent * 0.28,
                                                animateBlink: true,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (found.contains(i))
                                      const Positioned(
                                        bottom: 13,
                                        right: 4,
                                        child: ForestProp(
                                          ForestObject.heart,
                                          size: 36,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                bottom: 5,
                child: ForestProgress(
                  count: found.length,
                  total: widget.options.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Hat extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * .2, 5, s.width * .6, 32),
        const Radius.circular(16),
      ),
      Paint()..color = const Color(0xFFDEA96A),
    );
    c.drawOval(
      Rect.fromLTWH(0, 26, s.width, 15),
      Paint()..color = const Color(0xFFEBC88A),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * .22, 23, s.width * .56, 7),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF92AD70),
    );
  }

  @override
  bool shouldRepaint(_Hat old) => false;
}

class _Tracks extends CustomPainter {
  const _Tracks(this.step);
  final int step;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = const Color(0x887C8E60);
    for (var i = 0; i < 6; i++) {
      final x = s.width * (i + .5) / 6;
      final y = 25 + math.sin(i * .9 + step) * 17;
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 13, height: 17),
        p,
      );
      for (var j = 0; j < 3; j++) {
        c.drawCircle(Offset(x - 8 + j * 7, y - 13), 3.5, p);
      }
    }
  }

  @override
  bool shouldRepaint(_Tracks old) => old.step != step;
}
