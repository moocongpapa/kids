import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:momosup/main.dart';
import 'package:momosup/models/child_profile.dart';
import 'package:momosup/models/parent_account.dart';
import 'package:momosup/state/app_state.dart';
import 'package:momosup/screens/parent_onboarding_screen.dart';
import 'package:momosup/screens/parent/profile_editor_screen.dart';
import 'package:momosup/services/kakao_auth_service.dart';

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });
}

Widget localizedApp(Widget screen) => MaterialApp(
  locale: const Locale('ko', 'KR'),
  supportedLocales: const [Locale('ko', 'KR'), Locale('en')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: screen,
);

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('실제 앱의 한국어 생년월일 달력이 오류 없이 열린다', (tester) async {
    phone(tester);
    final state = AppState();
    await state.load();
    await state.setParentAccount(
      ParentAccount(
        id: 'test_parent',
        nickname: '테스트 보호자',
        connectedAt: DateTime(2026),
      ),
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(const MomosupApp());
      await (tester.state(find.byType(MomosupApp)) as dynamic).boot;
    });
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('카카오로 3초 만에 시작하기'));
    await tapVisible(tester, find.byIcon(Icons.calendar_today_rounded));
    expect(tester.takeException(), isNull);
    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(
      Localizations.localeOf(tester.element(find.byType(DatePickerDialog)))
          .languageCode,
      'ko',
    );
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets('로그인 취소 뒤 로그인 없이 생년월일·PIN을 등록하고 다시 접속한다', (tester) async {
    phone(tester);
    final state = AppState();
    await state.load();
    var talkCalls = 0, accountCalls = 0;
    final auth = KakaoAuthService(
      talkAvailable: () async => true,
      loginTalk: () async {
        talkCalls++;
        throw PlatformException(code: 'CANCELED');
      },
      loginAccount: () async {
        accountCalls++;
      },
      readUser: () async => throw StateError('취소 후 사용자 조회 금지'),
    );
    await tester.pumpWidget(
      localizedApp(ParentOnboardingScreen(appState: state, authService: auth)),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('카카오로 3초 만에 시작하기'));
    expect(state.hasParentAccount, isFalse);
    expect(find.textContaining('카카오 로그인을 취소했어요'), findsOneWidget);
    expect(accountCalls, 0);

    await tapVisible(tester, find.text('로그인 없이 시작하기'));
    expect(state.parentAccount?.isDevelopment, isTrue);
    await tester.enterText(find.byType(TextField).first, '테스트 아이');
    await tapVisible(tester, find.byIcon(Icons.calendar_today_rounded));
    expect(tester.takeException(), isNull);
    final birth = DateTime(2023, 5, 15);
    final localizedDate = MaterialLocalizations.of(
      tester.element(find.byType(DatePickerDialog)),
    ).formatCompactDate(birth);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    final dateField = find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dateField, localizedDate);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('2023-05-15'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.calendar_today_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('2023-05-15'), findsOneWidget);

    await tapVisible(tester, find.text('다음: 보호자 안전 PIN 설정'));
    await tester.enterText(find.byType(TextField).at(0), '1234');
    await tester.enterText(find.byType(TextField).at(1), '1234');
    await tapVisible(tester, find.text('등록 완료 및 모모숲 열기'));
    expect(find.textContaining('로그인 없이 등록했어요'), findsOneWidget);
    expect(state.profiles.single.birthDate, '2023-05-15');
    expect(
      state.profiles.single.ageMonths,
      ChildProfile.calculateAgeMonths(birth),
    );
    expect(state.hasPin, isTrue);
    expect(talkCalls, 1);
    expect(accountCalls, 0);
    final restored = AppState();
    await restored.load();
    expect(restored.parentAccount?.isDevelopment, isTrue);
    expect(restored.profiles.single.birthDate, '2023-05-15');
    expect(restored.hasPin, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    restored.dispose();
    state.dispose();
  });

  testWidgets('홈에서 로그인 없이 바로 아이 등록으로 이동한다', (tester) async {
    phone(tester);
    await tester.runAsync(() async {
      await tester.pumpWidget(const MomosupApp());
      await (tester.state(find.byType(MomosupApp)) as dynamic).boot;
    });
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('로그인 없이 시작하기'));
    expect(find.text('우리 아이를 소개해 주세요!'), findsOneWidget);
    expect(find.text('서비스 이용 동의'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('로그인 중 화면을 닫아도 저장이나 setState 오류가 발생하지 않는다', (tester) async {
    phone(tester);
    final state = AppState();
    final login = Completer<void>();
    await tester.pumpWidget(
      localizedApp(
        ParentOnboardingScreen(
          appState: state,
          authService: KakaoAuthService(
            talkAvailable: () async => false,
            loginAccount: () => login.future,
            readUser: () async => User.fromJson({'id': 42}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('카카오로 3초 만에 시작하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('카카오로 3초 만에 시작하기'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    login.complete();
    await tester.pumpAndSettle();
    expect(state.hasParentAccount, isFalse);
    expect(tester.takeException(), isNull);
    state.dispose();
  });

  for (final birth in ['2099-01-01', '2000-01-01']) {
    testWidgets('프로필에 범위 밖 생일이 있어도 달력을 연다 $birth', (tester) async {
      phone(tester);
      final state = AppState();
      await tester.pumpWidget(
        localizedApp(
          ProfileEditorScreen(
            appState: state,
            initial: ChildProfile(
              id: 'date_test',
              nickname: '테스트 아이',
              birthDate: birth,
              ageMonths: 36,
              avatar: 'momo',
              level: '기본',
              answers: const [3, 3, 3, 3, 3],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byIcon(Icons.calendar_today_rounded));
      await tester.tap(find.byIcon(Icons.calendar_today_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }

  for (final cancellation in [
    PlatformException(code: 'CANCELED'),
    KakaoClientException(ClientErrorCause.cancelled, '취소'),
  ]) {
    test(
      '카카오 취소는 다른 로그인이나 임시 계정으로 넘어가지 않는다 ${cancellation.runtimeType}',
      () async {
        var accountCalls = 0;
        final auth = KakaoAuthService(
          talkAvailable: () async => true,
          loginTalk: () async => throw cancellation,
          loginAccount: () async {
            accountCalls++;
          },
          readUser: () async => throw StateError('사용자 조회 금지'),
        );
        await expectLater(auth.loginWithKakao(), throwsA(same(cancellation)));
        expect(accountCalls, 0);
      },
    );
  }
  test('카카오톡 사용 오류는 계정 로그인으로 전환하며 실제 조회 결과만 반환한다', () async {
    var accountCalls = 0;
    final auth = KakaoAuthService(
      talkAvailable: () async => true,
      loginTalk: () async => throw StateError('카카오톡 사용 불가'),
      loginAccount: () async {
        accountCalls++;
      },
      readUser: () async => User.fromJson({'id': 42}),
    );
    final account = await auth.loginWithKakao(nickname: '테스트 보호자');
    expect(account.id, 'kakao_42');
    expect(account.provider, 'kakao');
    expect(accountCalls, 1);
  });
  test('계정 로그인 실패를 가짜 로그인 성공으로 바꾸지 않는다', () async {
    final failure = StateError('연결 실패');
    final auth = KakaoAuthService(
      talkAvailable: () async => false,
      loginAccount: () async => throw failure,
      readUser: () async => throw StateError('사용자 조회 금지'),
    );
    await expectLater(auth.loginWithKakao(), throwsA(same(failure)));
  });
}
