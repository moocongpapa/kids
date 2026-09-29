import 'package:flutter/material.dart';

import '../../utils/sound_effects.dart';
import '../forest_game_ui.dart';

class XylophoneGame extends StatefulWidget {
  const XylophoneGame({
    this.onComplete,
    this.lowStimulation = false,
    super.key,
  });
  final VoidCallback? onComplete;
  final bool lowStimulation;
  @override
  State<XylophoneGame> createState() => _XylophoneGameState();
}

class _XylophoneGameState extends State<XylophoneGame> {
  int? active;
  final played = <int>{};
  static const notes = ['도', '레', '미', '파', '솔', '라', '시', '높은 도'];
  static const colors = [
    Color(0xFFD98C76),
    Color(0xFFE6A766),
    Color(0xFFD7BF60),
    Color(0xFF91B56D),
    Color(0xFF73AAA2),
    Color(0xFF75A2B7),
    Color(0xFF9B98BA),
    Color(0xFFC197AF),
  ];
  void play(int i) {
    setState(() {
      active = i;
      played.add(i);
    });
    SoundEffects.instance.playNote(i);
    if (played.length == 8) widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => Column(
      children: [
        Expanded(
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 22,
              children: List.generate(
                8,
                (i) => Semantics(
                  label: '${notes[i]} 음 연주',
                  button: true,
                  onTap: () => play(i),
                  child: ExcludeSemantics(
                    child: GestureDetector(
                      onTapDown: (_) => play(i),
                      onTapUp: (_) => setState(() => active = null),
                      onTapCancel: () => setState(() => active = null),
                      child: AnimatedScale(
                        scale: active == i && !widget.lowStimulation ? .92 : 1,
                        duration: const Duration(milliseconds: 100),
                        child: Container(
                          width: ((bounds.maxWidth - 36) / 4).clamp(60.0, 84.0),
                          height: 132,
                          decoration: BoxDecoration(
                            color: colors[i],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(34),
                              topRight: Radius.circular(10),
                              bottomLeft: Radius.circular(34),
                              bottomRight: Radius.circular(34),
                            ),
                            border: Border.all(
                              color: const Color(0xFFFFF4D6).withAlpha(190),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors[i].withGreen(
                                  (colors[i].g * 180).round(),
                                ),
                                offset: const Offset(0, 7),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF718965),
                                ),
                              ),
                              const Icon(
                                Icons.water_drop_rounded,
                                color: Color(0xFFFFF2CC),
                                size: 30,
                              ),
                              Text(
                                i == 7 ? '도' : notes[i],
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: forestCream,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Icon(Icons.touch_app_rounded, size: 28, color: Color(0xFF779363)),
        const SizedBox(height: 8),
      ],
    ),
  );
}
