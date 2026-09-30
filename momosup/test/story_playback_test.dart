import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/story_repository.dart';
import 'package:momosup/models/child_profile.dart';
import 'package:momosup/models/story_episode.dart';
import 'package:momosup/screens/story_forest_screen.dart';
import 'package:momosup/screens/story_player_screen.dart';
import 'package:momosup/state/app_state.dart';
import 'package:momosup/utils/audio_policy.dart';
import 'package:momosup/utils/story_playback.dart';
import 'package:momosup/utils/story_video.dart';
import 'package:momosup/utils/toy_music_player.dart';

import 'audio_placement_test.dart' as audio;

const testProfile = ChildProfile(
  id: 'story_test',
  nickname: '테스트',
  ageMonths: 48,
  avatar: 'momo',
  level: '기본',
  answers: [3, 3, 3, 3, 3],
);
StoryEpisode episode(String id, int minAge, int maxAge) => StoryEpisode(
  id: id,
  title: {
    'cloud': '구름아, 내 마음을 들어줘',
    'swing': '그네 하나, 친구 셋',
    'moon': '사라진 달빛을 찾아서',
  }[id]!,
  series: '테스트',
  theme: '주제 하나',
  parentPrompt: '어른과 함께 이야기해요.',
  minAgeMonths: minAge,
  maxAgeMonths: maxAge,
  durationSeconds: 300,
  videoAsset: 'assets/stories/story_$id.mp4',
  posterAsset: 'assets/stories/story_$id.jpg',
  titleAudioAsset: 'assets/stories/story_${id}_title.m4a',
  musicAsset: 'assets/stories/story_${id}_music.m4a',
);
final allStories = [
  episode('cloud', 24, 35),
  episode('swing', 36, 71),
  episode('moon', 72, 95),
];

class Clock extends Stopwatch {
  int ms = 0;
  bool running = false;
  void advance(int seconds) {
    if (running) ms += seconds * 1000;
  }

  @override
  Duration get elapsed => Duration(milliseconds: ms);
  @override
  bool get isRunning => running;
  @override
  void start() => running = true;
  @override
  void stop() => running = false;
}

class FakeVideo extends StoryVideo {
  @override
  bool ready = false;
  @override
  bool playing = false;
  @override
  bool buffering = false;
  @override
  Duration position = Duration.zero;
  @override
  Duration duration = const Duration(minutes: 5);
  @override
  String? error;
  int starts = 0;
  double gain = 1;
  Completer<void>? loading;
  bool disposed = false;
  @override
  Future<void> initialize() async {
    await loading?.future;
    ready = true;
  }

  @override
  Future<void> play() async {
    playing = true;
    starts++;
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    playing = false;
    notifyListeners();
  }

  @override
  Future<void> seek(Duration value) async {
    position = value;
    notifyListeners();
  }

  @override
  Future<void> volume(double value) async {
    gain = value;
  }

  void update({Duration? at, bool? stalled}) {
    position = at ?? position;
    buffering = stalled ?? buffering;
    notifyListeners();
  }

  @override
  Widget picture() => const AspectRatio(
    aspectRatio: 16 / 9,
    child: ColoredBox(color: Colors.teal),
  );
  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

Future<AppState> setup([ChildProfile p = testProfile]) async {
  FlutterSecureStorage.setMockInitialValues({});
  final state = AppState();
  await state.load();
  await state.setParentPin('1234');
  await state.addProfile(p);
  AudioPolicy.instance.configure(p);
  AudioPolicy.instance.mute(false);
  AudioPolicy.instance.suspend(false);
  return state;
}

StoryPlayback playback(
  AppState state,
  FakeVideo video,
  Clock clock, {
  bool preview = false,
  StoryEpisode? story,
}) => StoryPlayback(
  episode: story ?? allStories[1],
  profile: state.activeProfile!,
  appState: state,
  video: video,
  watch: clock,
  preview: preview,
  music: ToyMusicPlayer(output: audio.FakeOutput()),
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('연령에 맞는 대표작이 먼저 나오고 어린 아이에게 상위 연령 영상을 노출하지 않는다', () {
    for (final (months, first, count) in [
      (6, '', 0),
      (23, '', 0),
      (24, 'cloud', 1),
      (35, 'cloud', 1),
      (36, 'swing', 2),
      (71, 'swing', 2),
      (72, 'moon', 3),
      (95, 'moon', 3),
      (96, '', 0),
    ]) {
      final result = StoryRepository.forProfile(
        allStories,
        testProfile.copyWith(ageMonths: months),
      );
      expect(result.length, count);
      if (count > 0) expect(result.first.id, first);
    }
    expect(
      StoryRepository.forProfile(
        allStories,
        testProfile.copyWith(ageMonths: 84, preschool: false),
      ),
      isEmpty,
    );
  });
  test('초안·미검수 영상은 게시 카탈로그에서 거부한다', () {
    expect(
      () => StoryEpisode.fromJson({'durationSeconds': 300, 'status': 'DRAFT'}),
      throwsFormatException,
    );
  });
  test('제작 중 미리보기는 부모 목록에서만 읽으며 아동 목록에는 없다', () async {
    const repository = StoryRepository();
    final child = await repository.load();
    final parent = await repository.load(includePreviews: true);
    expect(child.every((e) => !e.productionPreview), isTrue);
    expect(parent.length, 3);
    for (final draft in parent.where((e) => e.productionPreview)) {
      expect(draft.availableFor(testProfile.copyWith(ageMonths: 84)), isFalse);
    }
  });
  test('완성 카탈로그에는 연령별 영상 3편과 음성·음악이 들어 있다', () async {
    final films = await const StoryRepository().load();
    final catalog = jsonDecode(
      await rootBundle.loadString('assets/content/story_catalog.json'),
    ) as Map<String, dynamic>;
    if (catalog['productionStatus'] != 'COMPLETE') {
      expect(films, isEmpty);
      return;
    }
    expect(films.map((e) => e.id), [
      'story_cloud',
      'story_swing',
      'story_moon',
    ]);
    expect(films.first.durationSeconds, inInclusiveRange(170, 230));
    for (final film in films.skip(1)) {
      expect(film.durationSeconds, inInclusiveRange(290, 390));
    }
    expect(films.every((e) => e.musicAsset.isNotEmpty), isTrue);
    expect(
      StoryRepository.forProfile(
        films,
        testProfile.copyWith(ageMonths: 30),
      ).single.id,
      'story_cloud',
    );
  });
  test('실제 재생 시간만 합산하고 멈춤과 버퍼링 시간을 제외한다', () async {
    final state = await setup(), video = FakeVideo(), clock = Clock();
    final p = playback(state, video, clock);
    await p.initialize();
    clock.advance(12);
    video.update(at: const Duration(seconds: 12));
    await p.pause();
    clock.advance(30);
    await p.checkpoint();
    expect(state.records.single.seconds, 12);
    await p.play();
    video.update(stalled: true);
    clock.advance(20);
    expect(clock.elapsed.inSeconds, 12);
    video.update(stalled: false);
    clock.advance(8);
    video.update(at: const Duration(seconds: 20));
    await p.checkpoint();
    expect(state.records.single.seconds, 20);
    expect(
      state.storyProgress(testProfile.id, allStories[1].id)['positionMs'],
      20000,
    );
    p.dispose();
    await audio.flush();
  });
  test('앱 전환 후 명시적으로 재생해야 다시 움직이고 음소거가 적용된다', () async {
    final state = await setup(), video = FakeVideo(), clock = Clock();
    final p = playback(state, video, clock);
    await p.initialize();
    p.didChangeAppLifecycleState(AppLifecycleState.inactive);
    await audio.flush();
    expect(video.playing, isFalse);
    expect(clock.isRunning, isFalse);
    p.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await audio.flush();
    expect(video.starts, 1);
    await p.play();
    expect(video.starts, 2);
    p.toggleMute();
    await audio.flush();
    expect(video.gain, 0);
    p.toggleMute();
    await audio.flush();
    expect(video.gain, 1);
    p.dispose();
    await audio.flush();
  });
  test('로딩 도중 앱을 떠나면 늦은 자동재생이 없다', () async {
    final state = await setup(),
        video = FakeVideo()..loading = Completer<void>(),
        clock = Clock();
    final p = playback(state, video, clock);
    final pending = p.initialize();
    await audio.flush();
    p.didChangeAppLifecycleState(AppLifecycleState.paused);
    video.loading!.complete();
    await pending;
    expect(video.starts, 0);
    p.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(video.starts, 0);
    await p.play();
    expect(video.starts, 1);
    p.dispose();
    await audio.flush();
  });
  testWidgets('남은 하루 한도에서 멈추고 이어 볼 위치를 남긴다', (tester) async {
    final state = await setup(testProfile.copyWith(dailyLimitMinutes: 1));
    await state.recordPlay(
      profileId: testProfile.id,
      activityId: 'prior',
      seconds: 55,
    );
    final video = FakeVideo(),
        clock = Clock(),
        p = playback(state, video, clock);
    await p.initialize();
    clock.advance(5);
    video.update(at: const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    await p.checkpoint();
    expect(p.expired, isTrue);
    expect(video.playing, isFalse);
    expect(state.secondsRemaining(testProfile.id, 1), 0);
    expect(
      state.storyProgress(testProfile.id, allStories[1].id)['complete'],
      isFalse,
    );
    p.dispose();
    await tester.pump();
  });
  test('미리보기는 연령과 이용 한도를 넘겨도 아이 기록을 바꾸지 않는다', () async {
    final state = await setup(
      testProfile.copyWith(ageMonths: 12, dailyLimitMinutes: 0),
    );
    final video = FakeVideo(),
        clock = Clock(),
        p = playback(state, video, clock, preview: true);
    await p.initialize();
    clock.advance(20);
    video.update(at: video.duration);
    await p.checkpoint();
    expect(p.ended, isTrue);
    expect(state.records, isEmpty);
    expect(state.storyProgress(testProfile.id, allStories[1].id), isEmpty);
    expect(video.starts, 1);
    p.dispose();
    await audio.flush();
  });
  test('완주 뒤 다음 영상이 자동 시작하지 않고 다시 열면 처음부터 본다', () async {
    final state = await setup(),
        video = FakeVideo(),
        clock = Clock(),
        p = playback(state, video, clock);
    await p.initialize();
    clock.advance(300);
    video.update(at: video.duration);
    await audio.flush();
    expect(p.ended, isTrue);
    expect(video.starts, 1);
    expect(
      state.storyProgress(testProfile.id, allStories[1].id)['complete'],
      isTrue,
    );
    p.dispose();
    await audio.flush();
    final next = FakeVideo(), p2 = playback(state, next, Clock());
    await p2.initialize();
    expect(next.position, Duration.zero);
    p2.dispose();
    await audio.flush();
  });
  test('시청 위치와 즐겨찾기는 재시작 후 보존되고 프로필 삭제 시 함께 지운다', () async {
    final state = await setup();
    await state.saveStoryProgress(
      testProfile.id,
      'swing',
      positionMs: 65000,
      favorite: true,
    );
    await state.saveStoryProgress(testProfile.id, 'swing', positionMs: 67000);
    final restored = AppState();
    await restored.load();
    expect(restored.storyProgress(testProfile.id, 'swing')['favorite'], isTrue);
    expect(
      restored.storyProgress(testProfile.id, 'swing')['positionMs'],
      67000,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => '/private/tmp/kids-story-test-documents',
        );
    await restored.deleteProfile(testProfile.id);
    final deleted = AppState();
    await deleted.load();
    expect(deleted.storyProgress(testProfile.id, 'swing'), isEmpty);
  });
  test('연령 제한이나 소진된 한도에서는 네이티브 플레이어를 시작하지 않는다', () async {
    for (final p in [
      testProfile.copyWith(ageMonths: 12),
      testProfile.copyWith(dailyLimitMinutes: 0),
    ]) {
      final state = await setup(p),
          video = FakeVideo(),
          controller = playback(state, video, Clock());
      await controller.initialize();
      expect(video.ready, isFalse);
      expect(video.starts, 0);
      controller.dispose();
      await audio.flush();
    }
  });
  for (final size in [const Size(390, 700), const Size(640, 300)]) {
    testWidgets('극장 선택 화면은 작은 화면에서도 카드 없이 표시된다 $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final state = await setup();
      final heard = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryForestScreen(
              appState: state,
              profile: testProfile,
              episodes: allStories,
              playAsset: (p) async {
                heard.add(p);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('그네 하나, 친구 셋'), findsOneWidget);
      expect(find.byType(Card), findsNothing);
      await tester.tap(find.byTooltip('이야기 제목 듣기'));
      await tester.pumpAndSettle();
      expect(heard.single, allStories[1].titleAudioAsset);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('영상 화면에서 멈춤과 종료를 큰 버튼으로 조작한다', (tester) async {
    final state = await setup(),
        video = FakeVideo(),
        p = playback(state, video, Clock());
    await tester.pumpWidget(
      MaterialApp(
        home: StoryPlayerScreen(
          episode: allStories[1],
          profile: testProfile,
          appState: state,
          playback: p,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('이야기 잠깐 멈추기'));
    await tester.pump();
    expect(video.playing, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(video.disposed, isTrue);
  });
}
