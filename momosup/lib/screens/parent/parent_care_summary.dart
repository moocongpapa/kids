import 'package:flutter/material.dart';

import '../../models/child_profile.dart';
import '../../state/app_state.dart';

/// Shows saved controls and measured use, rather than a general safety badge.
class ParentCareSummary extends StatelessWidget {
  const ParentCareSummary({
    required this.appState,
    required this.profile,
    this.onSettings,
    super.key,
  });

  final AppState appState;
  final ChildProfile profile;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final seconds = appState.records
        .where(
          (r) =>
              r.profileId == profile.id &&
              r.at.year == now.year &&
              r.at.month == now.month &&
              r.at.day == now.day,
        )
        .fold<int>(0, (sum, r) => sum + r.seconds);
    final remaining = appState.secondsRemaining(
      profile.id,
      profile.dailyLimitMinutes,
    );
    final used = '${seconds ~/ 60}분 ${seconds % 60}초';
    final left = '${remaining ~/ 60}분 ${remaining % 60}초';
    return Container(
      key: const ValueKey('parent-care-summary'),
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF244D43), Color(0xFF3C6756)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Color(0xFFF5F1DF), height: 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.spa_rounded,
                  color: Color(0xFFDFE8B9),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${profile.nickname}의 오늘',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (profile.caregiverMode) ...[
              const Text(
                '보호자와 화면 밖에서',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text('24개월 미만은 보호자가 안내를 읽고 함께 놀아요. 아이용 놀이·영상은 열리지 않아요.'),
            ] else ...[
              Text(
                used,
                key: const ValueKey('today-exact-usage'),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text('오늘 기록된 놀이·영상 시간 · 하루 ${profile.dailyLimitMinutes}분'),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: profile.dailyLimitMinutes <= 0
                      ? 1
                      : (seconds / (profile.dailyLimitMinutes * 60)).clamp(
                          0.0,
                          1.0,
                        ),
                  minHeight: 8,
                  backgroundColor: const Color(0xFF557869),
                  color: const Color(0xFFDBE6A9),
                  semanticsLabel: '오늘 이용 시간 $used, 하루 ${profile.dailyLimitMinutes}분',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                remaining == 0
                    ? '오늘은 여기까지. 화면 밖에서 함께 쉬어요.'
                    : '$left 남았어요. 도중에 쉬어도 괜찮아요.',
              ),
            ],
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Status(
                  icon: Icons.lock_outline_rounded,
                  text: appState.hasPin ? '보호자 PIN 설정됨' : '보호자 PIN 필요',
                ),
                _Status(
                  icon: Icons.air_rounded,
                  text: profile.lowStimulation ? '차분한 움직임' : '기본 움직임',
                ),
                _Status(
                  icon: Icons.record_voice_over_rounded,
                  text: '안내 음성 ${profile.voiceOn ? '켬' : '끔'}',
                ),
                _Status(
                  icon: Icons.music_note_rounded,
                  text: '배경음악 ${profile.musicOn ? '켬' : '끔'}',
                ),
                _Status(
                  icon: Icons.piano_rounded,
                  text: '효과음 ${profile.effectsOn ? '켬' : '끔'}',
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              '영상은 한 편씩 선택해요. 다음 편은 자동으로 시작하지 않아요.',
              style: TextStyle(fontSize: 12, color: Color(0xFFD6E2D6)),
            ),
            if (onSettings != null)
              TextButton(
                onPressed: onSettings,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFF5F1DF),
                  minimumSize: const Size(48, 48),
                  padding: EdgeInsets.zero,
                ),
                child: const Text('이용시간과 소리 조절하기'),
              ),
          ],
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0x224FFFFF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFDFE8B9)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}
