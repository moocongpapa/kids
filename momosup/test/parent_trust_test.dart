import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/screens/parent/parent_care_summary.dart';
import 'package:momosup/screens/parent/parent_settings_screen.dart';

import 'story_playback_test.dart' as fixture;

void main() {
  testWidgets('보호자 요약은 같은 날짜의 아이 기록과 저장된 설정을 정확히 보여 준다', (tester) async {
    final profile = fixture.testProfile.copyWith(
      dailyLimitMinutes: 10,
      musicOn: false,
      voiceOn: true,
      lowStimulation: true,
    );
    final state = await fixture.setup(profile);
    await state.recordPlay(
      profileId: profile.id,
      activityId: 'game',
      seconds: 45,
    );
    await state.recordPlay(
      profileId: profile.id,
      activityId: 'story',
      seconds: 35,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ParentCareSummary(appState: state, profile: profile),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1분 20초'), findsOneWidget);
    expect(find.textContaining('8분 40초 남았어요'), findsOneWidget);
    expect(find.text('배경음악 끔'), findsOneWidget);
    expect(find.text('차분한 움직임'), findsOneWidget);
    expect(find.text('보호자 PIN 설정됨'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('영아 보호자 화면은 화면 밖 놀이를 안내한다', (tester) async {
    final profile = fixture.testProfile.copyWith(ageMonths: 8);
    final state = await fixture.setup(profile);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ParentCareSummary(appState: state, profile: profile),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('보호자와 화면 밖에서'), findsOneWidget);
    expect(find.byKey(const ValueKey('today-exact-usage')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('신뢰 화면의 영상 공개·검수 수치는 현재 카탈로그를 반영한다', (tester) async {
    final state = await fixture.setup();
    await tester.pumpWidget(MaterialApp(home: TrustScreen(appState: state)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('영상 준비 상태'), 250);
    await tester.pumpAndSettle();
    expect(find.textContaining('아이에게 공개된 영상 0편'), findsOneWidget);
    expect(find.textContaining('보호자 전용 전체 편집본 1편 · 첫 장면 2편'), findsOneWidget);
    expect(find.textContaining('사람의 최종 검수 기록 0 / 3편'), findsOneWidget);
    expect(find.textContaining('현재 음성·노래 파일이 없어'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
