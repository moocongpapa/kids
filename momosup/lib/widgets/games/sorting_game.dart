import 'package:flutter/material.dart';

import '../../utils/sound_effects.dart';
import '../forest_game_ui.dart';
import '../hand_guide_hint.dart';

class SortingGame extends StatefulWidget {
  const SortingGame({this.onComplete, this.lowStimulation = false, super.key});
  final VoidCallback? onComplete;
  final bool lowStimulation;
  @override
  State<SortingGame> createState() => _SortingGameState();
}

class _SortingGameState extends State<SortingGame> {
  final sorted = <int>{};
  int? selected;
  void place(int id, bool big) {
    if (sorted.contains(id)) return;
    if (id.isEven != big) {
      SoundEffects.instance.boing();
      return;
    }
    setState(() {
      sorted.add(id);
      selected = null;
    });
    SoundEffects.instance.pop();
    if (sorted.length == 6) widget.onComplete?.call();
  }

  Widget acorn(int i) => SizedBox.square(
    dimension: 82,
    child: Center(
      child: ForestProp(ForestObject.acorn, size: i.isEven ? 78 : 49),
    ),
  );
  Widget basket(bool big, double extent) => Expanded(
    child: DragTarget<int>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => place(d.data, big),
      builder: (_, candidates, _) => Semantics(
        label: big ? '큰 바구니' : '작은 바구니',
        button: true,
        onTap: selected == null ? null : () => place(selected!, big),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: selected == null ? null : () => place(selected!, big),
          child: AnimatedScale(
            scale: candidates.isNotEmpty && !widget.lowStimulation ? 1.06 : 1,
            duration: const Duration(milliseconds: 180),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ForestProp(ForestObject.acorn, size: big ? 26 : 20),
                ForestProp(
                  ForestObject.basket,
                  size: big ? extent : extent * .79,
                ),
                ForestProgress(
                  count: sorted.where((i) => i.isEven == big).length,
                  total: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ForestProgress(count: sorted.length, total: 6),
      Expanded(
        child: LayoutBuilder(
          builder: (_, box) => Stack(
            alignment: Alignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  basket(true, (box.maxHeight - 54).clamp(76, 142)),
                  basket(false, (box.maxHeight - 54).clamp(76, 142)),
                ],
              ),
              if (sorted.isEmpty && selected == null && !widget.lowStimulation)
                const Positioned(
                  bottom: 0,
                  child: HandGuideHint(
                    start: Offset(-60, 20),
                    end: Offset(-80, -70),
                  ),
                ),
            ],
          ),
        ),
      ),
      if (sorted.length == 6)
        SizedBox(
          height: 164,
          child: Center(
            child: ForestAction(
              label: '도토리 다시 담기',
              icon: Icons.refresh_rounded,
              size: 68,
              onPressed: () => setState(() {
                sorted.clear();
                selected = null;
              }),
            ),
          ),
        )
      else
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 0,
          children: [
            for (var i = 0; i < 6; i++)
              Semantics(
                button: true,
                label: '${i.isEven ? '큰' : '작은'} 도토리 ${i + 1}',
                selected: selected == i,
                enabled: !sorted.contains(i),
                child: GestureDetector(
                  onTap: sorted.contains(i)
                      ? null
                      : () => setState(() => selected = i),
                  child: Draggable<int>(
                    data: i,
                    maxSimultaneousDrags: sorted.contains(i) ? 0 : 1,
                    feedback: Material(
                      color: Colors.transparent,
                      child: acorn(i),
                    ),
                    childWhenDragging: Opacity(opacity: .2, child: acorn(i)),
                    child: Opacity(
                      opacity: sorted.contains(i) ? .16 : 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: selected == i
                              ? const Color(0xFFF8E2A9)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: acorn(i),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
    ],
  );
}
