import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/age_journey_repository.dart';
import 'package:momosup/data/catalog_repository.dart';
import 'package:momosup/models/activity.dart';
import 'package:momosup/models/age_journey.dart';
import 'package:momosup/screens/dynamic_toy_screen.dart';
import 'package:momosup/screens/journey_screen.dart';
import 'package:momosup/screens/play_screen.dart';
import 'package:momosup/utils/forest_orientation.dart';
import 'package:momosup/widgets/forest_landscape.dart';
import 'package:momosup/widgets/games/xylophone_game.dart';

import 'age_journey_test.dart' as fixtures;

void phone(WidgetTester tester, [Size size = const Size(568, 320)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  late List<AgeJourney> journeys;
  late List<Activity> classic;
  setUpAll(() async {
    journeys = await AgeJourneyRepository().load();
    classic = await const CatalogRepository().load();
    for (final (family, asset) in [
      ('NotoSansKR', 'assets/fonts/NotoSansKR-wght.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  for (final age in [24, 30, 36, 48, 60, 72, 84]) {
    for (var n = 1; n <= 6; n++) {
      final id = 'age_${age}_${n.toString().padLeft(2, '0')}';
      testWidgets('모든 월령 놀이의 가로 시작·놀이판 $id', (tester) async {
        phone(tester);
        final a = journeys.firstWhere((a) => a.id == id),
            state = await fixtures.prepare(age);
        await tester.pumpWidget(
          MaterialApp(
            home: JourneyPlayScreen(
              journey: a,
              appState: state,
              profile: state.activeProfile!.copyWith(playStage: 2),
              preview: true,
              playAsset: (_) async {},
              randomSeed: 42,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byTooltip('놀이 시작').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('놀이 시작'));
        await tester.pumpAndSettle();
        expect(find.byType(ForestLandscapeFrame), findsOneWidget);
        expect(find.byTooltip('놀이 닫기').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('놀이 닫기'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('숲으로 돌아가기').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  for (var i = 0; i < 10; i++) {
    testWidgets('모든 기존 놀이의 가로 시작·놀이판 $i', (tester) async {
      phone(tester);
      final a = classic[i], state = await fixtures.prepare(48);
      await tester.pumpWidget(
        MaterialApp(
          home: PlayScreen(
            activity: a,
            appState: state,
            profile: state.activeProfile!.copyWith(playStage: 2),
            isParentPreview: true,
            playAsset: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('놀이 시작'));
      await tester.tap(find.byTooltip('놀이 시작'));
      await tester.pumpAndSettle();
      expect(find.byType(ForestLandscapeFrame), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('놀이 마치기'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('숲으로 돌아가기').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  for (final toy in DynamicToyType.values) {
    testWidgets('감각 장난감 가로 놀이판과 끝 화면 ${toy.name}', (tester) async {
      phone(tester);
      final state = await fixtures.prepare(48);
      await tester.pumpWidget(
        MaterialApp(
          home: DynamicToyScreen(
            toyType: toy,
            appState: state,
            profile: state.activeProfile!.copyWith(playStage: 2),
            preview: true,
            playAsset: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byTooltip('놀이 마치기').first).shortestSide,
        greaterThanOrEqualTo(64),
      );
      await tester.tap(find.byTooltip('놀이 마치기').first);
      await tester.pumpAndSettle();
      expect(find.byTooltip('숲으로 돌아가기').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('보호자·놀이·팝업·뒤로가기와 복귀 때 화면 방향이 복원된다', (tester) async {
    final calls = <List<String>>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') {
          calls.add(List<String>.from(call.arguments as List));
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        navigatorObservers: [forestOrientationObserver],
        home: const ForestOrientationScope(child: Scaffold(body: Text('아이 홈'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls.last, [
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('보호자')),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls.last, ['DeviceOrientation.portraitUp']);
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const ForestOrientationScope(child: Scaffold(body: Text('놀이'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls.last.first, 'DeviceOrientation.landscapeLeft');
    final before = calls.length;
    showDialog<void>(
      context: nav.currentContext!,
      builder: (_) => const AlertDialog(content: Text('팝업')),
    );
    await tester.pumpAndSettle();
    expect(calls.length, before);
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(calls.last, ['DeviceOrientation.portraitUp']);
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(calls.last.first, 'DeviceOrientation.landscapeLeft');
    final previous = calls.length;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(calls.length, previous + 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets('세로 태블릿 창에서도 버튼을 축소하지 않고 가로 놀이판을 유지한다', (tester) async {
    phone(tester, const Size(768, 1024));
    final state = await fixtures.prepare(48);
    await tester.pumpWidget(
      MaterialApp(
        home: DynamicToyScreen(
          toyType: DynamicToyType.puzzle,
          appState: state,
          profile: state.activeProfile!,
          preview: true,
          playAsset: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final size = tester.getSize(find.byType(ForestLandscapeFrame));
    expect(size.width / size.height, closeTo(16 / 9, .01));
    expect(
      tester.getSize(find.byTooltip('놀이 마치기').first).shortestSide,
      greaterThanOrEqualTo(64),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('일반 실로폰의 큰 건반과 연주 상태는 태블릿 창 크기를 바꿔도 유지된다', (tester) async {
    phone(tester);
    final state = await fixtures.prepare(48);
    await tester.pumpWidget(
      MaterialApp(
        home: DynamicToyScreen(
          toyType: DynamicToyType.xylophone,
          appState: state,
          profile: state.activeProfile!.copyWith(
            lowStimulation: false,
            playStage: 2,
          ),
          preview: true,
          playAsset: (_) async {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    final original = tester.state(find.byType(XylophoneGame));
    final key = find
        .byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == '도 음 연주',
        )
        .first;
    expect(tester.getSize(key).width, greaterThanOrEqualTo(64));
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(768, 1024);
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      identical(tester.state(find.byType(XylophoneGame)), original),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
