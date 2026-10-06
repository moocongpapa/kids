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
    this.splitLongSessions = false,
    this.onError,
  });
  final AppState state;
  final String profileId, activityId;
  final Map<String, dynamic> Function() snapshot;
  final bool preview;

  /// Free play can exceed AppState's seven-minute bound for a single record.
  /// Store cumulative time in stable chunks without changing the daily limit.
  final bool splitLongSessions;
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

  Future<void> _checkpointWrites = Future.value();
  Future<void> checkpoint(int seconds) {
    if (!splitLongSessions) return _checkpoint(seconds);
    // A later cumulative total must never be overwritten by an older chunk.
    final next = _checkpointWrites
        .catchError((Object _) {})
        .then((_) => _checkpoint(seconds));
    _checkpointWrites = next;
    return next;
  }

  Future<void> _checkpoint(int seconds) async {
    if (preview) return;
    await flush();
    if (seconds > 0) {
      const recordLimitSeconds = 7 * 60;
      final chunkSize = splitLongSessions ? recordLimitSeconds : seconds;
      for (var offset = 0; offset < seconds; offset += chunkSize) {
        final chunk = offset ~/ chunkSize;
        await state.recordPlay(
          profileId: profileId,
          activityId: activityId,
          seconds: (seconds - offset).clamp(0, chunkSize),
          sessionId: chunk == 0 ? sessionId : '$sessionId:$chunk',
          // Session metrics belong to the first chunk only.
          metrics: chunk == 0 ? metrics : const {},
        );
      }
    }
  }

  void dispose() {
    timer?.cancel();
  }
}
