import 'package:momosup/data/journey_recommendation.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/age_journey_repository.dart';
import 'package:momosup/models/age_journey.dart';
import 'package:momosup/models/child_profile.dart';
import 'package:momosup/screens/home_screen.dart';
import 'package:momosup/screens/journey_screen.dart';
import 'package:momosup/state/app_state.dart';

const baseProfile = ChildProfile(
  id: 'age_test',
  nickname: '숲친구',
  ageMonths: 6,
  avatar: 'momo',
  level: '기본',
  answers: [3, 3, 3, 3, 3],
  lowStimulation: true,
  musicOn: false,
);
Future<AppState> prepare(int age) async {
  FlutterSecureStorage.setMockInitialValues({});
  final state = AppState();
  await state.load();
  await state.setParentPin('123456');
  await state.addProfile(baseProfile.copyWith(ageMonths: age));
  return state;
}

late List<AgeJourney> fixture;
Future<List<AgeJourney>> drafts() async => fixture;
Future<List<AgeJourney>> readDrafts() async {
  final pack = jsonDecode(
    await rootBundle.loadString('assets/content/age_journeys.json'),
  ) as Map<String, dynamic>;
  return (pack['activities'] as List)
      .map((v) => AgeJourney(Map<String, dynamic>.from(v as Map)))
      .toList();
}

void main() {
  setUpAll(() async {
    fixture = await readDrafts();
  });
  test('매달 정확히 여섯 놀이이며 영아는 보호자용만 있다', () async {
    final pack = await drafts();
    expect(pack.length, 72);
    expect(pack.map((a) => a.id).toSet().length, 72);
    for (var m = 6; m <= 95; m++) {
      final matching = pack.where((a) => a.supports(m));
      expect(matching.length, 6, reason: '$m개월');
      expect(matching.every((a) => a.isCaregiver), m < 24);
    }
    expect(pack.where((a) => a.supports(5)), isEmpty);
    expect(pack.where((a) => a.supports(96)), isEmpty);
    expect(pack.where((a) => a.supports(84, preschool: false)), isEmpty);
    expect(pack.expand((a) => a.steps).length, 216);
    expect(pack.expand((a) => a.variants).length, 216);
  });
  test('즐겨찾기는 적합한 다음 월령에서 유지되고 영아·취학 경계는 넘지 않는다', () {
    final a = fixture.firstWhere((a) => a.minAge == 36);
    final older = baseProfile.copyWith(ageMonths: 48, favoriteJourneys: [a.id]);
    expect(journeyEligible(a, older), isTrue);
    expect(journeyEligible(a, older.copyWith(ageMonths: 6)), isFalse);
    expect(
      journeyEligible(a, older.copyWith(ageMonths: 84, preschool: false)),
      isFalse,
    );
    final recommended = recommendJourneys(older, fixture, played: {a.id});
    expect(recommended.first.id, a.id);
    expect(recommended.length, 3);
    expect(recommended.map((a) => a.id).toSet().length, 3);
  });
  test('기존 프로필 호환·정확한 월령·도움 수준 저장', () {
    final old = baseProfile.toJson()
      ..remove('preschool')
      ..remove('playStage');
    expect(ChildProfile.fromJson(old).playStage, 0);
    final changed = ChildProfile.fromJson(
      baseProfile
          .copyWith(ageMonths: 35, playStage: 2, preschool: false)
          .toJson(),
    );
    expect(changed.ageLabel, '35개월');
    expect(changed.playStage, 2);
    expect(changed.preschool, isFalse);
  });
  test('검수는 정확한 대본과 음성 해시에 종속되며 파일 없는 승인은 거절된다', () async {
    final state = await prepare(36);
    final item = (await drafts()).firstWhere((a) => a.minAge == 36);
    expect(() => state.reviewJourney(item, approved: true), throwsStateError);
    final validated = AgeJourney(
      {
        ...item.data,
        'validatedAudioHashes': {'step_0': 'abc'},
      },
      audio: {for (final id in item.audioIds) id: 'verified/$id'},
    );
    await state.reviewJourney(validated, approved: true);
    expect(state.journeyApproved(validated), isTrue);
    final changed = AgeJourney({
      ...validated.data,
      'steps': ['새 안내', ...item.steps.skip(1)],
    }, audio: validated.audio);
    expect(state.journeyApproved(changed), isFalse);
    final changedAudio = AgeJourney({
      ...validated.data,
      'validatedAudioHashes': {'step_0': 'changed'},
    }, audio: validated.audio);
    expect(state.journeyApproved(changedAudio), isFalse);
    final reloaded = AppState();
    await reloaded.load();
    expect(reloaded.journeyApproved(validated), isTrue);
    await reloaded.reviewJourney(validated, approved: false);
    expect(reloaded.journeyApproved(validated), isFalse);
  });
  test('저장된 새 음성은 해시·대본 일치만 미리보기에 로드한다', () async {
    final items = await AgeJourneyRepository().load();
    expect(items.length, 72);
    final manifest = jsonDecode(
      await rootBundle.loadString('assets/content/age_audio_manifest.json'),
    ) as Map;
    final music = jsonDecode(
      await rootBundle.loadString('assets/content/age_music_manifest.json'),
    ) as Map;
    expect(
      items.fold<int>(0, (n, a) => n + a.audio.length),
      (manifest['jobs'] as List).length + (music['jobs'] as List).length,
    );
    final state = await prepare(24);
    expect(items.any(state.journeyApproved), isFalse);
  });
  testWidgets('6개월 홈은 모든 아이 게임과 음소거 해제를 숨긴다', (tester) async {
    final state = await prepare(6);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(appState: state, catalog: const []),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('오늘은 함께 노는 날'), findsOneWidget);
    expect(find.byTooltip('감각 놀이숲'), findsNothing);
    expect(find.byTooltip('열매 먹이기'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('보호자 안내는 화면 내려놓기로 끝나며 아동 이용 기록을 만들지 않는다', (tester) async {
    final state = await prepare(6);
    final item = (await drafts()).first;
    await tester.pumpWidget(
      MaterialApp(
        home: JourneyDetailScreen(
          journey: item,
          appState: state,
          profile: state.activeProfile!,
        ),
      ),
    );
    final start = find.text('안내 끝 · 휴대폰 내려놓기');
    await tester.scrollUntilVisible(start, 300);
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(find.text('휴대폰을 내려놓고\n함께 놀아 주세요'), findsOneWidget);
    expect(state.records, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('미승인·다른 월령은 게임 직접 진입도 차단한다', (tester) async {
    final state = await prepare(6);
    final item = (await drafts()).firstWhere((a) => !a.isCaregiver);
    await tester.pumpWidget(
      MaterialApp(
        home: JourneyPlayScreen(
          journey: item,
          appState: state,
          profile: state.activeProfile!,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('놀이 시작'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('추천 영아 놀이도 PIN을 거친 뒤 정확한 안내로 이동한다', (tester) async {
    final state=await prepare(6);state.journeys=fixture;
    await tester.pumpWidget(MaterialApp(home:HomeScreen(appState:state,catalog:const [])));await tester.pumpAndSettle();
    final title=fixture.first.title;await tester.scrollUntilVisible(find.text(title),150);await tester.tap(find.text(title));await tester.pumpAndSettle();
    expect(find.text('보호자만 들어갈 수 있어요'),findsOneWidget);
    await tester.enterText(find.byType(TextField),'123456');await tester.tap(find.text('보호자 화면 열기'));await tester.pumpAndSettle();
    expect(find.byType(JourneyDetailScreen),findsOneWidget);expect(find.text(title),findsOneWidget);await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final mechanic in [
    'reveal',
    'story',
    'sort',
    'build',
    'rhythm',
    'draw',
  ]) {
    testWidgets('$mechanic 미리보기 작은 화면에서 입력·종료 가능', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final item = (await drafts()).firstWhere((a) => a.mechanic == mechanic);
      final state = await prepare(item.minAge);
      await tester.pumpWidget(
        MaterialApp(
          home: JourneyPlayScreen(
            journey: item,
            appState: state,
            profile: state.activeProfile!,
            preview: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byTooltip('놀이 시작'), 200);
      await tester.tap(find.byTooltip('놀이 시작'));
      await tester.pumpAndSettle();
      if (mechanic == 'reveal' || mechanic == 'story') {
        await tester.tap(
          find.byTooltip(propLabel(item.choices.first.first)).first,
        );
      }
      if (mechanic == 'sort') {
        await tester.scrollUntilVisible(find.byTooltip('빨간 바구니'), 160);
        await tester.tap(find.byTooltip('빨간 바구니'));
      }
      if (mechanic == 'build') {
        for (var i = 1; i <= 2; i++) {
          await tester.tap(find.byTooltip('$i번째 빈 자리'));
        }
      }
      if (mechanic == 'rhythm') {
        for (var i = 1; i <= 2; i++) {
          await tester.tap(find.byTooltip('$i번째 소리 자리'));
        }
      }
      if (mechanic == 'draw') {
        await tester.drag(
          find.byKey(const ValueKey('journey_canvas')),
          const Offset(40, 30),
        );
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.byTooltip('놀이 마치기'), 160);
      await tester.tap(find.byTooltip('놀이 마치기'));
      await tester.pumpAndSettle();
      expect(find.text('즐거웠어!'), findsOneWidget);
      expect(state.records, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
