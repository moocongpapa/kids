import 'woodland_visual_assets.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/age_journey_repository.dart';
import 'package:momosup/data/catalog_repository.dart';
import 'package:momosup/data/story_repository.dart';
import 'package:momosup/models/activity.dart';
import 'package:momosup/models/age_journey.dart';
import 'package:momosup/models/story_episode.dart';
import 'package:momosup/screens/dynamic_toy_screen.dart';
import 'package:momosup/screens/home_screen.dart';
import 'package:momosup/screens/journey_screen.dart';
import 'package:momosup/screens/play_screen.dart';
import 'package:momosup/screens/story_player_screen.dart';

import 'age_journey_test.dart' as fixtures;
import 'story_playback_test.dart' as story;

class _PosterVideo extends story.FakeVideo {
  @override
  Widget picture() => const AspectRatio(
    aspectRatio: 16 / 9,
    child: Image(image: AssetImage('assets/stories/story_cloud.jpg')),
  );
}

void main() {
  late List<AgeJourney> journeys;
  late List<Activity> classic;
  late List<StoryEpisode> films;
  setUpAll(() async {
    journeys = await AgeJourneyRepository().load();
    classic = await const CatalogRepository().load();
    films = await const StoryRepository().load(includePreviews: true);
    for (final (family, asset) in [
      ('NotoSansKR', 'assets/fonts/NotoSansKR-wght.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });
  for (final name in [
    'age_36_01',
    'age_24_04',
    'age_72_04',
    'age_36_06',
    'age_72_05',
    'age_84_04',
    'age_36_05',
    'age_36_01_ending',
    'age_36_05_ending',
    'toy_feeding',
    'toy_sorting',
    'toy_peekaboo',
    'toy_xylophone',
    'toy_puzzle',
    'classic_touch',
    'classic_move',
    'classic_color',
    'home',
    'story',
    'story_ending',
    'ending',
  ]) {
    testWidgets('가로 디자인 $name', (tester) async {
      tester.view.physicalSize = name == 'story_ending'
          ? const Size(568, 320)
          : const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(
        left: 44,
        right: 44,
        bottom: 21,
      );
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
      });
      final state = await fixtures.prepare(48);
      Widget screen;
      if (name.startsWith('age_')) {
        final a = journeys.firstWhere(
          (a) => a.id == name.replaceFirst('_ending', ''),
        );
        screen = JourneyPlayScreen(
          journey: a,
          appState: state,
          profile: state.activeProfile!.copyWith(
            ageMonths: a.minAge,
            playStage: 2,
          ),
          preview: true,
          randomSeed: 42,
          playAsset: (_) async {},
        );
      } else if (name.startsWith('toy_') || name == 'ending') {
        final toy = name == 'ending'
            ? DynamicToyType.feeding
            : DynamicToyType.values.firstWhere(
                (t) => t.name == name.substring(4),
              );
        screen = DynamicToyScreen(
          toyType: toy,
          appState: state,
          profile: state.activeProfile!.copyWith(playStage: 2),
          preview: true,
          playAsset: (_) async {},
        );
      } else if (name.startsWith('classic_')) {
        final mode = PlayMode.values.firstWhere(
          (m) => m.name == name.substring(8),
        );
        screen = PlayScreen(
          activity: classic.firstWhere((a) => a.mode == mode),
          appState: state,
          profile: state.activeProfile!.copyWith(playStage: 2),
          isParentPreview: true,
          playAsset: (_) async {},
        );
      } else if (name.startsWith('story')) {
        final film = films.firstWhere((e) => e.fullFilmPreview);
        screen = StoryPlayerScreen(
          episode: film,
          profile: state.activeProfile!,
          appState: state,
          preview: true,
          playback: story.playback(
            state,
            _PosterVideo(),
            story.Clock(),
            preview: true,
            story: film,
          ),
        );
      } else {
        screen = HomeScreen(appState: state, catalog: classic);
      }
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'NotoSansKR'),
          home: screen,
        ),
      );
      await precacheWoodlandArt(tester);
      await tester.runAsync(() async {
        for (final file in [
          'assets/images/momo.png',
          'assets/images/duri.png',
          'assets/images/nuri.png',
          'assets/images/forest_weather.png',
          'assets/images/forest_places_v2.png',
          'assets/stories/story_cloud.jpg',
        ]) {
          await precacheImage(
            AssetImage(file),
            tester.element(find.byType(Scaffold).first),
          );
        }
      });
      await tester.pumpAndSettle();
      if (name.startsWith('age_') || name.startsWith('classic_')) {
        await tester.ensureVisible(find.byTooltip('놀이 시작'));
        await tester.tap(find.byTooltip('놀이 시작'));
        await tester.pumpAndSettle();
      }
      if (name.startsWith('age_') && name.endsWith('_ending')) {
        if (name == 'age_36_05_ending') {
          await tester.drag(
            find.byKey(const ValueKey('journey_canvas')),
            const Offset(60, 30),
          );
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byTooltip('놀이 닫기'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('숲으로 돌아가기').hitTestable(), findsOneWidget);
      }
      if (name == 'story_ending') {
        (screen as StoryPlayerScreen).playback!.finish();
        await tester.pumpAndSettle();
        expect(find.byTooltip('이야기숲으로 돌아가기').hitTestable(), findsOneWidget);
        expect(find.byTooltip('함께 놀이 안내').hitTestable(), findsOneWidget);
      }
      if (name == 'ending') {
        await tester.tap(find.byTooltip('놀이 마치기').first);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('goldens/landscape_$name.png'),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
}
