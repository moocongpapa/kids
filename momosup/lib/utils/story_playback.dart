import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/child_profile.dart';
import '../models/story_episode.dart';
import '../state/app_state.dart';
import 'audio_policy.dart';
import 'forest_audio.dart';
import 'story_video.dart';
import 'toy_music_player.dart';

/// Counts actual foreground playback, excluding pause/loading/buffering.
/// Preview never writes child records. Resuming after an interruption is explicit.
class StoryPlayback extends ChangeNotifier with WidgetsBindingObserver {
  StoryPlayback({
    required this.episode,
    required this.profile,
    required this.appState,
    required this.video,
    this.preview = false,
    ToyMusicPlayer? music,
    Stopwatch? watch,
  }) : music =
           music ??
           ToyMusicPlayer(speechGain: profile.lowStimulation ? .12 : .22),
       watch = watch ?? Stopwatch() {
    limitSeconds = preview
        ? 420
        : math.min(
            420,
            appState.secondsRemaining(profile.id, profile.dailyLimitMinutes),
          );
    video.addListener(_videoChanged);
    AudioPolicy.instance.addListener(_audioChanged);
    WidgetsBinding.instance.addObserver(this);
  }
  final StoryEpisode episode;
  final ChildProfile profile;
  final AppState appState;
  final StoryVideo video;
  final ToyMusicPlayer music;
  final Stopwatch watch;
  final bool preview;
  final String sessionId = 'story_${DateTime.now().microsecondsSinceEpoch}';
  late final int limitSeconds;
  bool loading = true, paused = true, ended = false, expired = false;
  bool saveFailed = false,
      _disposed = false,
      _away = false,
      _everPlayed = false;
  String? failure;
  Timer? _timer;
  int _lastCheckpoint = 0, _revision = 0;
  bool _musicRunning = false;
  Future<void> _writes = Future.value();
  final Object _speechToken = Object();
  int get seconds => watch.elapsed.inSeconds;
  bool get canStart =>
      preview || (episode.availableFor(profile) && limitSeconds > 0);
  bool get activelyPlaying =>
      !loading &&
      !paused &&
      !ended &&
      !_away &&
      video.playing &&
      !video.buffering &&
      failure == null;

  Future<void> initialize() async {
    final revision = ++_revision;
    if (!canStart) {
      loading = false;
      expired = limitSeconds <= 0;
      ended = true;
      notifyListeners();
      return;
    }
    await ForestAudio.instance.pauseBgm();
    if (_disposed || revision != _revision) return;
    try {
      await video.initialize().timeout(const Duration(seconds: 30));
      if (_disposed || revision != _revision) return;
      final saved = preview
          ? <String, dynamic>{}
          : appState.storyProgress(profile.id, episode.id);
      final position = saved['complete'] == true
          ? 0
          : (saved['positionMs'] as int? ?? 0);
      if (position > 0 && position < video.duration.inMilliseconds - 1000) {
        await video.seek(Duration(milliseconds: position));
      }
      if (_disposed || revision != _revision) return;
      loading = false;
      _timer = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => _tick(),
      );
      _audioChanged();
      notifyListeners();
      // The user selected the story, but an intervening background event cancels start.
      if (!_away) await play();
    } catch (_) {
      if (!_disposed) {
        loading = false;
        failure = '영상을 열지 못했어요';
        notifyListeners();
      }
    }
  }

  Future<void> play() async {
    if (_disposed || loading || ended || _away || failure != null) return;
    if (!canStart || seconds >= limitSeconds) {
      finish(timeLimit: true);
      return;
    }
    paused = false;
    _everPlayed = true;
    _audioChanged();
    notifyListeners();
    try {
      await video.play();
      if (_disposed) return;
      if (paused || ended || _away) await video.pause();
      _videoChanged();
    } catch (_) {
      _fail();
    }
  }

  Future<void> pause() async {
    if (_disposed || ended) return;
    paused = true;
    _reconcile();
    notifyListeners();
    unawaited(checkpoint());
    try {
      await video.pause();
    } catch (_) {
      _fail();
    }
  }

  void _fail() {
    if (_disposed) return;
    paused = true;
    failure = '영상 재생이 멈췄어요';
    _reconcile();
    notifyListeners();
  }

  void _videoChanged() {
    if (_disposed) return;
    if (video.error != null && failure == null) {
      _fail();
      return;
    }
    if (_everPlayed &&
        !ended &&
        video.ready &&
        video.duration.inMilliseconds > 0 &&
        video.position.inMilliseconds >= video.duration.inMilliseconds - 100) {
      finish();
      return;
    }
    _reconcile();
    notifyListeners();
  }

  void _tick() {
    if (_disposed || ended) return;
    _reconcile();
    if (seconds >= limitSeconds) {
      finish(timeLimit: true);
      return;
    }
    if (seconds - _lastCheckpoint >= 10) {
      _lastCheckpoint = seconds;
      unawaited(checkpoint());
    }
  }

  void _reconcile() {
    if (activelyPlaying) {
      watch.start();
    } else {
      watch.stop();
    }
    final wanted =
        activelyPlaying &&
        episode.musicAsset.isNotEmpty &&
        AudioPolicy.instance.canMusic;
    if (wanted != _musicRunning) {
      _musicRunning = wanted;
      if (wanted) {
        music.start(episode.musicAsset);
      } else {
        music.stop();
      }
    }
    if (activelyPlaying && AudioPolicy.instance.canVoice) {
      if (!AudioPolicy.instance.speaking) {
        AudioPolicy.instance.beginSpeech(_speechToken);
      }
    } else {
      AudioPolicy.instance.endSpeech(_speechToken);
    }
  }

  void _audioChanged() {
    if (_disposed) return;
    if (video.ready) {
      unawaited(
        video
            .volume(
              AudioPolicy.instance.canVoice && !_away && !paused
                  ? (profile.lowStimulation ? .8 : 1)
                  : 0,
            )
            .catchError((Object _) {}),
      );
    }
    _reconcile();
  }

  void toggleMute() => AudioPolicy.instance.mute(!AudioPolicy.instance.muted);
  void finish({bool timeLimit = false}) {
    if (_disposed || ended) return;
    ended = true;
    paused = true;
    expired = timeLimit;
    _timer?.cancel();
    _reconcile();
    _audioChanged();
    unawaited(video.pause().catchError((Object _) {}));
    unawaited(checkpoint(complete: !timeLimit));
    notifyListeners();
  }

  Future<void> checkpoint({bool? complete}) {
    if (preview || !_everPlayed) return Future.value();
    final elapsed = seconds.clamp(0, limitSeconds);
    final position = video.position.inMilliseconds;
    final completed = complete ?? (ended && !expired);
    final task = _writes.catchError((Object _) {}).then((_) async {
      await appState.recordPlay(
        profileId: profile.id,
        activityId: episode.id,
        seconds: elapsed,
        sessionId: sessionId,
        metrics: {'storyVideo': 1},
      );
      await appState.saveStoryProgress(
        profile.id,
        episode.id,
        positionMs: position,
        complete: completed,
      );
    });
    _writes = task;
    return task
        .then((_) {
          if (!_disposed) {
            saveFailed = false;
            notifyListeners();
          }
        })
        .catchError((Object _) {
          if (!_disposed) {
            saveFailed = true;
            notifyListeners();
          }
        });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _away = state != AppLifecycleState.resumed;
    if (_away) {
      unawaited(pause());
    }
    // Never resume automatically, even if initialization completed in background.
  }

  @override
  void dispose() {
    if (!ended) {
      watch.stop();
      unawaited(checkpoint());
    }
    _disposed = true;
    _revision++;
    _timer?.cancel();
    watch.stop();
    video.removeListener(_videoChanged);
    AudioPolicy.instance.removeListener(_audioChanged);
    WidgetsBinding.instance.removeObserver(this);
    AudioPolicy.instance.endSpeech(_speechToken);
    music.dispose();
    video.dispose();
    super.dispose();
  }
}
