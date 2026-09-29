import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/age_journey_repository.dart';
import 'package:momosup/models/child_profile.dart';
import 'package:momosup/screens/journey_screen.dart';
import 'package:momosup/screens/parent_screen.dart';
import 'package:momosup/widgets/journey_garden_scene.dart';
import 'package:momosup/widgets/journey_picnic_scene.dart';
import 'package:momosup/widgets/touch_invitation.dart';

import 'age_journey_test.dart' as fixtures;

void main() {
  setUpAll(() async {
    fixtures.fixture = await fixtures.readDrafts();
    fixtures.approvedPack = await AgeJourneyRepository().load();
  });

  test('월령 추천과 도움 답변을 적용하며 보호자가 고른 단계는 보존한다', () {
    for (final (age, expected) in [
      (6, 0),
      (24, 0),
      (30, 1),
      (48, 1),
      (60, 2),
      (84, 2),
    ]) {
      final p = fixtures.baseProfile.copyWith(ageMonths: age);
      expect(p.effectivePlayStage, expected);
      expect(ChildProfile.fromJson(p.toJson()).effectivePlayStage, expected);
    }
    final older = fixtures.baseProfile.copyWith(ageMonths: 72);
    expect(older.copyWith(answers: [0, 3, 3, 3, 3]).effectivePlayStage, 0);
    expect(older.copyWith(answers: [1, 3, 3, 3, 3]).effectivePlayStage, 1);
    expect(older.copyWith(playStage: 0).effectivePlayStage, 0);
    expect(
      ChildProfile.fromJson(older.copyWith(playStage: 0).toJson()).playStage,
      0,
    );
    expect(
      older.copyWith(playStage: 2, answers: [0, 0, 0, 0, 0]).effectivePlayStage,
      2,
    );
  });

  Future<void> openPlay(WidgetTester tester, String id, {int stage = 1}) async {
    final a = fixtures.fixture.firstWhere((a) => a.id == id);
    final state = await fixtures.prepare(a.minAge);
    await tester.pumpWidget(
      MaterialApp(
        home: JourneyPlayScreen(
          journey: a,
          appState: state,
          profile: state.activeProfile!.copyWith(playStage: stage),
          preview: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byTooltip('놀이 시작'), 180);
    await tester.tap(find.byTooltip('놀이 시작'));
    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester, {bool end = false}) async {
    final button = find.byTooltip(end ? '놀이 마치기' : '다음 장면');
    await tester.scrollUntilVisible(button, 120);
    await tester.tap(button);
    await tester.pumpAndSettle();
    if (!end) {
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 500),
      );
      await tester.pumpAndSettle();
    }
  }

  testWidgets('세 꽃은 모습이 다르고 앞서 핀 꽃이 정원에 남는다', (tester) async {
    await openPlay(tester, 'age_24_01');
    for (var i = 0; i < 3; i++) {
      final flowers = tester
          .widgetList<GardenFlower>(find.byType(GardenFlower))
          .toList();
      expect(flowers.where((f) => f.open).length, i);
      expect(flowers.last.variant, i);
      await tester.tap(find.byTooltip('꽃'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<GardenFlower>(find.byType(GardenFlower))
            .every((f) => f.open),
        isTrue,
      );
      await next(tester, end: i == 2);
    }
    expect(find.text('보호자와 손바닥을 천천히 펴봐요.'), findsOneWidget);
    expect(find.byTooltip('다음 장면'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('날씨 놀이의 구름 → 꽃 → 햇살을 각 대상에 직접 터치한다', (tester) async {
    await openPlay(tester, 'age_24_06');
    for (var i = 0; i < 3; i++) {
      final label = ['구름', '꽃', '해'][i];
      expect(find.byTooltip(label), findsOneWidget);
      await tester.tap(find.byTooltip(label));
      await tester.pumpAndSettle();
      final scene = tester.widget<JourneyGardenScene>(
        find.byType(JourneyGardenScene),
      );
      expect(scene.step, i);
      expect(scene.revealed, isTrue);
      if (i == 0) {
        expect(find.byKey(const ValueKey('garden-rain')), findsOneWidget);
      }
      await next(tester, end: i == 2);
    }
    expect(find.text('보호자와 창밖을 잠깐 바라봐요.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('소풍 선택을 바꾸면 친구 반응이 바뀌고 세 부탁 뒤에 끝난다', (tester) async {
    await openPlay(tester, 'age_48_01', stage: 2);
    final semantics = tester.ensureSemantics();
    for (final choice in ['나뭇잎', '바구니', '숲집']) {
      await tester.tap(find.byTooltip(choice));
      await tester.pumpAndSettle();
      final scene = tester.widget<JourneyPicnicScene>(
        find.byType(JourneyPicnicScene),
      );
      expect(
        scene.gift,
        {'나뭇잎': 'leaf', '바구니': 'basket', '숲집': 'home'}[choice],
      );
    }
    expect(find.bySemanticsLabel('친구가 비를 피해 숲집에서 쉬어요'), findsOneWidget);
    await next(tester);
    await tester.tap(find.byTooltip('구름'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('누리가 폭신한 구름 자리에서 쉬어요'), findsOneWidget);
    await next(tester);
    await tester.tap(find.byTooltip('친구 마음'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('친구들이 모모 곁에 모여요'), findsOneWidget);
    await next(tester, end: true);
    expect(find.text('즐거웠어!'), findsOneWidget);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('손짓 안내는 터치를 막지 않고 두 번 뒤 멈춘다', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GestureDetector(
              onTap: () => taps++,
              child: TouchInvitation(
                visible: true,
                quiet: false,
                child: Container(width: 150, height: 150, color: Colors.green),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byType(TouchInvitation));
    expect(taps, 1);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(TouchInvitation),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('보호자 추천에서 실제 놀이로 이동하고 단계 변경은 저장된다', (tester) async {
    final state = await fixtures.prepare(48);
    state.journeys = fixtures.approvedPack;
    await state.updateProfile(state.activeProfile!.copyWith(playStage: 0));
    await tester.pumpWidget(
      MaterialApp(
        home: ParentHubScreen(appState: state, catalog: const []),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '월령 추천'));
    await tester.pumpAndSettle();
    expect(state.activeProfile!.playStage, -1);
    expect(state.activeProfile!.effectivePlayStage, 1);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('parent-quick-start')),
      130,
    );
    await tester.tap(find.byKey(const ValueKey('parent-quick-start')));
    await tester.pumpAndSettle();
    final play = tester.widget<JourneyPlayScreen>(
      find.byType(JourneyPlayScreen),
    );
    expect(play.preview, isFalse);
    expect(play.journey.supports(48), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('영아 추천은 보호자 안내만 열고 화면 놀이를 시작하지 않는다', (tester) async {
    final state = await fixtures.prepare(6);
    state.journeys = fixtures.approvedPack;
    await tester.pumpWidget(
      MaterialApp(
        home: ParentHubScreen(appState: state, catalog: const []),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('parent-quick-start')));
    await tester.pumpAndSettle();
    expect(find.byType(JourneyDetailScreen), findsOneWidget);
    expect(find.byType(JourneyPlayScreen), findsNothing);
    expect(state.records, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
