import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/child_profile.dart';
import '../models/family_share.dart';
import '../models/parent_account.dart';
import '../services/kakao_auth_service.dart';
import '../widgets/avatar_image.dart';

class KakaoShareModal extends StatefulWidget {
  const KakaoShareModal({
    required this.profile,
    required this.payload,
    this.parentAccount,
    super.key,
  });

  final ChildProfile profile;
  final FamilyInvitePayload payload;
  final ParentAccount? parentAccount;

  static Future<void> show(
    BuildContext context, {
    required ChildProfile profile,
    required FamilyInvitePayload payload,
    ParentAccount? parentAccount,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => KakaoShareModal(
        profile: profile,
        payload: payload,
        parentAccount: parentAccount,
      ),
    );
  }

  @override
  State<KakaoShareModal> createState() => _KakaoShareModalState();
}

class _KakaoShareModalState extends State<KakaoShareModal> {
  bool copied = false;

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label을(를) 클립보드에 복사했어요! 카카오톡 대화방에 붙여넣어 공유하세요.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inviter = widget.payload.inviterName;
    final child = widget.profile.nickname;
    final shareUrl = widget.payload.toShareUrl();
    final inviteCode = widget.payload.code;
    final shareText = KakaoAuthService.instance.buildKakaoShareText(
      profile: widget.profile,
      inviterName: inviter,
      inviterRole: widget.payload.inviterRole,
      shareUrl: shareUrl,
      inviteCode: inviteCode,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDF5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE500),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Color(0xFF191919),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '카카오톡으로 가족 초대하기',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF284E3D),
                      ),
                    ),
                    Text(
                      '아이 프로필을 가족과 함께 공유해요',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Kakao message card preview
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F4EB),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE5DECC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AvatarImage(avatar: widget.profile.avatar, size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF477A53),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '모모숲 가족 초대',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$inviter님이 '$child'의 숲속 놀이에 초대했어요!",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF191919),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cake_outlined,
                        size: 20,
                        color: Color(0xFF477A53),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.profile.birthDateLabel.isNotEmpty
                              ? '${widget.profile.birthDateLabel} · ${widget.profile.ageLabel}'
                              : widget.profile.ageLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E4436),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      '초대 코드: ',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Text(
                      inviteCode,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF477A53),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Primary Kakao Share Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEE500),
                foregroundColor: const Color(0xFF191919),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () => _copy(shareText, '카카오톡 초대 메시지'),
              icon: const Icon(Icons.chat_bubble, size: 22),
              label: const Text(
                '카카오톡으로 초대장 보내기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _copy(shareUrl, '초대 링크'),
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: const Text('초대 링크 복사'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _copy(inviteCode, '초대 코드'),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('초대 코드 복사'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
