import '../utils/sound_effects.dart';
import '../utils/narration_player.dart';
import '../utils/play_session.dart';
import '../utils/play_checkpoint.dart';
import '../utils/audio_policy.dart';

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../models/activity.dart';
import '../models/child_profile.dart';
import '../state/app_state.dart';
import '../utils/forest_audio.dart';
import '../widgets/avatar_image.dart';
import '../widgets/forest_background.dart';
import '../widgets/forest_game_ui.dart';
import '../widgets/classic_forest_scene.dart';
import '../widgets/forest_art_studio.dart';
import '../widgets/forest_play_stage.dart';

/// One finite activity. Drafts may be opened only through the parent preview.
class PlayScreen extends StatefulWidget {
  const PlayScreen({
    required this.activity,
    required this.appState,
    required this.profile,
    required this.isParentPreview,
    this.playAsset,
    this.restoreSaved = false,
    super.key,
  });

  final Activity activity;
  final AppState appState;
  final ChildProfile profile;
  final bool isParentPreview;

  /// Allows the full narrated flow to be verified without a device audio plugin.
  final Future<void> Function(String path)? playAsset;
  final bool restoreSaved;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late final PlaySession session;
  late final PlayCheckpoint checkpoint;
  late final NarrationPlayer narration;
  final GlobalKey drawingKey = GlobalKey();
  final sceneScroll = ScrollController();
  final List<ArtMark> strokes = [];
  int phase = 0; // 0: introduction, 1: interaction, 2: finite ending.
  int step = 0;
  int reaction = 0;
  int? selectedChoice;
  final Set<int> visitedChoices = {};
  bool saved = false;
  bool saving = false;
  Completer<void>? saveCompletion;
  String? saveError;
  bool showHelp = false;
  int get stage => widget.profile.stageFor(widget.activity.id);
  bool finishing = false;
  bool audioFailed = false;
  int audioRequest = 0;

  @override
  void initState() {
    super.initState();
    narration = NarrationPlayer(playAsset: widget.playAsset);
    AudioPolicy.instance.configure(widget.profile);
    final savedWork = widget.isParentPreview && !widget.restoreSaved
        ? null
        : widget.appState.workFor(widget.profile.id, widget.activity.id);
    if (savedWork != null) {
      strokes.addAll(
        (savedWork['marks'] as List? ?? []).map(
          (m) => ArtMark.fromJson(Map<String, dynamic>.from(m)),
        ),
      );
      if (savedWork['complete'] != true) {
        step = (savedWork['step'] as int? ?? 0).clamp(
          0,
          math.max(0, widget.activity.verses.length - 1),
        );
        selectedChoice = savedWork['selected'] as int?;
        visitedChoices.addAll(
          List<int>.from(savedWork['visited'] as List? ?? []),
        );
      }
    }
    checkpoint = PlayCheckpoint(
      widget.appState,
      widget.profile.id,
      widget.activity.id,
      () => {
        'marks': strokes.map((m) => m.toJson()).toList(),
        'step': step,
        'selected': selectedChoice,
        'visited': visitedChoices.toList(),
        'complete': phase == 2,
      },
      preview: widget.isParentPreview,
      onError: () => session.reportSaveError(),
    );
    session = PlaySession(
      limitSeconds: widget.isParentPreview
          ? widget.activity.minutes * 60
          : math.min(
              widget.activity.minutes * 60,
              widget.appState.secondsRemaining(
                widget.profile.id,
                widget.profile.dailyLimitMinutes,
              ),
            ),
      onExpire: finish,
      onCheckpoint: checkpoint.checkpoint,
      onPause: () {
        checkpoint.event('interruptions');
        audioRequest++;
        narration.stop();
      },
      onResume: () {
        if (phase < 2) playAudio(phase == 0 ? ['intro'] : ['prompt']);
      },
    );
    if (!widget.isParentPreview &&
        (widget.profile.caregiverMode ||
            !widget.activity.supportsAge(widget.profile.ageMonths) ||
            !widget.activity.isFullyApproved)) {
      phase = 2;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      session.start();
      await ForestAudio.instance.pauseBgm();
      if (mounted && phase != 2) playAudio(['intro']);
    });
  }

  @override
  void dispose() {
    SoundEffects.instance.stopAll();
    if (!widget.isParentPreview) {
      ForestAudio.instance.startBgm(
        enabled: widget.profile.musicOn && !widget.profile.caregiverMode,
      );
    }
    session.dispose();
    checkpoint.dispose();
    narration.dispose();
    sceneScroll.dispose();
    super.dispose();
  }

  Future<void> playAudio(List<String> lineIds) async {
    if (audioFailed || !AudioPolicy.instance.canVoice) return;
    final request = ++audioRequest;
    try {
      final paths = lineIds.map((id) {
        final path = widget.activity.audioFiles[id];
        if (path == null) throw StateError('필수 음성이 없습니다: $id');
        return path;
      }).toList();
      await narration.speak(paths);
    } catch (error) {
      if (!mounted || request != audioRequest) return;
      assert(() {
        debugPrint('PlayScreen audio error: $error');
        return true;
      }());
      setState(() => audioFailed = true);
      await narration.stop();
    }
  }

  Future<void> finish() async {
    if (phase == 2 || finishing) return;
    finishing = true;
    SoundEffects.instance.stopAll();
    session.finish();
    if (widget.activity.mode == PlayMode.color &&
        strokes.isNotEmpty &&
        !saved) {
      await saveDrawing();
    }
    if (!mounted) return;

    if (sceneScroll.hasClients) sceneScroll.jumpTo(0);
    setState(() => phase = 2);
    if (!audioFailed) playAudio(['outro', 'offscreen']);
    await session.checkpoint();
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
  Widget build(BuildContext context) => PlaySessionView(
    session: session,
    child: PopScope(
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
                  onExit: phase == 2
                      ? () => Navigator.of(context).pop()
                      : finish,
                  onReplay: () {
                    if (audioFailed) setState(() => audioFailed = false);
                    playAudio(
                      phase == 0
                          ? ['intro']
                          : phase == 2
                          ? ['outro', 'offscreen']
                          : ['prompt'],
                    );
                  },
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: ListView(
                        controller: sceneScroll,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          if (audioFailed)
                            _Banner(
                              widget.isParentPreview
                                  ? '음성을 재생하지 못했어요. 위의 소리 버튼으로 다시 들어 주세요.'
                                  : '안내 소리를 다시 들어 주세요. 그림을 보며 계속 놀 수도 있어요.',
                            ),
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
    ),
  );

  Widget _intro(BuildContext context) => Column(
    children: [
      const SizedBox(height: 24),
      ForestPlayStage(
        height: 250,
        quiet: quiet,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 20,
              child: AvatarImage(
                avatar: widget.activity.avatar,
                size: 185,
                lowStimulation: quiet,
                showBlush: !quiet,
              ),
            ),
            Positioned(
              left: 2,
              bottom: 12,
              child: ForestProp(
                widget.activity.mode == PlayMode.color
                    ? ForestObject.paint
                    : ForestObject.bush,
                size: 90,
              ),
            ),
            Positioned(
              right: 4,
              top: 12,
              child: ForestProp(
                widget.activity.mode == PlayMode.move
                    ? ForestObject.music
                    : ForestObject.sun,
                size: 80,
              ),
            ),
          ],
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
          if (sceneScroll.hasClients) sceneScroll.jumpTo(0);
          setState(() => phase = 1);
          session.start();
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

  Widget _touch(BuildContext context) => Column(
    children: [
      ClassicForestScene(
        id: widget.activity.id,
        reaction: reaction,
        choices: widget.activity.choices.take(stage == 0 ? 2 : 3).toList(),
        selected: selectedChoice,
        visited: visitedChoices,
        quiet: quiet,
        onChoose: (index) {
          setState(() {
            reaction++;
            selectedChoice = index;
            visitedChoices.add(index);
          });
          checkpoint.event('actions');
          checkpoint.changed();
          SoundEffects.instance.pop();
          playAudio(['choice_$index', 'reaction_$index']);
        },
      ),
      if (selectedChoice != null && widget.isParentPreview)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            widget.activity.reactions[selectedChoice!],
            textAlign: TextAlign.center,
          ),
        ),
    ],
  );

  Widget _move(BuildContext context) => Column(
    children: [
      ForestMovementScene(id: widget.activity.id, step: step, quiet: quiet),
      if (widget.isParentPreview)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            widget.activity.verses[step],
            textAlign: TextAlign.center,
          ),
        ),
      ForestProgress(count: step + 1, total: widget.activity.verses.length),
      const SizedBox(height: 20),
      ForestAction(
        label: step < widget.activity.verses.length - 1 ? '다음 동작' : '동작 놀이 마치기',
        leaf: true,
        size: 88,
        quiet: quiet,
        icon: step < widget.activity.verses.length - 1
            ? Icons.front_hand_rounded
            : Icons.check_rounded,
        onPressed: step < widget.activity.verses.length - 1
            ? () {
                setState(() => step++);
                checkpoint.changed();
              }
            : finish,
      ),
    ],
  );

  Widget _color(BuildContext context) => Column(
    children: [
      ForestArtStudio(
        theme: widget.activity.id,
        marks: strokes,
        quiet: quiet,
        captureKey: drawingKey,
        simple: stage == 0,
        locked: saving,
        onChanged: () {
          checkpoint.metrics.putIfAbsent(
            'firstActionSeconds',
            () => session.seconds,
          );
          setState(() => saved = false);
          checkpoint.changed();
        },
      ),
      const SizedBox(height: 14),
      ForestAction(
        label: saved ? '기기에 저장됨' : '그림 저장',
        icon: saved ? Icons.check_rounded : Icons.collections_rounded,
        size: 68,
        quiet: quiet,
        onPressed: saving ? null : saveDrawing,
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
