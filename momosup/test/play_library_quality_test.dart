import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/play_catalog.dart';
import 'package:momosup/screens/play_library_screen.dart';
import 'package:momosup/widgets/forest_place_art.dart';

import 'age_journey_test.dart' as fixtures;

class _RouteCounter extends NavigatorObserver {
  int pushes = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
  }
}

void main() {
  testWidgets('아이 놀이숲은 장소 그림과 즐겨찾기로 고르고 모든 장난감에 접근한다', (tester) async {
    final state = await fixtures.prepare(48);
    final profile = state.activeProfile!;
    final entries = availablePlay(state, const [], profile);
    await tester.pumpWidget(
      MaterialApp(
        home: PlayLibraryScreen(
          appState: state,
          catalog: const [],
          profile: profile,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(ForestPlaceArt), findsWidgets);
    expect(find.byTooltip('최근 놀이'), findsNothing);
    expect(find.byTooltip('저장된 놀이'), findsNothing);
    for (final entry in entries) {
      await tester.scrollUntilVisible(
        find.byTooltip(entry.title),
        180,
        scrollable: find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.byTooltip(entry.title), findsOneWidget);
    }
    await tester.tap(find.byTooltip('좋아하는 놀이'));
    await tester.pumpAndSettle();
    expect(find.byType(ForestPlaceArt), findsNothing);
    await tester.tap(find.byTooltip('좋아하는 놀이'));
    await tester.pumpAndSettle();
    expect(find.byType(ForestPlaceArt), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('빠르게 두 번 눌러도 놀이 화면은 한 번만 열린다', (tester) async {
    final state = await fixtures.prepare(48);
    final counter = _RouteCounter();
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [counter],
        home: PlayLibraryScreen(
          appState: state,
          catalog: const [],
          profile: state.activeProfile!,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final tile = find.byTooltip('냠냠 열매');
    final queuedActivation = tester
        .widget<InkWell>(
          find.descendant(of: tile, matching: find.byType(InkWell)),
        )
        .onTap!;
    await tester.tap(tile);
    // Exercise a second activation already queued by the original tile. A new
    // hit test would be absorbed by the route transition and would never test
    // the opening guard. Without that guard this callback pushes a third route.
    queuedActivation();
    await tester.pumpAndSettle();
    expect(counter.pushes, 2, reason: '처음 화면과 한 개의 놀이 화면');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('보호자 목록은 최근·저장 필터를 유지한다', (tester) async {
    final state = await fixtures.prepare(48);
    await tester.pumpWidget(
      MaterialApp(
        home: PlayLibraryScreen(
          appState: state,
          catalog: const [],
          profile: state.activeProfile!,
          parent: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('최근 놀이'), findsOneWidget);
    expect(find.byTooltip('저장된 놀이'), findsOneWidget);
    expect(find.byType(ForestPlaceArt), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
