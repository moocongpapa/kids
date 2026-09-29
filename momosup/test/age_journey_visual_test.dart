import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/screens/journey_screen.dart';

import 'age_journey_test.dart' as fixtures;

void main() {
  setUpAll(() async {
    fixtures.fixture = await fixtures.readDrafts();
    await (FontLoader(
      'NotoSansKR',
    )..addFont(rootBundle.load('assets/fonts/NotoSansKR-wght.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final scenario in ['caregiver', 'reveal', 'rhythm', 'build', 'draw']) {
    testWidgets('월령 놀이 그림 검증 $scenario', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final a = fixtures.fixture.firstWhere((a) => a.mechanic == scenario);
      final state = await fixtures.prepare(a.minAge);
      final p = state.activeProfile!.copyWith(playStage: 2);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'NotoSansKR'),
          home: scenario == 'caregiver'
              ? JourneyDetailScreen(journey: a, appState: state, profile: p)
              : JourneyPlayScreen(
                  journey: a,
                  appState: state,
                  profile: p,
                  preview: true,
                ),
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
      if (scenario != 'caregiver') {
        await tester.tap(find.byTooltip('놀이 시작'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('goldens/age_$scenario.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
