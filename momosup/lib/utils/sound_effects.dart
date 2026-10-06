import 'dart:async';

import 'package:flutter/widgets.dart';

import 'audio_output.dart';
import 'audio_policy.dart';

/// Immediate tactile feedback, with bounded overlap and no stale queued sounds.
class SoundEffects with WidgetsBindingObserver {
  SoundEffects._({AudioOutput Function()? output, DateTime Function()? now})
    : _output = output ?? (() => AssetAudioOutput(null)),
      _now = now ?? DateTime.now {
    AudioPolicy.instance.addListener(_policyChanged);
    WidgetsBinding.instance.addObserver(this);
  }
  @visibleForTesting
  factory SoundEffects.test({
    required AudioOutput Function() output,
    required DateTime Function() now,
  }) => SoundEffects._(output: output, now: now);
  static final SoundEffects instance = SoundEffects._();
  final AudioOutput Function() _output;
  final DateTime Function() _now;
  final Map<String, AudioOutput> _players = {};
  final Map<String, Future<void>> _loads = {};
  final Map<String, DateTime> _retryAfter = {}, _lastPlayed = {};
  final Map<String, int> _active = {};
  int _request = 0;
  bool _away = false, _disposed = false;

  void _policyChanged() {
    if (!AudioPolicy.instance.canEffects) {
      stopAll();
    } else {
      for (final name in _active.keys) {
        unawaited(
          _players[name]!
              .volume(AudioPolicy.instance.effectGain(name))
              .catchError((Object _) {}),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _away = state != AppLifecycleState.resumed;
    if (_away) stopAll();
  }

  void stopAll() {
    _active.clear();
    for (final player in _players.values) {
      unawaited(player.stop().catchError((Object _) {}));
    }
  }

  Future<void> play(String name) async {
    final now = _now();
    if (_disposed ||
        _away ||
        !AudioPolicy.instance.canEffects ||
        (_retryAfter[name]?.isAfter(now) ?? false) ||
        now.difference(_lastPlayed[name] ?? DateTime(1970)).inMilliseconds <
            100) {
      return;
    }
    _lastPlayed[name] = now;
    final request = ++_request;
    final player = _players.putIfAbsent(name, _output);
    // Three simultaneous sounds at most; a repeated effect replaces itself.
    final evicted = <AudioOutput>[];
    _active.remove(name);
    while (_active.length >= 3) {
      final oldest = _active.keys.first;
      _active.remove(oldest);
      evicted.add(_players[oldest]!);
    }
    _active[name] = request;
    bool current() =>
        !_disposed &&
        !_away &&
        AudioPolicy.instance.canEffects &&
        _active[name] == request;
    try {
      for (final old in evicted) {
        await old.stop();
      }
      await _loads.putIfAbsent(
        name,
        () => player.load('assets/audio/$name.wav'),
      );
      if (!current()) return;
      await player.stop();
      if (!current()) return;
      await player.volume(AudioPolicy.instance.effectGain(name));
      if (!current()) return;
      await player.play();
    } catch (e) {
      _loads.remove(name);
      _retryAfter[name] = _now().add(const Duration(seconds: 2));
      assert(() {
        debugPrint('Sound effect error ($name): $e');
        return true;
      }());
    } finally {
      if (_active[name] == request) _active.remove(name);
    }
  }

  Future<void> playNote(int index) => play('sfx_note_${index.clamp(0, 7)}');
  Future<void> playSuccessPitch(int streak) => playNote(streak.clamp(0, 7));
  int _musicalStep = 0;
  Future<void> musicalTap() {
    _musicalStep = (_musicalStep + 1) % 5;
    const pentatonic = [0, 1, 2, 4, 5];
    return playNote(pentatonic[_musicalStep]);
  }
  Future<void> pop() => play('sfx_pop');
  Future<void> chew() => play('sfx_chew');
  Future<void> snap() => play('sfx_snap');
  Future<void> boing() => play('sfx_boing');
  Future<void> tada() => play('sfx_tada');
  Future<void> whoosh() => play('sfx_whoosh');
  void dispose() {
    _disposed = true;
    AudioPolicy.instance.removeListener(_policyChanged);
    WidgetsBinding.instance.removeObserver(this);
    stopAll();
    for (final player in _players.values) {
      unawaited(player.dispose().catchError((Object _) {}));
    }
    _players.clear();
    _loads.clear();
  }
}
