import '../../utils/narration_player.dart';
import '../../utils/forest_orientation.dart';
import '../../widgets/forest_landscape.dart';
import '../../widgets/journey_detective_scene.dart';
import '../../game/build_experiment.dart';
import '../../utils/play_session.dart';
import '../../utils/play_checkpoint.dart';
import '../../utils/audio_policy.dart';
import '../../data/journey_recommendation.dart';
import '../../widgets/journey_reveal_scene.dart';
import '../../widgets/journey_build_board.dart';
import '../../widgets/journey_story_scene.dart';
import '../../widgets/journey_sort_scene.dart';
import '../../widgets/journey_rhythm_scene.dart';
import '../../widgets/forest_play_stage.dart';
import '../../widgets/forest_art_studio.dart';
import '../../widgets/journey_picnic_scene.dart';
import '../../widgets/journey_garden_scene.dart';
import '../../widgets/cute_game_effects.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/age_journey.dart';
import '../../models/child_profile.dart';
import '../../state/app_state.dart';
import '../../utils/forest_audio.dart';
import '../../utils/sound_effects.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/forest_background.dart';
import '../../widgets/forest_game_ui.dart';
import 'journey_common.dart';

class JourneyPlayScreen extends StatefulWidget {
  const JourneyPlayScreen({
    required this.journey,
    required this.appState,
    required this.profile,
    this.preview = false,
    this.playAsset,
    this.restoreSaved = false,
    this.randomSeed,
    super.key,
  });
  final AgeJourney journey;
  final AppState appState;
  final ChildProfile profile;
  final bool preview;
  final Future<void> Function(String path)? playAsset;
  final bool restoreSaved;
  final int? randomSeed;
  @override
  State<JourneyPlayScreen> createState() => _JourneyPlayScreenState();
}

class _JourneyPlayScreenState extends State<JourneyPlayScreen> {
  late final NarrationPlayer narration;
  late final PlaySession session;
  late final PlayCheckpoint checkpoint;
  final sceneScroll = ScrollController();

  int step = 0,
      selected = 0,
      action = 0,
      token = 0,
      activeNote = -1,
      reaction = 0;
  bool firstNarrationRequested = false;
  int voiceRequest = 0;
  bool ready = false,
      ended = false,
      started = false,
      audioFailed = false,
      busy = false;
  int sequenceSeed = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
  bool helpRequested = false;
  BuildTrial? trial;
  BuildResult? trialResult;
  final List<Map<String, dynamic>> trials = [];
  final List<String> results = [];
  final Map<int, int> slots = {};
  final List<ArtMark> strokes = [];
  AgeJourney get a => widget.journey;
  int get stage => widget.profile.stageFor(a.id);
  bool get quiet =>
      widget.profile.lowStimulation || MediaQuery.disableAnimationsOf(context);
  bool get sound => AudioPolicy.instance.canEffects;
  bool get allowed =>
      !a.isCaregiver &&
      journeyEligible(a, widget.profile) &&
      (widget.preview || widget.appState.journeyApproved(a));
  int get sceneCount => stage == 0 ? 1 : 3;
  int get slotCount => stage == 0
      ? 2
      : a.minAge >= 72
      ? 4
      : 3;
  List<String> get options => a.choices[step]
      .take(
        stage == 0
            ? 1
            : stage == 1
            ? 2
            : 3,
      )
      .toList();
  @override
  void initState() {
    super.initState();
    narration = NarrationPlayer(playAsset: widget.playAsset);
    AudioPolicy.instance.configure(widget.profile);
    sequenceSeed = widget.randomSeed ?? sequenceSeed;
    final saved = widget.preview && !widget.restoreSaved
        ? null
        : widget.appState.workFor(widget.profile.id, a.id);
    if (saved != null && saved['review'] == a.reviewKey) {
      sequenceSeed = saved['sequenceSeed'] as int? ?? sequenceSeed;
      trials.addAll(
        (saved['trials'] as List? ?? []).map(
          (t) => Map<String, dynamic>.from(t),
        ),
      );
      strokes.addAll(
        (saved['marks'] as List? ?? []).map(
          (m) => ArtMark.fromJson(Map<String, dynamic>.from(m)),
        ),
      );
      slots.addAll(
        (saved['slots'] as Map? ?? {}).map(
          (k, v) => MapEntry(int.parse(k), v as int),
        ),
      );
      if (saved['complete'] != true &&
          (saved['stage'] == null || saved['stage'] == stage)) {
        step = (saved['step'] as int? ?? 0).clamp(0, sceneCount - 1);
        selected = saved['selected'] as int? ?? 0;
        action = saved['action'] as int? ?? 0;
        ready = saved['ready'] == true;
        results.addAll(List<String>.from(saved['results'] as List? ?? []));
      }
    }
    selected = selected.clamp(
      0,
      a.mechanic == 'build' ? a.symbols.length - 1 : options.length - 1,
    );
    slots.removeWhere(
      (k, v) =>
          k < 0 ||
          k >= slotCount ||
          v < 0 ||
          v > (a.mechanic == 'rhythm' ? 3 : 2),
    );
    checkpoint = PlayCheckpoint(
      widget.appState,
      widget.profile.id,
      a.id,
      () => {
        'sequenceSeed': sequenceSeed,
        'stage': stage,
        'trials': trials,
        'review': a.reviewKey,
        'step': step,
        'selected': selected,
        'action': action,
        'ready': ready,
        'results': results,
        'complete': ended,
        'slots': slots.map((k, v) => MapEntry('$k', v)),
        'marks': strokes.map((m) => m.toJson()).toList(),
      },
      preview: widget.preview,
      onError: () => session.reportSaveError(),
    );
    session = PlaySession(
      limitSeconds: widget.preview
          ? a.minutes * 60
          : math.min(
              a.minutes * 60,
              widget.appState.secondsRemaining(
                widget.profile.id,
                widget.profile.dailyLimitMinutes,
              ),
            ),
      onExpire: finish,
      onCheckpoint: checkpoint.checkpoint,
      onPause: () {
        checkpoint.event('interruptions');
        token++;
        voiceRequest++;
        narration.stop();
        if (mounted) {
          setState(() {
            if (a.mechanic != 'build') busy = false;
            activeNote = -1;
          });
        }
      },
      onResume: () {
        if (!ended) narrate();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && allowed) {
        session.start();
        announceFirstScene();
      }
    });
  }

  Future<void> announceFirstScene() async {
    await ForestAudio.instance.pauseBgm();
    if (!mounted || ended || firstNarrationRequested) return;
    firstNarrationRequested = true;
    narrate();
  }

  Future<void> narrate() async {
    if (!AudioPolicy.instance.canVoice) return;
    final path = a.audio['step_$step'];
    final mine = ++voiceRequest;
    if (path == null) {
      if (!widget.preview && mounted) setState(() => audioFailed = true);
      return;
    }
    try {
      await narration.speak([path]);
      if (mounted && mine == voiceRequest && audioFailed) {
        setState(() => audioFailed = false);
      }
    } catch (error) {
      assert(() {
        debugPrint('Journey narration error: $error');
        return true;
      }());
      if (mounted && mine == voiceRequest) setState(() => audioFailed = true);
    }
  }

  void start() {
    if (!allowed) return;
    final remaining = widget.appState.secondsRemaining(
      widget.profile.id,
      widget.profile.dailyLimitMinutes,
    );
    if (!widget.preview && remaining <= 0) {
      setState(() => ended = true);
      return;
    }
    if (sceneScroll.hasClients) sceneScroll.jumpTo(0);
    setState(() => started = true);
    session.start();
    if (!firstNarrationRequested) narrate();
  }

  void finish() {
    if (ended) return;
    if (sceneScroll.hasClients) sceneScroll.jumpTo(0);
    token++;
    voiceRequest++;
    narration.stop();
    SoundEffects.instance.stopAll();
    if (!quiet) {
      GameFeedback.celebration(lowStimulation: quiet);
      SoundEffects.instance.tada();
    }
    setState(() => ended = true);
    session.finish();
  }

  void next() {
    if (!ready) return;
    if (sceneScroll.hasClients) sceneScroll.jumpTo(0);
    if (step + 1 >= sceneCount) {
      finish();
      return;
    }
    token++;
    voiceRequest++;
    narration.stop();
    setState(() {
      step++;
      trialResult = null;
      helpRequested = false;
      ready = false;
      selected = 0;
      action = 0;
      busy = false;
      if (a.mechanic != 'build' && a.mechanic != 'rhythm') slots.clear();
      activeNote = -1;
    });
    checkpoint.changed();
    narrate();
  }

  Future<void> melody() async {
    if (busy) return;
    final mine = token;
    setState(() => busy = true);
    await narration.stop();
    for (var i = 0; i < slotCount; i++) {
      if (!mounted || ended || token != mine) break;
      setState(() => activeNote = i);
      final note = slots[i];
      if (sound && note != null && note != 3) {
        unawaited(SoundEffects.instance.playNote(note * 2));
      }
      await Future<void>.delayed(const Duration(milliseconds: 650));
    }
    if (mounted && token == mine) {
      setState(() {
        activeNote = -1;
        busy = false;
      });
    }
  }

  @override
  void dispose() {
    SoundEffects.instance.stopAll();
    token++;
    voiceRequest++;
    checkpoint.dispose();
    session.dispose();
    narration.dispose();
    sceneScroll.dispose();
    if (!widget.preview) {
      ForestAudio.instance.startBgm(enabled: widget.profile.musicOn);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!allowed) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('보호자 공방에서 월령과 검수를 먼저 확인해 주세요.')),
      );
    }
    return ForestOrientationScope(
      child: PlaySessionView(
        session: session,
        child: PopScope(
          canPop: ended || !started,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) finish();
          },
          child: forestIsWide(context)
              ? _landscape()
              : Scaffold(
                  body: ForestBackground(
                    lowStimulation: quiet,
                    child: SafeArea(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ForestAction(
                                  label: '놀이 닫기',
                                  icon: Icons.close_rounded,
                                  onPressed: () {
                                    if (started && !ended) {
                                      finish();
                                    } else {
                                      Navigator.pop(context);
                                    }
                                  },
                                  size: 58,
                                  quiet: quiet,
                                ),
                                const Spacer(),
                                if (widget.preview) const Text('보호자 미리보기'),
                                const Spacer(),
                                if (!ended)
                                  ForestAction(
                                    label: '안내 다시 듣기',
                                    icon: Icons.volume_up_rounded,
                                    onPressed: narrate,
                                    size: 58,
                                    quiet: quiet,
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, box) => SingleChildScrollView(
                                controller: sceneScroll,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: box.maxHeight,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      24,
                                    ),
                                    child: ended
                                        ? _ending()
                                        : !started
                                        ? _intro()
                                        : _play(),
                                  ),
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
      ),
    );
  }

  Widget _landscape() => ForestLandscapeFrame(
    quiet: quiet,
    preview: widget.preview,
    onExit: () {
      if (started && !ended) {
        finish();
      } else {
        Navigator.pop(context);
      }
    },
    onReplay: narrate,
    child: ended
        ? _ending()
        : !started
        ? _intro()
        : _playLandscape(),
  );
  Widget _playLandscape() => ForestSceneComposition(
    controlsWidth: 100,
    children: [
      if (audioFailed && !widget.preview)
        Center(
          child: ForestAction(
            label: '소리 재시도',
            icon: Icons.refresh_rounded,
            onPressed: narrate,
            size: 90,
          ),
        )
      else
        switch (a.mechanic) {
          'reveal' => _reveal(),
          'sort' => _sort(),
          'build' => _build(),
          'rhythm' => _rhythm(),
          'draw' => _draw(),
          _ => _story(),
        },
      ForestProgress(count: step + 1, total: sceneCount),
      if (widget.preview) Text(a.steps[step], textAlign: TextAlign.center),
      if (!ready && !busy)
        ForestAction(
          label: '도움 그림 보기',
          icon: Icons.touch_app_rounded,
          size: 72,
          quiet: quiet,
          onPressed: () => setState(() => helpRequested = !helpRequested),
        ),
      if (ready && (!audioFailed || widget.preview))
        ForestAction(
          label: step + 1 >= sceneCount ? '놀이 마치기' : '다음 장면',
          icon: step + 1 >= sceneCount
              ? Icons.check_rounded
              : Icons.spa_rounded,
          onPressed: next,
          size: 86,
          leaf: true,
          quiet: quiet,
        ),
    ],
  );

  Widget _intro() => ForestSceneComposition(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (a.id == 'age_48_01')
        const JourneyPicnicScene(step: 0, gift: null, quiet: true)
      else if (a.id == 'age_24_01' || a.id == 'age_24_06')
        IgnorePointer(
          child: JourneyGardenScene(
            weather: a.id == 'age_24_06',
            step: 0,
            revealed: true,
            quiet: true,
            onTap: () {},
          ),
        )
      else
        ForestPlayStage(
          height: 235,
          river: a.mechanic == 'build',
          quiet: quiet,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: 29,
                child: AvatarImage(
                  avatar: a.avatar,
                  size: 136,
                  lowStimulation: quiet,
                  showBlush: !quiet,
                ),
              ),
              Positioned(
                left: 7,
                bottom: 14,
                child: ForestProp(journeyProp(a.symbols.first), size: 98),
              ),
              Positioned(
                right: 7,
                top: 18,
                child: ForestProp(journeyProp(a.symbols.last), size: 84),
              ),
            ],
          ),
        ),
      const SizedBox(height: 20),
      ForestSign(a.title),
      const SizedBox(height: 20),
      if (widget.preview)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            '${journeyStages[stage]} · ${a.variants[stage]}',
            textAlign: TextAlign.center,
          ),
        ),
      if (audioFailed)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            widget.preview
                ? '음성을 재생하지 못했어요. 소리 버튼으로 다시 들어 주세요.'
                : '안내 소리를 다시 들어 주세요.',
            textAlign: TextAlign.center,
          ),
        ),
      ForestAction(
        label: audioFailed && !widget.preview ? '소리 재시도' : '놀이 시작',
        icon: audioFailed && !widget.preview
            ? Icons.refresh_rounded
            : Icons.play_arrow_rounded,
        onPressed: audioFailed && !widget.preview ? narrate : start,
        size: 96,
        leaf: true,
        quiet: quiet,
      ),
    ],
  );
  Widget _ending() {
    final viewport = ForestSceneViewport.of(context);
    if (forestIsWide(context)) {
      return Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: AvatarImage(
                      avatar: a.avatar,
                      size: 140,
                      lowStimulation: true,
                      showBlush: true,
                    ),
                  ),
                ),
                if (results.isNotEmpty)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: results
                        .take(6)
                        .map((s) => ForestProp(journeyProp(s), size: 64))
                        .toList(),
                  ),
                if (strokes.isNotEmpty)
                  SizedBox(
                    height: math.min(140, (viewport?.height ?? 280) / 2),
                    width: double.infinity,
                    child: CustomPaint(
                      painter: ForestArtPainter(a.id, strokes),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 220,
            child: Column(
              children: [
                const ForestSign('즐거웠어!'),
                const SizedBox(height: 12),
                ForestAction(
                  label: '숲으로 돌아가기',
                  onPressed: () => Navigator.pop(context),
                  size: 96,
                  leaf: true,
                  quiet: true,
                  child: const ForestProp(ForestObject.home, size: 65),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      a.offscreen,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: forestInk,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return _endingPortrait();
  }

  Widget _endingPortrait() => ForestSceneComposition(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      AvatarImage(
        avatar: a.avatar,
        size: 140,
        lowStimulation: true,
        showBlush: true,
      ),
      if (results.isNotEmpty)
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: results
              .take(6)
              .map((s) => ForestProp(journeyProp(s), size: 64))
              .toList(),
        ),
      if (strokes.isNotEmpty)
        SizedBox(
          width: 240,
          height: 150,
          child: CustomPaint(painter: ForestArtPainter(a.id, strokes)),
        ),
      const SizedBox(height: 20),
      const ForestSign('즐거웠어!'),
      const SizedBox(height: 16),
      const Icon(Icons.family_restroom_rounded, size: 48, color: forestInk),
      const SizedBox(height: 12),
      Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          color: forestCream,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Text(
          a.offscreen,
          textAlign: TextAlign.center,
          style: const TextStyle(color: forestInk, fontSize: 17, height: 1.5),
        ),
      ),
      const SizedBox(height: 20),
      ForestAction(
        label: '숲으로 돌아가기',
        onPressed: () => Navigator.pop(context),
        size: 96,
        leaf: true,
        quiet: true,
        child: const ForestProp(ForestObject.home, size: 65),
      ),
    ],
  );
  Widget _play() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < sceneCount; i++)
            Padding(
              padding: const EdgeInsets.all(6),
              child: Opacity(
                opacity: i <= step ? 1 : .35,
                child: const ForestProp(ForestObject.acorn, size: 26),
              ),
            ),
        ],
      ),
      if (widget.preview)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(a.steps[step], textAlign: TextAlign.center),
        ),
      if (audioFailed)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            widget.preview
                ? '음성을 재생하지 못했어요. 글 안내로 화면을 검수할 수 있어요.'
                : '안내 소리를 다시 들어 주세요.',
            textAlign: TextAlign.center,
          ),
        ),
      if (audioFailed && !widget.preview)
        ForestAction(
          label: '소리 재시도',
          icon: Icons.refresh_rounded,
          onPressed: () {
            narrate();
          },
          size: 90,
        )
      else
        switch (a.mechanic) {
          'reveal' => _reveal(),
          'sort' => _sort(),
          'build' => _build(),
          'rhythm' => _rhythm(),
          'draw' => _draw(),
          _ => _story(),
        },
      const SizedBox(height: 22),
      if (!ready && !busy)
        ForestAction(
          label: '도움 그림 보기',
          icon: Icons.touch_app_rounded,
          size: 64,
          quiet: quiet,
          onPressed: () => setState(() => helpRequested = !helpRequested),
        ),
      if (helpRequested && !ready)
        Padding(
          padding: const EdgeInsets.all(10),
          child: Semantics(
            label: '큰 그림을 고른 뒤 친구나 빈 자리를 눌러 보세요',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.touch_app_rounded, size: 40, color: forestInk),
                ForestProp(journeyProp(options.first), size: 64),
                const Icon(Icons.pets_rounded, size: 40, color: forestInk),
              ],
            ),
          ),
        ),
      if (ready && (!audioFailed || widget.preview))
        ForestAction(
          label: step + 1 >= sceneCount ? '놀이 마치기' : '다음 장면',
          icon: step + 1 >= sceneCount
              ? Icons.check_rounded
              : Icons.spa_rounded,
          onPressed: next,
          size: 86,
          leaf: true,
          quiet: quiet,
        ),
    ],
  );
  void choose(int i) {
    checkpoint.event('actions');
    checkpoint.metrics.putIfAbsent('firstActionSeconds', () => session.seconds);
    setState(() {
      reaction++;
      selected = i;
      if (!ready || results.isEmpty) {
        results.add(options[i]);
      } else {
        results[results.length - 1] = options[i];
      }
      ready = true;
    });
    checkpoint.changed();
    if (sound) SoundEffects.instance.pop();
  }

  Widget _reveal() => ['age_30_03', 'age_48_02', 'age_84_05'].contains(a.id)
      ? JourneyDetectiveScene(
          key: ValueKey('${a.id}-$step'),
          step: step,
          count: options.length,
          stage: helpRequested ? 0 : stage,
          quiet: quiet,
          cooperative: a.id == 'age_84_05',
          onFound: choose,
        )
      : JourneyRevealScene(
          stage: helpRequested ? 0 : stage,
          id: a.id,
          step: step,
          avatar: a.avatar,
          options: options.map(journeyProp).toList(),
          labels: options.map(propLabel).toList(),
          selected: selected,
          revealed: ready,
          quiet: quiet,
          onChoose: choose,
        );

  Widget _story() => JourneyStoryScene(
    stage: helpRequested ? 0 : stage,
    reaction: reaction,
    id: a.id,
    step: step,
    avatar: a.avatar,
    options: options.map(journeyProp).toList(),
    labels: options.map(propLabel).toList(),
    history: results.map(journeyProp).toList(),
    selected: selected,
    ready: ready,
    quiet: quiet,
    onChoose: choose,
  );

  Widget _sort() => JourneySortScene(
    key: ValueKey('${a.id}-$step'),
    seed: sequenceSeed,
    guided: stage == 0 || helpRequested,
    id: a.id,
    step: step,
    bySize:
        (stage == 2 && (step > 0 || a.minAge == 30)) ||
        ((a.id == 'age_60_01' || a.id == 'age_72_04') && step > 0),
    bins: stage == 0 ? 1 : 2,
    progress: action,
    goal: stage == 0
        ? 1
        : stage == 1
        ? 2
        : 4,
    quiet: quiet,
    onMatch: () {
      setState(() {
        action++;
        ready =
            action >=
            (stage == 0
                ? 1
                : stage == 1
                ? 2
                : 4);
        if (ready) results.add('basket');
      });
      checkpoint.changed();
      if (sound) SoundEffects.instance.snap();
    },
  );

  void placePiece(int i, int value) {
    if (busy) return;
    setState(() {
      slots[i] = value;
      ready = false;
      trialResult = null;
      results
        ..clear()
        ..addAll(slots.values.map((v) => a.symbols[v]));
    });
    checkpoint.changed();
    if (sound) SoundEffects.instance.snap();
  }

  void runTrial() {
    checkpoint.event('trials');
    if (busy || slots.isEmpty) return;
    setState(() {
      busy = true;
      ready = false;
      trialResult = null;
      trial = BuildTrial(
        attempt: ++action,
        id: a.id,
        step: step,
        stage: stage,
        count: slotCount,
        pieces: Map.of(slots),
      );
    });
  }

  void trialFinished() {
    if (!mounted || ended || trial == null) return;
    setState(() {
      busy = false;
      trialResult = trial!.evaluate();
      ready = trialResult!.success;
      trials.add(trial!.toJson());
      if (trials.length > 30) trials.removeAt(0);
    });
    checkpoint.changed();
    if (sound) {
      if (trialResult!.success) {
        SoundEffects.instance.snap();
      } else {
        SoundEffects.instance.whoosh();
      }
    }
  }

  Widget _build() => ForestSceneComposition(
    children: [
      JourneyBuildBoard(
        id: a.id,
        slots: slots,
        count: slotCount,
        active: busy ? 0 : -1,
        quiet: quiet,
        onPlace: (i) => placePiece(i, selected),
        onDrop: placePiece,
        trial: trial,
        onTrialFinished: trialFinished,
      ),
      const SizedBox(height: 20),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          for (
            var i = 0;
            i < (stage == 0 && a.id != 'age_60_02' ? 1 : a.symbols.length);
            i++
          )
            PlayPiece(
              label: buildPieceLabel(a.id, i),
              dragValue: i,
              onTap: () {
                if (!busy) setState(() => selected = i);
              },
              selected: selected == i,
              quiet: quiet,
              size: 82,
              child: JourneyBuildPiece(id: a.id, value: i, quiet: quiet),
            ),
        ],
      ),
      const SizedBox(height: 18),
      ForestAction(
        label: '만든 길 시험하기',
        icon: a.id == 'age_60_03' ? Icons.air_rounded : Icons.pets_rounded,
        size: 82,
        quiet: quiet,
        onPressed: busy || slots.isEmpty ? null : runTrial,
      ),
      if (trialResult != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Semantics(
            label: trialResult!.reason,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  trialResult!.success
                      ? Icons.check_circle_outline_rounded
                      : Icons.build_circle_outlined,
                  color: forestInk,
                  size: 42,
                ),
                if (!trialResult!.success &&
                    trialResult!.repairValue != null) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: JourneyBuildPiece(
                      id: a.id,
                      value: trialResult!.repairValue!,
                      quiet: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      if (widget.preview && trialResult != null)
        Text(trialResult!.reason, textAlign: TextAlign.center),
    ],
  );
  void placeNote(int slot, int note) {
    if (busy) return;
    setState(() {
      slots[slot] = note;
      ready = slots.length == slotCount;
    });
    checkpoint.changed();
    if (sound && note != 3) SoundEffects.instance.playNote(note * 2);
  }

  Widget _rhythm() => JourneyRhythmScene(
    id: a.id,
    slots: slots,
    count: slotCount,
    active: activeNote,
    selected: selected,
    stage: stage,
    busy: busy,
    quiet: quiet,
    onSelect: (note) {
      setState(() => selected = note);
      final empty = List.generate(
        slotCount,
        (i) => i,
      ).where((i) => !slots.containsKey(i));
      if (empty.isNotEmpty) {
        placeNote(empty.first, note);
      } else if (sound && note != 3) {
        SoundEffects.instance.playNote(note * 2);
      }
    },
    onPlace: placeNote,
    onListen: () {
      setState(() => ready = slots.length == slotCount);
      melody();
    },
  );

  Widget _draw() => ForestArtStudio(
    theme: a.id,
    marks: strokes,
    quiet: quiet,
    simple: stage == 0,
    canvasKey: const ValueKey('journey_canvas'),
    onChanged: () {
      setState(() => ready = strokes.isNotEmpty);
      checkpoint.changed();
    },
  );
}
