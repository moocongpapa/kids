import '../utils/forest_orientation.dart';
import '../widgets/forest_landscape.dart';

import 'dart:async';

import '../data/toy_audio_repository.dart';
import '../utils/narration_player.dart';
import '../utils/toy_music_player.dart';
import '../utils/audio_output.dart';
import '../data/play_catalog.dart';
export '../data/play_catalog.dart' show DynamicToyType;
import '../utils/play_session.dart';
import '../utils/play_checkpoint.dart';
import '../utils/audio_policy.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../state/app_state.dart';
import '../utils/forest_audio.dart';
import '../utils/sound_effects.dart';
import '../widgets/forest_background.dart';
import '../widgets/forest_game_ui.dart';
import '../widgets/games/feeding_game.dart';
import '../widgets/games/sorting_game.dart';
import '../widgets/games/peekaboo_game.dart';
import '../widgets/games/xylophone_game.dart';
import '../widgets/games/silhouette_puzzle_game.dart';
import '../widgets/cute_game_effects.dart';

class DynamicToyScreen extends StatefulWidget {
  const DynamicToyScreen({
    required this.toyType,
    required this.appState,
    required this.profile,
    this.preview = false,
    this.audioPack,
    this.playAsset,
    this.musicOutput,
    super.key,
  });
  final bool preview;
  final ToyAudioPack? audioPack;
  final Future<void> Function(String)? playAsset;
  final AudioOutput? musicOutput;
  final DynamicToyType toyType;
  final AppState appState;
  final ChildProfile profile;
  @override
  State<DynamicToyScreen> createState() => _DynamicToyScreenState();
}

class _DynamicToyScreenState extends State<DynamicToyScreen> {
  late final PlaySession session;
  late final PlayCheckpoint checkpoint;
  late final NarrationPlayer narration;
  late final ToyMusicPlayer music;
  ToyAudioPack? audio;
  String instruction = 'intro';
  int audioRequest = 0;
  bool audioFailed = false;
  bool ended = false;
  bool complete = false;

  @override
  void initState() {
    super.initState();
    AudioPolicy.instance.configure(widget.profile);
    narration = NarrationPlayer(playAsset: widget.playAsset);
    music = ToyMusicPlayer(output: widget.musicOutput);
    checkpoint = PlayCheckpoint(
      widget.appState,
      widget.profile.id,
      'toy_${widget.toyType.name}',
      () => {'complete': ended},
      preview: widget.preview,
      onError: () => session.reportSaveError(),
    );
    session = PlaySession(
      limitSeconds: widget.preview
          ? 180
          : math.min(
              180,
              widget.appState.secondsRemaining(
                widget.profile.id,
                widget.profile.dailyLimitMinutes,
              ),
            ),
      onExpire: finish,
      onPause: () {
        checkpoint.event('interruptions');
        audioRequest++;
        narration.stop();
      },
      onResume: () {
        if (!ended) speak(instruction);
      },
      onCheckpoint: checkpoint.checkpoint,
    );
    if (widget.profile.ageMonths < 36 || widget.profile.ageMonths >= 72) {
      ended = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      session.start();
      await ForestAudio.instance.pauseBgm();
      if (mounted) await loadAudio();
    });
  }

  Future<void> loadAudio() async {
    try {
      final pack = widget.audioPack ?? await ToyAudioRepository().load();
      if (!mounted) return;
      audio = pack;
      if (!ended) {
        music.start(
          widget.toyType == DynamicToyType.xylophone
              ? null
              : pack.music[widget.toyType.name],
        );
      }
      await speak(ended ? 'outro' : instruction);
    } catch (_) {
      if (mounted) setState(() => audioFailed = true);
    }
  }

  Future<void> speak(String cue) async {
    if (!mounted || session.paused || (ended && cue != 'outro')) return;
    final request = ++audioRequest;
    final path = audio?.cue(widget.toyType.name, cue);
    if (path == null) {
      if (audio != null) setState(() => audioFailed = true);
      return;
    }
    try {
      await narration.speak([path]);
      if (mounted && request == audioRequest && audioFailed) {
        setState(() => audioFailed = false);
      }
    } catch (_) {
      if (mounted && request == audioRequest) {
        setState(() => audioFailed = true);
      }
    }
  }

  void changeMusicMode(bool follow) {
    instruction = follow ? 'follow' : 'intro';
    speak(instruction);
  }

  @override
  void dispose() {
    audioRequest++;
    narration.dispose();
    music.dispose();
    SoundEffects.instance.stopAll();
    if (!widget.preview) {
      ForestAudio.instance.startBgm(
        enabled: widget.profile.musicOn && !widget.profile.caregiverMode,
      );
    }
    session.dispose();
    checkpoint.dispose();
    super.dispose();
  }

  void finish() {
    if (ended) return;
    setState(() => ended = true);
    session.finish();
    SoundEffects.instance.stopAll();
    music.stop();
    narration.stop();
    speak('outro');
  }

  void markComplete() {
    if (ended || !mounted) return;
    if (!complete) {
      setState(() => complete = true);
      speak('complete');
      final sticker = ForestSticker.forToy(widget.toyType.name);
      if (!widget.preview) {
        widget.appState.saveWork(
          widget.profile.id,
          'sticker_${widget.toyType.name}',
          sticker.toJson(),
        );
      }
      // Keep the child's play in view. The keepsake appears on the quiet
      // ending screen rather than interrupting exploration with a modal.
    }
  }

  String get title => switch (widget.toyType) {
    DynamicToyType.feeding => '냠냠 열매',
    DynamicToyType.sorting => '도토리 쏙쏙',
    DynamicToyType.peekaboo => '풀숲 까꿍',
    DynamicToyType.xylophone => '숲속 딩동',
    DynamicToyType.puzzle => '그림자 착착',
  };
  String get avatar => switch (widget.toyType) {
    DynamicToyType.sorting || DynamicToyType.puzzle => 'duri',
    DynamicToyType.peekaboo => 'nuri',
    _ => 'momo',
  };
  String get offscreen => switch (widget.toyType) {
    DynamicToyType.feeding => '가족과 함께 물 한 잔 마시러 가요.',
    DynamicToyType.sorting => '장난감을 바구니에 담아 보아요.',
    DynamicToyType.peekaboo => '가족과 까꿍 놀이를 해 보아요.',
    DynamicToyType.xylophone => '가족과 손뼉을 짝짝 쳐 보아요.',
    DynamicToyType.puzzle => '두 팔을 쭉 뻗고 쉬어요.',
  };
  @override
  Widget build(BuildContext context) {
    if (widget.profile.ageMonths < 36 || widget.profile.ageMonths >= 72) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('이 월령에 맞는 놀이를 보호자와 준비해 주세요.')),
      );
    }
    final quiet =
        widget.profile.lowStimulation ||
        MediaQuery.disableAnimationsOf(context);
    return ForestOrientationScope(
      child: PlaySessionView(
        session: session,
        child: PopScope(
          canPop: ended,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) finish();
          },
          child: forestIsWide(context)
              ? ForestLandscapeFrame(
                  quiet: quiet,
                  preview: widget.preview,
                  onExit: ended ? () => Navigator.pop(context) : finish,
                  onFinish: ended ? null : finish,
                  onReplay: () {
                    if (audio == null || audioFailed) {
                      loadAudio();
                    } else {
                      speak(
                        ended
                            ? 'outro'
                            : complete
                            ? 'complete'
                            : instruction,
                      );
                    }
                  },
                  child: ended
                      ? ForestCompletion(
                          avatar: avatar,
                          offscreen: offscreen,
                          quiet: quiet,
                          preview: widget.preview,
                          sticker: complete
                              ? ForestSticker.forToy(widget.toyType.name)
                              : null,
                          onHome: () => Navigator.pop(context),
                        )
                      : _toy(quiet),
                )
              : Scaffold(
                  body: ForestBackground(
                    lowStimulation: quiet,
                    clearing: true,
                    child: SafeArea(
                      child: Column(
                        children: [
                          ForestHeader(
                            title: title,
                            preview: widget.preview,
                            onReplay: () {
                              if (audio == null || audioFailed) {
                                loadAudio();
                              } else {
                                speak(
                                  ended
                                      ? 'outro'
                                      : complete
                                      ? 'complete'
                                      : instruction,
                                );
                              }
                            },
                            onExit: ended
                                ? () => Navigator.of(context).pop()
                                : finish,
                          ),
                          if (audioFailed)
                            TextButton.icon(
                              onPressed: loadAudio,
                              icon: const Icon(Icons.volume_up_rounded),
                              label: const Text('소리 다시 듣기'),
                            ),
                          Expanded(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 650,
                                ),
                                child: ended
                                    ? SingleChildScrollView(
                                        child: ForestCompletion(
                                          avatar: avatar,
                                          offscreen: offscreen,
                                          quiet: quiet,
                                          sticker: complete
                                              ? ForestSticker.forToy(
                                                  widget.toyType.name,
                                                )
                                              : null,
                                          onHome: () =>
                                              Navigator.of(context).pop(),
                                        ),
                                      )
                                    : LayoutBuilder(
                                        builder: (_, box) {
                                          final height = math.max(
                                            440.0,
                                            box.maxHeight,
                                          );
                                          return SingleChildScrollView(
                                            physics: box.maxHeight >= 440
                                                ? const NeverScrollableScrollPhysics()
                                                : null,
                                            child: SizedBox(
                                              height: height,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                    ),
                                                child: Column(
                                                  children: [
                                                    Expanded(
                                                      child: _toy(quiet),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 12,
                                                            top: 4,
                                                          ),
                                                      child: ForestAction(
                                                        label: '놀이 마치기',
                                                        size: 70,
                                                        leaf: true,
                                                        quiet: quiet,
                                                        caption: complete
                                                            ? '다 했어!'
                                                            : '쉬어요',
                                                        onPressed: finish,
                                                        icon: complete
                                                            ? Icons
                                                                  .check_rounded
                                                            : Icons.spa_rounded,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
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

  Widget _toy(bool quiet) => switch (widget.toyType) {
    DynamicToyType.feeding => FeedingGame(
      lowStimulation: quiet,
      stage: widget.profile.stageFor('toy_${widget.toyType.name}'),
      onComplete: markComplete,
    ),
    DynamicToyType.sorting => SortingGame(
      lowStimulation: quiet,
      stage: widget.profile.stageFor('toy_${widget.toyType.name}'),
      onComplete: markComplete,
    ),
    DynamicToyType.peekaboo => PeekabooGame(
      lowStimulation: quiet,
      stage: widget.profile.stageFor('toy_${widget.toyType.name}'),
      onComplete: markComplete,
    ),
    DynamicToyType.xylophone => XylophoneGame(
      onModeChanged: changeMusicMode,
      onNote: () {
        narration.stop();
      },
      lowStimulation: quiet,
      stage: widget.profile.stageFor('toy_${widget.toyType.name}'),
      onComplete: markComplete,
    ),
    DynamicToyType.puzzle => SilhouettePuzzleGame(
      lowStimulation: quiet,
      stage: widget.profile.stageFor('toy_${widget.toyType.name}'),
      onComplete: markComplete,
    ),
  };
}
