import 'package:flutter/material.dart';

import '../utils/sound_effects.dart';
import 'coloring_templates.dart';
import 'forest_game_ui.dart';
import 'forest_landscape.dart';
import 'forest_play_stage.dart';
import 'game_particles.dart';

export 'coloring_templates.dart';

/// The interactive Tap-to-Fill coloring studio widget.
class ForestColoringStudio extends StatefulWidget {
  const ForestColoringStudio({
    this.initialTemplateIndex = 0,
    this.quiet = false,
    this.onChanged,
    super.key,
  });

  final int initialTemplateIndex;
  final bool quiet;
  final VoidCallback? onChanged;

  @override
  State<ForestColoringStudio> createState() => _ForestColoringStudioState();
}

class _ForestColoringStudioState extends State<ForestColoringStudio> {
  // 12 warm forest-friendly paint colors
  static const palette = [
    Color(0xFFE25B5B), // 딸기 빨강
    Color(0xFFF48FB1), // 복숭아 핑크
    Color(0xFFFF9E40), // 살구 오렌지
    Color(0xFFF9D423), // 개나리 노랑
    Color(0xFF9CCC65), // 새싹 연두
    Color(0xFF4CAF50), // 깊은숲 초록
    Color(0xFF4FC3F7), // 하늘 파랑
    Color(0xFF2979FF), // 바다 파랑
    Color(0xFFAB47BC), // 포도 보라
    Color(0xFF8D6E63), // 초코 갈색
    Color(0xFFFFF9E9), // 포근 크림
    Color(0xFF424242), // 숲 먹색
  ];

  static const colorNames = [
    '딸기 빨강',
    '복숭아 핑크',
    '살구 오렌지',
    '개나리 노랑',
    '새싹 연두',
    '숲 초록',
    '하늘 파랑',
    '바다 파랑',
    '포도 보라',
    '초코 갈색',
    '포근 크림',
    '숲 먹색',
  ];

  late int selectedTemplateIndex;
  int selectedColorIndex = 0;
  late List<ColoringSegment> currentSegments;
  final List<List<Color?>> _history = [];
  final GlobalKey<GameParticlesState> _particlesKey = GlobalKey();
  int _lastTappedSegment = -1;
  int _wobble = 0;
  bool _celebrated = false;

  @override
  void initState() {
    super.initState();
    selectedTemplateIndex =
        widget.initialTemplateIndex.clamp(0, ColoringCatalog.all.length - 1);
    _loadTemplate(selectedTemplateIndex);
  }

  void _loadTemplate(int index) {
    selectedTemplateIndex = index;
    currentSegments = ColoringCatalog.all[index].createSegments();
    _history.clear();
    _saveHistory();
    _celebrated = false;
  }

  void _saveHistory() {
    _history.add(currentSegments.map((s) => s.color).toList());
    if (_history.length > 30) _history.removeAt(0);
  }

  void _undo() {
    if (_history.length <= 1) return;
    setState(() {
      _history.removeLast();
      final prev = _history.last;
      for (var i = 0; i < currentSegments.length; i++) {
        currentSegments[i].color = prev[i];
      }
    });
    SoundEffects.instance.pop();
    widget.onChanged?.call();
  }

  void _reset() {
    setState(() {
      _loadTemplate(selectedTemplateIndex);
    });
    SoundEffects.instance.whoosh();
    widget.onChanged?.call();
  }

  void _handleTap(Offset localPos, Size canvasSize) {
    // Canvas is normalized to 280 x 290 reference frame
    final scaleX = canvasSize.width / 280;
    final scaleY = canvasSize.height / 290;
    final normalizedPos = Offset(localPos.dx / scaleX, localPos.dy / scaleY);

    // Hit test segments from top to bottom (last drawn wins)
    int hitIndex = -1;
    for (var i = currentSegments.length - 1; i >= 0; i--) {
      if (currentSegments[i].path.contains(normalizedPos)) {
        hitIndex = i;
        break;
      }
    }

    if (hitIndex != -1) {
      final chosenColor = palette[selectedColorIndex];
      setState(() {
        currentSegments[hitIndex].color = chosenColor;
        _lastTappedSegment = hitIndex;
        _wobble++;
      });
      _saveHistory();
      SoundEffects.instance.pop();
      widget.onChanged?.call();

      // Check if all segments are colored
      final coloredCount =
          currentSegments.where((s) => s.color != null).length;
      if (coloredCount >= currentSegments.length && !_celebrated) {
        _celebrated = true;
        SoundEffects.instance.tada();
        if (!widget.quiet) {
          _particlesKey.currentState?.celebrate(
            Offset(canvasSize.width / 2, canvasSize.height / 2),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final template = ColoringCatalog.all[selectedTemplateIndex];
    final isWide = forestIsWide(context);

    // 1. Template Selector Chips
    final templateSelector = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          for (var i = 0; i < ColoringCatalog.all.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  if (selectedTemplateIndex != i) {
                    SoundEffects.instance.pop();
                    setState(() => _loadTemplate(i));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selectedTemplateIndex == i
                        ? const Color(0xFF5A7942)
                        : const Color(0xFFEAD2A0),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selectedTemplateIndex == i
                          ? const Color(0xFFF9E8BD)
                          : const Color(0xFFD4B57D),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ColoringCatalog.all[i].emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ColoringCatalog.all[i].title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: selectedTemplateIndex == i
                              ? Colors.white
                              : forestInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // 2. Title Row
    final titleRow = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(template.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            '${template.title} 색칠하기',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: forestInk,
            ),
          ),
        ],
      ),
    );

    // 3. Canvas Widget
    final canvasWidget = Center(
      child: SceneReaction(
        event: _wobble,
        quiet: widget.quiet,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFD4B57D),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFAF8C57), width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x447B744B),
                offset: Offset(0, 6),
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: isWide ? 260 : 300,
              height: isWide ? 245 : 290,
              color: const Color(0xFFFFFDF5),
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (ctx, box) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) => _handleTap(d.localPosition, box.biggest),
                      child: CustomPaint(
                        size: box.biggest,
                        painter: _ColoringCanvasPainter(
                          segments: currentSegments,
                          lastTapped: _lastTappedSegment,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: GameParticles(key: _particlesKey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // 4. Palette Widget
    final paletteWidget = Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < palette.length; i++)
          Semantics(
            label: '${colorNames[i]} 물감 선택',
            button: true,
            child: GestureDetector(
              onTap: () {
                SoundEffects.instance.pop();
                setState(() => selectedColorIndex = i);
              },
              child: AnimatedScale(
                scale: selectedColorIndex == i ? 1.18 : 1.0,
                duration: const Duration(milliseconds: 160),
                child: Container(
                  width: isWide ? 40 : 40,
                  height: isWide ? 40 : 40,
                  decoration: BoxDecoration(
                    color: palette[i],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selectedColorIndex == i
                          ? const Color(0xFF2C4A28)
                          : Colors.white,
                      width: selectedColorIndex == i ? 3.5 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(
                          selectedColorIndex == i ? 70 : 35,
                        ),
                        offset: const Offset(0, 3),
                        blurRadius: selectedColorIndex == i ? 6 : 3,
                      ),
                    ],
                  ),
                  child: selectedColorIndex == i
                      ? const Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
            ),
          ),
      ],
    );

    // 5. Action Buttons (Undo & Reset)
    final actionButtons = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ForestAction(
          label: '되돌리기',
          caption: '되돌리기',
          icon: Icons.undo_rounded,
          size: 58,
          quiet: widget.quiet,
          onPressed: _history.length > 1 ? _undo : null,
        ),
        const SizedBox(width: 16),
        ForestAction(
          label: '깨끗이 다시 칠하기',
          caption: '다시 시작',
          icon: Icons.refresh_rounded,
          size: 58,
          quiet: widget.quiet,
          onPressed: _reset,
        ),
      ],
    );

    if (isWide) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                titleRow,
                canvasWidget,
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 250,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                templateSelector,
                const SizedBox(height: 8),
                paletteWidget,
                const SizedBox(height: 10),
                actionButtons,
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        templateSelector,
        titleRow,
        canvasWidget,
        const SizedBox(height: 12),
        paletteWidget,
        const SizedBox(height: 12),
        actionButtons,
      ],
    );
  }
}

/// Custom painter for the coloring canvas.
class _ColoringCanvasPainter extends CustomPainter {
  _ColoringCanvasPainter({
    required this.segments,
    required this.lastTapped,
  });

  final List<ColoringSegment> segments;
  final int lastTapped;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Scale canvas coordinates from reference 280 x 290
    final scaleX = size.width / 280;
    final scaleY = size.height / 290;
    canvas.scale(scaleX, scaleY);

    // 1. Draw segment fills
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = seg.color ?? const Color(0xFFFAF7EE);

      canvas.drawPath(seg.path, fillPaint);
    }

    // 2. Draw crisp dark borders over all segments
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF382E25);

    for (final seg in segments) {
      canvas.drawPath(seg.path, borderPaint);
    }

    // 3. Draw inner details (eyes, nose, mouth lines) for character expressions
    final detailPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF2B221B);

    final lineDetail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2B221B);

    // Eyes and cute features depending on segments present
    if (segments.any((s) => s.id == 'snout' || s.id == 'head')) {
      // Rabbit / Bear eye positions
      canvas.drawCircle(const Offset(112, 135), 4.5, detailPaint);
      canvas.drawCircle(const Offset(168, 135), 4.5, detailPaint);
      // Highlights
      canvas.drawCircle(
        const Offset(110.5, 133.5),
        1.5,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        const Offset(166.5, 133.5),
        1.5,
        Paint()..color = Colors.white,
      );
      // Small nose & mouth
      canvas.drawOval(const Rect.fromLTWH(136, 155, 8, 6), detailPaint);
      final mouth = Path()
        ..moveTo(140, 161)
        ..lineTo(140, 167)
        ..moveTo(134, 167)
        ..quadraticBezierTo(140, 172, 140, 167)
        ..quadraticBezierTo(140, 172, 146, 167);
      canvas.drawPath(mouth, lineDetail);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ColoringCanvasPainter oldDelegate) => true;
}
