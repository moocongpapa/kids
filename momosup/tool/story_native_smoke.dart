// Developer-only native codec smoke test; no child profile or API key is used.
// flutter run -t tool/story_native_smoke.dart -d <simulator>
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:momosup/data/story_repository.dart';
import 'package:video_player/video_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: Smoke()));
}

class Smoke extends StatefulWidget {
  const Smoke({super.key});
  @override
  State<Smoke> createState() => _SmokeState();
}

class _SmokeState extends State<Smoke> {
  VideoPlayerController? video;
  String status = 'Loading';
  @override
  void initState() {
    super.initState();
    unawaited(run());
  }

  Future<void> run() async {
    try {
      final stories = await const StoryRepository().load(includePreviews: true);
      if (stories.length != 3) {
        throw StateError('Expected three films/previews');
      }
      for (final e in stories) {
        final c = VideoPlayerController.asset(e.videoAsset);
        video = c;
        await c.initialize();
        await c.setLooping(false);
        await c.setVolume(1);
        setState(() => status = e.title);
        await c.play();
        await Future<void>.delayed(const Duration(seconds: 3));
        final at = await c.position;
        await c.pause();
        if (at == null ||
            at.inMilliseconds < 500 ||
            c.value.hasError ||
            c.value.isPlaying) {
          throw StateError('Native playback failed: ${e.id}');
        }
        debugPrint(
          'NATIVE_STORY ${jsonEncode({'id': e.id, 'durationMs': c.value.duration.inMilliseconds, 'playedMs': at.inMilliseconds, 'paused': !c.value.isPlaying, 'size': '${c.value.size.width}x${c.value.size.height}'})}',
        );
        video = null;
        setState(() {});
        await c.dispose();
      }
      setState(() => status = 'NATIVE_STORY_ALL_PASSED');
      debugPrint(status);
    } catch (e) {
      setState(() => status = 'NATIVE_STORY_FAILED: $e');
      debugPrint(status);
    }
  }

  @override
  void dispose() {
    video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF102B28),
    body: SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (video?.value.isInitialized == true)
            AspectRatio(
              aspectRatio: video!.value.aspectRatio,
              child: VideoPlayer(video!),
            ),
          Text(status, style: const TextStyle(color: Colors.white)),
        ],
      ),
    ),
  );
}
