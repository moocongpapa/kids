import 'package:flutter/material.dart';

import '../../utils/sound_effects.dart';
import '../avatar_image.dart';
import '../forest_game_ui.dart';
import '../hand_guide_hint.dart';

class SilhouettePuzzleGame extends StatefulWidget {
  const SilhouettePuzzleGame({
    this.onComplete,
    this.lowStimulation = false,
    super.key,
  });
  final VoidCallback? onComplete;
  final bool lowStimulation;
  @override
  State<SilhouettePuzzleGame> createState() => _SilhouettePuzzleGameState();
}

class _SilhouettePuzzleGameState extends State<SilhouettePuzzleGame> {
  final matched = <String>{};
  String? selected;
  static const avatars = ['momo', 'duri', 'nuri'];
  static const names = ['모모', '두리', '누리'];
  void place(String id, String target) {
    if (matched.contains(target)) return;
    if (id != target) {
      SoundEffects.instance.boing();
      return;
    }
    setState(() {
      matched.add(id);
      selected = null;
    });
    SoundEffects.instance.snap();
    if (matched.length == 3) widget.onComplete?.call();
  }

  Widget piece(String avatar) => AvatarImage(
    avatar: avatar,
    size: 88,
    interactive: false,
    lowStimulation: true,
  );
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => Column(
      children: [
        ForestProgress(count: matched.length, total: 3),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < 3; i++)
                    DragTarget<String>(
                      onWillAcceptWithDetails: (_) =>
                          !matched.contains(avatars[i]),
                      onAcceptWithDetails: (d) => place(d.data, avatars[i]),
                      builder: (_, candidates, _) => Semantics(
                        button: true,
                        label: '${names[i]} 그림자',
                        onTap: selected == null
                            ? null
                            : () => place(selected!, avatars[i]),
                        child: GestureDetector(
                          onTap: selected == null
                              ? null
                              : () => place(selected!, avatars[i]),
                          child: Container(
                            width: ((bounds.maxWidth - 24) / 3).clamp(
                              78.0,
                              108.0,
                            ),
                            height: 132,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: candidates.isEmpty
                                  ? const Color(0xFFE8CD9F)
                                  : const Color(0xFFF8E7AC),
                              borderRadius: const BorderRadius.all(
                                Radius.elliptical(55, 62),
                              ),
                              border: Border.all(
                                color: const Color(0xFFC49A69),
                                width: 4,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFFAD8354),
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: matched.contains(avatars[i])
                                ? piece(avatars[i])
                                : ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFFA18760),
                                      BlendMode.srcIn,
                                    ),
                                    child: piece(avatars[i]),
                                  ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (matched.isEmpty && selected == null && !widget.lowStimulation)
                const Positioned(
                  bottom: 10,
                  child: HandGuideHint(
                    start: Offset(-80, 35),
                    end: Offset(-90, -60),
                  ),
                ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < 3; i++)
              Semantics(
                button: true,
                label: '${names[i]} 퍼즐 조각',
                selected: selected == avatars[i],
                child: GestureDetector(
                  onTap: matched.contains(avatars[i])
                      ? null
                      : () => setState(() => selected = avatars[i]),
                  child: Draggable<String>(
                    data: avatars[i],
                    maxSimultaneousDrags: matched.contains(avatars[i]) ? 0 : 1,
                    feedback: Material(
                      color: Colors.transparent,
                      child: piece(avatars[i]),
                    ),
                    childWhenDragging: Opacity(
                      opacity: .15,
                      child: piece(avatars[i]),
                    ),
                    child: Opacity(
                      opacity: matched.contains(avatars[i]) ? .15 : 1,
                      child: Container(
                        width: (bounds.maxWidth / 3).clamp(78.0, 100.0),
                        height: 110,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected == avatars[i]
                              ? const Color(0xFFFBE5AE)
                              : Colors.transparent,
                        ),
                        child: piece(avatars[i]),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(
          height: 66,
          child: matched.length == 3
              ? ForestAction(
                  label: '퍼즐 다시 맞추기',
                  icon: Icons.refresh_rounded,
                  size: 60,
                  onPressed: () => setState(() {
                    matched.clear();
                    selected = null;
                  }),
                )
              : const Icon(
                  Icons.touch_app_rounded,
                  size: 32,
                  color: Color(0xFF779363),
                ),
        ),
      ],
    ),
  );
}
