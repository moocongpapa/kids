import 'woodland_visual_assets.dart';

import 'package:momosup/widgets/journey_sort_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/age_journey_repository.dart';
import 'package:momosup/screens/journey_screen.dart';

import 'age_journey_test.dart' as fixtures;

void main() {
  setUpAll(() async {
    fixtures.approvedPack = await AgeJourneyRepository().load();
    for (final (family, path) in [
      ('NotoSansKR', 'assets/fonts/NotoSansKR-wght.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(path))).load();
    }
  });
  for (final (name, id) in [
    ('reveal', 'age_36_01'),
    ('story_bus', 'age_24_04'),
    ('sorting', 'age_72_04'),
    ('house', 'age_36_06'),
    ('bridge', 'age_72_05'),
    ('rhythm', 'age_48_06'),
    ('art', 'age_36_05'),
  ]) {
    testWidgets('새 놀이 장면 $name', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final a = fixtures.approvedPack.firstWhere((a) => a.id == id);
      final state = await fixtures.prepare(a.minAge);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'NotoSansKR'),
          home: JourneyPlayScreen(
            randomSeed: 42,
            journey: a,
            appState: state,
            profile: state.activeProfile!.copyWith(playStage: 2),
            playAsset: (_) async {},
          ),
        ),
      );
      await precacheWoodlandArt(tester);
      await tester.runAsync(() async {
        for (final image in ['momo', 'duri', 'nuri']) {
          await precacheImage(
            AssetImage('assets/images/$image.png'),
            tester.element(find.byType(Scaffold).first),
          );
        }
      });
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('놀이 시작'));
      await tester.pumpAndSettle();
      Future<void> tap(String label) async {
        final f = find.byTooltip(label).first;
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      if (name == 'reveal' || name == 'story_bus') {
        await tap(name == 'story_bus' ? '모모 태우기' : propLabel(a.choices[0][0]));
      }
      if (name == 'sorting') {
        for (var i = 0; i < 2; i++) {
          final scene = tester.widget<JourneySortScene>(
            find.byType(JourneySortScene),
          );
          await tap(scene.sequence[i] == 0 ? '빨간 바구니' : '파란 바구니');
        }
      }
      if (name == 'house' || name == 'bridge') {
        await tap('1번째 빈 자리');
        await tap('2번째 빈 자리');
      }
      if (name == 'rhythm') {
        await tap('1번 소리');
        await tap('2번 소리');
      }
      if (name == 'art') {
        final canvas = find.byKey(const ValueKey('journey_canvas'));
        await tester.ensureVisible(canvas);
        await tester.drag(canvas, const Offset(80, 35));
        await tap('꽃 도장');
        await tester.ensureVisible(canvas);
        await tester.pumpAndSettle();
        await tester.tapAt(tester.getCenter(canvas) + const Offset(-55, -40));
        await tester.pumpAndSettle();
      }
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('goldens/upgrade_$name.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
