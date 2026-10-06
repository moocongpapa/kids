import 'woodland_visual_assets.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/screens/story_forest_screen.dart';
import 'package:momosup/data/story_repository.dart';

import 'story_playback_test.dart' as fixture;

void main() {
  setUpAll(() async {
    await (FontLoader(
      'NotoSansKR',
    )..addFont(rootBundle.load('assets/fonts/NotoSansKR-wght.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final (name, size) in [
    ('story_theatre_phone', const Size(390, 700)),
    ('story_theatre_landscape', const Size(720, 330)),
  ]) {
    testWidgets(name, (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final state = await fixture.setup();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'NotoSansKR'),
          home: Scaffold(
            backgroundColor: const Color(0xFFF1F2DD),
            body: RepaintBoundary(
              key: const ValueKey('story-theatre'),
              child: ColoredBox(
                color: const Color(0xFFF1F2DD),
                child: StoryForestScreen(
                  appState: state,
                  profile: fixture.testProfile,
                  episodes: fixture.allStories,
                  playAsset: (_) async {},
                ),
              ),
            ),
          ),
        ),
      );
      await precacheWoodlandArt(tester);
      await tester.runAsync(() async {
        for (final e in fixture.allStories) {
          await precacheImage(
            AssetImage(e.posterAsset),
            tester.element(find.byType(Scaffold)),
          );
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('story-theatre')),
        matchesGoldenFile('goldens/$name.png'),
      );
      await tester.pumpWidget(const SizedBox());
    });
  }
  for (final (name, size) in [
    ('story_parent_phone', const Size(390, 700)),
    ('story_parent_landscape', const Size(720, 330)),
  ]) {
    testWidgets(name, (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final state = await fixture.setup(),
          stories = (await tester.runAsync(
            () => const StoryRepository().load(includePreviews: true),
          ))!;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'NotoSansKR'),
          home: Scaffold(
            backgroundColor: const Color(0xFFF1F2DD),
            body: RepaintBoundary(
              key: const ValueKey('parent-theatre'),
              child: ColoredBox(
                color: const Color(0xFFF1F2DD),
                child: StoryForestScreen(
                  appState: state,
                  profile: fixture.testProfile,
                  preview: true,
                  episodes: stories,
                  playAsset: (_) async {},
                ),
              ),
            ),
          ),
        ),
      );
      await precacheWoodlandArt(tester);
      await tester.runAsync(() async {
        for (final e in stories) {
          await precacheImage(
            AssetImage(e.posterAsset),
            tester.element(find.byType(Scaffold)),
          );
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('parent-theatre')),
        matchesGoldenFile('goldens/$name.png'),
      );
      await tester.pumpWidget(const SizedBox());
    });
  }
}
