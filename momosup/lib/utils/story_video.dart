import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

/// Native playback with a replaceable boundary for lifecycle/time-limit tests.
abstract class StoryVideo extends ChangeNotifier {
  bool get ready;
  bool get playing;
  bool get buffering;
  Duration get position;
  Duration get duration;
  String? get error;
  Future<void> initialize();
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> volume(double value);
  Widget picture();
}

class AssetStoryVideo extends StoryVideo {
  AssetStoryVideo(String asset)
    : controller = VideoPlayerController.asset(
        asset,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      ) {
    controller.addListener(notifyListeners);
  }
  final VideoPlayerController controller;
  @override
  bool get ready => controller.value.isInitialized;
  @override
  bool get playing => controller.value.isPlaying;
  @override
  bool get buffering => controller.value.isBuffering;
  @override
  Duration get position => controller.value.position;
  @override
  Duration get duration => controller.value.duration;
  @override
  String? get error => controller.value.errorDescription;
  @override
  Future<void> initialize() async {
    await controller.initialize();
    await controller.setLooping(false);
  }

  @override
  Future<void> play() => controller.play();
  @override
  Future<void> pause() => controller.pause();
  @override
  Future<void> seek(Duration position) => controller.seekTo(position);
  @override
  Future<void> volume(double value) => controller.setVolume(value);
  @override
  Widget picture() => AspectRatio(
    aspectRatio: controller.value.aspectRatio,
    child: VideoPlayer(controller),
  );
  @override
  void dispose() {
    controller.removeListener(notifyListeners);
    controller.dispose();
    super.dispose();
  }
}
