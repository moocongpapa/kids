import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/child_profile.dart';
import '../models/story_episode.dart';
import '../state/app_state.dart';
import '../utils/audio_policy.dart';
import '../utils/story_playback.dart';
import '../utils/story_video.dart';
import '../widgets/forest_game_ui.dart';

class StoryPlayerScreen extends StatefulWidget {
  const StoryPlayerScreen({
    required this.episode,
    required this.profile,
    required this.appState,
    this.preview = false,
    this.playback,
    super.key,
  });
  final StoryEpisode episode;
  final ChildProfile profile;
  final AppState appState;
  final bool preview;
  final StoryPlayback? playback;
  @override
  State<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends State<StoryPlayerScreen> {
  late final StoryPlayback player;
  @override
  void initState() {
    super.initState();
    player =
        widget.playback ??
        StoryPlayback(
          episode: widget.episode,
          profile: widget.profile,
          appState: widget.appState,
          preview: widget.preview,
          video: AssetStoryVideo(widget.episode.videoAsset),
        );
    player.initialize();
  }

  @override
  void dispose() {
    player.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF102B28),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: player,
        builder: (_, _) {
          if (player.ended) return _ending();
          return LayoutBuilder(
            builder: (context, constraints) {
              final landscape = constraints.maxWidth > constraints.maxHeight;
              final video = Stack(
                alignment: Alignment.center,
                children: [
                  if (player.video.ready)
                    player.video.picture()
                  else
                    Image.asset(
                      widget.episode.posterAsset,
                      fit: BoxFit.contain,
                    ),
                  if (player.loading || player.video.buffering)
                    Semantics(
                      label: '이야기 준비 중',
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: CircularProgressIndicator(
                          color: Color(0xFFF5DFAC),
                        ),
                      ),
                    ),
                  if (!player.loading &&
                      player.paused &&
                      player.failure == null)
                    ForestAction(
                      label: '이야기 이어 보기',
                      icon: Icons.play_arrow_rounded,
                      size: 96,
                      quiet: true,
                      leaf: true,
                      onPressed: player.play,
                    ),
                  if (player.failure != null)
                    Container(
                      color: const Color(0xDE102B28),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_florist,
                            color: forestCream,
                            size: 48,
                          ),
                          Text(
                            player.failure!,
                            style: const TextStyle(color: forestCream),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              '이야기숲으로 돌아가기',
                              style: TextStyle(color: forestCream),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
              final controls = _controls();
              return Stack(
                children: [
                  if (landscape)
                    Center(child: video)
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 75, 24, 22),
                          child: Text(
                            widget.episode.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: forestCream,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        video,
                        const SizedBox(height: 24),
                        controls,
                        const SizedBox(height: 24),
                        const Icon(
                          Icons.spa_outlined,
                          color: Color(0xFF688C71),
                          size: 36,
                        ),
                      ],
                    ),
                  Positioned(
                    left: 12,
                    top: 10,
                    child: ForestAction(
                      label: '이야기 닫기',
                      icon: Icons.close_rounded,
                      size: 64,
                      quiet: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  if (widget.preview)
                    const Positioned(
                      top: 25,
                      right: 92,
                      child: Text(
                        '보호자 미리보기',
                        style: TextStyle(color: forestCream),
                      ),
                    ),
                  if (landscape)
                    Positioned(left: 82, right: 16, bottom: 8, child: controls),
                  Positioned(
                    top: 10,
                    right: 12,
                    child: ForestAction(
                      label: landscape ? '세로로 보기' : '가로 전체 화면',
                      icon: landscape
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                      size: 64,
                      quiet: true,
                      onPressed: () => SystemChrome.setPreferredOrientations(
                        landscape
                            ? [DeviceOrientation.portraitUp]
                            : [
                                DeviceOrientation.landscapeLeft,
                                DeviceOrientation.landscapeRight,
                              ],
                      ),
                    ),
                  ),
                  if (player.saveFailed)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: TextButton(
                        onPressed: player.checkpoint,
                        child: const Text(
                          '시청 기록 저장 다시 시도',
                          style: TextStyle(color: forestCream),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    ),
  );
  Widget _controls() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: Row(
      children: [
        ForestAction(
          label: player.paused ? '이야기 재생' : '이야기 잠깐 멈추기',
          icon: player.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          size: 64,
          quiet: true,
          leaf: true,
          onPressed: player.loading || player.failure != null
              ? null
              : () => player.paused ? player.play() : player.pause(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Semantics(
            label: '이야기 진행',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: player.video.duration.inMilliseconds > 0
                    ? (player.video.position.inMilliseconds /
                              player.video.duration.inMilliseconds)
                          .clamp(0, 1)
                    : 0,
                backgroundColor: const Color(0xFF36564B),
                color: const Color(0xFFF0D293),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        ListenableBuilder(
          listenable: AudioPolicy.instance,
          builder: (_, _) => ForestAction(
            label: AudioPolicy.instance.muted ? '이야기 소리 켜기' : '이야기 소리 끄기',
            icon: AudioPolicy.instance.muted
                ? Icons.volume_off_rounded
                : Icons.volume_up_rounded,
            size: 64,
            quiet: true,
            onPressed: player.toggleMute,
          ),
        ),
      ],
    ),
  );
  Widget _ending() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            player.expired ? Icons.bedtime_rounded : Icons.spa_rounded,
            size: 72,
            color: const Color(0xFFF0D293),
          ),
          const SizedBox(height: 20),
          Text(
            player.expired
                ? '숲도 쉬는 시간'
                : widget.episode.productionPreview
                ? '미리보기 끝'
                : '이야기 끝, 우리 차례!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: forestCream,
            ),
          ),
          const SizedBox(height: 20),
          if (widget.preview)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                widget.episode.parentPrompt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: forestCream,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ),
          ForestAction(
            label: '이야기숲으로 돌아가기',
            icon: Icons.forest_rounded,
            size: 104,
            quiet: true,
            leaf: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}
