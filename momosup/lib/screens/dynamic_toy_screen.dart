import 'dart:async';
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

enum DynamicToyType { feeding, sorting, peekaboo, xylophone, puzzle }

class DynamicToyScreen extends StatefulWidget {
  const DynamicToyScreen({
    required this.toyType,
    required this.appState,
    required this.profile,
    super.key,
  });
  final DynamicToyType toyType;
  final AppState appState;
  final ChildProfile profile;
  @override
  State<DynamicToyScreen> createState() => _DynamicToyScreenState();
}

class _DynamicToyScreenState extends State<DynamicToyScreen> {
  final Stopwatch stopwatch = Stopwatch();
  bool ended = false;
  bool complete = false;
  Timer? sessionTimer;
  @override
  void initState() {
    super.initState();
    ForestAudio.instance.pauseBgm();
    stopwatch.start();
    final remaining =
        widget.profile.dailyLimitMinutes -
        widget.appState.minutesToday(widget.profile.id);
    sessionTimer = Timer(
      Duration(minutes: math.max(1, math.min(3, remaining))),
      finish,
    );
  }

  @override
  void dispose() {
    ForestAudio.instance.startBgm(enabled: widget.profile.musicOn);
    sessionTimer?.cancel();
    stopwatch.stop();
    super.dispose();
  }

  void finish() {
    if (ended) return;
    sessionTimer?.cancel();
    stopwatch.stop();
    setState(() => ended = true);
    SoundEffects.instance.tada();
    widget.appState.recordPlay(
      profileId: widget.profile.id,
      activityId: 'toy_${widget.toyType.name}',
      seconds: math.max(1, stopwatch.elapsed.inSeconds),
    );
  }

  void markComplete() {
    if (!complete) setState(() => complete = true);
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
    final quiet =
        widget.profile.lowStimulation ||
        MediaQuery.disableAnimationsOf(context);
    return PopScope(
      canPop: ended,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) finish();
      },
      child: Scaffold(
        body: ForestBackground(
          lowStimulation: quiet,
          clearing: true,
          child: SafeArea(
            child: Column(
              children: [
                ForestHeader(
                  title: title,
                  onExit: ended ? () => Navigator.of(context).pop() : finish,
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 650),
                      child: ended
                          ? SingleChildScrollView(
                              child: ForestCompletion(
                                avatar: avatar,
                                offscreen: offscreen,
                                quiet: quiet,
                                onHome: () => Navigator.of(context).pop(),
                              ),
                            )
                          : LayoutBuilder(
                              builder: (_, box) {
                                final height = math.max(440.0, box.maxHeight);
                                return SingleChildScrollView(
                                  physics: box.maxHeight >= 440
                                      ? const NeverScrollableScrollPhysics()
                                      : null,
                                  child: SizedBox(
                                    height: height,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: switch (widget.toyType) {
                                              DynamicToyType.feeding =>
                                                FeedingGame(
                                                  lowStimulation: quiet,
                                                  onComplete: markComplete,
                                                ),
                                              DynamicToyType.sorting =>
                                                SortingGame(
                                                  lowStimulation: quiet,
                                                  onComplete: markComplete,
                                                ),
                                              DynamicToyType.peekaboo =>
                                                PeekabooGame(
                                                  lowStimulation: quiet,
                                                  onComplete: markComplete,
                                                ),
                                              DynamicToyType.xylophone =>
                                                XylophoneGame(
                                                  lowStimulation: quiet,
                                                  onComplete: markComplete,
                                                ),
                                              DynamicToyType.puzzle =>
                                                SilhouettePuzzleGame(
                                                  lowStimulation: quiet,
                                                  onComplete: markComplete,
                                                ),
                                            },
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
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
                                                  ? Icons.check_rounded
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
    );
  }
}
