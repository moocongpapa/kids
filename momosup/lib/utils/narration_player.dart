import 'dart:async';

import 'package:flutter/widgets.dart';

import 'audio_output.dart';
import 'audio_policy.dart';

/// Latest instruction wins. Loading is serialized, playback is cancellable,
/// and repeated taps never restart the sentence already being spoken.
class NarrationPlayer with WidgetsBindingObserver {
  NarrationPlayer({
    Future<void> Function(String)? playAsset,
    AudioOutput? output,
  }) : _output = output ?? AssetAudioOutput(playAsset) {
    AudioPolicy.instance.addListener(_policyChanged);
    WidgetsBinding.instance.addObserver(this);
  }
  final AudioOutput _output;
  Future<void> _operations = Future.value();
  Completer<void>? _cancel;
  Object? _speech;
  String? _key;
  bool _disposed = false;
  Future<void> _current = Future.value();

  Future<void> _enqueue(Future<void> Function() work) {
    final next = _operations.then((_) => work());
    _operations = next.catchError((Object _) {});
    return next;
  }

  void _cancelCurrent() {
    final cancel = _cancel;
    _cancel = null;
    _key = null;
    if (cancel != null && !cancel.isCompleted) cancel.complete();
    final speech = _speech;
    _speech = null;
    if (speech != null) AudioPolicy.instance.endSpeech(speech);
  }

  Future<void> stop() {
    _cancelCurrent();
    return _enqueue(_output.stop);
  }

  void _policyChanged() {
    if (!AudioPolicy.instance.canVoice && _cancel != null) {
      unawaited(stop().catchError((Object _) {}));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(stop().catchError((Object _) {}));
    }
  }

  Future<void> speak(List<String> paths) {
    if (_disposed || !AudioPolicy.instance.canVoice || paths.isEmpty) {
      return Future.value();
    }
    final key = paths.join('|');
    if (_key == key && _cancel != null) return _current;
    _cancelCurrent();
    _key = key;
    final cancel = _cancel = Completer<void>();
    final speech = _speech = Object();
    AudioPolicy.instance.beginSpeech(speech);
    _current = _speak(paths, cancel, speech);
    return _current;
  }

  Future<void> _speak(
    List<String> paths,
    Completer<void> cancel,
    Object speech,
  ) async {
    bool current() =>
        !_disposed && !cancel.isCompleted && AudioPolicy.instance.canVoice;
    try {
      for (final path in paths) {
        Future<void>? playing;
        await _enqueue(() async {
          if (!current()) return;
          await _output.stop();
          if (!current()) return;
          await _output.load(path);
          if (!current()) return;
          await _output.volume(AudioPolicy.instance.voiceGain(path));
          if (!current()) return;
          // Install an error handler immediately, before another request can load.
          playing = Future.any([_output.play(), cancel.future]);
          unawaited(playing!.catchError((Object _) {}));
        });
        if (!current()) return;
        await playing;
        if (!current()) return;
      }
    } catch (_) {
      if (current()) rethrow;
    } finally {
      if (identical(_cancel, cancel)) {
        _cancelCurrent();
      } else {
        AudioPolicy.instance.endSpeech(speech);
      }
    }
  }

  void dispose() {
    _disposed = true;
    AudioPolicy.instance.removeListener(_policyChanged);
    WidgetsBinding.instance.removeObserver(this);
    _cancelCurrent();
    unawaited(_enqueue(_output.dispose).catchError((Object _) {}));
  }
}
