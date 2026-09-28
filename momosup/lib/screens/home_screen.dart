import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../data/recommendation.dart';
import '../state/app_state.dart';
import '../widgets/avatar_image.dart';
import '../widgets/touch_sparkles.dart';
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
          child: TouchSparkles(
            lowStimulation: profile.lowStimulation,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    Card(
                      color: const Color(0xFFE9F2E2),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: const BorderSide(
                          color: Color(0xFFD4E5CC),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            AvatarImage(
                              avatar: profile.avatar,
                              size: 96,
                              lowStimulation: profile.lowStimulation,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${profile.nickname}의 숲',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF1E3524),
                                            ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        '🌿',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${profile.ageLabel} · 톡톡 만져보고 교감해요',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF43604A),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(200),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.timer_outlined,
                                          size: 14,
                                          color: Color(0xFF4A7C59),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '오늘 놀이: ${appState.minutesToday(profile.id)}분 / ${profile.dailyLimitMinutes}분',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2C5538),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Text(
                          '오늘은 무엇을 해 볼까?',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF203628),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('✨', style: TextStyle(fontSize: 18)),
                      ],
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
                          lowStimulation: profile.lowStimulation,
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
        ),
      );
    },
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.onTap,
    this.lowStimulation = false,
  });

  final Activity activity;
  final VoidCallback onTap;
  final bool lowStimulation;

  @override
  Widget build(BuildContext context) {
    final (badgeColor, badgeTextColor, modeIcon, bgTint) = switch (activity.mode) {
      PlayMode.touch => (
        const Color(0xFFD6E8D5),
        const Color(0xFF1E4627),
        Icons.touch_app_rounded,
        const Color(0xFFF7FBF4),
      ),
      PlayMode.color => (
        const Color(0xFFFFE5D0),
        const Color(0xFF6B3308),
        Icons.palette_rounded,
        const Color(0xFFFFFDF8),
      ),
      PlayMode.move => (
        const Color(0xFFE0EBF7),
        const Color(0xFF1E3F66),
        Icons.music_note_rounded,
        const Color(0xFFF6F9FD),
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: bgTint,
        borderRadius: BorderRadius.circular(24),
        elevation: 1,
        shadowColor: Colors.black.withAlpha(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: badgeColor.withAlpha(140),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: AvatarImage(
                    avatar: activity.avatar,
                    size: 74,
                    lowStimulation: lowStimulation,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(modeIcon, size: 13, color: badgeTextColor),
                                const SizedBox(width: 4),
                                Text(
                                  activity.modeLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: badgeTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0EE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '약 ${activity.minutes}분',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5A5E5A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        activity.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF223127),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${activity.theme} 놀이 · 함께 해봐요',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B756B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(120),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: badgeTextColor,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
