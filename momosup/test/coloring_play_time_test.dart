import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/models/child_profile.dart';
import 'package:momosup/screens/coloring_screen.dart';
import 'package:momosup/state/app_state.dart';
import 'package:momosup/utils/play_checkpoint.dart';
import 'package:momosup/utils/play_session.dart';
import 'package:momosup/widgets/forest_coloring_studio.dart';
import 'package:momosup/widgets/forest_game_ui.dart';

class _ActiveWatch extends Stopwatch {
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

class _DelayedState extends AppState {
  Completer<void>? gate;
  bool fail = false;

  @override
  Future<void> saveWork(
    String profileId,
    String activityId,
    Map<String, dynamic> data,
  ) async {
    await gate?.future;
    if (fail) throw StateError('storage unavailable');
    await super.saveWork(profileId, activityId, data);
  }
}

class _DelayedRecordState extends AppState {
  final gate = Completer<void>();
  final calls = <int>[];

  @override
  Future<void> recordPlay({
    required String profileId,
    required String activityId,
    required int seconds,
    String? sessionId,
    Map<String, int> metrics = const {},
  }) async {
    calls.add(seconds);
    if (calls.length == 1) await gate.future;
    await super.recordPlay(
      profileId: profileId,
      activityId: activityId,
      seconds: seconds,
      sessionId: sessionId,
      metrics: metrics,
    );
  }
}

const _profile = ChildProfile(
  id: 'coloring_test',
  nickname: '숲친구',
  ageMonths: 48,
  avatar: 'momo',
  level: '기본',
  answers: [3, 3, 3, 3, 3],
  dailyLimitMinutes: 1,
  lowStimulation: true,
  musicOn: false,
  effectsOn: false,
);

Future<AppState> _prepare({AppState? state, ChildProfile? profile}) async {
  FlutterSecureStorage.setMockInitialValues({});
  final result = state ?? AppState();
  await result.load();
  await result.addProfile(profile ?? _profile);
  return result;
}

Future<void> _mount(
  WidgetTester tester,
  AppState state,
  _ActiveWatch clock,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ColoringScreen(
                  profile: state.activeProfile!,
                  appState: state,
                  stopwatch: clock,
                ),
              ),
            ),
            child: const Text('색칠 시작'),
          ),
        ),
      ),
    ),
  );
  await _open(tester);
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('색칠 시작'));
  await tester.pumpAndSettle();
}

PlaySession _session(WidgetTester tester) =>
    tester.widget<PlaySessionView>(find.byType(PlaySessionView)).session;

Future<void> _advance(
  WidgetTester tester,
  _ActiveWatch clock,
  int seconds,
) async {
  clock.advance(seconds);
  await tester.pump(Duration(seconds: seconds));
  await tester.pumpAndSettle();
}

Future<void> _close(WidgetTester tester) async {
  await tester.tap(find.byTooltip('놀이 마치기'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('색칠 체크포인트와 여러 생명주기 중단은 활성 시간만 한 번 기록한다', (tester) async {
    final state = await _prepare();
    final clock = _ActiveWatch();
    await _mount(tester, state, clock);
    final session = _session(tester);
    tester
        .widget<ForestColoringStudio>(find.byType(ForestColoringStudio))
        .onChanged!();
    await _advance(tester, clock, 15);
    expect(state.records.single.seconds, 15);
    expect(state.records.single.activityId, 'coloring');
    final sessionId = state.records.single.sessionId;

    clock.advance(4);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(state.records.single.seconds, 19);
    expect(state.records.single.metrics['interruptions'], 1);
    expect(state.records.single.metrics['actions'], 1);
    await _advance(tester, clock, 100);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(session.paused, isTrue);
    expect(clock.running, isFalse);
    expect(find.byTooltip('이어서 놀기'), findsOneWidget);
    // Input underneath the resume overlay is blocked; the studio stays mounted.
    expect(find.byType(ForestColoringStudio), findsOneWidget);
    final input = find.ancestor(
      of: find.byType(ForestColoringStudio),
      matching: find.byType(IgnorePointer),
    );
    expect(
      input.evaluate().any((e) => (e.widget as IgnorePointer).ignoring),
      isTrue,
    );

    await tester.tap(find.byTooltip('이어서 놀기'));
    await tester.pumpAndSettle();
    await _advance(tester, clock, 7);
    await _close(tester);
    expect(find.byType(ColoringScreen), findsNothing);
    expect(state.records.single.seconds, 26);
    expect(state.records.single.sessionId, sessionId);
    expect(state.secondsRemaining(_profile.id, 1), 34);
    final reopened = AppState();
    await reopened.load();
    expect(reopened.records.single.seconds, 26);
  });

  testWidgets('남은 하루 시간이 끝나면 색칠 입력이 사라지고 초과·중복 차감하지 않는다', (tester) async {
    final state = await _prepare();
    await state.recordPlay(
      profileId: _profile.id,
      activityId: 'other',
      seconds: 55,
    );
    final clock = _ActiveWatch();
    await _mount(tester, state, clock);
    final session = _session(tester);
    expect(session.limitSeconds, 5);
    // A delayed frame/timer must not record beyond the available allowance.
    await _advance(tester, clock, 9);
    expect(session.ended, isTrue);
    expect(clock.running, isFalse);
    expect(find.byType(ForestColoringStudio), findsNothing);
    expect(find.byType(ForestCompletion), findsOneWidget);
    expect(state.records.last.seconds, 5);
    expect(state.secondsRemaining(_profile.id, 1), 0);
    await _advance(tester, clock, 100);
    await _close(tester);
    expect(state.records.length, 2);
    expect(state.records.last.seconds, 5);
    clock.value = Duration.zero;
    await _open(tester);
    expect(_session(tester).ended, isTrue);
    expect(find.byType(ForestColoringStudio), findsNothing);
    await _close(tester);
    expect(state.records.length, 2);
  });

  testWidgets('체크포인트 전 나가기와 재입장은 누적 사용량과 별도 세션을 보존한다', (tester) async {
    final state = await _prepare();
    final clock = _ActiveWatch();
    await _mount(tester, state, clock);
    await _advance(tester, clock, 6);
    await _close(tester);
    final firstId = state.records.single.sessionId;
    expect(state.records.single.seconds, 6);
    clock.value = Duration.zero;
    await _open(tester);
    expect(_session(tester).limitSeconds, 54);
    await _advance(tester, clock, 8);
    await _close(tester);
    expect(state.records.length, 2);
    expect(state.records.last.sessionId, isNot(firstId));
    expect(state.records.last.seconds, 8);
    expect(state.secondsRemaining(_profile.id, 1), 46);
  });

  testWidgets('중단된 화면에서 시스템 뒤로 가기는 마지막 시간을 저장하고 종료한다', (tester) async {
    final state = await _prepare();
    final clock = _ActiveWatch();
    await _mount(tester, state, clock);
    await _advance(tester, clock, 11);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ColoringScreen), findsNothing);
    expect(state.records.single.seconds, 11);
    expect(state.records.single.metrics['interruptions'], 1);
  });

  testWidgets('강제로 화면을 제거해도 마지막 체크포인트 이후 사용량을 잃지 않는다', (tester) async {
    final state = await _prepare();
    final clock = _ActiveWatch();
    await _mount(tester, state, clock);
    await _advance(tester, clock, 15);
    clock.advance(3);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(clock.running, isFalse);
    expect(state.records.single.seconds, 18);
    expect(state.secondsRemaining(_profile.id, 1), 42);
  });

  testWidgets('7분 넘는 색칠도 모두 기록하고 재입장 후 하루 한도에서만 끝난다', (tester) async {
    final state = await _prepare(
      profile: _profile.copyWith(dailyLimitMinutes: 15),
    );
    final clock = _ActiveWatch();
    await _mount(tester, state, clock);
    expect(_session(tester).limitSeconds, 900);
    await _advance(tester, clock, 420);
    expect(find.byType(ForestColoringStudio), findsOneWidget);
    expect(state.records.single.seconds, 420);
    await _advance(tester, clock, 45);
    expect(state.records.map((r) => r.seconds), [420, 45]);
    expect(state.secondsRemaining(_profile.id, 15), 435);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(state.records.first.metrics['interruptions'], 1);
    expect(state.records.last.metrics, isEmpty);
    await tester.tap(find.byTooltip('이어서 놀기'));
    await tester.pumpAndSettle();
    await _close(tester);
    expect(state.records.map((r) => r.seconds), [420, 45]);
    clock.value = Duration.zero;
    await _open(tester);
    expect(_session(tester).limitSeconds, 435);
    await _advance(tester, clock, 435);
    expect(find.byType(ForestCompletion), findsOneWidget);
    await _close(tester);
    expect(state.records.map((r) => r.seconds), [420, 45, 420, 15]);
    expect(state.secondsRemaining(_profile.id, 15), 0);
    final reopened = AppState();
    await reopened.load();
    expect(reopened.secondsRemaining(_profile.id, 15), 0);
  });

  testWidgets('긴 세션의 겹친 저장은 순서대로 처리하고 오래된 청크로 덮어쓰지 않는다', (tester) async {
    final state =
        await _prepare(state: _DelayedRecordState()) as _DelayedRecordState;
    final checkpoint = PlayCheckpoint(
      state,
      _profile.id,
      'coloring',
      () => {},
      splitLongSessions: true,
    );
    final earlier = checkpoint.checkpoint(435);
    await tester.pumpAndSettle();
    final later = checkpoint.checkpoint(450);
    await tester.pumpAndSettle();
    expect(state.calls, [420]);
    state.gate.complete();
    await Future.wait([earlier, later]);
    expect(state.calls, [420, 15, 420, 30]);
    expect(state.records.map((r) => r.seconds), [420, 30]);
    expect(state.records.last.sessionId, '${state.records.first.sessionId}:1');
    checkpoint.dispose();
  });

  testWidgets('저장이 지연되어도 중복 나가기로 먼저 재입장하거나 시간을 두 번 더하지 않는다', (tester) async {
    final state = await _prepare(state: _DelayedState()) as _DelayedState;
    final clock = _ActiveWatch();
    await _mount(tester, state, clock);
    await _advance(tester, clock, 4);
    state.gate = Completer<void>();
    await tester.tap(find.byTooltip('놀이 마치기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('놀이 마치기'));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ColoringScreen), findsOneWidget);
    expect(clock.running, isFalse);
    expect(find.byType(ForestColoringStudio), findsNothing);
    state.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ColoringScreen), findsNothing);
    expect(state.records.single.seconds, 4);
    clock.value = Duration.zero;
    await _open(tester);
    expect(_session(tester).limitSeconds, 56);
    await _close(tester);
  });

  testWidgets('저장 실패 시 종료 화면에서 시간을 멈추고 나가기 재시도로 사용량을 보존한다', (tester) async {
    final state = await _prepare(state: _DelayedState()) as _DelayedState;
    final clock = _ActiveWatch();
    await _mount(tester, state, clock);
    await _advance(tester, clock, 9);
    state.fail = true;
    await _close(tester);
    expect(find.byType(ColoringScreen), findsOneWidget);
    expect(_session(tester).saveError, isNotNull);
    expect(clock.running, isFalse);
    await _advance(tester, clock, 100);
    state.fail = false;
    await _close(tester);
    expect(find.byType(ColoringScreen), findsNothing);
    expect(state.records.single.seconds, 9);
  });
}
