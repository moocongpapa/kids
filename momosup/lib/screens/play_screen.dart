import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../models/activity.dart';
import '../models/child_profile.dart';
import '../state/app_state.dart';
import '../utils/forest_audio.dart';
import '../widgets/avatar_image.dart';
import '../widgets/forest_background.dart';
import '../widgets/forest_game_ui.dart';

/// One finite activity. Drafts may be opened only through the parent preview.
class PlayScreen extends StatefulWidget {
  const PlayScreen({
    required this.activity,
    required this.appState,
    required this.profile,
    required this.isParentPreview,
    super.key,
  });

  final Activity activity;
  final AppState appState;
  final ChildProfile profile;
  final bool isParentPreview;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  final Stopwatch clock = Stopwatch();
  final AudioPlayer voice = AudioPlayer();
  final GlobalKey drawingKey = GlobalKey();
  final List<_Stroke> strokes = [];
  _Stroke? currentStroke;
  Color selectedColor = const Color(0xFFDB857D);
  int phase = 0; // 0: introduction, 1: interaction, 2: finite ending.
  int step = 0;
  int? selectedChoice;
  final Set<int> visitedChoices = {};
  bool saved = false;
  bool saving = false;
  Completer<void>? saveCompletion;
  String? saveError;
  bool recorded = false;
  bool finishing = false;
  bool audioFailed = false;
  int audioRequest = 0;
  Timer? endTimer;

  @override
  void initState() {
    super.initState();
    ForestAudio.instance.pauseBgm();
    clock.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => playAudio(['intro']));
    if (!widget.isParentPreview) {
      final remainingMinutes = math.max(
        1,
        widget.profile.dailyLimitMinutes -
            widget.appState.minutesToday(widget.profile.id),
      );
      endTimer = Timer(
        Duration(minutes: math.min(widget.activity.minutes, remainingMinutes)),
        finish,
      );
    }
  }

  @override
  void dispose() {
    ForestAudio.instance.startBgm(enabled: widget.profile.musicOn);
    endTimer?.cancel();
    clock.stop();
    voice.dispose();
    super.dispose();
  }

  Future<void> playAudio(List<String> lineIds) async {
    if (widget.isParentPreview || audioFailed) return;
    final request = ++audioRequest;
    try {
      await voice.stop();
      for (final id in lineIds) {
        if (!mounted || request != audioRequest) return;
        final path = widget.activity.audioFiles[id];
        if (path == null) throw StateError('필수 음성이 없습니다: $id');
        await voice.setAsset(path);
        if (!mounted || request != audioRequest) return;
        await voice.play();
      }
    } catch (_) {
      if (!mounted || request != audioRequest) return;
      setState(() => audioFailed = true);
      await voice.stop();
      await finish();
    }
  }

  Future<void> finish() async {
    if (phase == 2 || finishing) return;
    finishing = true;
    endTimer?.cancel();
    if (widget.activity.mode == PlayMode.color &&
        strokes.isNotEmpty &&
        !saved) {
      await saveDrawing();
    }
    if (!mounted) return;
    clock.stop();
    setState(() => phase = 2);
    if (!audioFailed) playAudio(['outro', 'offscreen']);
    if (!widget.isParentPreview && !recorded) {
      recorded = true;
      await widget.appState.recordPlay(
        profileId: widget.profile.id,
        activityId: widget.activity.id,
        seconds: clock.elapsed.inSeconds,
      );
    }
  }

  Future<void> saveDrawing() async {
    if (saving) {
      await saveCompletion?.future;
      return;
    }
    final completion = Completer<void>();
    saveCompletion = completion;
    setState(() {
      saving = true;
      saveError = null;
    });
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          drawingKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('그림이 준비되지 않았어요.');
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('그림을 저장할 수 없어요.');
      final directory = await getApplicationDocumentsDirectory();
      final drawings = Directory('${directory.path}/momosup_drawings');
      await drawings.create(recursive: true);
      final filename =
          '${widget.profile.id}_${widget.activity.id}_'
          '${DateTime.now().millisecondsSinceEpoch}.png';
      await File('${drawings.path}/$filename')
          .writeAsBytes(data.buffer.asUint8List(), flush: true);
      if (mounted) setState(() => saved = true);
    } catch (_) {
      if (mounted) {
        setState(() => saveError = '기기에 저장하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => saving = false);
      saveCompletion = null;
      completion.complete();
    }
  }

  bool get quiet =>
      widget.profile.lowStimulation || MediaQuery.disableAnimationsOf(context);
  String get shortTitle => switch (widget.activity.id) {
    'animal_tracks' => '누구 발자국?',
    'animal_steps_song' => '동물처럼 쿵쿵',
    'feeling_cloud' => '마음 구름',
    'momo_faces' => '모모의 표정',
    'body_hello' => '몸으로 안녕',
    'hand_shapes' => '손으로 쓱쓱',
    'bus_stop' => '숲속 버스',
    'my_bus' => '나의 버스',
    'forest_weather' => '오늘의 날씨',
    _ => '비 온 뒤 꽃밭',
  };

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: phase == 2 || widget.isParentPreview,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && phase != 2) finish();
    },
    child: Scaffold(
      body: ForestBackground(
        lowStimulation: quiet,
        clearing: true,
        child: SafeArea(
          child: Column(
            children: [
              ForestHeader(
                title: shortTitle,
                preview: widget.isParentPreview,
                onExit: phase == 2 ? () => Navigator.of(context).pop() : finish,
                onReplay: widget.isParentPreview || audioFailed
                    ? null
                    : () => playAudio(
                        phase == 0
                            ? ['intro']
                            : phase == 2
                            ? ['outro', 'offscreen']
                            : ['prompt'],
                      ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        if (audioFailed)
                          const _Banner('음성을 재생할 수 없어 놀이를 마쳤어요. 보호자에게 알려 주세요.'),
                        if (phase == 0) _intro(context),
                        if (phase == 1) _interaction(context),
                        if (phase == 2) _ending(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _intro(BuildContext context) => Column(
    children: [
      const SizedBox(height: 24),
      ForestFloat(
        still: quiet,
        child: AvatarImage(
          avatar: widget.activity.avatar,
          size: 235,
          lowStimulation: quiet,
        ),
      ),
      const SizedBox(height: 20),
      if (widget.isParentPreview)
        Text(
          widget.activity.intro,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, color: forestInk),
        )
      else
        Semantics(
          label: widget.activity.intro,
          child: const ExcludeSemantics(
            child: Text(
              '같이 놀자!',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: forestInk,
              ),
            ),
          ),
        ),
      const SizedBox(height: 28),
      ForestAction(
        label: '놀이 시작',
        size: 104,
        leaf: true,
        quiet: quiet,
        caption: '톡!',
        icon: Icons.touch_app_rounded,
        onPressed: () {
          setState(() => phase = 1);
          playAudio(
            widget.activity.mode == PlayMode.move
                ? ['prompt', 'song']
                : ['prompt'],
          );
        },
      ),
    ],
  );

  Widget _interaction(BuildContext context) => Column(
    children: [
      if (widget.isParentPreview)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            widget.activity.prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: forestInk),
          ),
        ),
      Semantics(
        label: widget.activity.prompt,
        child: switch (widget.activity.mode) {
          PlayMode.touch => _touch(context),
          PlayMode.color => _color(context),
          PlayMode.move => _move(context),
        },
      ),
      const SizedBox(height: 24),
      ForestAction(
        label: '놀이 마치기',
        icon: Icons.spa_rounded,
        onPressed: finish,
        leaf: true,
        size: 70,
        quiet: quiet,
        caption: '쉬어요',
      ),
    ],
  );

  Widget _choicePicture(int index) {
    if (widget.activity.id == 'forest_weather') {
      return index == 0
          ? const ForestProp(ForestObject.sun, size: 67)
          : Icon(
              index == 1 ? Icons.water_drop_rounded : Icons.air_rounded,
              color: const Color(0xFF4B91A4),
              size: 53,
            );
    }
    if (widget.activity.id == 'momo_faces') {
      return AvatarImage(
        avatar: ['momo', 'momo_quiet', 'momo_upset'][index % 3],
        size: 75,
        interactive: false,
        lowStimulation: quiet,
      );
    }
    if (widget.activity.id == 'animal_tracks' && index == 2) {
      return const Icon(
        Icons.cruelty_free_rounded,
        size: 58,
        color: Color(0xFF93745B),
      );
    }
    if (widget.activity.id == 'bus_stop' ||
        widget.activity.id == 'animal_tracks') {
      return AvatarImage(
        avatar: widget.activity.id == 'bus_stop'
            ? ['momo', 'duri', 'nuri'][index % 3]
            : ['duri', 'momo', 'nuri'][index % 3],
        size: 76,
        interactive: false,
        lowStimulation: quiet,
      );
    }
    return const ForestProp(ForestObject.paw, size: 64);
  }

  Widget _touch(BuildContext context) => Column(
    children: [
      if (widget.activity.id == 'animal_tracks' ||
          widget.activity.id == 'bus_stop' ||
          widget.activity.id == 'forest_weather')
        _touchScene()
      else
        ForestFloat(
          still: quiet,
          child: AvatarImage(
            avatar: widget.activity.id == 'momo_faces'
                ? ['momo', 'momo_quiet', 'momo_upset'][selectedChoice ?? 0]
                : widget.activity.avatar,
            size: 215,
            lowStimulation: quiet,
          ),
        ),
      const SizedBox(height: 20),
      ForestProgress(
        count: visitedChoices.length,
        total: widget.activity.choices.length,
      ),
      const SizedBox(height: 20),
      LayoutBuilder(
        builder: (_, box) {
          final size = ((box.maxWidth - 24) / 3).clamp(80.0, 120.0);
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (
                var index = 0;
                index < widget.activity.choices.length;
                index++
              )
                ForestAction(
                  label: widget.activity.choices[index],
                  size: size,
                  quiet: quiet,
                  selected: selectedChoice == index,
                  child: _choicePicture(index),
                  onPressed: () {
                    setState(() {
                      selectedChoice = index;
                      visitedChoices.add(index);
                    });
                    playAudio(['choice_$index', 'reaction_$index']);
                  },
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      if (selectedChoice != null)
        Semantics(
          liveRegion: true,
          label: widget.activity.reactions[selectedChoice!],
          child: widget.isParentPreview
              ? Text(
                  widget.activity.reactions[selectedChoice!],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: forestInk),
                )
              : const ExcludeSemantics(
                  child: ForestProp(ForestObject.heart, size: 48),
                ),
        )
      else
        const Icon(Icons.touch_app_rounded, size: 35, color: forestInk),
    ],
  );

  Widget _touchScene() {
    final asset = switch (widget.activity.id) {
      'animal_tracks' => 'assets/images/forest_tracks.png',
      'bus_stop' => 'assets/images/forest_bus.png',
      'forest_weather' => switch (selectedChoice) {
        1 => 'assets/images/forest_weather_rain.png',
        2 => 'assets/images/forest_weather_wind.png',
        _ => 'assets/images/forest_weather.png',
      },
      _ => 'assets/images/forest_weather.png',
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: LayoutBuilder(
          builder: (context, bounds) {
            final width = bounds.maxWidth;
            final height = bounds.maxHeight;
            return Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: quiet
                      ? Duration.zero
                      : const Duration(milliseconds: 400),
                  child: Image.asset(
                    asset,
                    key: ValueKey(asset),
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                  ),
                ),
                if (widget.activity.id == 'bus_stop')
                  for (final index in visitedChoices)
                    Positioned(
                      left: width * (.275 + index * .12),
                      top: height * .38,
                      child: AvatarImage(
                        avatar: ['momo', 'duri', 'nuri'][index],
                        size: width * .075,
                        interactive: false,
                        lowStimulation: quiet,
                      ),
                    ),
                if (widget.activity.id == 'forest_weather' &&
                    selectedChoice != null)
                  Positioned(
                    right: width * .16,
                    top: height * .12,
                    child: AnimatedSwitcher(
                      duration: quiet
                          ? Duration.zero
                          : const Duration(milliseconds: 400),
                      child: Icon(
                        _iconFor(selectedChoice!),
                        key: ValueKey(selectedChoice),
                        color: const Color(0xFF446C7C),
                        size: width * .12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _iconFor(int index) {
    if (widget.activity.id == 'forest_weather') {
      return [
        Icons.wb_sunny_outlined,
        Icons.water_drop_outlined,
        Icons.air_rounded,
      ][index % 3];
    }
    if (widget.activity.id == 'bus_stop') {
      return [
        Icons.cruelty_free_outlined,
        Icons.pets_outlined,
        Icons.cloud_outlined,
      ][index % 3];
    }
    return [
      Icons.pets_outlined,
      Icons.flutter_dash_outlined,
      Icons.favorite_outline,
    ][index % 3];
  }

  Widget _move(BuildContext context) {
    final verses = widget.activity.verses;
    return Column(
      children: [
        ForestFloat(
          still: quiet,
          child: AvatarImage(
            avatar: widget.activity.avatar,
            size: 195,
            lowStimulation: quiet,
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          label: verses[math.min(step, verses.length - 1)],
          child: AnimatedSwitcher(
            duration: quiet ? Duration.zero : const Duration(milliseconds: 280),
            child: Icon(
              (widget.activity.id == 'animal_steps_song'
                  ? [
                      Icons.flutter_dash_rounded,
                      Icons.pets_rounded,
                      Icons.air_rounded,
                    ]
                  : [
                      Icons.waving_hand_rounded,
                      Icons.accessibility_new_rounded,
                      Icons.self_improvement_rounded,
                    ])[step % 3],
              key: ValueKey(step),
              size: 80,
              color: const Color(0xFF66946B),
            ),
          ),
        ),
        if (widget.isParentPreview)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              verses[math.min(step, verses.length - 1)],
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 20),
        ForestProgress(count: step + 1, total: verses.length),
        const SizedBox(height: 20),
        ForestAction(
          label: step < verses.length - 1 ? '다음 동작' : '동작 놀이 마치기',
          leaf: true,
          size: 88,
          quiet: quiet,
          icon: step < verses.length - 1
              ? Icons.front_hand_rounded
              : Icons.check_rounded,
          onPressed: step < verses.length - 1
              ? () => setState(() => step++)
              : finish,
        ),
      ],
    );
  }

  Widget _color(BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE4C38E),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFB58B59), width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0xFFAD8857), offset: Offset(0, 5)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: RepaintBoundary(
            key: drawingKey,
            child: AspectRatio(
              aspectRatio: 1.05,
              child: GestureDetector(
                onPanStart: saving
                    ? null
                    : (details) => _startStroke(details.localPosition),
                onPanUpdate: saving
                    ? null
                    : (details) => _continueStroke(details.localPosition),
                child: CustomPaint(
                  painter: _DrawingPainter(
                    strokes: strokes,
                    theme: widget.activity.id,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Wrap(
        spacing: 6,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (final entry in const [
            (Color(0xFFDB857D), '분홍'),
            (Color(0xFFE4BB5D), '노랑'),
            (Color(0xFF7C9F77), '초록'),
            (Color(0xFF7BA7B7), '파랑'),
            (Color(0xFF947BAF), '보라'),
            (Color(0xFF394D43), '진한 초록'),
          ])
            Semantics(
              button: true,
              selected: selectedColor == entry.$1,
              label: '${entry.$2} 그림 색 선택',
              child: GestureDetector(
                onTap: () => setState(() => selectedColor = entry.$1),
                child: Container(
                  width: 52,
                  height: 58,
                  decoration: BoxDecoration(
                    color: entry.$1,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                    border: Border.all(
                      color: selectedColor == entry.$1
                          ? forestCream
                          : Colors.white.withAlpha(140),
                      width: 4,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF9B9165), offset: Offset(0, 3)),
                    ],
                  ),
                  child: selectedColor == entry.$1
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 28,
                        )
                      : null,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 18),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ForestAction(
            label: '한 번 되돌리기',
            icon: Icons.undo_rounded,
            size: 64,
            onPressed: strokes.isEmpty || saving
                ? null
                : () => setState(() {
                    strokes.removeLast();
                    saved = false;
                  }),
          ),
          const SizedBox(width: 22),
          ForestAction(
            label: '깨끗이 지우기',
            icon: Icons.cleaning_services_rounded,
            size: 64,
            onPressed: strokes.isEmpty || saving
                ? null
                : () => setState(() {
                    strokes.clear();
                    saved = false;
                  }),
          ),
          const SizedBox(width: 22),
          ForestAction(
            label: saved ? '기기에 저장됨' : '그림 저장',
            icon: saved ? Icons.check_rounded : Icons.collections_rounded,
            size: 64,
            onPressed: saving ? null : saveDrawing,
          ),
        ],
      ),
      if (saveError != null)
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            saveError!,
            style: const TextStyle(color: Color(0xFF974B3D)),
          ),
        ),
    ],
  );

  void _startStroke(Offset point) => setState(() {
    saved = false;
    currentStroke = _Stroke(selectedColor, [point]);
    strokes.add(currentStroke!);
  });

  void _continueStroke(Offset point) {
    if (currentStroke == null) return;
    setState(() => currentStroke!.points.add(point));
  }

  Widget _ending(BuildContext context) => Column(
    children: [
      ForestCompletion(
        avatar: widget.activity.avatar,
        offscreen: widget.activity.offscreen,
        quiet: quiet,
        preview: widget.isParentPreview,
        saved: saved,
        onHome: () => Navigator.of(context).pop(),
      ),
      if (saveError != null)
        Text(saveError!, style: const TextStyle(color: Color(0xFF974B3D))),
    ],
  );
}

class _Stroke {
  _Stroke(this.color, this.points);
  final Color color;
  final List<Offset> points;
}

class _DrawingPainter extends CustomPainter {
  const _DrawingPainter({required this.strokes, required this.theme});
  final List<_Stroke> strokes;
  final String theme;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. White canvas background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFFFDF6),
    );

    // 2. Child coloring strokes
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first, 7, paint);
      } else {
        final path = Path()
          ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (final point in stroke.points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, paint);
      }
    }

    // 3. Clean line-art outline layered on TOP
    final outline = Paint()
      ..color = const Color(0xFF8AA888)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    final cx = size.width / 2;
    final cy = size.height / 2;
    _drawThemeOutline(canvas, size, outline, cx, cy);
  }

  void _drawThemeOutline(
    Canvas canvas,
    Size size,
    Paint outline,
    double cx,
    double cy,
  ) {
    if (theme == 'my_bus') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * .16,
            size.height * .28,
            size.width * .68,
            size.height * .46,
          ),
          const Radius.circular(24),
        ),
        outline,
      );
      for (final x in [.31, .52, .72]) {
        canvas.drawCircle(
          Offset(size.width * x, size.height * .78),
          17,
          outline,
        );
      }
      for (final x in [.25, .44, .63]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * x,
              size.height * .35,
              size.width * .13,
              size.height * .17,
            ),
            const Radius.circular(8),
          ),
          outline,
        );
      }
    } else if (theme == 'hand_shapes') {
      final path = Path()
        ..moveTo(cx - 55, cy + 75)
        ..lineTo(cx - 65, cy - 8)
        ..quadraticBezierTo(cx - 65, cy - 40, cx - 43, cy - 15)
        ..lineTo(cx - 37, cy - 82)
        ..quadraticBezierTo(cx - 33, cy - 105, cx - 20, cy - 83)
        ..lineTo(cx - 11, cy - 20)
        ..lineTo(cx - 6, cy - 100)
        ..quadraticBezierTo(cx + 2, cy - 119, cx + 10, cy - 98)
        ..lineTo(cx + 12, cy - 18)
        ..lineTo(cx + 25, cy - 81)
        ..quadraticBezierTo(cx + 37, cy - 99, cx + 42, cy - 75)
        ..lineTo(cx + 32, cy + 1)
        ..lineTo(cx + 55, cy - 37)
        ..quadraticBezierTo(cx + 73, cy - 50, cx + 67, cy - 25)
        ..lineTo(cx + 43, cy + 75)
        ..close();
      canvas.drawPath(path, outline);
    } else if (theme == 'feeling_cloud') {
      final left = size.width * .19;
      final right = size.width * .81;
      final top = size.height * .29;
      final bottom = size.height * .69;
      final cloud = Path()
        ..moveTo(left + 18, bottom)
        ..cubicTo(
          left - 28,
          bottom - 4,
          left - 24,
          top + 48,
          left + 28,
          top + 45,
        )
        ..cubicTo(left + 34, top + 5, cx - 17, top - 15, cx + 9, top + 26)
        ..cubicTo(
          right - 31,
          top - 5,
          right + 16,
          top + 24,
          right - 3,
          top + 66,
        )
        ..cubicTo(
          right + 38,
          bottom - 8,
          right + 11,
          bottom + 15,
          right - 29,
          bottom,
        )
        ..close();
      canvas.drawPath(cloud, outline);
    } else {
      canvas.drawLine(
        Offset(size.width * .12, size.height * .77),
        Offset(size.width * .88, size.height * .77),
        outline,
      );
      for (final x in [.24, .5, .76]) {
        final stem = size.width * x;
        canvas.drawLine(
          Offset(stem, size.height * .75),
          Offset(stem, size.height * .40),
          outline,
        );
        final center = Offset(stem, size.height * .36);
        for (var petal = 0; petal < 5; petal++) {
          final angle = petal * 2 * math.pi / 5;
          canvas.drawCircle(
            center + Offset(math.cos(angle) * 17, math.sin(angle) * 17),
            10,
            outline,
          );
        }
        canvas.drawCircle(center, 7, outline);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}

class _Banner extends StatelessWidget {
  const _Banner(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFFFFF1D8),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}
