import '../game/sort_sequence.dart';

import 'package:flutter/material.dart';

import 'avatar_image.dart';
import 'forest_game_ui.dart';
import 'forest_play_stage.dart';
import 'cute_game_effects.dart';
import 'touch_invitation.dart';

class JourneySortScene extends StatefulWidget {
  const JourneySortScene({
    required this.id,
    required this.step,
    required this.bySize,
    required this.bins,
    required this.progress,
    required this.goal,
    required this.quiet,
    required this.onMatch,
    this.seed = 0,
    this.guided = false,
    super.key,
  });
  final int seed;
  final bool guided;
  List<int> get sequence =>
      sortSequence(seed: seed, step: step, bins: bins, goal: goal);
  final String id;
  final int step, bins, progress, goal;
  final bool bySize, quiet;
  final VoidCallback onMatch;
  @override
  State<JourneySortScene> createState() => _JourneySortSceneState();
}

class _JourneySortSceneState extends State<JourneySortScene> {
  bool hint = false, picked = false;
  int get target => widget.sequence[widget.progress.clamp(0, widget.goal - 1)];
  bool get done => widget.progress >= widget.goal;
  bool get post => widget.id == 'age_72_04';
  bool get shop => widget.id == 'age_48_03' || widget.id == 'age_60_01';
  Color tint(int i) => widget.bySize
      ? const Color(0xFFDCB365)
      : [const Color(0xFFD68069), const Color(0xFF81AFC4)][i % 2];
  String label(int i) => widget.bySize
      ? (i == 0 ? '작은 도토리 바구니' : '큰 도토리 바구니')
      : (i == 0 ? '빨간 바구니' : '파란 바구니');
  void deliver(int i) {
    if (done) return;
    if (i != target) {
      setState(() => hint = true);
      return;
    }
    setState(() {
      hint = false;
      picked = false;
    });
    widget.onMatch();
  }

  Widget object(int i, double size) => post
      ? CustomPaint(size: Size.square(size), painter: _Letter(tint(i)))
      : Stack(
          alignment: Alignment.center,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(tint(i), BlendMode.modulate),
              child: ForestProp(
                widget.id == 'age_24_02'
                    ? (widget.step == 2
                          ? ForestObject.leaf
                          : ForestObject.berry)
                    : ForestObject.acorn,
                size: size,
              ),
            ),
            if (!widget.quiet)
              Positioned(
                top: size * 0.35,
                child: CuteFace(
                  mood: picked ? FaceMood.surprised : FaceMood.happy,
                  size: size * 0.35,
                  animateBlink: !widget.quiet,
                ),
              ),
          ],
        );

  @override
  Widget build(BuildContext context) => ForestPlayStage(
    height: 355,
    quiet: widget.quiet,
    child: LayoutBuilder(
      builder: (_, box) => Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 2,
            top: 1,
            child: SceneReaction(
              event: widget.progress,
              quiet: widget.quiet,
              child: AvatarImage(
                avatar: 'duri',
                size: 87,
                interactive: false,
                lowStimulation: widget.quiet,
                showBlush: done || widget.progress > 0,
              ),
            ),
          ),
          if (shop || post)
            Positioned(
              top: 9,
              left: 8,
              child: ForestProp(
                post ? ForestObject.home : ForestObject.basket,
                size: 62,
              ),
            ),
          Positioned(
            top: 32,
            child: done
                ? SceneReaction(
                    event: 'all-done',
                    quiet: widget.quiet,
                    child: const ForestProp(ForestObject.heart, size: 110),
                  )
                : TouchInvitation(
                    visible: widget.progress == 0 && !picked,
                    quiet: widget.quiet,
                    drag: true,
                    child: PlayPiece(
                      label: widget.bySize
                          ? (target == 0 ? '작은 도토리' : '큰 도토리')
                          : '분류할 물건',
                      size: 126,
                      dragValue: target,
                      quiet: widget.quiet,
                      selected: picked,
                      onTap: () => setState(() => picked = true),
                      child: object(
                        target,
                        widget.bySize && target == 0 ? 65 : 104,
                      ),
                    ),
                  ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 29,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < widget.bins; i++)
                  DragTarget<int>(
                    onWillAcceptWithDetails: (_) => !done,
                    onAcceptWithDetails: (d) {
                      if (d.data == target) deliver(i);
                    },
                    builder: (_, candidates, _) => TouchInvitation(
                      visible: !done && (hint || widget.guided) && i == target,
                      quiet: widget.quiet,
                      child: PlayPiece(
                        label: label(i),
                        size: 120,
                        quiet: widget.quiet,
                        selected:
                            candidates.isNotEmpty ||
                            ((hint || widget.guided) && i == target),
                        onTap: () => deliver(i),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (post)
                              Positioned(
                                top: 4,
                                child: Icon(
                                  Icons.markunread_mailbox_rounded,
                                  size: 94,
                                  color: tint(i),
                                ),
                              )
                            else ...[
                              const ForestProp(ForestObject.basket, size: 108),
                              if (!widget.quiet)
                                Positioned(
                                  top: 48,
                                  child: CuteFace(
                                    mood:
                                        (candidates.isNotEmpty ||
                                            ((hint || widget.guided) &&
                                                i == target))
                                        ? FaceMood.happy
                                        : FaceMood.idle,
                                    size: 26,
                                    animateBlink: !widget.quiet,
                                  ),
                                ),
                            ],
                            Positioned(
                              bottom: 21,
                              child: Container(
                                width: widget.bySize && i == 0 ? 25 : 42,
                                height: widget.bySize && i == 0 ? 25 : 42,
                                decoration: BoxDecoration(
                                  color: tint(i),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFFEFC3),
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                            for (var n = 0; n < widget.progress; n++)
                              if (widget.sequence[n] == i)
                                Positioned(
                                  left: 12 + (n ~/ widget.bins) * 23.0,
                                  top: 0,
                                  child: SceneReaction(
                                    event: 'delivered-$n',
                                    quiet: widget.quiet,
                                    child: object(i, 42),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            child: ForestProgress(count: widget.progress, total: widget.goal),
          ),
        ],
      ),
    ),
  );
}

class _Letter extends CustomPainter {
  const _Letter(this.color);
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    final r = Rect.fromLTWH(
      s.width * .05,
      s.height * .2,
      s.width * .9,
      s.height * .63,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        r.shift(const Offset(0, 4)),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0x44706140),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(12)),
      Paint()..color = color,
    );
    c.drawPath(
      Path()
        ..moveTo(r.left + 2, r.top + 4)
        ..lineTo(r.center.dx, r.center.dy + 2)
        ..lineTo(r.right - 2, r.top + 4),
      Paint()
        ..color = const Color(0xFFFFE9C0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    c.drawCircle(
      r.center.translate(0, 5),
      s.width * .10,
      Paint()..color = const Color(0xFFFAE5AE),
    );
  }

  @override
  bool shouldRepaint(_Letter old) => old.color != color;
}
