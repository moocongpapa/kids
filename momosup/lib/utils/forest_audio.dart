import 'dart:async';

import 'audio_policy.dart';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Forest ambience & background music controller.
/// Provides a soothing, immersive forest soundscape with birds and gentle melodies.
class ForestAudio {
  ForestAudio._() {
    AudioPolicy.instance.addListener(() {
      if (!AudioPolicy.instance.canMusic) pauseBgm();
    });
  }
  static final ForestAudio instance = ForestAudio._();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final ValueNotifier<bool> isMuted = ValueNotifier<bool>(false);
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _enabled = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _bgmPlayer.setAsset('assets/audio/bgm_forest.wav');
      await _bgmPlayer.setLoopMode(LoopMode.all);
      await _bgmPlayer.setVolume(0.40);
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ForestAudio init error: $e');
      }
    }
  }

  Future<void> startBgm({bool enabled = true}) async {
    _enabled = enabled;
    if (!enabled || !AudioPolicy.instance.canMusic) {
      await stopBgm();
      return;
    }
    try {
      if (!_isInitialized) await init();
      if (!_isInitialized || !AudioPolicy.instance.canMusic || !_enabled) {
        return;
      }
      if (!_isPlaying) {
        _isPlaying = true;
        unawaited(
          _bgmPlayer.play().catchError((Object error) {
            _isPlaying = false;
            if (kDebugMode) debugPrint('ForestAudio playback error: $error');
          }),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ForestAudio start error: $e');
      }
    }
  }

  Future<void> pauseBgm() async {
    _enabled = false;
    try {
      if (_isPlaying) {
        await _bgmPlayer.pause();
        _isPlaying = false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ForestAudio pause error: $e');
      }
    }
  }

  Future<void> stopBgm() async {
    _enabled = false;
    if (!_isInitialized) return;
    try {
      await _bgmPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ForestAudio stop error: $e');
      }
    }
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    AudioPolicy.instance.mute(isMuted.value);
    if (isMuted.value) {
      stopBgm();
    } else {
      startBgm();
    }
  }

  void dispose() {
    _bgmPlayer.dispose();
    isMuted.dispose();
  }
}
