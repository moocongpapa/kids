import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'avatar_image.dart';
import 'forest_game_ui.dart';
import 'forest_play_stage.dart';

class JourneyRhythmScene extends StatelessWidget {
  const JourneyRhythmScene({
    required this.id,
    required this.slots,
    required this.count,
    required this.active,
    required this.selected,
    required this.stage,
    required this.busy,
    required this.quiet,
    required this.onSelect,
    required this.onPlace,
    required this.onListen,
    super.key,
  });
  final String id;
  final Map<int, int> slots;
  final int count, active, selected, stage;
  final bool busy, quiet;
  final ValueChanged<int> onSelect;
  final void Function(int slot, int note) onPlace;
  final VoidCallback onListen;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ForestPlayStage(
        height: 274,
        river: id == 'age_48_06',
        quiet: quiet,
        child: LayoutBuilder(
          builder: (_, box) => Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 0,
                child: SceneReaction(
                  event: active,
                  quiet: quiet,
                  child: AvatarImage(
                    avatar: id == 'age_48_06' ? 'nuri' : 'momo',
                    size: 115,
                    interactive: false,
                    lowStimulation: quiet,
                    showBlush: active >= 0,
                  ),
                ),
              ),
              if (active >= 0)
                Positioned(
                  top: 6,
                  right: box.maxWidth * .12,
                  child: ForestProp(
                    slots[active] == 3
                        ? ForestObject.cloud
                        : ForestObject.music,
                    size: 55,
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 25,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < count; i++)
                      DragTarget<int>(
                        onWillAcceptWithDetails: (d) =>
                            !busy && d.data >= 0 && d.data < 4,
                        onAcceptWithDetails: (d) => onPlace(i, d.data),
                        builder: (_, candidates, _) => PlayPiece(
                          label: '${i + 1}번째 소리 자리',
                          size: ((box.maxWidth - 8) / count).clamp(64.0, 94.0),
                          enabled: !busy,
                          selected: active == i || candidates.isNotEmpty,
                          quiet: quiet,
                          onTap: () => onPlace(i, selected),
                          child: Opacity(
                            opacity: slots.containsKey(i) ? 1 : .3,
                            child: InstrumentPicture(
                              note: slots[i] ?? i % 3,
                              hand: id == 'age_24_05' || id == 'age_84_04',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (
            var i = 0;
            i <
                (stage == 0
                    ? 1
                    : stage == 1
                    ? 3
                    : 4);
            i++
          )
            PlayPiece(
              label: i == 3 ? '쉼' : '${i + 1}번 소리',
              size: 76,
              selected: selected == i,
              quiet: quiet,
              enabled: !busy,
              dragValue: i,
              onTap: () => onSelect(i),
              child: InstrumentPicture(
                note: i,
                hand: id == 'age_24_05' || id == 'age_84_04',
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
      ForestAction(
        label: '내 소리 이어 듣기',
        size: 80,
        quiet: quiet,
        leaf: true,
        onPressed: slots.isEmpty || busy ? null : onListen,
        child: const ForestProp(ForestObject.music, size: 56),
      ),
    ],
  );
}

class InstrumentPicture extends StatelessWidget {
  const InstrumentPicture({required this.note, this.hand = false, super.key});
  final int note;
  final bool hand;
  @override
  Widget build(BuildContext context) => hand && note != 3
      ? ForestProp(
          [ForestObject.paw, ForestObject.leaf, ForestObject.heart][note % 3],
          size: 72,
        )
      : CustomPaint(painter: _Instrument(note), child: const SizedBox.expand());
}

class _Instrument extends CustomPainter {
  const _Instrument(this.note);
  final int note;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 80, s.height / 80);
    if (note == 3) {
      c.drawCircle(
        const Offset(40, 39),
        28,
        Paint()..color = const Color(0xFFF2D58B),
      );
      c.drawCircle(
        const Offset(51, 29),
        22,
        Paint()..color = const Color(0xFFADC59A),
      );
      c.drawCircle(
        const Offset(60, 56),
        3,
        Paint()..color = const Color(0xFFFFF4D6),
      );
    } else {
      const colors = [Color(0xFFD99579), Color(0xFF87B4C0), Color(0xFFE2C273)];
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(27, 33, 27, 37),
          const Radius.circular(9),
        ),
        Paint()..color = const Color(0xFFDEC79D),
      );
      c.drawOval(
        const Rect.fromLTWH(9, 18, 63, 41),
        Paint()..color = colors[note % 3],
      );
      c.drawArc(
        const Rect.fromLTWH(11, 18, 59, 37),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = const Color(0x66FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      for (final p in [
        const Offset(27, 32),
        const Offset(47, 28),
        const Offset(56, 40),
      ]) {
        c.drawOval(
          Rect.fromCenter(center: p, width: 8, height: 6),
          Paint()..color = const Color(0xFFFFF0CC),
        );
      }
      c.drawCircle(const Offset(36, 56), 2, Paint()..color = forestInk);
      c.drawCircle(const Offset(46, 56), 2, Paint()..color = forestInk);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_Instrument old) => old.note != note;
}
