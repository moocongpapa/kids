import 'dart:math';
import 'package:flutter/services.dart';
import '../models/child_profile.dart';
import '../models/parent_account.dart';

class KakaoAuthService {
  KakaoAuthService._();
  static final KakaoAuthService instance = KakaoAuthService._();

  /// Simulates / performs Kakao login with guardian confirmation.
  Future<ParentAccount> loginWithKakao({
    String? nickname,
    String? email,
  }) async {
    // Artificial small delay for realistic authentication interaction
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final randomId = Random().nextInt(899999) + 100000;
    final parentName = nickname ?? '모모보호자';
    return ParentAccount(
      id: 'kakao_$randomId',
      nickname: parentName,
      email: email ?? 'kakao_$randomId@kakao.com',
      provider: 'kakao',
      connectedAt: DateTime.now(),
    );
  }

  /// Builds the rich KakaoTalk sharing message text
  String buildKakaoShareText({
    required ChildProfile profile,
    required String inviterName,
    required String inviterRole,
    required String shareUrl,
    required String inviteCode,
  }) {
    final ageText = profile.birthDate != null && profile.birthDate!.isNotEmpty
        ? '${profile.birthDateLabel} (${profile.ageLabel})'
        : profile.ageLabel;

    return '''[모모숲] 🌲 $inviterName님이 '${profile.nickname}'의 숲속 놀이에 초대했어요!

💛 우리 아이: ${profile.nickname} ($ageText)
💛 초대자: $inviterName ($inviterRole)

온 가족이 함께 아이의 따뜻한 숲속 놀이와 관찰 기록을 공유할 수 있어요.
아래 링크를 누르면 모모숲 앱에서 아이 프로필을 바로 등록할 수 있습니다.

🔗 초대 링크:
$shareUrl

🔑 직접 입력 초대 코드:
$inviteCode''';
  }

  /// Copies invitation link and text to clipboard
  Future<void> copyShareLink(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
