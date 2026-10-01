import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../../state/app_state.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/kakao_share_modal.dart';
import '../../widgets/parent_today_play.dart';
import '../family_management_screen.dart';
import '../journey_screen.dart';
import '../observation_screen.dart';
import '../parent_onboarding_screen.dart';
import '../play_library_screen.dart';
import '../story_forest_screen.dart';
import 'parent_common_widgets.dart';
import 'parent_gallery_screen.dart';
import 'parent_settings_screen.dart';
import 'profile_editor_screen.dart';

class ParentHubScreen extends StatelessWidget {
  const ParentHubScreen({
    required this.appState,
    required this.catalog,
    super.key,
  });

  final AppState appState;
  final List<Activity> catalog;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('보호자 공간'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('아이 화면'),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: AnimatedBuilder(
            animation: appState,
            builder: (context, _) {
              final profile = appState.activeProfile;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: appState.hasParentAccount
                          ? const Color(0xFFFFFBE6)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: appState.hasParentAccount
                            ? const Color(0xFFFEE500)
                            : const Color(0xFFE5DECC),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE500),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.chat_bubble,
                            size: 16,
                            color: Color(0xFF191919),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            appState.hasParentAccount
                                ? appState.parentAccount!.isDevelopment
                                      ? '로그인 없이 사용 중: ${appState.parentAccount!.nickname}'
                                      : '카카오 연동 계정: ${appState.parentAccount!.nickname}'
                                : '카카오 계정 미연동 상태',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF284E3D),
                            ),
                          ),
                        ),
                        if (!appState.hasParentAccount)
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ParentOnboardingScreen(appState: appState),
                              ),
                            ),
                            child: const Text('연동하기'),
                          ),
                      ],
                    ),
                  ),
                  ParentNoticeCard(
                    text: appState.parentAccount?.isDevelopment == true
                        ? '개발용 접속 · 카카오 로그인 없이 이 기기에서 놀이를 사용할 수 있습니다.'
                        : '비공개 시제품 · 카카오 계정으로 아이 프로필을 가족과 안전하게 공유할 수 있습니다.',
                  ),
                  const SizedBox(height: 16),
                  if (profile != null)
                    ParentTodayPlay(
                      key: ValueKey(profile.id),
                      appState: appState,
                      profile: profile,
                    ),
                  Text('자녀 프로필', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ...appState.profiles.map(
                    (item) => ParentRow(
                      child: ListTile(
                        leading: AvatarImage(avatar: item.avatar, size: 48),
                        title: Text(item.nickname),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.birthDateLabel.isNotEmpty
                                  ? '${item.birthDateLabel} (${item.ageLabel}) · ${item.level} 시작 단계'
                                  : '${item.ageLabel} · ${item.level} 시작 단계',
                            ),
                            if (item.isShared || item.sharedMembers.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '👨‍👩‍👧 가족 공유 중 (${item.sharedMembers.isEmpty ? 1 : item.sharedMembers.length}명)',
                                  style: const TextStyle(
                                    color: Color(0xFF477A53),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: item.id == profile?.id
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF78966A),
                              )
                            : const Icon(Icons.circle_outlined),
                        onTap: () => appState.selectProfile(item.id),
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ProfileEditorScreen(appState: appState),
                          ),
                        ),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('아이 추가'),
                      ),
                      if (profile != null) ...[
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ProfileEditorScreen(
                                appState: appState,
                                initial: profile,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('프로필 수정'),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFEE500),
                            foregroundColor: const Color(0xFF191919),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () async {
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
                          },
                          icon: const Icon(Icons.chat_bubble, size: 16),
                          label: const Text('가족 초대 (카카오톡)'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (profile != null) ...[
                    ListTile(
                      leading: const Icon(Icons.movie_creation_outlined),
                      title: const Text('이야기숲 영상'),
                      subtitle: const Text('연령·핵심 주제 확인과 보호자 미리보기'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => Scaffold(
                            appBar: AppBar(title: const Text('이야기 영상 미리보기')),
                            body: SafeArea(
                              child: StoryForestScreen(
                                appState: appState,
                                profile: profile,
                                preview: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '오늘 ${appState.minutesToday(profile.id)}분 / '
                      '${profile.dailyLimitMinutes}분 이용',
                    ),
                    const SizedBox(height: 12),
                    ParentHubTile(
                      icon: Icons.family_restroom_rounded,
                      title: '가족 공유 관리 (카카오톡)',
                      subtitle: '배우자·조부모님과 아이 프로필 공유 및 초대장 발송',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => FamilyManagementScreen(
                            appState: appState,
                            profile: profile,
                          ),
                        ),
                      ),
                    ),
                    ParentHubTile(
                      icon: Icons.tune_rounded,
                      title: '이용시간·소리 설정',
                      subtitle: '아이별 제한과 자극 수준',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ParentSettingsScreen(
                            appState: appState,
                            profile: profile,
                          ),
                        ),
                      ),
                    ),
                    ParentHubTile(
                      icon: Icons.auto_stories_rounded,
                      title: '전체 놀이·이어하기',
                      subtitle: '월령 놀이·기존 놀이·장난감 · 즐겨찾기와 저장 기록',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => PlayLibraryScreen(
                            appState: appState,
                            catalog: catalog,
                            profile: profile,
                            parent: true,
                          ),
                        ),
                      ),
                    ),
                    ParentHubTile(
                      icon: Icons.forest_rounded,
                      title: '월령별 놀이 72개',
                      subtitle: '6개월~만 7세 · 세 단계 · 놀이와 음성 안내',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => JourneyLibraryScreen(
                            appState: appState,
                            profile: profile,
                            parent: true,
                          ),
                        ),
                      ),
                    ),
                    ParentHubTile(
                      icon: Icons.family_restroom_rounded,
                      title: '가족 놀이 관찰',
                      subtitle: '준비 안내·실제 관찰 기록·문제 요약',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ObservationScreen(
                            state: appState,
                            profile: profile,
                            catalog: catalog,
                          ),
                        ),
                      ),
                    ),
                    ParentHubTile(
                      icon: Icons.palette_outlined,
                      title: '기기에 저장된 그림',
                      subtitle: '아이별로 보기·삭제하기',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ParentGalleryScreen(profile: profile),
                        ),
                      ),
                    ),
                    ParentHubTile(
                      icon: Icons.shield_outlined,
                      title: '안전·검수 정보',
                      subtitle: '왜 아직 공개되지 않았는지 확인',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TrustScreen(),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.login_rounded),
                    title: Text('카카오 로그인'),
                    subtitle: Text('법정대리인 확인·개인정보 고지 설계 뒤 연결'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.family_restroom_rounded),
                    title: Text('가족 초대·동시 접속'),
                    subtitle: Text('공개 MVP 구현 범위'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.credit_card_off_rounded),
                    title: Text('월 4,900원 구독'),
                    subtitle: Text('비공개 시제품에서는 결제하지 않음'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
