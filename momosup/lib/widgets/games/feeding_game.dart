import 'package:flutter/material.dart';

import '../../utils/sound_effects.dart';
import '../avatar_image.dart';
import '../forest_game_ui.dart';
import '../hand_guide_hint.dart';

class FeedingGame extends StatefulWidget {
  const FeedingGame({this.onComplete, this.lowStimulation = false, super.key});
  final VoidCallback? onComplete;
  final bool lowStimulation;
  @override
  State<FeedingGame> createState() => _FeedingGameState();
}

class _FeedingGameState extends State<FeedingGame> {
  final eaten = <int>{};
  bool chewing = false;
  bool hovering = false;
  static const names = ['딸기', '산딸기', '도토리', '블루베리'];
  Future<void> eat(int index) async {
    if (eaten.contains(index) || chewing) return;
    setState(() {
      eaten.add(index);
      chewing = true;
      hovering = false;
    });
    SoundEffects.instance.chew();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => chewing = false);
    if (eaten.length == names.length) widget.onComplete?.call();
  }

  Widget fruit(int i, {bool faded = false}) => Opacity(
    opacity: faded ? .16 : 1,
    child: SizedBox.square(
      dimension: 76,
      child: ForestProp(
        [
          ForestObject.berry,
          ForestObject.raspberry,
          ForestObject.acorn,
          ForestObject.blueberry,
        ][i],
        size: 72,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ForestProgress(count: eaten.length, total: names.length),
      Expanded(
        child: Stack(
          alignment: Alignment.center,
          children: [
            DragTarget<int>(
              onWillAcceptWithDetails: (_) {
                setState(() => hovering = true);
                return !chewing;
              },
              onLeave: (_) => setState(() => hovering = false),
              onAcceptWithDetails: (details) => eat(details.data),
              builder: (_, _, _) => Semantics(
                label: '모모에게 열매를 가져다 주세요',
                child: AnimatedScale(
                  scale: !widget.lowStimulation && (chewing || hovering)
                      ? 1.07
                      : 1,
                  duration: widget.lowStimulation
                      ? Duration.zero
                      : const Duration(milliseconds: 240),
                  child: LayoutBuilder(
                    builder: (_, box) {
                      final size = (box.maxHeight * .72).clamp(120.0, 250.0);
                      return SizedBox(
                        width: size + 40,
                        height: size + 60,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (hovering)
                              Container(
                                width: size,
                                height: size,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFF8DEA2),
                                ),
                              ),
                            ForestFloat(
                              still: widget.lowStimulation,
                              child: AvatarImage(
                                avatar: 'momo',
                                size: size,
                                interactive: false,
                                lowStimulation: widget.lowStimulation,
                              ),
                            ),
                            if (chewing)
                              const Positioned(
                                top: 0,
                                right: 8,
                                child: ForestProp(ForestObject.heart, size: 55),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (eaten.isEmpty && !widget.lowStimulation)
              const Positioned(
                bottom: 0,
                child: HandGuideHint(
                  start: Offset(-70, 25),
                  end: Offset(0, -65),
                ),
              ),
          ],
        ),
      ),
      Text(
        chewing
            ? '냠냠!'
            : eaten.length == 4
            ? '고마워!'
            : '아~',
        style: const TextStyle(
          fontSize: 24,
          color: forestInk,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 98,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < names.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  label: '${names[i]} 먹이기',
                  enabled: !eaten.contains(i) && !chewing,
                  onTap: eaten.contains(i) || chewing ? null : () => eat(i),
                  child: ExcludeSemantics(
                    child: Draggable<int>(
                      data: i,
                      maxSimultaneousDrags: eaten.contains(i) || chewing
                          ? 0
                          : 1,
                      feedback: Material(
                        color: Colors.transparent,
                        child: fruit(i),
                      ),
                      childWhenDragging: fruit(i, faded: true),
                      child: GestureDetector(
                        onTap: eaten.contains(i) || chewing
                            ? null
                            : () => eat(i),
                        child: fruit(i, faded: eaten.contains(i)),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      SizedBox(
        height: 64,
        child: eaten.length == 4
            ? ForestAction(
                label: '열매 다시 담기',
                icon: Icons.refresh_rounded,
                size: 60,
                onPressed: () => setState(eaten.clear),
              )
            : const Icon(
                Icons.touch_app_rounded,
                size: 32,
                color: Color(0xFF779363),
              ),
      ),
    ],
  );
}
