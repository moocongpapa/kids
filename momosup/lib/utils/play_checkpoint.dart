import 'dart:async';

import '../state/app_state.dart';

/// Serialised, debounced draft writes; failed saves remain retryable.
class PlayCheckpoint {
  PlayCheckpoint(
    this.state,
    this.profileId,
    this.activityId,
    this.snapshot, {
    this.preview = false,
    this.onError,
  });
  final AppState state;
  final String profileId, activityId;
  final Map<String, dynamic> Function() snapshot;
  final bool preview;
  final void Function()? onError;
  final Map<String, int> metrics = {};
  void event(String name) {
    metrics[name] = (metrics[name] ?? 0) + 1;
  }

  Timer? timer;
  String? error;
  final sessionId = DateTime.now().microsecondsSinceEpoch.toString();
  void changed() {
    if (preview) return;
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 600), () async {
      try {
        await flush();
      } catch (_) {
        onError?.call();
      }
    });
  }

  Future<void> flush() async {
    timer?.cancel();
    if (preview) return;
    try {
      await state.saveWork(profileId, activityId, snapshot());
      error = null;
    } catch (_) {
      error = '작품 저장을 다시 시도해 주세요.';
      rethrow;
    }
  }

  Future<void> checkpoint(int seconds) async {
    if (preview) return;
    await flush();
    if (seconds > 0) {
      await state.recordPlay(
        profileId: profileId,
        activityId: activityId,
        seconds: seconds,
        sessionId: sessionId,
        metrics: metrics,
      );
    }
  }

  void dispose() {
    timer?.cancel();
  }
}
