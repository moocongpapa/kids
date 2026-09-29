import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/catalog_repository.dart';
import 'package:momosup/models/child_profile.dart';
import 'package:momosup/screens/play_screen.dart';
import 'package:momosup/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('휴대폰 화면의 발자국 놀이 배치', (tester) async {
    final font = FontLoader('NotoSansKR')
      ..addFont(rootBundle.load('assets/fonts/NotoSansKR-wght.ttf'));
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final catalog = await const CatalogRepository().load();
    final activity = catalog.firstWhere((item) => item.id == 'animal_tracks');
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'NotoSansKR'),
        home: PlayScreen(
          activity: activity,
          appState: AppState(),
          profile: const ChildProfile(
            id: 'visual',
            nickname: '아이',
            ageMonths: 48,
            avatar: 'momo',
            level: '기본',
            answers: [3, 3, 3, 3, 3],
            lowStimulation: true,
          ),
          isParentPreview: true,
          playAsset: (_) async {},
        ),
      ),
    );
    await tester.runAsync(() async {
      for (final name in ['forest_tracks', 'forest_weather', 'momo', 'duri']) {
        await precacheImage(
          AssetImage('assets/images/$name.png'),
          tester.element(find.byType(PlayScreen)),
        );
      }
    });
    await tester.tap(find.byTooltip('놀이 시작'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/animal_tracks_phone.png'),
    );
  });
}
