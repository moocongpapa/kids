import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:momosup/models/child_profile.dart';
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
    expect(find.text('카카오톡으로 가족 초대하기'), findsNothing);
    expect(state.profiles.length, 1);
    expect(state.profiles.first.nickname, '하은');
    expect(state.profiles.first.gender, '여아');
  });

  testWidgets('이전 초대 링크로 진입해도 아이 정보를 가져오지 않는다', (tester) async {
    final sender = AppState();
    await sender.load();
    await sender.addProfile(child);
    final invite = await sender.createFamilyInvite(child, inviterRole: '보호자');
    FlutterSecureStorage.setMockInitialValues({});
    final receiver = AppState();
    await receiver.load();
    await tester.pumpWidget(
      MaterialApp(
        home: FamilyInviteAcceptScreen(
          appState: receiver,
          initialCodeOrUrl: invite.toShareUrl(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('지금은 이 기기에서 함께해요'), findsOneWidget);
    expect(find.text(child.nickname), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(receiver.profiles, isEmpty);
  });

  testWidgets('가족 관리와 이전 공유 모달에서 링크나 아이 정보를 내보내지 않는다', (tester) async {
    final state = AppState();
    await state.load();
    await state.addProfile(child);
    await tester.pumpWidget(
      MaterialApp(
        home: FamilyManagementScreen(appState: state, profile: child),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('카카오톡으로 가족 초대하기'), findsNothing);
    expect(state.profiles.single.isShared, isFalse);
    final invite = await state.createFamilyInvite(child, inviterRole: '보호자');
    final clipboardWrites = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') clipboardWrites.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KakaoShareModal(profile: child, payload: invite),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('지금은 이 기기에서 함께해요'), findsOneWidget);
    expect(find.text('초대 링크 복사'), findsNothing);
    expect(find.text('카카오톡으로 초대장 보내기'), findsNothing);
    expect(find.textContaining(child.birthDate!), findsNothing);
    expect(find.textContaining('momosup.app/share'), findsNothing);
    expect(clipboardWrites, isEmpty);
  });
}

const child = ChildProfile(
  id: 'fixture_child',
  nickname: '테스트아이',
  birthDate: '2023-01-01',
  ageMonths: 36,
  avatar: 'momo',
  level: '기본',
  answers: [3, 3, 3, 3, 3],
);
