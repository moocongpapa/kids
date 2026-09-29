import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/age_journey_repository.dart';
import 'package:momosup/screens/home_screen.dart';
import 'package:momosup/screens/journey_screen.dart';
import 'package:momosup/screens/parent_screen.dart';

import 'age_journey_test.dart' as fixtures;

void main() {
  setUpAll(() async {
    fixtures.approvedPack = await AgeJourneyRepository().load();
    await (FontLoader(
      'NotoSansKR',
    )..addFont(rootBundle.load('assets/fonts/NotoSansKR-wght.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final scenario in [
    'home',
    'flowers',
    'sunshine',
    'picnic',
    'parent',
    'library',
  ]) {
    testWidgets('놀이 경험 화면 $scenario', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final state = await fixtures.prepare(48);
      state.journeys = fixtures.approvedPack;
      final id = scenario == 'flowers'
          ? 'age_24_01'
          : scenario == 'sunshine'
          ? 'age_24_06'
          : 'age_48_01';
      final a = state.journeys.firstWhere((a) => a.id == id);
      final p = state.activeProfile!;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'NotoSansKR'),
          home: switch (scenario) {
            'home' => HomeScreen(appState: state, catalog: const []),
            'parent' => ParentHubScreen(appState: state, catalog: const []),
            'library' => JourneyLibraryScreen(
              appState: state,
              profile: p,
              parent: true,
            ),
            _ => JourneyPlayScreen(
              journey: a,
              appState: state,
              profile: p.copyWith(ageMonths: a.minAge, playStage: 2),
              preview: true,
            ),
          },
        ),
      );
      await tester.runAsync(() async {
        for (final image in ['momo', 'duri', 'nuri', 'forest_weather']) {
          await precacheImage(
            AssetImage('assets/images/$image.png'),
            tester.element(find.byType(Scaffold).first),
          );
        }
      });
      await tester.pumpAndSettle();
      if (['flowers', 'sunshine', 'picnic'].contains(scenario)) {
        await tester.tap(find.byTooltip('놀이 시작'));
        await tester.pumpAndSettle();
        final actions = scenario == 'flowers'
            ? ['꽃', '꽃', '꽃']
            : scenario == 'sunshine'
            ? ['구름', '꽃', '해']
            : ['나뭇잎'];
        for (var i = 0; i < actions.length; i++) {
          await tester.tap(find.byTooltip(actions[i]));
          await tester.pumpAndSettle();
          if (i < actions.length - 1) {
            await tester.tap(find.byTooltip('다음 장면'));
            await tester.pumpAndSettle();
          }
        }
      }
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('goldens/experience_$scenario.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
