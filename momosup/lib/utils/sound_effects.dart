import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Lightweight sound effects player for tactile toddler games.
class SoundEffects {
  SoundEffects._();
  static final SoundEffects instance = SoundEffects._();

  final Map<String, AudioPlayer> _players = {};

  Future<void> play(String name) async {
    try {
      final assetPath = 'assets/audio/$name.wav';
      AudioPlayer? player = _players[name];
      if (player == null) {
        player = AudioPlayer();
        await player.setAsset(assetPath);
        _players[name] = player;
      }
      await player.seek(Duration.zero);
      await player.play();
    } catch (e) {
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
      player.dispose();
    }
    _players.clear();
  }
}
