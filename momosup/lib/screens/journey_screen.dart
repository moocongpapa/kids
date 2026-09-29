import '../data/journey_recommendation.dart';
import '../widgets/journey_reveal_scene.dart';
import '../widgets/journey_build_board.dart';
import '../widgets/journey_story_scene.dart';
import '../widgets/journey_sort_scene.dart';
import '../widgets/journey_rhythm_scene.dart';
import '../widgets/forest_play_stage.dart';
import '../widgets/forest_art_studio.dart';
import '../widgets/journey_picnic_scene.dart';
import '../widgets/journey_garden_scene.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/age_journey.dart';
import '../models/child_profile.dart';
import '../state/app_state.dart';
import '../utils/forest_audio.dart';
import '../utils/sound_effects.dart';
import '../widgets/avatar_image.dart';
import '../widgets/forest_background.dart';
import '../widgets/forest_game_ui.dart';

ForestObject journeyProp(String value) => ForestObject.values.firstWhere(
  (o) => o.name == value,
  orElse: () => ForestObject.leaf,
);
String propLabel(String value) =>
    const {
      'berry': '열매',
      'raspberry': '빨간 열매',
      'blueberry': '파란 열매',
      'basket': '바구니',
      'bush': '풀숲',
      'music': '소리',
      'paw': '손 인사',
      'sun': '해',
      'bus': '버스',
      'flower': '꽃',
      'cloud': '구름',
      'leaf': '나뭇잎',
      'home': '숲집',
      'acorn': '도토리',
      'heart': '친구 마음',
    }[value] ??
    value;

class JourneyLibraryScreen extends StatefulWidget {
  const JourneyLibraryScreen({
    required this.appState,
    required this.profile,
    this.parent = false,
    super.key,
  });
  final AppState appState;
  final ChildProfile profile;
  final bool parent;
  @override
  State<JourneyLibraryScreen> createState() => _JourneyLibraryScreenState();
}

class _JourneyLibraryScreenState extends State<JourneyLibraryScreen> {
  late int age = widget.profile.ageMonths;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.appState,
    builder: (context, _) {
      final items = widget.appState.journeys
          .where(
            (a) =>
                (widget.parent
                    ? a.supports(age, preschool: true)
                    : journeyEligible(a, widget.profile)) &&
                (widget.parent ||
                    (!a.isCaregiver && widget.appState.journeyApproved(a))),
          )
          .toList();
      if (!widget.parent) {
        return Scaffold(
          body: ForestBackground(
            lowStimulation: widget.profile.lowStimulation,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ForestAction(
                          label: '숲으로 돌아가기',
                          icon: Icons.close_rounded,
                          onPressed: () => Navigator.pop(context),
                          size: 58,
                        ),
                        const Spacer(),
                        const ForestSign('놀이숲'),
                        const Spacer(),
                        const SizedBox(width: 58),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.extent(
                      maxCrossAxisExtent: 190,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 20,
                      padding: const EdgeInsets.all(24),
                      children: [
                        for (final a in items)
                          Center(
                            child: ForestAction(
                              label: a.title,
                              size: 120,
                              leaf: true,
                              quiet: widget.profile.lowStimulation,
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => JourneyPlayScreen(
                                    journey: a,
                                    appState: widget.appState,
                                    profile: widget.profile,
                                  ),
                                ),
                              ),
                              child: ForestProp(
                                journeyProp(a.symbols.first),
                                size: 88,
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
        );
      }
      return Scaffold(
        appBar: AppBar(title: Text(widget.parent ? '월령별 놀이 공방' : '우리 놀이숲')),
        body: Material(
          color: forestCream,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.parent) ...[
                  const Text('72개 놀이 · 보호자 안내\n월령에 맞는 실제 놀이와 짧은 장면을 만나보세요.'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: journeyBands
                        .firstWhere((b) => age >= b.$1 && age <= b.$2)
                        .$1,
                    decoration: const InputDecoration(labelText: '살펴볼 월령'),
                    items: [
                      for (final b in journeyBands)
                        DropdownMenuItem(
                          value: b.$1,
                          child: Text(journeyBandLabel(b.$1)),
                        ),
                    ],
                    onChanged: (v) => setState(() => age = v!),
                  ),
                  const SizedBox(height: 20),
                ],
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('이 월령의 놀이를 보호자 공방에서 먼저 준비해 주세요.'),
                  ),
                for (final a in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      minVerticalPadding: 20,
                      leading: ForestProp(
                        journeyProp(a.symbols.first),
                        size: 58,
                      ),
                      title: Text(
                        a.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: widget.parent
                          ? Text(
                              '${a.world} · ${a.minutes}분 안팎\n${a.isCaregiver
                                  ? '화면 밖 놀이 안내'
                                  : widget.appState.journeyApproved(a)
                                  ? '검수 완료 · 이용 가능'
                                  : a.bundledApproved
                                  ? '이 기기에서 숨김'
                                  : '새 콘텐츠 검수 대기'}',
                            )
                          : null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => widget.parent
                              ? JourneyDetailScreen(
                                  journey: a,
                                  appState: widget.appState,
                                  profile: widget.profile,
                                )
                              : JourneyPlayScreen(
                                  journey: a,
                                  appState: widget.appState,
                                  profile: widget.profile,
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class JourneyDetailScreen extends StatefulWidget {
  const JourneyDetailScreen({
    required this.journey,
    required this.appState,
    required this.profile,
    super.key,
  });
  final AgeJourney journey;
  final AppState appState;
  final ChildProfile profile;
  @override
  State<JourneyDetailScreen> createState() => _JourneyDetailScreenState();
}

class _JourneyDetailScreenState extends State<JourneyDetailScreen>
    with WidgetsBindingObserver {
  final player = AudioPlayer();
  int stage = 0;
  int audioRequest = 0;
  bool script = false,
      listened = false,
      rights = false,
      away = false,
      playing = false,
      saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    stage = widget.profile.effectivePlayStage;
    ForestAudio.instance.pauseBgm();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) stop();
  }

  Future<void> stop() async {
    audioRequest++;
    if (player.processingState != ProcessingState.idle) await player.stop();
    if (mounted) setState(() => playing = false);
  }

  Future<void> listen(String id) async {
    final request = ++audioRequest;
    final path = widget.journey.audio[id];
    if (path == null) return;
    try {
      await player.stop();
      await player.setAsset(path);
      if (!mounted || away || request != audioRequest) return;
      setState(() {
        playing = true;
        error = null;
      });
      await player.play();
      if (mounted) setState(() => playing = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          error = '음성을 재생하지 못했어요. 다시 들어 주세요.';
          playing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.journey;
    if (away) {
      return Scaffold(
        backgroundColor: const Color(0xFF203B30),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.spa_outlined, size: 64, color: forestCream),
                  const SizedBox(height: 28),
                  const Text(
                    '휴대폰을 내려놓고\n함께 놀아 주세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, color: forestCream),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '소리와 음악은 멈췄어요.\n완료 버튼을 누르지 않아도 괜찮아요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: forestCream),
                  ),
                  const SizedBox(height: 36),
                  TextButton(
                    onPressed: () => setState(() => away = false),
                    child: const Text(
                      '보호자 안내로 돌아가기',
                      style: TextStyle(color: forestCream),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(a.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Text(
              '${journeyBandLabel(a.minAge)} · ${a.world}',
              style: const TextStyle(
                color: forestInk,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final current = widget.appState.profiles.firstWhere(
                  (p) => p.id == widget.profile.id,
                  orElse: () => widget.profile,
                );
                final favorites = List<String>.from(current.favoriteJourneys);
                if (favorites.contains(a.id)) {
                  favorites.remove(a.id);
                } else {
                  favorites.add(a.id);
                }
                await widget.appState.updateProfile(
                  current.copyWith(favoriteJourneys: favorites),
                );
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.favorite_outline_rounded),
              label: Text(
                widget.appState.profiles.any(
                      (p) =>
                          p.id == widget.profile.id &&
                          p.favoriteJourneys.contains(a.id),
                    )
                    ? '좋아하는 놀이에서 빼기'
                    : '좋아하는 놀이로 기억하기',
              ),
            ),
            Text(a.summary),
            const SizedBox(height: 12),
            Text('준비물: ${a.materials}'),
            Text('약 ${a.minutes}분 · 아이 관심에 따라 더 짧게 끝내도 돼요.'),
            const SizedBox(height: 22),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < 3; i++)
                  ChoiceChip(
                    label: Text(journeyStages[i]),
                    selected: stage == i,
                    onSelected: (_) => setState(() => stage = i),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              a.variants[stage],
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Divider(),
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '${i + 1}. ${a.steps[i]}',
                  style: const TextStyle(fontSize: 17, height: 1.6),
                ),
              ),
            Text(
              a.offscreen,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Divider(),
            for (final s in a.safety)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• $s'),
              ),
            const SizedBox(height: 16),
            Text(
              a.audioReady
                  ? a.bundledApproved
                        ? '안내 음성 · 검수와 사용권 확인 완료'
                        : 'Gemini로 만든 새 안내 음성 · 청취 검수 대상'
                  : '음성 제작 중 · 글 안내와 화면 미리보기를 확인할 수 있어요.',
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final id in a.audioIds)
                  OutlinedButton.icon(
                    onPressed: a.audio.containsKey(id)
                        ? () => listen(id)
                        : null,
                    icon: const Icon(Icons.volume_up_rounded),
                    label: Text(
                      id == 'song'
                          ? '인사 노래 듣기'
                          : id == 'guide'
                          ? '안내 듣기'
                          : '${int.parse(id.split('_').last) + 1}장면 듣기',
                    ),
                  ),
                if (playing)
                  TextButton(onPressed: stop, child: const Text('소리 멈춤')),
              ],
            ),
            if (a.data['musicLyrics'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('함께 부를 노래\n${a.data['musicLyrics']}'),
              ),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                await stop();
                await ForestAudio.instance.stopBgm();
                if (!context.mounted) return;
                if (a.isCaregiver) {
                  setState(() => away = true);
                } else {
                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => JourneyPlayScreen(
                        journey: a,
                        appState: widget.appState,
                        profile: widget.profile.copyWith(
                          ageMonths: a.minAge,
                          preschool: true,
                          playStage: stage,
                        ),
                        preview: true,
                      ),
                    ),
                  );
                }
              },
              icon: Icon(
                a.isCaregiver
                    ? Icons.phone_iphone_rounded
                    : Icons.play_arrow_rounded,
              ),
              label: Text(a.isCaregiver ? '안내 끝 · 휴대폰 내려놓기' : '이 단계로 직접 미리 놀기'),
            ),
            const SizedBox(height: 24),
            if (a.bundledApproved) ...[
              const Text(
                '검수·사용권 확인 완료',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                a.isCaregiver
                    ? '보호자가 안내를 확인한 뒤 아이와 화면 밖에서 함께 놀아 주세요.'
                    : '아이 월령에 맞춰 홈에 나타납니다. 이 기기에서만 숨기거나 다시 보이게 할 수 있어요.',
              ),
              if (!a.isCaregiver)
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setState(() => saving = true);
                          try {
                            await widget.appState.reviewJourney(
                              a,
                              approved: !widget.appState.journeyApproved(a),
                            );
                          } catch (_) {
                            if (mounted) {
                              setState(() => error = '설정을 저장하지 못했어요.');
                            }
                          } finally {
                            if (mounted) setState(() => saving = false);
                          }
                        },
                  child: Text(
                    widget.appState.journeyApproved(a)
                        ? '이 기기에서 숨기기'
                        : '이 기기에서 다시 보이기',
                  ),
                ),
            ] else ...[
              const Text(
                '이 기기에서 검수하기',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text(
                '실제로 확인한 항목만 선택해 주세요. 대본이나 음성이 바뀌면 다시 검수합니다. 이 기록은 공개 출시 승인과 별개예요.',
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('세 단계 대본·놀이 동작·안전을 확인했어요'),
                value: script,
                onChanged: (v) => setState(() => script = v!),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('모든 안내의 발음·내용·음량을 직접 들었어요'),
                value: listened,
                onChanged: (v) => setState(() => listened = v!),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('새 음성을 이 아동용 앱에 쓸 권리를 확인했어요'),
                value: rights,
                onChanged: (v) => setState(() => rights = v!),
              ),
              FilledButton(
                onPressed:
                    !saving && script && listened && rights && a.audioReady
                    ? () async {
                        setState(() => saving = true);
                        try {
                          await widget.appState.reviewJourney(
                            a,
                            approved: true,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  a.isCaregiver
                                      ? '보호자 안내의 검수를 기록했어요.'
                                      : '이 월령의 아이 홈에서 놀이를 열 수 있어요.',
                                ),
                              ),
                            );
                          }
                        } catch (_) {
                          if (mounted) {
                            setState(() => error = '검수 기록을 저장하지 못했어요.');
                          }
                        } finally {
                          if (mounted) setState(() => saving = false);
                        }
                      }
                    : null,
                child: Text(a.isCaregiver ? '보호자 안내 검수 기록' : '이 기기 아이 홈에 공개'),
              ),
              if (widget.appState.journeyApproved(a))
                TextButton(
                  onPressed: () async {
                    await widget.appState.reviewJourney(a, approved: false);
                    if (mounted) setState(() {});
                  },
                  child: const Text('이 기기에서 숨기기'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class JourneyPlayScreen extends StatefulWidget {
  const JourneyPlayScreen({
    required this.journey,
    required this.appState,
    required this.profile,
    this.preview = false,
    this.playAsset,
    super.key,
  });
  final AgeJourney journey;
  final AppState appState;
  final ChildProfile profile;
  final bool preview;
  final Future<void> Function(String path)? playAsset;
  @override
  State<JourneyPlayScreen> createState() => _JourneyPlayScreenState();
}

class _JourneyPlayScreenState extends State<JourneyPlayScreen>
    with WidgetsBindingObserver {
  final player = AudioPlayer();
  final watch = Stopwatch();
  final sceneScroll = ScrollController();
  Timer? timer;
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
  final List<String> results = [];
  final Map<int, int> slots = {};
  final List<ArtMark> strokes = [];
  AgeJourney get a => widget.journey;
  int get stage => widget.profile.effectivePlayStage;
  bool get quiet =>
      widget.profile.lowStimulation || MediaQuery.disableAnimationsOf(context);
  bool get sound =>
      widget.profile.musicOn && !ForestAudio.instance.isMuted.value;
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
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && allowed) announceFirstScene();
    });
  }

  Future<void> announceFirstScene() async {
    await ForestAudio.instance.pauseBgm();
    if (!mounted || ended || firstNarrationRequested) return;
    firstNarrationRequested = true;
    narrate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      token++;
      voiceRequest++;
      player.stop();
      if (started && !ended) finish();
    }
  }

  Future<void> narrate() async {
    final path = a.audio['step_$step'];
    final mine = ++voiceRequest;
    if (path == null) {
      if (!widget.preview && mounted) setState(() => audioFailed = true);
      return;
    }
    try {
      if (widget.playAsset == null) {
        await player.stop();
        await player.setAsset(path);
        if (!mounted || mine != voiceRequest || ended) return;
        await player.play();
      } else {
        await widget.playAsset!(path);
      }
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
    final remaining =
        widget.profile.dailyLimitMinutes -
        widget.appState.minutesToday(widget.profile.id);
    if (!widget.preview && remaining <= 0) {
      setState(() => ended = true);
      return;
    }
    if (sceneScroll.hasClients) sceneScroll.jumpTo(0);
    setState(() => started = true);
    watch.start();
    timer = Timer(
      Duration(
        minutes: widget.preview ? a.minutes : math.min(a.minutes, remaining),
      ),
      finish,
    );
    announceFirstScene();
  }

  void finish() {
    if (ended) return;
    if (sceneScroll.hasClients) sceneScroll.jumpTo(0);
    token++;
    voiceRequest++;
    timer?.cancel();
    player.stop();
    watch.stop();
    setState(() => ended = true);
    if (!widget.preview && started) {
      widget.appState.recordPlay(
        profileId: widget.profile.id,
        activityId: a.id,
        seconds: watch.elapsed.inSeconds,
      );
    }
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
    player.stop();
    setState(() {
      step++;
      ready = false;
      selected = 0;
      action = 0;
      busy = false;
      if (a.mechanic != 'build' && a.mechanic != 'rhythm') slots.clear();
      activeNote = -1;
    });
    narrate();
  }

  Future<void> melody() async {
    if (busy) return;
    final mine = token;
    setState(() => busy = true);
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
    token++;
    voiceRequest++;
    timer?.cancel();
    watch.stop();
    WidgetsBinding.instance.removeObserver(this);
    player.dispose();
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
    return PopScope(
      canPop: ended || !started,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) finish();
      },
      child: Scaffold(
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
                        constraints: BoxConstraints(minHeight: box.maxHeight),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
    );
  }

  Widget _intro() => Column(
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: 29,
                child: AvatarImage(
                  avatar: a.avatar,
                  size: 136,
                  lowStimulation: quiet,
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
  Widget _ending() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      AvatarImage(avatar: a.avatar, size: 140, lowStimulation: true),
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
    setState(() {
      reaction++;
      selected = i;
      if (!ready) {
        results.add(options[i]);
      } else {
        results[results.length - 1] = options[i];
      }
      ready = true;
    });
    if (sound) SoundEffects.instance.pop();
  }

  Widget _reveal() => JourneyRevealScene(
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
      if (sound) SoundEffects.instance.snap();
    },
  );

  void placePiece(int i, int value) {
    if (busy) return;
    setState(() {
      slots[i] = value;
      ready = slots.length == slotCount;
      results
        ..clear()
        ..addAll(slots.values.map((v) => a.symbols[v]));
    });
    if (sound) SoundEffects.instance.snap();
  }

  Widget _build() => Column(
    children: [
      JourneyBuildBoard(
        id: a.id,
        slots: slots,
        count: slotCount,
        active: activeNote,
        quiet: quiet,
        onPlace: (i) => placePiece(i, selected),
        onDrop: placePiece,
      ),
      const SizedBox(height: 25),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          for (var i = 0; i < (stage == 0 ? 1 : a.symbols.length); i++)
            PlayPiece(
              label: propLabel(a.symbols[i]),
              dragValue: i,
              onTap: () => setState(() => selected = i),
              selected: selected == i,
              quiet: quiet,
              size: 82,
              child: JourneyBuildPiece(id: a.id, value: i, quiet: quiet),
            ),
        ],
      ),
      if (slots.length == slotCount) ...[
        const SizedBox(height: 18),
        ForestAction(
          label: a.id == 'age_60_03' && step == 1 ? '바람 불러보기' : '친구가 길을 따라가 보기',
          icon: Icons.pets_rounded,
          size: 72,
          quiet: quiet,
          onPressed: busy
              ? null
              : () async {
                  final mine = token;
                  setState(() => busy = true);
                  for (var i = 0; i < slotCount; i++) {
                    if (!mounted || ended || token != mine) break;
                    setState(() => activeNote = i);
                    await Future<void>.delayed(
                      Duration(milliseconds: quiet ? 120 : 400),
                    );
                  }
                  if (mounted && token == mine) {
                    setState(() {
                      activeNote = -1;
                      busy = false;
                      ready = true;
                      if (a.id == 'age_60_03' && step == 1 && action == 0) {
                        slots.remove(0);
                        ready = false;
                        action++;
                      }
                      results
                        ..clear()
                        ..addAll(slots.values.map((v) => a.symbols[v]));
                    });
                  }
                },
        ),
        if (activeNote >= 0)
          Text(
            '${activeNote + 1} / $slotCount',
            style: const TextStyle(color: forestInk),
          ),
      ],
    ],
  );
  void placeNote(int slot, int note) {
    if (busy) return;
    setState(() {
      slots[slot] = note;
      ready = slots.length == slotCount;
    });
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
    onChanged: () => setState(() => ready = strokes.isNotEmpty),
  );
}
