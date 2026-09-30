import 'package:flame/game.dart';
import 'package:momosup/game/forest_experiment_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/age_journey_repository.dart';
import 'package:momosup/data/catalog_repository.dart';
import 'package:momosup/data/play_catalog.dart';
import 'package:momosup/game/build_experiment.dart';
import 'package:momosup/game/sort_sequence.dart';
import 'package:momosup/models/play_observation.dart';
import 'package:momosup/screens/journey_screen.dart';
import 'package:momosup/screens/observation_screen.dart';
import 'package:momosup/state/app_state.dart';
import 'package:momosup/utils/audio_policy.dart';
import 'package:momosup/utils/play_session.dart';
import 'package:momosup/widgets/forest_art_studio.dart';
import 'package:momosup/widgets/journey_detective_scene.dart';
import 'package:momosup/widgets/games/xylophone_game.dart';

import 'age_journey_test.dart' as fixtures;

class ControlledWatch extends Stopwatch {
  Duration value = Duration.zero;
  bool running = false;
  void advance(int seconds) {
    if (running) value += Duration(seconds: seconds);
  }

  @override
  Duration get elapsed => value;
  @override
  void start() => running = true;
  @override
  void stop() => running = false;
}

class FailingStorage extends FlutterSecureStorage {
  bool fail = false;
  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
  }) async {
    if (fail) throw StateError('storage unavailable');
    return super.write(key: key, value: value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    AudioPolicy.instance.mute(false);
    AudioPolicy.instance.suspend(false);
  });
  setUpAll(() async {
    fixtures.fixture = await fixtures.readDrafts();
    fixtures.approvedPack = await AgeJourneyRepository().load();
  });
  testWidgets('일시중단은 시간·입력을 멈추고 복귀만으로 재개하지 않는다', (tester) async {
    final clock = ControlledWatch();
    var expired = 0, saves = 0, resumed = 0;
    late final PlaySession session;
    session = PlaySession(
      limitSeconds: 40,
      stopwatch: clock,
      onExpire: () {
        expired++;
        session.finish();
      },
      onPause: () {},
      onResume: () => resumed++,
      onCheckpoint: (s) async => saves = s,
    );
    session.start();
    clock.advance(11);
    session.didChangeAppLifecycleState(AppLifecycleState.inactive);
    clock.advance(100);
    session.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(session.paused, isTrue);
    expect(session.seconds, 11);
    expect(AudioPolicy.instance.canVoice, isFalse);
    session.resume();
    clock.advance(29);
    await tester.pump(const Duration(seconds: 1));
    expect(resumed, 1);
    expect(expired, 1);
    expect(saves, 40);
    session.dispose();
  });
  testWidgets('Flame 시험은 중단 상태에서 진행하지 않고 이어한 뒤 한 번만 끝난다', (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 325,
            child: ForestExperimentScene(
              trial: const BuildTrial(
                attempt: 1,
                id: 'age_60_03',
                step: 1,
                stage: 2,
                count: 3,
                pieces: {0: 2, 1: 0, 2: 0},
              ),
              quiet: false,
              onFinished: () => completed++,
            ),
          ),
        ),
      ),
    );
    final finder = find.byWidgetPredicate((w) => w is GameWidget);
    await tester.runAsync(
      () => tester.state<GameWidgetState>(finder).loaderFuture,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final game =
        tester.widget<GameWidget>(finder).game! as ForestExperimentGame;
    expect(game.running, isTrue);
    AudioPolicy.instance.suspend(true);
    final elapsed = game.elapsed;
    await tester.pump(const Duration(seconds: 8));
    expect(game.elapsed, elapsed);
    expect(completed, 0);
    expect(game.paused, isTrue);
    AudioPolicy.instance.suspend(false);
    for (var i = 0; i < 55; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(completed, 1);
    expect(game.running, isFalse);
    expect(game.paused, isTrue);
    await tester.pump(const Duration(seconds: 5));
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('시험 후 조각을 수정하다 앱을 나가도 다시 시험할 수 있다', (tester) async {
    final state = await fixtures.prepare(36);
    final a = fixtures.approvedPack.firstWhere((a) => a.id == 'age_36_06');
    await tester.pumpWidget(
      MaterialApp(
        home: JourneyPlayScreen(
          journey: a,
          appState: state,
          profile: state.activeProfile!.copyWith(
            playStage: 1,
            effectsOn: false,
          ),
          preview: true,
          playAsset: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> tap(String s) async {
      final f = find.byTooltip(s).first;
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    await tap('놀이 시작');
    await tester.runAsync(
      () => tester
          .state<GameWidgetState>(
            find.byWidgetPredicate((w) => w is GameWidget),
          )
          .loaderFuture,
    );
    for (var i = 1; i <= 3; i++) {
      await tap('$i번째 빈 자리');
    }
    await tap('만든 길 시험하기');
    expect(find.byTooltip('다음 장면'), findsOneWidget);
    await tap('1번째 빈 자리');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    await tap('이어서 놀기');
    await tap('만든 길 시험하기');
    expect(find.byTooltip('다음 장면'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('저장 실패는 드래프트를 보존하고 재시도할 수 있다', (tester) async {
    final storage = FailingStorage();
    final state = AppState(storage: storage);
    await state.load();
    await state.addProfile(fixtures.baseProfile);
    final session = PlaySession(
      limitSeconds: 60,
      onExpire: () {},
      onPause: () {},
      onResume: () {},
      onCheckpoint: (_) => state.saveWork(fixtures.baseProfile.id, 'art', {
        'marks': [1, 2, 3],
      }),
    );
    storage.fail = true;
    await session.checkpoint();
    expect(session.saveError, isNotNull);
    expect(state.workFor(fixtures.baseProfile.id, 'art'), isNull);
    storage.fail = false;
    await session.checkpoint();
    expect(session.saveError, isNull);
    final reopened = AppState();
    await reopened.load();
    expect(reopened.workFor(fixtures.baseProfile.id, 'art')!['marks'], [
      1,
      2,
      3,
    ]);
    session.dispose();
  });
  test('음악·안내·효과음 설정과 임시 음소거는 각각 동작한다', () {
    final policy = AudioPolicy.instance;
    policy.configure(
      fixtures.baseProfile.copyWith(
        musicOn: false,
        voiceOn: true,
        effectsOn: false,
      ),
    );
    expect(
      [policy.canMusic, policy.canVoice, policy.canEffects],
      [false, true, false],
    );
    policy.mute(true);
    expect(policy.canVoice, isFalse);
    policy.mute(false);
    expect(policy.canVoice, isTrue);
    expect(policy.canMusic, isFalse);
  });
  test('57개 디지털 놀이를 하나의 목록으로 관리하고 영아에게는 노출하지 않는다', () async {
    final state = await fixtures.prepare(48);
    state.journeys = fixtures.approvedPack;
    final catalog = await const CatalogRepository().load();
    expect(playCatalog(state, catalog).length, 57);
    expect(
      availablePlay(
        state,
        catalog,
        state.activeProfile!,
      ).where((e) => e.toy != null).length,
      5,
    );
    expect(
      availablePlay(
        state,
        catalog,
        state.activeProfile!.copyWith(ageMonths: 6),
      ),
      isEmpty,
    );
    final selected = recommendPlay(state, catalog, state.activeProfile!);
    expect(
      selected.every(
        (e) => e.eligible(state.activeProfile!) && e.approved(state),
      ),
      isTrue,
    );
  });
  test('다리는 약한 재료에서 멈추고 교체 후 통과하며 버스·정원도 실제 조건을 검사한다', () {
    BuildResult trial(
      String id,
      Map<int, int> pieces, {
      int stage = 2,
      int step = 2,
    }) => BuildTrial(
      attempt: 1,
      id: id,
      step: step,
      stage: stage,
      count: 3,
      pieces: pieces,
    ).evaluate();
    expect(trial('age_72_05', {0: 1, 1: 2, 2: 1}).problemSlot, 1);
    expect(trial('age_72_05', {0: 1, 1: 1, 2: 1}).success, isTrue);
    expect(trial('age_60_03', {0: 2, 1: 0, 2: 0}).success, isFalse);
    expect(trial('age_60_03', {0: 0, 1: 0, 2: 0}).success, isTrue);
    expect(trial('age_60_02', {0: 0, 1: 0, 2: 0}).success, isFalse);
    expect(trial('age_60_02', {0: 0, 1: 1, 2: 2}).success, isTrue);
    expect(trial('age_60_06', {0: 0, 1: 1, 2: 0}).success, isFalse);
    expect(trial('age_60_06', {0: 0, 1: 1, 2: 2}).success, isTrue);
  });
  test('분류 순서는 재개 시 보존되며 항상 좌우 교대로 나오지 않는다', () {
    final orders = [
      for (var seed = 0; seed < 12; seed++)
        sortSequence(seed: seed, step: 0, bins: 2, goal: 4),
    ];
    expect(orders.any((v) => v[0] == v[1] || v[1] == v[2]), isTrue);
    expect(orders.map((v) => v.join()).toSet().length, greaterThan(2));
    expect(
      sortSequence(seed: 8, step: 1, bins: 2, goal: 4),
      sortSequence(seed: 8, step: 1, bins: 2, goal: 4),
    );
  });
  testWidgets('탐정은 맞는 단서를 비교하고 차례를 건넨 뒤 찾는다', (tester) async {
    var found = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JourneyDetectiveScene(
            step: 1,
            count: 3,
            stage: 2,
            quiet: true,
            cooperative: true,
            onFound: (_) => found++,
          ),
        ),
      ),
    );
    expect(find.byTooltip('1번째 단서 친구'), findsNothing);
    await tester.tap(find.byTooltip('다음 탐정에게 건네기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('1번째 단서 친구'));
    await tester.pumpAndSettle();
    expect(found, 0);
    await tester.tap(find.byTooltip('2번째 단서 친구'));
    await tester.pumpAndSettle();
    expect(found, 1);
    await tester.tap(find.byTooltip('2번째 단서 친구'));
    await tester.pumpAndSettle();
    expect(found, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('실로폰 따라하기를 마친 뒤 연타해도 한 번만 완료된다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var complete = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: XylophoneGame(
            lowStimulation: true,
            onComplete: () => complete++,
          ),
        ),
      ),
    );
    Finder key(String s) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == '$s 음 연주',
    );
    for (final n in ['도', '레', '미', '파', '솔', '라', '시', '높은 도']) {
      await tester.tap(key(n));
      await tester.pump();
    }
    await tester.tap(find.text('따라하기'));
    await tester.pump();
    for (final n in ['도', '레', '미', '도', '미', '도', '레']) {
      await tester.tap(key(n));
      await tester.pump();
    }
    expect(complete, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('저장된 그림을 재시작 후 복원하고 미리보기는 덮어쓰지 않는다', (tester) async {
    final state = await fixtures.prepare(36);
    final p = state.activeProfile!;
    final a = fixtures.approvedPack.firstWhere((a) => a.id == 'age_36_05');
    await state.saveWork(p.id, a.id, {
      'review': a.reviewKey,
      'complete': false,
      'marks': [
        ArtMark(Colors.red, [
          const Offset(.2, .3),
          const Offset(.4, .5),
        ]).toJson(),
      ],
    });
    final loaded = AppState();
    await loaded.load();
    loaded.journeys = fixtures.approvedPack;
    await tester.pumpWidget(
      MaterialApp(
        home: JourneyPlayScreen(
          journey: a,
          appState: loaded,
          profile: p,
          preview: true,
          restoreSaved: true,
          playAsset: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('놀이 시작'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ForestArtStudio>(find.byType(ForestArtStudio)).marks.length,
      1,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    expect(loaded.records, isEmpty);
    expect(loaded.workFor(p.id, a.id)!['marks'].length, 1);
  });
  testWidgets('관찰 화면은 가짜 결과 없이 시작하며 실제 기록은 분리 저장·삭제한다', (tester) async {
    final state = await fixtures.prepare(48);
    final p = state.activeProfile!;
    await tester.pumpWidget(
      MaterialApp(
        home: ObservationScreen(state: state, profile: p, catalog: const []),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('관찰 0건'), findsOneWidget);
    expect(
      observationSuggestion(state.observations),
      contains('아직 실제 관찰 기록이 없어요'),
    );
    final o = PlayObservation(
      id: 'o',
      profileId: p.id,
      activityId: 'age_48_01',
      at: DateTime.now(),
      ageMonths: 48,
      stage: 1,
      start: 1,
      help: 1,
      enjoyment: 1,
      ending: 0,
      offscreen: 0,
      device: 'iPhone',
      issues: const [],
    );
    await state.saveObservation(o);
    await tester.pumpAndSettle();
    final restored = AppState();
    await restored.load();
    expect(restored.observations.length, 1);
    expect(o.anonymousSummaryRow().keys, isNot(contains('profileId')));
    expect(o.anonymousSummaryRow().keys, isNot(contains('ageMonths')));
    await state.deleteObservation('o');
    expect(state.observations, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
