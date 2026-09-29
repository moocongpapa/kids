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
import '../widgets/jelly_button.dart';
import '../widgets/touch_sparkles.dart';

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

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    return PopScope(
      canPop: phase == 2 || widget.isParentPreview,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && phase != 2) finish();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(activity.title),
          actions: [
            if (widget.isParentPreview)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(child: Text('보호자 미리보기')),
              ),
          ],
        ),
        body: SafeArea(
          child: TouchSparkles(
            lowStimulation: widget.profile.lowStimulation,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    if (widget.isParentPreview)
                      const _Banner(
                        '음성·노래 파일과 사람 검수 전의 조작 시제품입니다. 아이 혼자 사용하지 마세요.',
                      ),
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
        ),
      ),
    );
  }

  Widget _intro(BuildContext context) => Column(
    children: [
      AvatarImage(avatar: widget.activity.avatar, size: 210),
      const SizedBox(height: 14),
      Text(
        widget.activity.intro,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 30),
      FilledButton.icon(
        onPressed: () {
          setState(() => phase = 1);
          playAudio(
            widget.activity.mode == PlayMode.move
                ? ['prompt', 'song']
                : ['prompt'],
          );
        },
        icon: const Icon(Icons.touch_app_rounded),
        label: const Text('놀이 시작'),
      ),
      const SizedBox(height: 12),
      TextButton(onPressed: finish, child: const Text('지금 마치기')),
    ],
  );

  Widget _interaction(BuildContext context) => Column(
    children: [
      if (widget.activity.id != 'animal_tracks' &&
          widget.activity.id != 'bus_stop' &&
          widget.activity.id != 'forest_weather') ...[
        AnimatedScale(
          scale: selectedChoice != null && !widget.profile.lowStimulation
              ? 1.05
              : 1,
          duration: const Duration(milliseconds: 500),
          child: widget.activity.id == 'momo_faces'
              ? AnimatedSwitcher(
                  duration: widget.profile.lowStimulation
                      ? Duration.zero
                      : const Duration(milliseconds: 400),
                  child: Image.asset(
                    selectedChoice == 1
                        ? 'assets/images/momo_quiet.png'
                        : selectedChoice == 2
                        ? 'assets/images/momo_upset.png'
                        : 'assets/images/momo.png',
                    key: ValueKey(selectedChoice),
                    width: 145,
                    height: 145,
                    fit: BoxFit.contain,
                    semanticLabel: selectedChoice == 1
                        ? '조용한 표정의 모모'
                        : selectedChoice == 2
                        ? '속상한 표정의 모모'
                        : '반가운 표정의 모모',
                  ),
                )
              : AvatarImage(avatar: widget.activity.avatar, size: 145),
        ),
        const SizedBox(height: 12),
      ],
      Text(
        widget.activity.prompt,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 18),
      switch (widget.activity.mode) {
        PlayMode.touch => _touch(context),
        PlayMode.color => _color(context),
        PlayMode.move => _move(context),
      },
      const SizedBox(height: 22),
      OutlinedButton.icon(
        onPressed: finish,
        icon: const Icon(Icons.stop_circle_outlined),
        label: const Text('놀이 마치기'),
      ),
    ],
  );

  Widget _touch(BuildContext context) {
    final activity = widget.activity;
    final narrow = MediaQuery.sizeOf(context).width < 480;
    return Column(
      children: [
        if (activity.id == 'animal_tracks' ||
            activity.id == 'bus_stop' ||
            activity.id == 'forest_weather') ...[
          _touchScene(),
          const SizedBox(height: 16),
        ],
        Wrap(
          spacing: narrow ? 8 : 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (var index = 0; index < activity.choices.length; index++)
              SizedBox(
                width: narrow ? 104 : 190,
                height: narrow ? 96 : 120,
                child: JellyButton(
                  isSelected: selectedChoice == index,
                  lowStimulation: widget.profile.lowStimulation,
                  semanticsLabel: activity.choices[index],
                  padding: narrow
                      ? const EdgeInsets.symmetric(horizontal: 6, vertical: 6)
                      : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  onPressed: () {
                    setState(() {
                      selectedChoice = index;
                      visitedChoices.add(index);
                    });
                    playAudio(['choice_$index', 'reaction_$index']);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconFor(index),
                        size: narrow ? 26 : 34,
                        color: selectedChoice == index
                            ? const Color(0xFF235338)
                            : const Color(0xFF3F634A),
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: Text(
                          activity.choices[index],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: narrow ? 12 : 15,
                            height: 1.2,
                            fontWeight: selectedChoice == index
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: selectedChoice == index
                                ? const Color(0xFF1B3827)
                                : const Color(0xFF2E4034),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (selectedChoice != null)
          Semantics(
            liveRegion: true,
            child: Card(
              color: const Color(0xFFE9F2E2),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  activity.reactions[selectedChoice!],
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ),
        if (visitedChoices.length == activity.choices.length) ...[
          const SizedBox(height: 12),
          FilledButton(onPressed: finish, child: const Text('이야기 마치기')),
        ],
      ],
    );
  }

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
                  duration: widget.profile.lowStimulation
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
                      ),
                    ),
                if (widget.activity.id == 'forest_weather' &&
                    selectedChoice != null)
                  Positioned(
                    right: width * .16,
                    top: height * .12,
                    child: AnimatedSwitcher(
                      duration: widget.profile.lowStimulation
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
        const _Banner('현재 실제 노래는 연결되지 않았습니다. 보호자가 가사를 읽으며 동작을 확인하는 미리보기입니다.'),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFFEAF2FA),
          child: SizedBox(
            width: double.infinity,
            height: 150,
            child: Center(
              child: AnimatedSwitcher(
                duration: widget.profile.lowStimulation
                    ? Duration.zero
                    : const Duration(milliseconds: 350),
                child: Text(
                  verses[math.min(step, verses.length - 1)],
                  key: ValueKey(step),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: step < verses.length - 1
              ? () => setState(() => step++)
              : finish,
          icon: const Icon(Icons.pan_tool_alt_outlined),
          label: Text(step < verses.length - 1 ? '다음 동작' : '쉬는 시간'),
        ),
        const SizedBox(height: 8),
        const Text('따라 하지 않아도 괜찮아요. 마이크와 카메라는 쓰지 않아요.'),
      ],
    );
  }

  Widget _color(BuildContext context) => Column(
    children: [
      RepaintBoundary(
        key: drawingKey,
        child: AspectRatio(
          aspectRatio: 1.25,
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
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children:
            const [
                  (Color(0xFFDB857D), '분홍'),
                  (Color(0xFFE4BB5D), '노랑'),
                  (Color(0xFF7C9F77), '초록'),
                  (Color(0xFF7BA7B7), '파랑'),
                  (Color(0xFF947BAF), '보라'),
                  (Color(0xFF394D43), '진한 초록'),
                ]
                .map(
                  (entry) {
                    final isSelected = selectedColor == entry.$1;
                    return InkWell(
                      onTap: () => setState(() => selectedColor = entry.$1),
                      borderRadius: BorderRadius.circular(26),
                      child: Semantics(
                        button: true,
                        selected: isSelected,
                        label: '${entry.$2} 그림 색 선택',
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 50 : 42,
                          height: isSelected ? 50 : 42,
                          decoration: BoxDecoration(
                            color: entry.$1,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF24372D)
                                  : Colors.white,
                              width: isSelected ? 4 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: entry.$1.withAlpha(isSelected ? 100 : 40),
                                blurRadius: isSelected ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                )
                .toList(),
      ),
      const SizedBox(height: 14),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: strokes.isEmpty
                ? null
                : () => setState(() {
                    strokes.removeLast();
                    saved = false;
                  }),
            icon: const Icon(Icons.undo_rounded),
            label: const Text('한 번 되돌리기'),
          ),
          OutlinedButton.icon(
            onPressed: strokes.isEmpty
                ? null
                : () => setState(() {
                    strokes.clear();
                    saved = false;
                  }),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('깨끗이 지우기'),
          ),
          OutlinedButton.icon(
            onPressed: saving ? null : saveDrawing,
            icon: const Icon(Icons.save_alt_rounded),
            label: Text(saved ? '기기에 저장됨' : '기기에 저장'),
          ),
        ],
      ),
      if (saveError != null)
        Text(saveError!, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 8),
      const Text('앱은 그림을 서버로 올리지 않아요. 기기 백업은 운영체제 설정을 확인하세요.'),
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
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4D6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFD166), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('💮', style: TextStyle(fontSize: 18)),
            SizedBox(width: 6),
            Text(
              '숲 탐험 도장 쾅! 참 잘했어요',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF8A5A00),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      AvatarImage(avatar: widget.activity.avatar, size: 185),
      const SizedBox(height: 12),
      Text(
        widget.activity.outro,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 20),
      Card(
        color: const Color(0xFFE9F2E2),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFCCE2C3), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.nature_people_outlined,
                size: 40,
                color: Color(0xFF386641),
              ),
              const SizedBox(height: 10),
              const Text(
                '이제 화면 밖에서',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Color(0xFF1E3F27),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.activity.offscreen,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      if (saveError != null)
        Text(saveError!, style: const TextStyle(color: Colors.red)),
      if (widget.activity.mode == PlayMode.color && saved)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            '그림은 이 기기에 소중히 저장됐어요. 🎨',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF3D6B4E),
            ),
          ),
        ),
      FilledButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        icon: const Icon(Icons.home_outlined),
        label: const Text(
          '숲으로 돌아가기',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        '다음 놀이는 자동으로 시작하지 않아요.',
        style: TextStyle(color: Color(0xFF6B756B)),
      ),
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
