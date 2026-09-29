import 'package:flutter/material.dart';

import '../data/journey_recommendation.dart';
import '../models/age_journey.dart';
import '../models/child_profile.dart';
import '../screens/journey_screen.dart';
import '../state/app_state.dart';
import 'forest_game_ui.dart';

class ParentTodayPlay extends StatefulWidget {
  const ParentTodayPlay({
    required this.appState,
    required this.profile,
    super.key,
  });
  final AppState appState;
  final ChildProfile profile;
  @override
  State<ParentTodayPlay> createState() => _ParentTodayPlayState();
}

class _ParentTodayPlayState extends State<ParentTodayPlay> {
  bool saving = false;
  Future<void> changeStage(int stage) async {
    setState(() => saving = true);
    try {
      await widget.appState.updateProfile(
        widget.profile.copyWith(playStage: stage),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('놀이 방법을 저장하지 못했어요. 다시 선택해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final picks = recommendJourneys(
      p,
      widget.appState.journeys.where((a) => widget.appState.journeyApproved(a)),
      played: widget.appState.records
          .where((r) => r.profileId == p.id)
          .map((r) => r.activityId)
          .toSet(),
    );
    if (picks.isEmpty) return const SizedBox.shrink();
    final a = picks.first;
    final limitReached =
        !p.caregiverMode &&
        widget.appState.minutesToday(p.id) >= p.dailyLimitMinutes;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${p.nickname}의 오늘 놀이',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${p.ageLabel} · ${p.caregiverMode ? '보호자와 화면 밖에서' : journeyStages[p.effectivePlayStage]}',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ForestProp(journeyProp(a.symbols.first), size: 68),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('약 ${a.minutes}분 · ${a.materials}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(a.summary, style: const TextStyle(height: 1.5)),
          if (!p.caregiverMode) ...[
            const SizedBox(height: 12),
            const Text('오늘은 어느 정도 도와줄까요?'),
            Wrap(
              spacing: 7,
              children: [
                for (var i = -1; i < 3; i++)
                  ChoiceChip(
                    label: Text(i == -1 ? '월령 추천' : journeyStages[i]),
                    selected: p.playStage == i,
                    onSelected: saving ? null : (_) => changeStage(i),
                  ),
              ],
            ),
            Text(
              p.playStage == -1
                  ? '월령과 보호자 답변으로 고른 시작 방법이에요. 언제든 바꿀 수 있어요.'
                  : '직접 고른 방법을 유지해요. 월령 추천: ${journeyStages[p.suggestedPlayStage]}',
            ),
          ],
          const SizedBox(height: 14),
          if (limitReached) Text('오늘 화면 놀이는 마쳤어요. ${a.offscreen}'),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('parent-quick-start'),
              onPressed: limitReached
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => a.isCaregiver
                            ? JourneyDetailScreen(
                                journey: a,
                                appState: widget.appState,
                                profile: p,
                              )
                            : JourneyPlayScreen(
                                journey: a,
                                appState: widget.appState,
                                profile: p,
                              ),
                      ),
                    ),
              icon: Icon(
                a.isCaregiver
                    ? Icons.family_restroom_rounded
                    : Icons.play_arrow_rounded,
              ),
              label: Text(a.isCaregiver ? '함께 놀 준비하기' : '이 놀이 함께 시작'),
            ),
          ),
          const Divider(height: 32),
        ],
      ),
    );
  }
}
