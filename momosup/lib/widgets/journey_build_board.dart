import '../game/build_experiment.dart';
import '../game/forest_experiment_scene.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'avatar_image.dart';
import 'forest_game_ui.dart';
import 'forest_play_stage.dart';
import 'journey_garden_scene.dart';
import 'woodland_art.dart';

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
      : _PaintedBridgePiece(value);
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
                          child: _TrialMaterial(
                            trial: trial,
                            index: i,
                            quiet: quiet,
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
                                    ? _PaintedHousePart(i, slots[i] ?? 0)
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
                                    : _PaintedBridgePiece(slots[i] ?? 0),
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
                    ? ((trial != null && trial!.evaluate().success)
                          ? (w - 76)
                          : 4)
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

/// Show the material being tested, then leave it ready for a gentle repair.
/// Movement ends with the Flame walk; it never shakes indefinitely.
class _TrialMaterial extends StatelessWidget {
  const _TrialMaterial({
    required this.trial,
    required this.index,
    required this.quiet,
    required this.child,
  });
  final BuildTrial? trial;
  final int index;
  final bool quiet;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final result = trial?.evaluate();
    if (trial == null ||
        result!.success ||
        result.problemSlot != index ||
        (!trial!.wind && !trial!.bridge)) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey('material-trial-${trial!.attempt}-$index'),
      tween: Tween(begin: 0, end: 1),
      duration: quiet ? Duration.zero : const Duration(milliseconds: 2400),
      child: child,
      builder: (_, t, child) {
        final wave = quiet
            ? 0.0
            : math.sin(t * math.pi * 4) * math.sin(t * math.pi);
        return Transform.translate(
          offset: Offset(
            trial!.wind ? wave * 10 : 0,
            trial!.bridge ? wave.abs() * 11 : 0,
          ),
          child: Transform.rotate(angle: wave * .07, child: child),
        );
      },
    );
  }
}

class _PaintedHousePart extends StatelessWidget {
  const _PaintedHousePart(this.part, this.variant);
  final int part, variant;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, box) => ColorFiltered(
      colorFilter: ColorFilter.mode(
        [
          Colors.transparent,
          const Color(0x309D704B),
          const Color(0x308FA883),
        ][variant % 3],
        BlendMode.srcATop,
      ),
      child: WoodlandSprite(
        asset: woodlandArtAssets[4],
        frame: part == 0
            ? 5
            : part == 1
            ? 6
            : 7,
        columns: 4,
        rows: 3,
        size: box.maxWidth,
        height: box.maxHeight,
      ),
    ),
  );
}

class _PaintedBridgePiece extends StatelessWidget {
  const _PaintedBridgePiece(this.variant);
  final int variant;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, box) {
      final w = box.maxWidth;
      final h = box.maxHeight;
      return Stack(
        alignment: Alignment.center,
        children: [
          if (variant == 2)
            Center(child: ForestProp(ForestObject.leaf, size: math.min(w, h)))
          else
            for (var i = 0; i < (variant == 1 ? 2 : 3); i++)
              Positioned(
                left: 0,
                right: 0,
                top: h * (.02 + i * (variant == 1 ? .44 : .30)),
                child: WoodlandSprite(
                  asset: woodlandArtAssets.first,
                  frame: 15,
                  columns: 4,
                  rows: 4,
                  size: w,
                  height: h * (variant == 1 ? .48 : .29),
                ),
              ),
        ],
      );
    },
  );
}
