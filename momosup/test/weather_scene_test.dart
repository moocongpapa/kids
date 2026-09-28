import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/catalog_repository.dart';
import 'package:momosup/models/child_profile.dart';
import 'package:momosup/screens/play_screen.dart';
import 'package:momosup/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('날씨 선택에 맞는 숲 장면이 나타난다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final catalog = await const CatalogRepository().load();
    final activity = catalog.firstWhere((item) => item.id == 'forest_weather');
    const profile = ChildProfile(
      id: 'weather-test',
      nickname: '테스트',
      ageMonths: 48,
      avatar: 'nuri',
      level: '기본',
      answers: [3, 3, 3, 3, 3],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PlayScreen(
          activity: activity,
          appState: AppState(),
          profile: profile,
          isParentPreview: true,
        ),
      ),
    );
    await tester.tap(find.text('놀이 시작'));
    await tester.pumpAndSettle();

    Future<void> selectWeather(int index, String asset) async {
      await tester.ensureVisible(find.text(activity.choices[index]));
      await tester.pumpAndSettle();
      await tester.tap(find.text(activity.choices[index]));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == asset,
        ),
        findsOneWidget,
      );
    }

    await selectWeather(1, 'assets/images/forest_weather_rain.png');
    await selectWeather(2, 'assets/images/forest_weather_wind.png');
    await selectWeather(0, 'assets/images/forest_weather.png');
  });
}
