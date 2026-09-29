import 'package:flutter/material.dart';

import 'avatar_image.dart';
import 'forest_game_ui.dart';
import 'journey_garden_scene.dart';
import 'touch_invitation.dart';

class JourneyRevealScene extends StatelessWidget {
  const JourneyRevealScene({
    required this.id,
    this.step = 0,
    required this.avatar,
    required this.options,
    required this.selected,
    required this.revealed,
    required this.quiet,
    required this.onChoose,
    super.key,
  });
  final String id, avatar;
  final int step;
  final List<ForestObject> options;
  final int selected;
  final bool revealed, quiet;
  final ValueChanged<int> onChoose;
  @override
  Widget build(BuildContext context) {
    if (id == 'age_24_01' || id == 'age_24_06') {
      return JourneyGardenScene(
        weather: id == 'age_24_06',
        step: step,
        revealed: revealed,
        quiet: quiet,
        onTap: () => onChoose(0),
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
                child: TouchInvitation(
                  visible: !revealed && i == 0,
                  quiet: quiet,
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
          ),
      ],
    );
  }
}
