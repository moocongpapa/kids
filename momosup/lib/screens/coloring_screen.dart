import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../state/app_state.dart';
import '../utils/forest_orientation.dart';
import '../utils/audio_policy.dart';
import '../utils/play_checkpoint.dart';
import '../utils/play_session.dart';
import '../utils/sound_effects.dart';
import '../widgets/forest_background.dart';
import '../widgets/forest_coloring_studio.dart';
import '../widgets/forest_game_ui.dart';

class ColoringScreen extends StatefulWidget {
  const ColoringScreen({
    required this.profile,
    required this.appState,
    this.initialTemplateIndex = 0,
    this.stopwatch,
    super.key,
  });

  final ChildProfile profile;
  final AppState appState;
  final int initialTemplateIndex;

  /// Allows active time to be controlled in headless lifecycle tests.
  final Stopwatch? stopwatch;

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen> {
  late final PlaySession session;
  late final PlayCheckpoint checkpoint;
  bool ended = false;
  bool exiting = false;
  bool canPop = false;

  @override
  void initState() {
    super.initState();
    AudioPolicy.instance.configure(widget.profile);
    checkpoint = PlayCheckpoint(
      widget.appState,
      widget.profile.id,
      'coloring',
      () => {'complete': ended},
      splitLongSessions: true,
    );
    session = PlaySession(
      limitSeconds: widget.appState.secondsRemaining(
        widget.profile.id,
        widget.profile.dailyLimitMinutes,
      ),
      stopwatch: widget.stopwatch,
      onExpire: finish,
      onPause: () {
        checkpoint.event('interruptions');
        SoundEffects.instance.stopAll();
      },
      onResume: () {},
      onCheckpoint: (seconds) =>
          checkpoint.checkpoint(math.min(seconds, session.limitSeconds)),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) session.start();
    });
  }

  void finish() {
    if (ended) return;
    setState(() => ended = true);
    session.finish();
    SoundEffects.instance.stopAll();
  }

  Future<void> exit() async {
    if (exiting) return;
    exiting = true;
    finish();
    // Persist the final total before the home screen can start another session.
    // Checkpoints replace this session's record, so repeated saves do not add time.
    await session.checkpoint();
    if (!mounted) return;
    if (session.saveError != null) {
      exiting = false;
      return;
    }
    setState(() => canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    session.dispose();
    checkpoint.dispose();
    SoundEffects.instance.stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ForestOrientationScope(
    mode: ForestOrientation.landscape,
    child: PlaySessionView(
      session: session,
      child: PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) exit();
        },
        child: Scaffold(
          body: ForestBackground(
            lowStimulation: widget.profile.lowStimulation,
            child: SafeArea(
              child: Column(
                children: [
                  ForestHeader(title: '톡톡 색칠하기', onExit: exit),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ended
                            ? ForestCompletion(
                                avatar: widget.profile.avatar,
                                offscreen: '가족과 함께 색깔을 찾아보며 쉬어요.',
                                quiet: widget.profile.lowStimulation,
                                onHome: exit,
                              )
                            : ForestColoringStudio(
                                initialTemplateIndex:
                                    widget.initialTemplateIndex,
                                quiet: widget.profile.lowStimulation,
                                onChanged: () => checkpoint.event('actions'),
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
