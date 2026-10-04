import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/game/forest_response_scene.dart';
import 'package:momosup/screens/journey_screen.dart';
import 'package:momosup/widgets/forest_art_studio.dart';
import 'package:momosup/widgets/journey_reveal_scene.dart';
import 'package:momosup/widgets/journey_rhythm_scene.dart';
import 'package:momosup/widgets/journey_sort_scene.dart';

import 'age_journey_test.dart' as fixtures;

void main() {
  setUpAll(() async => fixtures.fixture = await fixtures.readDrafts());

  Future<void> tap(WidgetTester tester, String label) async {
    final control = find.byTooltip(label).first;
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, String id, {int stage = 2}) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final a = fixtures.fixture.firstWhere((a) => a.id == id);
    final state = await fixtures.prepare(a.minAge);
    await tester.pumpWidget(
      MaterialApp(
        home: JourneyPlayScreen(
          journey: a,
          appState: state,
          profile: state.activeProfile!.copyWith(playStage: stage),
          preview: true,
          randomSeed: 37,
          playAsset: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, '놀이 시작');
  }

  testWidgets('숨은 친구를 모두 만나고 중복 터치로 건너뛰지 않는다', (tester) async {
    await open(tester, 'age_36_03');
    final scene = tester.widget<JourneyRevealScene>(
      find.byType(JourneyRevealScene),
    );
    for (var i = 0; i < scene.labels.length; i++) {
      await tap(tester, scene.labels[i]);
      await tap(tester, scene.labels[i]);
      expect(
        find.byTooltip('다음 장면'),
        i == scene.labels.length - 1 ? findsOneWidget : findsNothing,
      );
    }
    await tap(tester, '다음 장면');
    expect(find.byTooltip('다음 장면'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('어린 단계는 한 친구를 만나면 마칠 수 있다', (tester) async {
    await open(tester, 'age_36_03', stage: 0);
    final scene = tester.widget<JourneyRevealScene>(
      find.byType(JourneyRevealScene),
    );
    expect(scene.labels.length, 1);
    await tap(tester, scene.labels.single);
    expect(find.byTooltip('놀이 마치기'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('악보를 고치고 순서를 뒤집은 뒤 끝까지 듣고 다음으로 간다', (tester) async {
    await open(tester, 'age_72_03');
    JourneyRhythmScene scene() =>
        tester.widget(find.byType(JourneyRhythmScene));
    await tap(tester, '1번 소리');
    await tap(tester, '2번 소리');
    await tap(tester, '3번 소리');
    await tap(tester, '쉼');
    expect(scene().slots.values.toList(), [0, 1, 2, 3]);
    expect(find.byTooltip('다음 장면'), findsNothing);
    await tap(tester, '소리 순서 뒤집기');
    expect(scene().slots.values.toList(), [3, 2, 1, 0]);
    await tap(tester, '마지막 소리 지우기');
    expect(scene().slots.length, 3);
    await tap(tester, '2번 소리');
    expect(scene().slots[3], 1);
    await tap(tester, '내 소리 이어 듣기');
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 700));
    }
    await tester.pumpAndSettle();
    expect(find.byTooltip('다음 장면'), findsOneWidget);
    await tap(tester, '다음 장면');
    expect(scene().slots.values.toList(), [3, 2, 1, 1]);
    expect(find.byTooltip('다음 장면'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('물건이 바구니에 도착해야 쌓이고 이동 중 중복 입력을 받지 않는다', (tester) async {
    var matches = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (_, set) => JourneySortScene(
              id: 'age_30_01',
              step: 0,
              bySize: false,
              bins: 2,
              progress: matches,
              goal: 4,
              quiet: false,
              onMatch: () => set(() => matches++),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scene = tester.widget<JourneySortScene>(
      find.byType(JourneySortScene),
    );
    final correct = scene.sequence.first == 0 ? '빨간 바구니' : '파란 바구니';
    await tester.tap(find.byTooltip(correct));
    await tester.pump(const Duration(milliseconds: 100));
    expect(matches, 0);
    await tester.tap(find.byTooltip(correct));
    await tester.pumpAndSettle();
    expect(matches, 1);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('지운 선 복원과 유한한 그림 움직임은 작품을 바꾸지 않는다', (tester) async {
    final marks = <ArtMark>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ForestArtStudio(
              theme: 'my_bus',
              marks: marks,
              quiet: false,
              onChanged: () {},
              canvasKey: const ValueKey('paper'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('paper')),
      const Offset(80, 25),
    );
    await tester.pumpAndSettle();
    final drawing = marks.map((m) => m.toJson()).toList();
    await tap(tester, '마지막 선 지우기');
    expect(marks, isEmpty);
    await tap(tester, '지운 선 되돌리기');
    expect(marks.map((m) => m.toJson()).toList(), drawing);
    await tap(tester, '그림 흔들어 보기');
    expect(marks.map((m) => m.toJson()).toList(), drawing);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Flame 반응은 입력을 가로채지 않고 잠든다, 조용한 모드는 엔진을 띄우지 않는다', (tester) async {
    var events = 0;
    var quiet = false;
    late StateSetter change;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (_, set) {
              change = set;
              return ForestResponseScene(
                event: events,
                response: ForestResponse.discovery,
                quiet: quiet,
                child: SizedBox.expand(
                  child: GestureDetector(
                    key: const ValueKey('scene'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => set(() => events++),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => tester
          .state<GameWidgetState<ForestResponseGame>>(
            find.byType(GameWidget<ForestResponseGame>),
          )
          .loaderFuture,
    );
    await tester.pumpAndSettle();
    final game = tester
        .widget<GameWidget<ForestResponseGame>>(
          find.byType(GameWidget<ForestResponseGame>),
        )
        .game!;
    expect(game.responding, isFalse);
    await tester.tap(find.byKey(const ValueKey('scene')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(events, 1);
    expect(game.responding, isTrue);
    await tester.pumpAndSettle();
    expect(game.responding, isFalse);
    expect(tester.binding.hasScheduledFrame, isFalse);
    change(() => quiet = true);
    await tester.pumpAndSettle();
    expect(find.byType(GameWidget<ForestResponseGame>), findsNothing);
    await tester.tap(find.byKey(const ValueKey('scene')));
    await tester.pumpAndSettle();
    expect(events, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
