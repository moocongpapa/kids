import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/catalog_repository.dart';
import 'package:momosup/models/child_profile.dart';
import 'package:momosup/screens/play_screen.dart';
import 'package:momosup/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('터치 놀이는 직접 종료하며 다음 놀이가 자동 시작하지 않는다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final catalog = await const CatalogRepository().load();
    final activity = catalog.firstWhere((item) => item.id == 'animal_tracks');
    const profile = ChildProfile(
      id: 'test',
      nickname: '테스트',
      ageMonths: 48,
      avatar: 'momo',
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
    expect(find.text('보호자 미리보기'), findsOneWidget);
    expect(find.text(activity.intro), findsOneWidget);
    await tester.tap(find.text('놀이 시작'));
    await tester.pumpAndSettle();
    expect(find.text(activity.prompt), findsOneWidget);
    await tester.ensureVisible(find.text(activity.choices.first));
    await tester.pumpAndSettle();
    await tester.tap(find.text(activity.choices.first));
    await tester.pumpAndSettle();
    expect(find.text(activity.reactions.first), findsOneWidget);
    await tester.ensureVisible(find.text('놀이 마치기'));
    await tester.tap(find.text('놀이 마치기'));
    await tester.pumpAndSettle();
    expect(find.text(activity.offscreen), findsOneWidget);
    expect(find.text('다음 놀이는 자동으로 시작하지 않아요.'), findsOneWidget);
  });
}
