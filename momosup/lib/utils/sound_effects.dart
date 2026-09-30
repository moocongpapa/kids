import 'audio_cleanup.dart';

import 'package:flutter/foundation.dart';

import 'audio_policy.dart';

import 'package:just_audio/just_audio.dart';

/// Lightweight sound effects player for tactile toddler games.
class SoundEffects {
  SoundEffects._() {
    AudioPolicy.instance.addListener(() {
      if (!AudioPolicy.instance.canEffects) {
        for (final p in _players.values) {
          p.stop().catchError((Object _) {});
        }
      }
    });
  }
  static final SoundEffects instance = SoundEffects._();

  final Map<String, AudioPlayer> _players = {};
  final Map<String, Future<void>> _loads = {};
  final Map<String, DateTime> _retryAfter = {};

  Future<void> play(String name) async {
    if (!AudioPolicy.instance.canEffects ||
        (_retryAfter[name]?.isAfter(DateTime.now()) ?? false)) {
      return;
    }
    try {
      final assetPath = 'assets/audio/$name.wav';
      final player = _players.putIfAbsent(name, AudioPlayer.new);
      await _loads.putIfAbsent(name, () async {
        await player.setAsset(assetPath);
      });
      if (!AudioPolicy.instance.canEffects) return;
      await player.setVolume(.55);
      await player.seek(Duration.zero);
      await player.play();
    } catch (e) {
      _loads.remove(name);
      _retryAfter[name] = DateTime.now().add(const Duration(seconds: 2));
      if (kDebugMode) {
        debugPrint('Sound effect error ($name): $e');
      }
    }
  }

  Future<void> playNote(int index) => play('sfx_note_${index.clamp(0, 7)}');
  Future<void> pop() => play('sfx_pop');
  Future<void> chew() => play('sfx_chew');
  Future<void> snap() => play('sfx_snap');
  Future<void> boing() => play('sfx_boing');
  Future<void> tada() => play('sfx_tada');
  Future<void> whoosh() => play('sfx_whoosh');

  void dispose() {
    for (final player in _players.values) {
      disposeAudioPlayer(player);
    }
    _players.clear();
  }
}
