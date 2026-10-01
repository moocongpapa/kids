import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../models/child_profile.dart';
import '../models/parent_account.dart';

class KakaoAuthService {
  KakaoAuthService({
    Future<bool> Function()? talkAvailable,
    Future<void> Function()? loginTalk,
    Future<void> Function()? loginAccount,
    Future<User> Function()? readUser,
  }) : _talkAvailable = talkAvailable ?? isKakaoTalkInstalled,
       _loginTalk =
           loginTalk ??
           (() async {
             await UserApi.instance.loginWithKakaoTalk();
           }),
       _loginAccount =
           loginAccount ??
           (() async {
             await UserApi.instance.loginWithKakaoAccount();
           }),
       _readUser = readUser ?? (() => UserApi.instance.me());

  static final KakaoAuthService instance = KakaoAuthService();
  final Future<bool> Function() _talkAvailable;
  final Future<void> Function() _loginTalk, _loginAccount;
  final Future<User> Function() _readUser;

  static bool isLoginCancelled(Object error) =>
      (error is PlatformException &&
          const {
            'CANCELED',
            'user_cancel',
            'cancelled',
          }.contains(error.code)) ||
      (error is KakaoClientException &&
          error.reason == ClientErrorCause.cancelled);

  /// Performs Kakao login using KakaoTalk app or Kakao Account in browser.
  /// Failed or cancelled SDK login never creates an authenticated account.
  Future<ParentAccount> loginWithKakao({
    String? nickname,
    String? email,
  }) async {
    if (await _talkAvailable()) {
      try {
        await _loginTalk();
      } catch (error) {
        if (isLoginCancelled(error)) rethrow;
        await _loginAccount();
      }
    } else {
      await _loginAccount();
    }

    final user = await _readUser();
    final id = user.id.toString();
    final profileNickname = user.kakaoAccount?.profile?.nickname?.trim();
    final finalNickname =
        (profileNickname != null && profileNickname.isNotEmpty)
        ? profileNickname
        : (nickname ?? '카카오보호자');
    final finalEmail = user.kakaoAccount?.email ?? email;
    final profileImg = user.kakaoAccount?.profile?.profileImageUrl;

    return ParentAccount(
      id: 'kakao_$id',
      nickname: finalNickname,
      email: finalEmail,
      profileImageUrl: profileImg,
      provider: 'kakao',
      connectedAt: DateTime.now(),
    );
  }

  /// Sends a KakaoTalk sharing message using default Feed template.
  /// Returns true if KakaoTalk sharing succeeded, false if fallen back to clipboard.
  Future<bool> shareChildProfileKakaoTalk({
    required ChildProfile profile,
    required String inviterName,
    required String inviterRole,
    required String shareUrl,
    required String inviteCode,
  }) async {
    final shareText = buildKakaoShareText(
      profile: profile,
      inviterName: inviterName,
      inviterRole: inviterRole,
      shareUrl: shareUrl,
      inviteCode: inviteCode,
    );

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      await copyShareLink(shareText);
      return false;
    }

    try {
      final isAvailable = await ShareClient.instance
          .isKakaoTalkSharingAvailable();
      if (isAvailable) {
        final ageText =
            profile.birthDate != null && profile.birthDate!.isNotEmpty
            ? '${profile.birthDateLabel} (${profile.ageLabel})'
            : profile.ageLabel;

        final template = FeedTemplate(
          content: Content(
            title: "[모모숲] $inviterName님이 '${profile.nickname}'의 놀이에 초대했어요!",
            description:
                "아이: ${profile.nickname} ($ageText)\n초대 코드: $inviteCode\n함께 모모숲에서 우리 아이의 성장과 놀이를 지켜봐요!",
            imageUrl: Uri.parse(
              'https://raw.githubusercontent.com/flutter/assets/master/momosup/app_banner.png',
            ),
            link: Link(
              webUrl: Uri.parse(shareUrl),
              mobileWebUrl: Uri.parse(shareUrl),
              androidExecutionParams: {'invite_code': inviteCode},
              iosExecutionParams: {'invite_code': inviteCode},
            ),
          ),
          buttons: [
            Button(
              title: '초대 수락하고 숲속 가기',
              link: Link(
                webUrl: Uri.parse(shareUrl),
                mobileWebUrl: Uri.parse(shareUrl),
                androidExecutionParams: {'invite_code': inviteCode},
                iosExecutionParams: {'invite_code': inviteCode},
              ),
            ),
          ],
        );

        await ShareClient.instance.shareDefault(template: template);
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'KakaoTalk sharing invocation failed ($e). Falling back to clipboard.',
        );
      }
    }

    // Fallback: clipboard copy
    await copyShareLink(shareText);
    return false;
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
