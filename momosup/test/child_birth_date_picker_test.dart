import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/models/child_profile.dart';
import 'package:momosup/models/parent_account.dart';
import 'package:momosup/screens/parent/profile_editor_screen.dart';
import 'package:momosup/screens/parent_onboarding_screen.dart';
import 'package:momosup/state/app_state.dart';

import 'development_onboarding_test.dart' as fixtures;

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  for (final registration in [true, false]) {
    testWidgets('한국어 설정 없는 기존 앱에서도 생일 달력을 연다: ${registration ? '등록' : '수정'}', (
      tester,
    ) async {
      fixtures.phone(tester);
      final state = AppState();
      await state.load();
      await state.setParentAccount(
        ParentAccount(
          id: 'date_test_parent',
          nickname: '테스트 보호자',
          connectedAt: DateTime(2026),
        ),
      );
      final screen = registration
          ? ParentOnboardingScreen(appState: state)
          : ProfileEditorScreen(
              appState: state,
              initial: const ChildProfile(
                id: 'date_test',
                nickname: '테스트 아이',
                birthDate: '2023-05-15',
                ageMonths: 36,
                avatar: 'momo',
                level: '기본',
                answers: [3, 3, 3, 3, 3],
              ),
            );
      // This intentionally matches the older app host, without Korean delegates.
      await tester.pumpWidget(MaterialApp(home: screen));
      await tester.pumpAndSettle();
      await fixtures.tapVisible(
        tester,
        find.byIcon(Icons.calendar_today_rounded),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(DatePickerDialog), findsOneWidget);
      final context = tester.element(find.byType(DatePickerDialog));
      expect(MaterialLocalizations.of(context).cancelButtonLabel, '취소');
      expect(Localizations.localeOf(context).languageCode, 'ko');
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }
}
