// Run on an iOS simulator/device, with in-memory synthetic family data only.
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:momosup/data/story_repository.dart';
import 'package:momosup/main.dart' as app;
import 'package:momosup/screens/dynamic_toy_screen.dart';
import 'package:momosup/screens/home_screen.dart';
import 'package:momosup/screens/parent/parent_gate_screen.dart';
import 'package:momosup/screens/parent/parent_hub_screen.dart';
import 'package:momosup/screens/play_library_screen.dart';
import 'package:momosup/screens/story_player_screen.dart';
import 'package:momosup/utils/audio_policy.dart';
import 'package:momosup/utils/story_playback.dart';
import 'package:momosup/utils/story_video.dart';
import 'package:momosup/widgets/forest_game_ui.dart';
import 'package:momosup/widgets/games/xylophone_game.dart';

Finder action(String label) => find.byWidgetPredicate(
  (widget) => widget is ForestAction && widget.label == label,
  description: label,
);

Finder semantic(String label) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == label,
  description: label,
);

Future<void> waitFor(
  WidgetTester tester,
  bool Function() ready,
  String reason, {
  int seconds = 30,
}) async {
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (!ready() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(ready(), isTrue, reason: reason);
  expect(tester.takeException(), isNull, reason: reason);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('iPhone home, toy, PIN and all native story previews', (
    tester,
  ) async {
    // Never read or overwrite a developer's Keychain/profile data.
    FlutterSecureStorage.setMockInitialValues({});
    AudioPolicy.instance.resetForTesting();
    app.main();
    await waitFor(
      tester,
      () => find.text('개발용 둘러보기').evaluate().isNotEmpty,
      'Fresh welcome screen',
    );
    await binding.takeScreenshot('iphone-welcome');
    await tester.tap(find.text('개발용 둘러보기'));
    await waitFor(
      tester,
      () => find.byKey(const ValueKey('forest-area-1')).evaluate().isNotEmpty,
      'Child forest home',
    );
    final state = tester.widget<HomeScreen>(find.byType(HomeScreen)).appState;
    expect(state.activeProfile?.ageMonths, 48);
    await binding.takeScreenshot('iphone-home');

    await tester.tap(find.byKey(const ValueKey('forest-area-1')));
    await waitFor(
      tester,
      () => find.text('새로운 이야기를 만들고 있어요').evaluate().isNotEmpty,
      'Production previews are hidden from the child shelf',
    );
    await tester.tap(find.byKey(const ValueKey('forest-area-0')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(semantic('다른 숲 놀이'));
    await waitFor(
      tester,
      () => find.byType(PlayLibraryScreen).evaluate().isNotEmpty,
      'Play library',
    );
    await tester.tap(action('소리'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(action('숲속 딩동'));
    await tester.tap(action('숲속 딩동'));
    await waitFor(
      tester,
      () => find.byType(XylophoneGame).evaluate().isNotEmpty,
      'Native xylophone game',
    );
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('소리 다시 듣기'), findsNothing);
    for (final note in ['도', '레', '미', '파']) {
      await tester.tap(semantic('$note 음 연주'));
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(action('따라하기'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await binding.takeScreenshot('iphone-xylophone');
    await tester.tap(action('놀이 마치기').last);
    await tester.pump(const Duration(milliseconds: 750));
    await tester.tap(action('숲으로 돌아가기'));
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.byType(DynamicToyScreen), findsNothing);
    await tester.tap(action('놀이 마치기'));
    await tester.pump(const Duration(milliseconds: 750));

    await tester.tap(action('보호자 영역'));
    await waitFor(
      tester,
      () => find.byType(ParentGateScreen).evaluate().isNotEmpty,
      'Parent PIN gate',
    );
    await tester.enterText(find.byType(TextField), '0000');
    await tester.tap(find.text('보호자 화면 열기'));
    await waitFor(
      tester,
      () => find.text('PIN이 맞지 않아요.').evaluate().isNotEmpty,
      'Incorrect PIN stays locked',
    );
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('보호자 화면 열기'));
    await waitFor(
      tester,
      () => find.byType(ParentHubScreen).evaluate().isNotEmpty,
      'Correct test PIN opens the parent hub',
    );
    await tester.ensureVisible(find.text('이야기숲 영상'));
    await tester.tap(find.text('이야기숲 영상'));
    final stories = await const StoryRepository().load(includePreviews: true);
    expect(stories, hasLength(3));
    final recordsBeforePreview = state.records.length;

    for (var i = 0; i < stories.length; i++) {
      final episode = stories[i];
      if (i > 0) {
        await tester.drag(find.byType(PageView), const Offset(-450, 0));
        await tester.pump(const Duration(seconds: 1));
      }
      await waitFor(
        tester,
        () => action('${episode.title} 재생').evaluate().isNotEmpty,
        'Story shelf ${episode.id}',
      );
      await tester.tap(action('${episode.title} 재생'));
      await waitFor(
        tester,
        () => find.byType(StoryPlayerScreen).evaluate().isNotEmpty,
        'Story route ${episode.id}',
      );
      final player =
          (tester.state(find.byType(StoryPlayerScreen)) as dynamic).player
              as StoryPlayback;
      await waitFor(
        tester,
        () =>
            player.activelyPlaying &&
            player.video.position.inMilliseconds > 500,
        'AVPlayer starts ${episode.id}',
      );
      expect(player.failure, isNull);
      expect(player.video.error, isNull);
      final native = (player.video as AssetStoryVideo).controller;
      expect(native.value.volume, greaterThan(0));
      if (i == 0) {
        await binding.takeScreenshot('iphone-story');
        await tester.tap(action('이야기 잠깐 멈추기'));
        await waitFor(tester, () => !player.video.playing, 'Video pauses');
        final atPause = player.video.position;
        await tester.pump(const Duration(seconds: 1));
        expect(
          (player.video.position - atPause).inMilliseconds.abs(),
          lessThan(300),
        );
        await tester.tap(action('이야기 소리 끄기'));
        await waitFor(tester, () => native.value.volume == 0, 'Video mutes');
        await tester.tap(action('이야기 소리 켜기'));
        await waitFor(tester, () => native.value.volume > 0, 'Video unmutes');
        await tester.tap(action('이야기 이어 보기'));
        await waitFor(tester, () => player.activelyPlaying, 'Explicit resume');
        binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        await waitFor(
          tester,
          () => !player.video.playing,
          'Interruption pauses',
        );
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump(const Duration(milliseconds: 500));
        expect(player.paused, isTrue);
        await tester.tap(action('이야기 이어 보기'));
        await waitFor(
          tester,
          () => player.activelyPlaying,
          'Resume after interruption',
        );
        await tester.tap(action('가로 전체 화면'));
        await waitFor(
          tester,
          () => action('세로로 보기').evaluate().isNotEmpty,
          'Native landscape orientation',
        );
        await binding.takeScreenshot('iphone-story-landscape');
        await tester.tap(action('세로로 보기'));
        await waitFor(
          tester,
          () => action('가로 전체 화면').evaluate().isNotEmpty,
          'Native portrait orientation',
        );
      }
      final middle = Duration(
        milliseconds: player.video.duration.inMilliseconds ~/ 2,
      );
      await player.video.seek(middle);
      await waitFor(
        tester,
        () =>
            player.video.position > middle + const Duration(milliseconds: 500),
        'Native middle seek ${episode.id}',
      );
      await player.video.seek(
        player.video.duration - const Duration(seconds: 2),
      );
      await waitFor(
        tester,
        () => player.ended,
        'Native story end ${episode.id}',
      );
      expect(player.video.playing, isFalse);
      expect(player.video.error, isNull);
      expect(find.text('첫 장면 미리보기 끝'), findsOneWidget);
      debugPrint(
        'IPHONE_STORY_PASSED ${episode.id}: ${player.video.duration.inMilliseconds} ms',
      );
      await tester.tap(action('이야기숲으로 돌아가기'));
      await tester.pump(const Duration(milliseconds: 750));
      expect(state.records.length, recordsBeforePreview);
    }
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 750));
    await tester.tap(find.text('아이 화면'));
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.byType(ParentHubScreen), findsNothing);
    expect(tester.takeException(), isNull);
    debugPrint('IPHONE_SMOKE_ALL_PASSED');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
