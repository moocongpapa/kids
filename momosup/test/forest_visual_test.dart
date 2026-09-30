import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/catalog_repository.dart';
import 'package:momosup/models/child_profile.dart';
import 'package:momosup/screens/home_screen.dart';
import 'package:momosup/screens/dynamic_toy_screen.dart';
import 'package:momosup/state/app_state.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'NotoSansKR',
    )..addFont(rootBundle.load('assets/fonts/NotoSansKR-wght.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  const profile = ChildProfile(
    id: 'visual',
    nickname: '모모친구',
    ageMonths: 48,
    avatar: 'momo',
    level: '기본',
    answers: [3, 3, 3, 3, 3],
    lowStimulation: true,
  );
  Future<AppState> state() async {
    FlutterSecureStorage.setMockInitialValues({});
    final value = AppState();
    await value.load();
    await value.setParentPin('123456');
    await value.addProfile(profile);
    return value;
  }

  Future<void> images(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (final name in ['momo', 'duri', 'nuri', 'forest_weather']) {
        await precacheImage(
          AssetImage('assets/images/$name.png'),
          tester.element(find.byType(Scaffold).first),
        );
      }
    });
    await tester.pumpAndSettle();
  }

  for (final screen in [
    ('phone', const Size(390, 844)),
    ('small', const Size(320, 568)),
    ('landscape', const Size(844, 390)),
  ]) {
    testWidgets('숲 지도 반응형 ${screen.$1}', (tester) async {
      tester.view.physicalSize = screen.$2;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final appState = await state();
      final catalog = await const CatalogRepository().load();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'NotoSansKR'),
          home: HomeScreen(appState: appState, catalog: catalog),
        ),
      );
      await images(tester);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/forest_home_${screen.$1}.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  for (final toy in DynamicToyType.values) {
    testWidgets('작은 휴대폰의 감각 놀이 ${toy.name}', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final appState = await state();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'NotoSansKR'),
          home: DynamicToyScreen(
            playAsset: (_) async {},
            toyType: toy,
            appState: appState,
            profile: profile,
          ),
        ),
      );
      await images(tester);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/forest_${toy.name}_small.png'),
      );
      if (toy == DynamicToyType.feeding) {
        await tester.tap(find.byTooltip('놀이 마치기').first);
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('goldens/forest_ending_small.png'),
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
