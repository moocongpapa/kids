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
  int _revision = 0;
  AudioPlayer get player => _player ??= AudioPlayer();
  @override
  Future<void> load(String value) async {
    _revision++;
    path = value;
    if (callback == null) await player.setAsset(value);
  }

  @override
  Future<void> volume(double value) async {
    if (callback == null) await player.setVolume(value);
  }

  @override
  Future<void> play() async {
    if (callback != null) {
      await callback!(path);
      return;
    }
    final revision = _revision;
    await player.seek(Duration.zero);
    if (revision == _revision) await player.play();
  }

  @override
  Future<void> stop() async {
    _revision++;
    await _player?.stop();
  }

  @override
  Future<void> dispose() async {
    _revision++;
    if (_player != null) await disposeAudioPlayer(_player!);
  }
}
