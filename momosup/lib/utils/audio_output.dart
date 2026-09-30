import 'package:just_audio/just_audio.dart';

import 'audio_cleanup.dart';

/// A small seam for testing real load/play/stop ordering without a device.
abstract interface class AudioOutput {
  Future<void> load(String path);
  Future<void> volume(double value);
  Future<void> play();
  Future<void> stop();
  Future<void> dispose();
}

class AssetAudioOutput implements AudioOutput {
  AssetAudioOutput(this.callback);
  final Future<void> Function(String)? callback;
  AudioPlayer? _player;
  String path = '';
  AudioPlayer get player => _player ??= AudioPlayer();
  @override
  Future<void> load(String value) async {
    path = value;
    if (callback == null) await player.setAsset(value);
  }

  @override
  Future<void> volume(double value) async {
    if (callback == null) await player.setVolume(value);
  }

  @override
  Future<void> play() => callback == null ? player.play() : callback!(path);
  @override
  Future<void> stop() async {
    await _player?.stop();
  }

  @override
  Future<void> dispose() async {
    if (_player != null) await disposeAudioPlayer(_player!);
  }
}
