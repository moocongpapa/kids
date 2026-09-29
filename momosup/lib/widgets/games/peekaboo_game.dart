import 'package:flutter/material.dart';

import '../../utils/sound_effects.dart';
import '../avatar_image.dart';
import '../forest_game_ui.dart';

class PeekabooGame extends StatefulWidget {
  const PeekabooGame({this.onComplete, this.lowStimulation = false, super.key});
  final VoidCallback? onComplete;
  final bool lowStimulation;
  @override
  State<PeekabooGame> createState() => _PeekabooGameState();
}

class _PeekabooGameState extends State<PeekabooGame> {
  final found = <int>{};
  void reveal(int i) {
    if (found.contains(i)) return;
    setState(() => found.add(i));
    SoundEffects.instance.pop();
    if (found.length == 3) widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ForestProgress(count: found.length, total: 3),
      Expanded(
        child: LayoutBuilder(
          builder: (_, box) => Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 340,
                height: 370,
                child: Stack(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Positioned(
                        left: [95.0, 3.0, 187.0][i],
                        top: [10.0, 190.0, 180.0][i],
                        child: Semantics(
                          button: true,
                          label: ['풀숲 속 모모 찾기', '나무 뒤 두리 찾기', '꽃밭 속 누리 찾기'][i],
                          onTap: () => reveal(i),
                          child: ExcludeSemantics(
                            child: GestureDetector(
                              onTap: () => reveal(i),
                              child: SizedBox(
                                width: 150,
                                height: 170,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    AnimatedPositioned(
                                      duration: widget.lowStimulation
                                          ? Duration.zero
                                          : const Duration(milliseconds: 420),
                                      curve: Curves.easeOutBack,
                                      bottom: found.contains(i) ? 55 : 0,
                                      child: AnimatedOpacity(
                                        opacity: found.contains(i) ? 1 : 0,
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        child: AvatarImage(
                                          avatar: ['momo', 'duri', 'nuri'][i],
                                          size: 106,
                                          interactive: false,
                                        ),
                                      ),
                                    ),
                                    ForestFloat(
                                      still:
                                          widget.lowStimulation ||
                                          found.contains(i),
                                      offset: i.toDouble(),
                                      child: ForestProp(
                                        i == 2
                                            ? ForestObject.flower
                                            : ForestObject.bush,
                                        size: 143,
                                      ),
                                    ),
                                    if (found.contains(i))
                                      const Positioned(
                                        top: 0,
                                        child: Text(
                                          '까꿍!',
                                          style: TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.w900,
                                            color: forestInk,
                                          ),
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
            ),
          ),
        ),
      ),
      SizedBox(
        height: 66,
        child: found.length == 3
            ? ForestAction(
                label: '다시 숨기기',
                icon: Icons.refresh_rounded,
                size: 60,
                onPressed: () => setState(found.clear),
              )
            : const Icon(
                Icons.touch_app_rounded,
                size: 38,
                color: Color(0xFF779363),
              ),
      ),
    ],
  );
}
