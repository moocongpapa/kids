import 'package:flutter/material.dart';
import '../models/child_profile.dart';
import '../state/app_state.dart';
import '../widgets/avatar_image.dart';
import '../widgets/forest_background.dart';
import '../widgets/kakao_share_modal.dart';
import 'family_invite_screen.dart';

class FamilyManagementScreen extends StatelessWidget {
  const FamilyManagementScreen({
    required this.appState,
    required this.profile,
    super.key,
  });

  final AppState appState;
  final ChildProfile profile;

  Future<void> _inviteMore(BuildContext context) async {
    final payload = await appState.createFamilyInvite(
      profile,
      inviterRole: '가족',
    );
    if (!context.mounted) return;
    KakaoShareModal.show(
      context,
      profile: profile,
      payload: payload,
      parentAccount: appState.parentAccount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final currentProfile =
            appState.profiles.firstWhere(
              (p) => p.id == profile.id,
              orElse: () => profile,
            );
        final members = currentProfile.sharedMembers;
        final isOwner =
            !currentProfile.isShared ||
            currentProfile.ownerParentId == appState.parentAccount?.id;

        return Scaffold(
          appBar: AppBar(
            title: const Text('가족 공유 관리'),
          ),
          body: ForestBackground(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      // Child Info Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFD7DDBE)),
                        ),
                        child: Row(
                          children: [
                            AvatarImage(
                              avatar: currentProfile.avatar,
                              size: 72,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        currentProfile.nickname,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF284E3D),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F0E2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          currentProfile.gender,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF477A53),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentProfile.birthDateLabel.isNotEmpty
                                        ? '${currentProfile.birthDateLabel} (${currentProfile.ageLabel})'
                                        : currentProfile.ageLabel,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '👨‍👩‍👧 가족 공유: ${members.isEmpty ? '1명 (나)' : '${members.length}명 참여 중'}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF477A53),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Kakao Share Action Button
                      SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFEE500),
                            foregroundColor: const Color(0xFF191919),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () => _inviteMore(context),
                          icon: const Icon(Icons.chat_bubble, size: 22),
                          label: const Text(
                            '카카오톡으로 가족 초대하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => FamilyInviteAcceptScreen(
                                appState: appState,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_link_rounded),
                        label: const Text('받은 초대 코드나 링크 직접 등록'),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '함께하는 가족 구성원',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF284E3D),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (members.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Text(
                            '아직 다른 가족 구성원이 초대되지 않았어요.\n카카오톡으로 배우자나 조부모님을 초대해 보세요!',
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        )
                      else
                        ...members.map(
                          (m) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE5DECC),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: m.isOwner
                                      ? const Color(0xFFFEE500)
                                      : const Color(0xFFE8F0E2),
                                  child: Icon(
                                    m.isOwner
                                        ? Icons.star_rounded
                                        : Icons.person_rounded,
                                    color: const Color(0xFF284E3D),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            m.name,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF284E3D),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0F4E8),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              m.role,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF477A53),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (m.isOwner) ...[
                                            const SizedBox(width: 4),
                                            const Text(
                                              '(소유자)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.black45,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '참여일: ${m.joinedAt.year}.${m.joinedAt.month}.${m.joinedAt.day}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      if (!isOwner) ...[
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('가족 공유 해제'),
                                content: const Text(
                                  '이 기기에서 공유받은 아이 프로필을 제거할까요? 소유자의 원본 프로필은 안전하게 유지됩니다.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('취소'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('공유 해제'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await appState.leaveFamilyShare(currentProfile.id);
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.link_off_rounded),
                          label: const Text('이 기기에서 공유 연결 해제'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
