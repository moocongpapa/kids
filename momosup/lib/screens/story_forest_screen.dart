import '../utils/forest_orientation.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../data/story_repository.dart';
import '../models/child_profile.dart';
import '../models/story_episode.dart';
import '../state/app_state.dart';
import '../utils/forest_audio.dart';
import '../utils/audio_policy.dart';
import '../utils/narration_player.dart';
import '../widgets/forest_game_ui.dart';
import 'story_player_screen.dart';

/// The child chooses a large illustrated stage; no video autoplays in the shelf.
class StoryForestScreen extends StatefulWidget {
  const StoryForestScreen({
    required this.appState,
    required this.profile,
    this.preview = false,
    this.episodes,
    this.playAsset,
    this.loadStories,
    super.key,
  });
  final AppState appState;
  final ChildProfile profile;
  final bool preview;
  final List<StoryEpisode>? episodes;
  final Future<void> Function(String)? playAsset;
  final Future<List<StoryEpisode>> Function()? loadStories;
  @override
  State<StoryForestScreen> createState() => _StoryForestScreenState();
}

class _StoryForestScreenState extends State<StoryForestScreen> {
  late Future<List<StoryEpisode>> stories;
  late final NarrationPlayer voice;
  final pages = PageController();
  int selected = 0;
  bool favoritesOnly = false, opening = false;
  @override
  void initState() {
    super.initState();
    stories = _loadStories();
    voice = NarrationPlayer(playAsset: widget.playAsset);
    unawaited(ForestAudio.instance.pauseBgm());
  }

  Future<List<StoryEpisode>> _loadStories() =>
      widget.loadStories?.call() ??
      (widget.episodes != null
          ? Future.value(widget.episodes)
          : const StoryRepository().load(includePreviews: widget.preview));

  @override
  void dispose() {
    pages.dispose();
    voice.dispose();
    super.dispose();
  }

  void announce(StoryEpisode e) =>
      unawaited(voice.speak([e.titleAudioAsset]).catchError((Object _) {}));
  Future<void> open(StoryEpisode e) async {
    if (opening) return;
    setState(() => opening = true);
    await voice.stop();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => StoryPlayerScreen(
          episode: e,
          profile: widget.profile,
          appState: widget.appState,
          preview: widget.preview,
        ),
      ),
    );
    if (mounted) setState(() => opening = false);
  }

  @override
  Widget build(BuildContext context) => ForestOrientationScope(
    child: FutureBuilder<List<StoryEpisode>>(
      future: stories,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () {
                final retry = _loadStories();
                setState(() {
                  stories = retry;
                });
              },
              child: const Text('이야기를 준비하지 못했어요'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListenableBuilder(
          listenable: widget.appState,
          builder: (_, _) {
            final available = widget.preview
                ? snapshot.data!
                : StoryRepository.forProfile(snapshot.data!, widget.profile);
            final items = favoritesOnly
                ? available
                      .where(
                        (e) =>
                            widget.appState.storyProgress(
                              widget.profile.id,
                              e.id,
                            )['favorite'] ==
                            true,
                      )
                      .toList()
                : available;
            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_stories_rounded,
                      size: 72,
                      color: forestInk,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      favoritesOnly ? '좋아하는 이야기를 담아 주세요' : '새로운 이야기를 만들고 있어요',
                    ),
                    if (favoritesOnly)
                      TextButton(
                        onPressed: () => setState(() {
                          favoritesOnly = false;
                          selected = 0;
                        }),
                        child: const Text('모든 이야기'),
                      ),
                  ],
                ),
              );
            }
            final index = selected.clamp(0, items.length - 1),
                current = items[index];
            return LayoutBuilder(
              builder: (context, box) {
                final short = box.maxHeight < 370;
                final gallery = PageView.builder(
                  controller: pages,
                  itemCount: items.length,
                  onPageChanged: (i) {
                    setState(() => selected = i);
                    announce(items[i]);
                  },
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: AspectRatio(
                          aspectRatio: 16 / 10,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipPath(
                                clipper: _TheatreArch(),
                                child: Semantics(
                                  button: true,
                                  label: '${items[i].title} 보기',
                                  child: GestureDetector(
                                    onTap: opening
                                        ? null
                                        : () => open(items[i]),
                                    child: Image.asset(
                                      items[i].posterAsset,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              IgnorePointer(
                                child: CustomPaint(painter: _TheatreFrame()),
                              ),
                              Positioned(
                                bottom: 12,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: ForestAction(
                                    label: _canResume(items[i])
                                        ? '${items[i].title} 이어 보기'
                                        : '${items[i].title} 재생',
                                    icon: Icons.play_arrow_rounded,
                                    size: short ? 66 : 82,
                                    leaf: true,
                                    quiet: true,
                                    onPressed: opening
                                        ? null
                                        : () => open(items[i]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                final details = Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      current.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: short ? 16 : 22,
                        fontWeight: FontWeight.w900,
                        color: forestInk,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (widget.preview && current.productionPreview)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              current.fullFilmPreview
                                  ? Icons.check_circle_rounded
                                  : Icons.hourglass_bottom_rounded,
                              color: current.fullFilmPreview
                                  ? const Color(0xFF447352)
                                  : const Color(0xFF9A6C2D),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              current.previewLabel,
                              style: const TextStyle(
                                color: forestInk,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      widget.preview
                          ? '${current.ageLabel} · ${current.durationLabel} · ${current.theme}'
                          : current.durationLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: forestInk, fontSize: 13),
                    ),
                    if (widget.preview)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          current.parentPrompt,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    if (widget.preview) _audioStatus(current),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ForestAction(
                          label: current.openingAudioPreview
                              ? '첫 장면 음성 듣기'
                              : '이야기 제목 듣기',
                          icon: Icons.volume_up_rounded,
                          size: 60,
                          quiet: true,
                          onPressed: () => announce(current),
                        ),
                        const SizedBox(width: 20),
                        for (var i = 0; i < items.length; i++)
                          Padding(
                            padding: const EdgeInsets.all(5),
                            child: Icon(
                              i == index ? Icons.local_florist : Icons.circle,
                              size: i == index ? 22 : 8,
                              color: i == index
                                  ? forestInk
                                  : const Color(0xFFA7B98B),
                            ),
                          ),
                        if (!widget.preview) const SizedBox(width: 20),
                        if (!widget.preview)
                          ForestAction(
                            label: '좋아하는 이야기 저장',
                            icon:
                                widget.appState.storyProgress(
                                      widget.profile.id,
                                      current.id,
                                    )['favorite'] ==
                                    true
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 60,
                            quiet: true,
                            onPressed: () async {
                              try {
                                await widget.appState.saveStoryProgress(
                                  widget.profile.id,
                                  current.id,
                                  favorite:
                                      widget.appState.storyProgress(
                                        widget.profile.id,
                                        current.id,
                                      )['favorite'] !=
                                      true,
                                );
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('저장하지 못했어요. 다시 눌러 주세요.'),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                );
                return Column(
                  children: [
                    if (!short)
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.auto_stories_rounded,
                              color: forestInk,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '숲속 작은 극장',
                              style: TextStyle(
                                color: forestInk,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (!widget.preview)
                              IconButton(
                                tooltip: favoritesOnly
                                    ? '모든 이야기 보기'
                                    : '좋아하는 이야기만 보기',
                                icon: Icon(
                                  favoritesOnly
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: forestInk,
                                ),
                                onPressed: () {
                                  setState(() {
                                    favoritesOnly = !favoritesOnly;
                                    selected = 0;
                                  });
                                  if (pages.hasClients) pages.jumpToPage(0);
                                },
                              ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: short
                          ? Row(
                              children: [
                                Expanded(flex: 3, child: gallery),
                                Expanded(
                                  flex: 2,
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(10),
                                    child: details,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Expanded(child: gallery),
                                if (widget.preview)
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight: box.maxHeight * .48,
                                    ),
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: details,
                                    ),
                                  )
                                else
                                  details,
                                const SizedBox(height: 12),
                              ],
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    ),
  );
  bool _canResume(StoryEpisode e) {
    if (widget.preview) return false;
    final saved = widget.appState.storyProgress(widget.profile.id, e.id);
    return saved['complete'] != true && (saved['positionMs'] as int? ?? 0) > 0;
  }

  Widget _audioStatus(StoryEpisode e) => ListenableBuilder(
    listenable: AudioPolicy.instance,
    builder: (_, _) => Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      children: [
        Text(
          '음성 ${AudioPolicy.instance.canVoice ? '켜짐' : '꺼짐'}',
          style: const TextStyle(color: forestInk, fontSize: 12),
        ),
        Text(
          e.musicAsset.isEmpty
              ? '음악 없는 첫 장면'
              : '음악 ${AudioPolicy.instance.canMusic ? '켜짐' : '꺼짐'}',
          style: const TextStyle(color: forestInk, fontSize: 12),
        ),
      ],
    ),
  );
}

class _TheatreArch extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(14, s.height)
    ..lineTo(14, s.height * .25)
    ..quadraticBezierTo(
      s.width * .5,
      -s.height * .13,
      s.width - 14,
      s.height * .25,
    )
    ..lineTo(s.width - 14, s.height)
    ..close();
  @override
  bool shouldReclip(_TheatreArch oldClipper) => false;
}

class _TheatreFrame extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final arch = _TheatreArch().getClip(s);
    canvas.drawPath(
      arch,
      Paint()
        ..color = const Color(0xFF5D7750)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeJoin = StrokeJoin.round,
    );
    for (final x in [s.width * .16, s.width * .84]) {
      canvas.drawLine(
        Offset(x, s.height * .09),
        Offset(x, s.height * .22),
        Paint()
          ..color = const Color(0xFF6F6A42)
          ..strokeWidth = 3,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, s.height * .23),
          width: 20,
          height: 28,
        ),
        Paint()..color = const Color(0xFFF3D795),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, s.height - 10, s.width, 10),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF8C7951),
    );
  }

  @override
  bool shouldRepaint(_TheatreFrame oldDelegate) => false;
}
