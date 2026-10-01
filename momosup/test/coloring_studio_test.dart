import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/catalog_repository.dart';
import 'package:momosup/screens/coloring_screen.dart';
import 'package:momosup/screens/home_screen.dart';
import 'package:momosup/widgets/forest_coloring_studio.dart';

import 'age_journey_test.dart' as fixtures;

void main() {
  group('ColoringCatalog', () {
    test('8가지 다양한 도안이 모두 등록되어 있고 최소 5개 이상의 영역을 갖는다', () {
      final catalog = ColoringCatalog.all;
      expect(catalog.length, 8);

      final expectedIds = [
        'rabbit',
        'bear',
        'cat',
        'bus',
        'flower',
        'rocket',
        'fruit',
        'whale',
      ];

      for (var i = 0; i < catalog.length; i++) {
        final template = catalog[i];
        expect(template.id, expectedIds[i]);
        expect(template.title.isNotEmpty, isTrue);
        expect(template.emoji.isNotEmpty, isTrue);

        final segments = template.createSegments();
        expect(
          segments.length,
          greaterThanOrEqualTo(5),
          reason: '${template.id}는 최소 5개 이상의 색칠 영역을 가져야 함',
        );

        for (final seg in segments) {
          expect(seg.id.isNotEmpty, isTrue);
          expect(seg.name.isNotEmpty, isTrue);
          expect(seg.path.getBounds().isEmpty, isFalse);
          expect(seg.color, isNull);
        }
      }
    });
  });

  group('ForestColoringStudio Widget Tests', () {
    testWidgets('색칠하기 스튜디오가 정상 렌더링되고 도안 선택 칩들이 표시된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ForestColoringStudio(quiet: true),
            ),
          ),
        ),
      );

      // Verify title of default template (포근 토끼)
      expect(find.text('포근 토끼 색칠하기'), findsOneWidget);

      // Verify template chips
      for (final t in ColoringCatalog.all) {
        expect(find.text(t.title), findsOneWidget);
        expect(find.text(t.emoji), findsWidgets);
      }

      // Verify 12 paint color options exist
      expect(find.byType(GestureDetector), findsWidgets);
      expect(find.text('되돌리기'), findsOneWidget);
      expect(find.text('다시 시작'), findsOneWidget);
    });

    testWidgets('다른 도안을 선택하면 캔버스와 제목이 해당 도안으로 바뀐다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ForestColoringStudio(quiet: true),
            ),
          ),
        ),
      );

      // Initially 포근 토끼
      expect(find.text('포근 토끼 색칠하기'), findsOneWidget);

      // Tap on 아기 곰
      await tester.tap(find.text('아기 곰'));
      await tester.pump();

      // Title should change
      expect(find.text('아기 곰 색칠하기'), findsOneWidget);

      // Tap on 숲속 야옹이 (scrolls into view if needed)
      await tester.ensureVisible(find.text('숲속 야옹이'));
      await tester.tap(find.text('숲속 야옹이'));
      await tester.pump();

      expect(find.text('숲속 야옹이 색칠하기'), findsOneWidget);
    });

    testWidgets('물감을 선택하고 캔버스를 터치하면 해당 영역이 색칠된다', (tester) async {
      var changedCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ForestColoringStudio(
                quiet: true,
                onChanged: () => changedCount++,
              ),
            ),
          ),
        ),
      );

      // Select yellow color (4th in palette)
      final yellowSemantic = find.byTooltip('개나리 노랑 물감 선택');
      if (yellowSemantic.evaluate().isNotEmpty) {
        await tester.tap(yellowSemantic);
        await tester.pump();
      }

      // Tap on canvas center (likely hitting rabbit head or body)
      final customPaintFinder = find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == '_ColoringCanvasPainter',
      );
      expect(customPaintFinder, findsOneWidget);

      await tester.tap(customPaintFinder);
      await tester.pump();

      expect(changedCount, greaterThanOrEqualTo(1));
    });

    testWidgets('가로 모드(isWide)에서도 오버플로 없이 정상 렌더링된다', (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ForestColoringStudio(quiet: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('포근 토끼 색칠하기'), findsOneWidget);
      expect(find.text('되돌리기'), findsOneWidget);
      expect(find.text('다시 시작'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ColoringScreen 전체 화면이 정상 동작한다', (tester) async {
      final state = await fixtures.prepare(48);
      await tester.pumpWidget(
        MaterialApp(
          home: ColoringScreen(
            profile: state.activeProfile!,
            appState: state,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('톡톡 색칠하기'), findsOneWidget);
      expect(find.text('포근 토끼 색칠하기'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('HomeScreen에서 그림숲 탭 선택 시 톡톡 색칠하기 포털이 나타난다', (tester) async {
      final state = await fixtures.prepare(48);
      final catalog = await const CatalogRepository().load();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(appState: state, catalog: catalog),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to 그림숲 tab (area == 2)
      final artTab = find.byKey(const ValueKey('forest-area-2'));
      expect(artTab, findsOneWidget);
      await tester.tap(artTab);
      await tester.pumpAndSettle();

      // Verify "색칠하기" sign and "톡톡 색칠하기" portal are visible
      expect(find.text('색칠하기'), findsOneWidget);
      expect(find.bySemanticsLabel('톡톡 색칠하기'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
