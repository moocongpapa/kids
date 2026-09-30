import 'package:flutter/material.dart';

import 'avatar_image.dart';
import 'forest_game_ui.dart';
import 'forest_play_stage.dart';
import 'touch_invitation.dart';

/// Matching a visible clue, with optional hand-over between two detectives.
class JourneyDetectiveScene extends StatefulWidget {
  const JourneyDetectiveScene({
    required this.step,
    required this.count,
    required this.stage,
    required this.quiet,
    required this.cooperative,
    required this.onFound,
    super.key,
  });
  final int step, count, stage;
  final bool quiet, cooperative;
  final ValueChanged<int> onFound;
  int get target => step % count;
  @override
  State<JourneyDetectiveScene> createState() => _JourneyDetectiveSceneState();
}

class _JourneyDetectiveSceneState extends State<JourneyDetectiveScene> {
  bool hint = false, found = false, handedOver = false;
  int? inspected;
  static const clues = [
    Icons.pets_rounded,
    Icons.spa_rounded,
    Icons.circle_outlined,
  ];
  @override
  Widget build(BuildContext context) {
    final needsHandover = widget.cooperative && widget.step > 0 && !handedOver;
    return Column(
      children: [
        if (needsHandover)
          ForestAction(
            label: '다음 탐정에게 건네기',
            size: 100,
            icon: Icons.front_hand_rounded,
            quiet: widget.quiet,
            onPressed: () => setState(() => handedOver = true),
          ),
        if (!needsHandover)
          ForestPlayStage(
            height: 330,
            quiet: widget.quiet,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Semantics(
                  label: '찾을 단서 ${widget.target + 1}',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        size: 40,
                        color: forestInk,
                      ),
                      const SizedBox(width: 12),
                      Icon(clues[widget.target], size: 56, color: forestInk),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < widget.count; i++)
                      Flexible(
                        child: TouchInvitation(
                          visible:
                              !found &&
                              (hint || widget.stage == 0) &&
                              i == widget.target,
                          quiet: widget.quiet,
                          child: PlayPiece(
                            label: '${i + 1}번째 단서 친구',
                            size: widget.count == 3 ? 90 : 120,
                            quiet: widget.quiet,
                            selected: inspected == i,
                            onTap: () {
                              if (found) return;
                              setState(() {
                                inspected = i;
                                hint = i != widget.target;
                                found = i == widget.target;
                              });
                              if (found) widget.onFound(i);
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(child: AvatarImage(
                                  avatar: ['momo', 'duri', 'nuri'][i],
                                  size: widget.count == 3 ? 48 : 72,
                                  interactive: false,
                                  lowStimulation: widget.quiet,
                                  showBlush: found && i == widget.target,
                                )),
                                Icon(clues[i], size: 28, color: forestInk),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (hint)
                  Semantics(
                    label: '길 위 단서와 친구의 단서를 함께 살펴봐요',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(clues[widget.target], size: 40, color: forestInk),
                        const Icon(
                          Icons.compare_arrows_rounded,
                          size: 34,
                          color: forestInk,
                        ),
                        Icon(clues[inspected!], size: 40, color: forestInk),
                      ],
                    ),
                  ),
                if (found)
                  const Icon(
                    Icons.favorite_rounded,
                    size: 40,
                    color: Color(0xFFCC8269),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
