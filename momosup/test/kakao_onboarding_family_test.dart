import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:momosup/models/child_profile.dart';
import 'package:momosup/models/family_share.dart';
import 'package:momosup/models/parent_account.dart';
import 'package:momosup/services/kakao_auth_service.dart';
import 'package:momosup/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('카카오 로그인 및 부모 계정 연동', () {
    test('카카오 로그인 수행 후 부모 계정 정보를 저장하고 복원한다', () async {
      final state = AppState();
      await state.load();
      expect(state.hasParentAccount, isFalse);

      final auth = KakaoAuthService(
        talkAvailable: () async => false,
        loginAccount: () async {},
        readUser: () async => User.fromJson({
          'id': 123456789,
          'kakao_account': {
            'profile': {'nickname': '민준아빠'},
            'email': 'minjun_dad@kakao.com',
          },
        }),
      );
      final account = await auth.loginWithKakao(
        nickname: '민준아빠',
        email: 'minjun_dad@kakao.com',
      );
      await state.setParentAccount(account);

      expect(state.hasParentAccount, isTrue);
      expect(state.parentAccount?.nickname, '민준아빠');
      expect(state.parentAccount?.email, 'minjun_dad@kakao.com');
      expect(state.parentAccount?.provider, 'kakao');

      // Reload into a new state instance to verify persistence
      final reloadedState = AppState();
      await reloadedState.load();
      expect(reloadedState.hasParentAccount, isTrue);
      expect(reloadedState.parentAccount?.nickname, '민준아빠');
    });

    test('카카오 계정 로그아웃 시 계정 정보를 삭제한다', () async {
      final state = AppState();
      await state.load();
      final account = ParentAccount(
        id: 'kakao_123',
        nickname: '테스트부모',
        connectedAt: DateTime.now(),
      );
      await state.setParentAccount(account);
      expect(state.hasParentAccount, isTrue);

      await state.logoutParentAccount();
      expect(state.hasParentAccount, isFalse);
      expect(state.parentAccount, isNull);
    });
  });

  group('아이 정보(이름, 성별, 생년월일) 등록 및 월령 계산', () {
    test('생년월일로부터 정확한 개월 수와 라벨을 계산한다', () {
      final now = DateTime(2026, 9, 30);

      // 2023년 5월 15일생 -> 40개월
      final birth = DateTime(2023, 5, 15);
      final months = ChildProfile.calculateAgeMonths(birth, now);
      expect(months, 40);

      // 2025년 9월 10일생 -> 12개월
      final birthOneYear = DateTime(2025, 9, 10);
      expect(ChildProfile.calculateAgeMonths(birthOneYear, now), 12);

      // 생일이 아직 이번 달에 오지 않은 경우 (2025년 9월 30일 vs 10월 5일생)
      final birthNear = DateTime(2024, 10, 5);
      expect(ChildProfile.calculateAgeMonths(birthNear, now), 23);
    });

    test('아이 프로필에 이름, 성별, 생년월일이 정상적으로 보존된다', () async {
      final state = AppState();
      await state.load();

      const profile = ChildProfile(
        id: 'child_minjun',
        nickname: '민준',
        birthDate: '2023-05-15',
        gender: '남아',
        avatar: 'momo',
        ageMonths: 40,
        level: '기본',
        answers: [3, 3, 3, 3, 3],
      );

      await state.addProfile(profile);
      expect(state.profiles.length, 1);
      final saved = state.profiles.first;
      expect(saved.nickname, '민준');
      expect(saved.gender, '남아');
      expect(saved.birthDate, '2023-05-15');
      expect(saved.birthDateLabel, '2023년 5월 15일생');
      expect(saved.ageLabel, '만 3세');
    });
  });

  group('아이 프로필 가족 공유 (카카오톡 링크/코드 공유)', () {
    test('가족 초대 링크 및 코드를 생성하고 프로필에 소유자 정보를 연결한다', () async {
      final state = AppState();
      await state.load();
      await state.setParentAccount(
        ParentAccount(
          id: 'kakao_owner_1',
          nickname: '민준아빠',
          connectedAt: DateTime.now(),
        ),
      );

      const profile = ChildProfile(
        id: 'child_share_1',
        nickname: '민준',
        birthDate: '2023-05-15',
        gender: '남아',
        avatar: 'momo',
        ageMonths: 40,
        level: '기본',
        answers: [3, 3, 3, 3, 3],
      );
      await state.addProfile(profile);

      final payload = await state.createFamilyInvite(
        profile,
        inviterRole: '아빠',
      );

      expect(payload.childName, '민준');
      expect(payload.inviterName, '민준아빠');
      expect(payload.inviterRole, '아빠');
      expect(payload.code, startsWith('MOMO-'));
      expect(
        payload.toShareUrl(),
        contains('https://momosup.app/share?invite='),
      );

      // 카카오톡 공유 텍스트 메시지 검증
      final shareText = KakaoAuthService.instance.buildKakaoShareText(
        profile: profile,
        inviterName: payload.inviterName,
        inviterRole: payload.inviterRole,
        shareUrl: payload.toShareUrl(),
        inviteCode: payload.code,
      );
      expect(shareText, contains('민준아빠님이'));
      expect(shareText, contains('민준'));
      expect(shareText, contains(payload.toShareUrl()));
      expect(shareText, contains(payload.code));
    });

    test('초대 URL 또는 코드를 다른 가족 기기에서 수락하면 공유 프로필로 등록된다', () async {
      // 기기 A (소유자 부모)
      final stateA = AppState();
      await stateA.load();
      await stateA.setParentAccount(
        ParentAccount(
          id: 'kakao_owner_1',
          nickname: '민준아빠',
          connectedAt: DateTime.now(),
        ),
      );

      const originalProfile = ChildProfile(
        id: 'child_cross_device',
        nickname: '서아',
        birthDate: '2024-02-10',
        gender: '여아',
        avatar: 'duri',
        ageMonths: 31,
        level: '기본',
        answers: [3, 3, 3, 3, 3],
      );
      await stateA.addProfile(originalProfile);
      final invite = await stateA.createFamilyInvite(
        originalProfile,
        inviterRole: '아빠',
      );
      final shareUrl = invite.toShareUrl();

      // 기기 B (엄마 기기)
      final stateB = AppState();
      await stateB.load();
      await stateB.setParentAccount(
        ParentAccount(
          id: 'kakao_mom_2',
          nickname: '서아엄마',
          connectedAt: DateTime.now(),
        ),
      );

      // 기기 B에서 초대 링크 수락
      final acceptedProfile = await stateB.acceptFamilyInvite(
        shareUrl,
        myName: '서아엄마',
        myRole: '엄마',
      );

      expect(acceptedProfile.id, 'child_cross_device');
      expect(acceptedProfile.nickname, '서아');
      expect(acceptedProfile.gender, '여아');
      expect(acceptedProfile.birthDate, '2024-02-10');
      expect(acceptedProfile.isShared, isTrue);
      expect(acceptedProfile.ownerName, '민준아빠');
      expect(acceptedProfile.sharedMembers.length, 2);
      expect(acceptedProfile.sharedMembers.any((m) => m.role == '아빠'), isTrue);
      expect(acceptedProfile.sharedMembers.any((m) => m.role == '엄마'), isTrue);

      expect(stateB.profiles.length, 1);
      expect(stateB.activeProfile?.nickname, '서아');
    });

    test('초대 토큰이 잘못된 경우 오류를 발생시킨다', () async {
      final state = AppState();
      await state.load();
      expect(
        () => state.acceptFamilyInvite(
          'invalid_garbage_token',
          myName: '할머니',
          myRole: '할머니',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('위조되거나 변조된 서명의 초대 토큰은 거부된다', () async {
      final state = AppState();
      await state.load();

      final payload = FamilyInvitePayload(
        code: 'MOMO-7777-KIDS',
        familyId: 'fam_tamper',
        childId: 'child_tamper',
        childName: '변조아이',
        birthDate: '2023-01-01',
        gender: '남아',
        avatar: 'momo',
        inviterName: '해커',
        inviterRole: '가족',
        ageMonths: 36,
        createdAt: DateTime.now(),
      );

      final validToken = payload.toToken();
      final parts = validToken.split('.');
      expect(parts.length, 2);

      // 서명 변조: 서명의 마지막 글자를 변경
      final tamperedSig = parts[1].replaceRange(
        parts[1].length - 1,
        parts[1].length,
        parts[1].endsWith('a') ? 'b' : 'a',
      );
      final tamperedToken = '${parts[0]}.$tamperedSig';

      // 변조된 토큰 파싱 시 null 반환 검증
      expect(FamilyInvitePayload.fromRaw(tamperedToken), isNull);

      // acceptFamilyInvite 시 FormatException 발생 검증
      expect(
        () =>
            state.acceptFamilyInvite(tamperedToken, myName: '삼촌', myRole: '삼촌'),
        throwsA(isA<FormatException>()),
      );

      // 다른 시크릿으로 서명된 토큰도 거부되는지 검증
      final wrongSecretToken = payload.toToken(secret: 'wrong_secret_key');
      expect(FamilyInvitePayload.fromRaw(wrongSecretToken), isNull);
    });
  });
}
