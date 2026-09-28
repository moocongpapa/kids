import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../data/recommendation.dart';
import '../state/app_state.dart';
import '../widgets/avatar_image.dart';
import 'parent_screen.dart';
import 'play_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.appState, required this.catalog, super.key});

  final AppState appState;
  final List<Activity> catalog;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: appState,
    builder: (context, _) {
      final profile = appState.activeProfile;
      if (!appState.hasPin || profile == null) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AvatarImage(avatar: 'momo', size: 190),
                      const SizedBox(height: 12),
                      Text(
                        '모모숲에 오신 걸 환영해요',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '짧게 놀고, 자연스럽게 마치는 아이 놀이.\n현재는 보호자 동반 비공개 시제품입니다.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => appState.hasPin
                                ? ParentGateScreen(
                                    appState: appState,
                                    catalog: catalog,
                                  )
                                : ParentSetupScreen(appState: appState),
                          ),
                        ),
                        icon: const Icon(Icons.lock_person_rounded),
                        label: Text(
                          appState.hasPin ? '보호자 화면 열기' : '보호자 설정 시작',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '실제 카카오 로그인·결제·아이 음성 파일은 아직 연결되지 않았습니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6B756B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      final visible = recommendedFor(
        profile,
        catalog.where((activity) => activity.isFullyApproved),
      );
      final preview = catalog
          .where((activity) => activity.supportsAge(profile.ageMonths))
          .toList(growable: false);
      final reachedLimit =
          appState.minutesToday(profile.id) >= profile.dailyLimitMinutes;

      return Scaffold(
        appBar: AppBar(
          title: const Text('모모숲'),
          actions: [
            IconButton(
              tooltip: '보호자 영역',
              icon: const Icon(Icons.lock_outline_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ParentGateScreen(appState: appState, catalog: catalog),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Card(
                    color: const Color(0xFFE9F2E2),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          AvatarImage(avatar: profile.avatar, size: 100),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${profile.nickname}의 숲',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                                Text('${profile.ageLabel} · 오늘의 놀이'),
                                Text(
                                  '오늘 ${appState.minutesToday(profile.id)}분 / '
                                  '${profile.dailyLimitMinutes}분',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    '오늘은 무엇을 해 볼까?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (reachedLimit)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('오늘 놀이 시간이 끝났어. 이제 화면 밖에서 쉬자!'),
                      ),
                    )
                  else if (visible.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.verified_outlined,
                              size: 42,
                              color: Color(0xFF709465),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '놀이를 꼼꼼히 준비하고 있어요.\n보호자 검수가 끝나면 이곳에 나타나요.',
                              textAlign: TextAlign.center,
                            ),
                            if (kDebugMode) ...[
                              const SizedBox(height: 8),
                              Text(
                                '개발 미리보기 초안 ${preview.length}개는 보호자 영역에서 확인',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    ...visible.map(
                      (activity) => _ActivityCard(
                        activity: activity,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PlayScreen(
                              activity: activity,
                              appState: appState,
                              profile: profile,
                              isParentPreview: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text(
                    '다음 놀이는 자동으로 시작하지 않아요. 한 놀이가 끝나면 잠깐 쉬어요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF6B756B)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.onTap});

  final Activity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AvatarImage(avatar: activity.avatar, size: 76),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${activity.theme} · ${activity.modeLabel} · '
                    '약 ${activity.minutes}분',
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          ],
        ),
      ),
    ),
  );
}
