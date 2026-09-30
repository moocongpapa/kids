import 'dart:async';

import 'package:flutter/widgets.dart';

import 'audio_output.dart';
import 'audio_policy.dart';

/// A screen-owned background loop. Speech ducks it; leaving or finishing the
/// toy cancels pending loads too. Xylophone intentionally supplies no track.
class ToyMusicPlayer with WidgetsBindingObserver {
  ToyMusicPlayer({AudioOutput? output, this.speechGain = .08})
    : output = output ?? AssetAudioOutput(null) {
    AudioPolicy.instance.addListener(_sync);
    WidgetsBinding.instance.addObserver(this);
  }
  final AudioOutput output;
  final double speechGain;
  double get _gain => AudioPolicy.instance.speaking
      ? speechGain.clamp(0.0, 1.0)
      : AudioPolicy.instance.musicGain;
  String? _path;
  bool _wanted = false, _away = false, _disposed = false, _running = false;
  int _request = 0;
  Future<void> _operations = Future.value();
  Future<void> _enqueue(Future<void> Function() fn) {
    final next = _operations.then((_) => fn());
    _operations = next.catchError((Object _) {});
    return next;
  }

  void start(String? path) {
    if (_path != path) _halt();
    _path = path;
    _wanted = path != null;
    _sync();
  }

  void _halt() {
    _request++;
    _running = false;
    unawaited(_enqueue(output.stop).catchError((Object _) {}));
  }

  void stop() {
    _wanted = false;
    _halt();
  }

  void _sync() {
    if (_disposed) return;
    if (!_wanted || _away || !AudioPolicy.instance.canMusic) {
      if (_running) _halt();
      return;
    }
    if (_running) {
      unawaited(output.volume(_gain).catchError((Object _) {}));
    } else {
      unawaited(_loop());
    }
  }

  Future<void> _loop() async {
    final request = ++_request;
    final path = _path!;
    _running = true;
    bool current() =>
        !_disposed &&
        request == _request &&
        _wanted &&
        !_away &&
        AudioPolicy.instance.canMusic;
    try {
      await _enqueue(() async {
        if (current()) await output.load(path);
      });
      while (current()) {
        Future<void>? playing;
        await _enqueue(() async {
          if (!current()) return;
          await output.volume(_gain);
          if (current()) {
            playing = output.play();
            unawaited(playing!.catchError((Object _) {}));
          }
        });
        if (!current()) return;
        await playing;
      }
    } catch (error) {
      if (current()) {
        _wanted = false;
        assert(() {
          debugPrint('Toy music unavailable: $error');
          return true;
        }());
      }
    } finally {
      if (request == _request) _running = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _away = state != AppLifecycleState.resumed;
    _sync();
  }

  void dispose() {
    _disposed = true;
    AudioPolicy.instance.removeListener(_sync);
    WidgetsBinding.instance.removeObserver(this);
    stop();
    unawaited(_enqueue(output.dispose).catchError((Object _) {}));
  }
}
