import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:momosup/models/child_profile.dart';
import 'package:momosup/models/parent_account.dart';
import 'package:momosup/screens/family_invite_screen.dart';
import 'package:momosup/screens/family_management_screen.dart';
import 'package:momosup/screens/parent_onboarding_screen.dart';
import 'package:momosup/state/app_state.dart';
import 'package:momosup/services/kakao_auth_service.dart';
import 'package:momosup/widgets/kakao_share_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('온보딩 화면: 카카오 로그인 -> 아이 정보 등록 -> PIN 설정 흐름', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final state = AppState();
    await state.load();

    await tester.pumpWidget(
      MaterialApp(
        home: ParentOnboardingScreen(
          appState: state,
          authService: KakaoAuthService(
            talkAvailable: () async => false,
            loginAccount: () async {},
            readUser: () async => User.fromJson({'id': 123456789}),
          ),
        ),
      ),
    );
    await tester.pump();

    // Step 0: Kakao login view
    expect(find.text('모모숲에 오신 것을 환영해요!'), findsOneWidget);
    expect(find.text('카카오로 3초 만에 시작하기'), findsOneWidget);

    // Tap Kakao login button
    await tester.tap(find.text('카카오로 3초 만에 시작하기'));
    await tester.pump(const Duration(milliseconds: 800));

    // Step 1: Child info registration view
    expect(find.text('우리 아이를 소개해 주세요!'), findsOneWidget);
    expect(find.text('아이 이름 또는 별명 *'), findsOneWidget);
    expect(find.text('생년월일'), findsOneWidget);

    // Enter child name
    await tester.enterText(find.byType(TextField).first, '하은');
    await tester.pump(const Duration(milliseconds: 100));

    // Select gender '여아'
    await tester.tap(find.text('여아'));
    await tester.pump(const Duration(milliseconds: 100));

    // Proceed to PIN setup
    await tester.tap(find.text('다음: 보호자 안전 PIN 설정'));
    await tester.pump(const Duration(milliseconds: 200));

    // Step 2: Parent PIN setup
    expect(find.text('보호자 안전 PIN 만들기'), findsOneWidget);
    final pinFields = find.byType(TextField);
    await tester.enterText(pinFields.at(0), '1234');
    await tester.enterText(pinFields.at(1), '1234');
    await tester.pump(const Duration(milliseconds: 100));

    // Submit and finish
    await tester.tap(find.text('등록 완료 및 모모숲 열기'));
    await tester.pump(const Duration(milliseconds: 300));

    // Step 3: Completion screen
    expect(find.textContaining('하은'), findsOneWidget);
    expect(find.text('카카오톡으로 가족 초대하기'), findsOneWidget);
    expect(state.profiles.length, 1);
    expect(state.profiles.first.nickname, '하은');
    expect(state.profiles.first.gender, '여아');
  });

  testWidgets('가족 초대 링크 등록 화면: 코드 입력 시 아이 정보 표시 및 가족 등록', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final state = AppState();
    await state.load();
    await state.setParentAccount(
      ParentAccount(
        id: 'kakao_p1',
        nickname: '태양아빠',
        connectedAt: DateTime.now(),
      ),
    );

    const child = ChildProfile(
      id: 'child_sun',
      nickname: '태양이',
      birthDate: '2023-01-01',
      gender: '남아',
      avatar: 'nuri',
      ageMonths: 44,
      level: '기본',
      answers: [3, 3, 3, 3, 3],
    );
    await state.addProfile(child);
    final invite = await state.createFamilyInvite(child, inviterRole: '아빠');
    final shareUrl = invite.toShareUrl();

    // On another device/state:
    final stateReceiver = AppState();
    await stateReceiver.load();

    await tester.pumpWidget(
      MaterialApp(
        home: FamilyInviteAcceptScreen(
          appState: stateReceiver,
          initialCodeOrUrl: shareUrl,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('태양이'), findsOneWidget);
    expect(find.textContaining('태양아빠 (아빠)'), findsOneWidget);
    expect(find.text('아이와의 관계를 선택해 주세요'), findsOneWidget);

    // Select role '할머니'
    await tester.tap(find.text('할머니'));
    await tester.pump(const Duration(milliseconds: 100));

    // Tap join
    await tester.tap(find.text('가족으로 함께하기'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(stateReceiver.profiles.length, 1);
    expect(stateReceiver.profiles.first.nickname, '태양이');
    expect(stateReceiver.profiles.first.isShared, isTrue);
  });

  testWidgets('가족 공유 관리 화면 및 카카오 공유 모달 렌더링 검증', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final state = AppState();
    await state.load();
    await state.setParentAccount(
      ParentAccount(
        id: 'kakao_p2',
        nickname: '루다엄마',
        connectedAt: DateTime.now(),
      ),
    );

    const child = ChildProfile(
      id: 'child_ruda',
      nickname: '루다',
      birthDate: '2024-05-20',
      gender: '여아',
      avatar: 'momo',
      ageMonths: 28,
      level: '기본',
      answers: [3, 3, 3, 3, 3],
    );
    await state.addProfile(child);

    await tester.pumpWidget(
      MaterialApp(
        home: FamilyManagementScreen(appState: state, profile: child),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('가족 공유 관리'), findsOneWidget);
    expect(find.text('루다'), findsOneWidget);
    expect(find.text('카카오톡으로 가족 초대하기'), findsOneWidget);

    // Tap Kakao invite button
    await tester.tap(find.text('카카오톡으로 가족 초대하기'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(KakaoShareModal), findsOneWidget);
    expect(find.text('카카오톡으로 초대장 보내기'), findsOneWidget);
    expect(find.text('초대 링크 복사'), findsOneWidget);
    expect(find.text('초대 코드 복사'), findsOneWidget);
  });
}
