import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/forest_game_ui.dart';
import 'audio_policy.dart';

/// Active play time only; leaving the app always requires an explicit resume.
class PlaySession extends ChangeNotifier with WidgetsBindingObserver {
  PlaySession({
    required this.limitSeconds,
    required this.onExpire,
    required this.onPause,
    required this.onResume,
    required this.onCheckpoint,
    Stopwatch? stopwatch,
  }) : watch = stopwatch ?? Stopwatch() {
    WidgetsBinding.instance.addObserver(this);
  }
  final int limitSeconds;
  final VoidCallback onExpire, onPause, onResume;
  final Future<void> Function(int seconds) onCheckpoint;
  final Stopwatch watch;
  Timer? _timer;
  bool started = false, paused = false, ended = false, _disposed = false;
  String? saveError;
  void reportSaveError() {
    saveError = '저장하지 못했어요. 다시 시도해 주세요.';
    if (!_disposed) notifyListeners();
  }

  int get seconds => watch.elapsed.inSeconds;
  int get remaining =>
      (limitSeconds - seconds).clamp(0, limitSeconds < 0 ? 0 : limitSeconds);
  void start() {
    if (started || ended) return;
    if (limitSeconds <= 0) {
      onExpire();
      return;
    }
    started = true;
    AudioPolicy.instance.suspend(false);
    watch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (paused || ended) return;
      if (remaining == 0) {
        onExpire();
        return;
      }
      if (seconds % 15 == 0) checkpoint();
      if (remaining <= 20) notifyListeners();
    });
  }

  Future<void> checkpoint() async {
    try {
      await onCheckpoint(seconds);
      saveError = null;
    } catch (_) {
      saveError = '저장하지 못했어요. 다시 시도해 주세요.';
    }
    if (!_disposed) notifyListeners();
  }

  void pause() {
    if (paused || ended) return;
    paused = true;
    watch.stop();
    AudioPolicy.instance.suspend(true);
    onPause();
    checkpoint();
    notifyListeners();
  }

  void resume() {
    if (!paused || ended) return;
    paused = false;
    AudioPolicy.instance.suspend(false);
    if (started) watch.start();
    onResume();
    notifyListeners();
  }

  void finish() {
    if (ended) return;
    ended = true;
    paused = false;
    watch.stop();
    _timer?.cancel();
    checkpoint();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) pause();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    watch.stop();
    if (started && !ended) {
      onCheckpoint(seconds).catchError((Object error) {
        debugPrint('Final play checkpoint failed: $error');
      });
    }
    WidgetsBinding.instance.removeObserver(this);
    AudioPolicy.instance.suspend(false);
    super.dispose();
  }
}

class PlaySessionView extends StatelessWidget {
  const PlaySessionView({
    required this.session,
    required this.child,
    super.key,
  });
  final PlaySession session;
  final Widget child;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (_, _) => Stack(
      children: [
        TickerMode(
          enabled: !session.paused,
          child: IgnorePointer(ignoring: session.paused, child: child),
        ),
        if (!session.paused &&
            !session.ended &&
            session.started &&
            session.remaining <= 20)
          Positioned(
            top: 80,
            right: 16,
            child: IgnorePointer(
              child: Semantics(
                label: '곧 쉬는 시간이에요',
                child: Icon(Icons.bedtime_rounded, size: 38, color: forestInk),
              ),
            ),
          ),
        if (session.paused)
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xEFEEF2DC),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bedtime_rounded,
                      size: 72,
                      color: forestInk,
                    ),
                    const SizedBox(height: 24),
                    ForestAction(
                      label: '이어서 놀기',
                      size: 104,
                      leaf: true,
                      quiet: true,
                      icon: Icons.play_arrow_rounded,
                      onPressed: session.resume,
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (session.saveError != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Material(
              color: forestCream,
              child: TextButton.icon(
                onPressed: session.checkpoint,
                icon: const Icon(Icons.save_rounded),
                label: Text(session.saveError!),
              ),
            ),
          ),
      ],
    ),
  );
}
