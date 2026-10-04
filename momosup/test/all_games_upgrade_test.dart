import 'package:flame/game.dart';
import 'package:momosup/widgets/journey_detective_scene.dart';
import 'package:momosup/widgets/journey_reveal_scene.dart';
import 'package:momosup/game/build_experiment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/catalog_repository.dart';
import 'package:momosup/models/activity.dart';
import 'package:momosup/screens/journey_screen.dart';
import 'package:momosup/screens/play_screen.dart';
import 'package:momosup/widgets/forest_art_studio.dart';
import 'package:momosup/widgets/classic_forest_scene.dart';
import 'package:momosup/widgets/journey_build_board.dart';
import 'package:momosup/widgets/journey_rhythm_scene.dart';
import 'package:momosup/widgets/journey_sort_scene.dart';

import 'age_journey_test.dart' as fixtures;

void main() {
  setUpAll(() async {
    fixtures.fixture = await fixtures.readDrafts();
  });
  Future<void> tap(WidgetTester tester, String label) async {
    final f = find.byTooltip(label).first;
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('월령별 42개 놀이가 실제 조작으로 모든 장면을 끝내며 작품을 보존한다', (tester) async {
    phone(tester);
    final games = fixtures.fixture.where((a) => !a.isCaregiver).toList();
    expect(games.length, 42);
    for (final a in games) {
      final state = await fixtures.prepare(a.minAge);
      final profile = state.activeProfile!.copyWith(
        playStage: 2,
        effectsOn: false,
      );
      final voices = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: JourneyPlayScreen(
            key: ValueKey(a.id),
            journey: a,
            appState: state,
            profile: profile,
            preview: true,
            playAsset: (p) async => voices.add(p),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, '놀이 시작');
      for (var step = 0; step < 3; step++) {
        switch (a.mechanic) {
          case 'reveal':
          case 'story':
            if (find.byType(JourneyDetectiveScene).evaluate().isNotEmpty) {
              if (a.id == 'age_84_05' && step > 0) {
                await tap(tester, '다음 탐정에게 건네기');
              }
              final detective = tester.widget<JourneyDetectiveScene>(
                find.byType(JourneyDetectiveScene),
              );
              await tap(tester, '${detective.target + 1}번째 단서 친구');
            } else if (find.byType(JourneyRevealScene).evaluate().isNotEmpty &&
                a.id != 'age_24_01' &&
                a.id != 'age_24_06') {
              for (final option in a.choices[step].take(3)) {
                await tap(tester, propLabel(option));
              }
            } else {
              await tap(
                tester,
                a.id == 'age_24_04' && step < 2
                    ? '모모 태우기'
                    : propLabel(a.choices[step].first),
              );
            }
          case 'sort':
            for (var n = 0; n < 4; n++) {
              final scene = tester.widget<JourneySortScene>(
                find.byType(JourneySortScene),
              );
              final label = scene.bySize
                  ? (scene.sequence[n] == 0 ? '작은 도토리 바구니' : '큰 도토리 바구니')
                  : (scene.sequence[n] == 0 ? '빨간 바구니' : '파란 바구니');
              await tap(tester, label);
            }
          case 'build':
            await tester.runAsync(
              () => tester
                  .state<GameWidgetState>(
                    find.byWidgetPredicate((w) => w is GameWidget),
                  )
                  .loaderFuture,
            );
            await tester.pumpAndSettle();
            final board = tester.widget<JourneyBuildBoard>(
              find.byType(JourneyBuildBoard),
            );
            if (step > 0) {
              expect(
                board.slots.length,
                board.count,
                reason: '${a.id} 이전 작품 보존',
              );
            }
            for (var i = 1; i <= board.count; i++) {
              final value = a.id == 'age_60_02'
                  ? (i - 1) % 3
                  : a.id == 'age_60_06' && i == board.count
                  ? 2
                  : a.id == 'age_84_02' && i == board.count
                  ? 1
                  : a.id == 'age_72_05'
                  ? 1
                  : 0;
              await tap(tester, buildPieceLabel(a.id, value));
              await tap(tester, '$i번째 빈 자리');
            }
            expect(
              find.byTooltip('다음 장면'),
              findsNothing,
              reason: '시험 전에는 다음으로 넘어가지 않음',
            );
            await tap(tester, '만든 길 시험하기');
          case 'rhythm':
            final scene = tester.widget<JourneyRhythmScene>(
              find.byType(JourneyRhythmScene),
            );
            if (step > 0) {
              expect(
                scene.slots.length,
                scene.count,
                reason: '${a.id} 이전 악보 보존',
              );
            }
            for (var i = 1; i <= scene.count; i++) {
              await tap(tester, '$i번째 소리 자리');
            }
            expect(
              find.byTooltip(step == 2 ? '놀이 마치기' : '다음 장면'),
              findsNothing,
            );
            await tap(tester, '내 소리 이어 듣기');
            for (var i = 0; i <= scene.count; i++) {
              await tester.pump(const Duration(milliseconds: 700));
            }
            await tester.pumpAndSettle();
          case 'draw':
            final canvas = find.byKey(const ValueKey('journey_canvas'));
            await tester.ensureVisible(canvas);
            await tester.drag(canvas, const Offset(45, 25));
            await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull, reason: '${a.id} 장면 $step');
        expect(
          find.byTooltip(step == 2 ? '놀이 마치기' : '다음 장면'),
          findsOneWidget,
          reason: '${a.id} step $step',
        );
        await tap(tester, step == 2 ? '놀이 마치기' : '다음 장면');
      }
      expect(find.text('즐거웠어!'), findsOneWidget, reason: a.id);
      expect(state.records, isEmpty, reason: '미리보기는 아동 기록에서 제외');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('악보 재생 중 안내를 다시 들어도 놀이가 멈추지 않는다', (tester) async {
    phone(tester);
    final state = await fixtures.prepare(48);
    final a = fixtures.fixture.firstWhere((a) => a.id == 'age_48_06');
    await tester.pumpWidget(
      MaterialApp(
        home: JourneyPlayScreen(
          journey: a,
          appState: state,
          profile: state.activeProfile!.copyWith(playStage: 2),
          preview: true,
          playAsset: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, '놀이 시작');
    for (var i = 1; i <= 3; i++) {
      await tap(tester, '$i번째 소리 자리');
    }
    await tap(tester, '내 소리 이어 듣기');
    expect(
      tester.widget<JourneyRhythmScene>(find.byType(JourneyRhythmScene)).busy,
      isTrue,
    );
    await tap(tester, '안내 다시 듣기');
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 700));
    }
    final scene = tester.widget<JourneyRhythmScene>(
      find.byType(JourneyRhythmScene),
    );
    expect(scene.busy, isFalse);
    expect(scene.active, -1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('기존 10개 놀이의 선택·그림·몸동작이 모두 새 장면에서 작동한다', (tester) async {
    phone(tester);
    final catalog = await const CatalogRepository().load();
    expect(catalog.length, 10);
    for (final a in catalog) {
      final state = await fixtures.prepare(48);
      await tester.pumpWidget(
        MaterialApp(
          home: PlayScreen(
            key: ValueKey(a.id),
            activity: a,
            appState: state,
            profile: state.activeProfile!,
            isParentPreview: true,
            playAsset: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, '놀이 시작');
      if (a.mode == PlayMode.touch) {
        for (final choice in a.choices) {
          await tap(tester, choice);
        }
      } else if (a.mode == PlayMode.move) {
        for (var i = 1; i < a.verses.length; i++) {
          await tap(tester, '다음 동작');
        }
        await tap(tester, '동작 다시 보기');
      } else {
        final studio = find.byType(ForestArtStudio);
        await tap(tester, '꽃 도장');
        final canvas = find
            .descendant(of: studio, matching: find.byType(AspectRatio))
            .first;
        await tester.ensureVisible(canvas);
        await tester.pumpAndSettle();
        await tester.tap(canvas);
        await tester.pumpAndSettle();
        expect(tester.widget<ForestArtStudio>(studio).marks.single.stamp, 1);
        await tap(tester, '마지막 선 지우기');
        expect(tester.widget<ForestArtStudio>(studio).marks, isEmpty);
      }
      expect(tester.takeException(), isNull, reason: a.id);
      await tap(tester, '놀이 마치기');
      expect(find.byTooltip('숲으로 돌아가기'), findsOneWidget, reason: a.id);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('분류는 틀린 바구니를 채우지 않고 맞는 드래그만 쌓인다', (tester) async {
    phone(tester);
    var count = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (_, set) => JourneySortScene(
              id: 'age_30_01',
              step: 0,
              bySize: false,
              bins: 2,
              progress: count,
              goal: 4,
              quiet: true,
              onMatch: () => set(() => count++),
            ),
          ),
        ),
      ),
    );
    for (var n = 0; n < 4; n++) {
      final scene = tester.widget<JourneySortScene>(
        find.byType(JourneySortScene),
      );
      final correct = scene.sequence[n] == 0 ? '빨간 바구니' : '파란 바구니';
      final wrong = scene.sequence[n] == 0 ? '파란 바구니' : '빨간 바구니';
      await tap(tester, wrong);
      expect(count, n);
      await tester.dragFrom(
        tester.getCenter(find.byTooltip('분류할 물건')),
        tester.getCenter(find.byTooltip(correct)) -
            tester.getCenter(find.byTooltip('분류할 물건')),
      );
      await tester.pumpAndSettle();
      expect(count, n + 1);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('동작 반응은 반복해도 멈추고 도중에 나갈 수 있다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ForestMovementScene(id: 'body_hello', step: 0, quiet: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('동작 다시 보기'));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.byTooltip('동작 다시 보기'));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.tap(find.byTooltip('동작 다시 보기'));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
