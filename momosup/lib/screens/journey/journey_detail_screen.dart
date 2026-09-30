import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/age_journey.dart';
import '../../models/child_profile.dart';
import '../../state/app_state.dart';
import '../../utils/forest_audio.dart';
import '../../utils/narration_player.dart';
import '../../widgets/forest_game_ui.dart';
import 'journey_play_screen.dart';

class JourneyDetailScreen extends StatefulWidget {
  const JourneyDetailScreen({
    required this.journey,
    required this.appState,
    required this.profile,
    super.key,
  });
  final AgeJourney journey;
  final AppState appState;
  final ChildProfile profile;
  @override
  State<JourneyDetailScreen> createState() => _JourneyDetailScreenState();
}

class _JourneyDetailScreenState extends State<JourneyDetailScreen>
    with WidgetsBindingObserver {
  late final NarrationPlayer narration;
  int stage = 0;
  int audioRequest = 0;
  bool script = false,
      listened = false,
      rights = false,
      away = false,
      playing = false,
      saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    narration = NarrationPlayer();
    WidgetsBinding.instance.addObserver(this);
    stage = widget.profile.stageFor(widget.journey.id);
    ForestAudio.instance.pauseBgm();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) stop();
  }

  Future<void> stop() async {
    audioRequest++;
    await narration.stop();
    if (mounted) setState(() => playing = false);
  }

  Future<void> listen(String id) async {
    final request = ++audioRequest;
    final path = widget.journey.audio[id];
    if (path == null) return;
    try {
      if (!mounted || away || request != audioRequest) return;
      setState(() {
        playing = true;
        error = null;
      });
      await narration.speak([path]);
      if (mounted && request == audioRequest) setState(() => playing = false);
    } catch (_) {
      if (mounted && request == audioRequest) {
        setState(() {
          error = '음성을 재생하지 못했어요. 다시 들어 주세요.';
          playing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    narration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.journey;
    if (away) {
      return Scaffold(
        backgroundColor: const Color(0xFF203B30),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.spa_outlined, size: 64, color: forestCream),
                  const SizedBox(height: 28),
                  const Text(
                    '휴대폰을 내려놓고\n함께 놀아 주세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, color: forestCream),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '소리와 음악은 멈췄어요.\n완료 버튼을 누르지 않아도 괜찮아요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: forestCream),
                  ),
                  const SizedBox(height: 36),
                  TextButton(
                    onPressed: () => setState(() => away = false),
                    child: const Text(
                      '보호자 안내로 돌아가기',
                      style: TextStyle(color: forestCream),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(a.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Text(
              '${journeyBandLabel(a.minAge)} · ${a.world}',
              style: const TextStyle(
                color: forestInk,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final current = widget.appState.profiles.firstWhere(
                  (p) => p.id == widget.profile.id,
                  orElse: () => widget.profile,
                );
                final favorites = List<String>.from(current.favoriteJourneys);
                if (favorites.contains(a.id)) {
                  favorites.remove(a.id);
                } else {
                  favorites.add(a.id);
                }
                await widget.appState.updateProfile(
                  current.copyWith(favoriteJourneys: favorites),
                );
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.favorite_outline_rounded),
              label: Text(
                widget.appState.profiles.any(
                      (p) =>
                          p.id == widget.profile.id &&
                          p.favoriteJourneys.contains(a.id),
                    )
                    ? '좋아하는 놀이에서 빼기'
                    : '좋아하는 놀이로 기억하기',
              ),
            ),
            Text(a.summary),
            const SizedBox(height: 12),
            Text('준비물: ${a.materials}'),
            Text('약 ${a.minutes}분 · 아이 관심에 따라 더 짧게 끝내도 돼요.'),
            const SizedBox(height: 22),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < 3; i++)
                  ChoiceChip(
                    label: Text(journeyStages[i]),
                    selected: stage == i,
                    onSelected: (_) => setState(() => stage = i),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              a.variants[stage],
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Divider(),
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '${i + 1}. ${a.steps[i]}',
                  style: const TextStyle(fontSize: 17, height: 1.6),
                ),
              ),
            Text(
              a.offscreen,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Divider(),
            for (final s in a.safety)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• $s'),
              ),
            const SizedBox(height: 16),
            Text(
              a.audioReady
                  ? a.bundledApproved
                        ? '안내 음성 · 검수와 사용권 확인 완료'
                        : 'Gemini로 만든 새 안내 음성 · 청취 검수 대상'
                  : '음성 제작 중 · 글 안내와 화면 미리보기를 확인할 수 있어요.',
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final id in a.audioIds)
                  OutlinedButton.icon(
                    onPressed: a.audio.containsKey(id)
                        ? () => listen(id)
                        : null,
                    icon: const Icon(Icons.volume_up_rounded),
                    label: Text(
                      id == 'song'
                          ? '인사 노래 듣기'
                          : id == 'guide'
                          ? '안내 듣기'
                          : '${int.parse(id.split('_').last) + 1}장면 듣기',
                    ),
                  ),
                if (playing)
                  TextButton(onPressed: stop, child: const Text('소리 멈춤')),
              ],
            ),
            if (a.data['musicLyrics'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('함께 부를 노래\n${a.data['musicLyrics']}'),
              ),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                await stop();
                await ForestAudio.instance.stopBgm();
                if (!context.mounted) return;
                if (a.isCaregiver) {
                  setState(() => away = true);
                } else {
                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => JourneyPlayScreen(
                        journey: a,
                        appState: widget.appState,
                        profile: widget.profile.copyWith(
                          ageMonths: a.minAge,
                          preschool: true,
                          activityStages: {
                            ...widget.profile.activityStages,
                            a.id: stage,
                          },
                        ),
                        preview: true,
                      ),
                    ),
                  );
                }
              },
              icon: Icon(
                a.isCaregiver
                    ? Icons.phone_iphone_rounded
                    : Icons.play_arrow_rounded,
              ),
              label: Text(a.isCaregiver ? '안내 끝 · 휴대폰 내려놓기' : '이 단계로 직접 미리 놀기'),
            ),
            const SizedBox(height: 24),
            if (a.bundledApproved) ...[
              const Text(
                '검수·사용권 확인 완료',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                a.isCaregiver
                    ? '보호자가 안내를 확인한 뒤 아이와 화면 밖에서 함께 놀아 주세요.'
                    : '아이 월령에 맞춰 홈에 나타납니다. 이 기기에서만 숨기거나 다시 보이게 할 수 있어요.',
              ),
              if (!a.isCaregiver)
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setState(() => saving = true);
                          try {
                            await widget.appState.reviewJourney(
                              a,
                              approved: !widget.appState.journeyApproved(a),
                            );
                          } catch (_) {
                            if (mounted) {
                              setState(() => error = '설정을 저장하지 못했어요.');
                            }
                          } finally {
                            if (mounted) setState(() => saving = false);
                          }
                        },
                  child: Text(
                    widget.appState.journeyApproved(a)
                        ? '이 기기에서 숨기기'
                        : '이 기기에서 다시 보이기',
                  ),
                ),
            ] else ...[
              const Text(
                '이 기기에서 검수하기',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text(
                '실제로 확인한 항목만 선택해 주세요. 대본이나 음성이 바뀌면 다시 검수합니다. 이 기록은 공개 출시 승인과 별개예요.',
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('세 단계 대본·놀이 동작·안전을 확인했어요'),
                value: script,
                onChanged: (v) => setState(() => script = v!),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('모든 안내의 발음·내용·음량을 직접 들었어요'),
                value: listened,
                onChanged: (v) => setState(() => listened = v!),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('새 음성을 이 아동용 앱에 쓸 권리를 확인했어요'),
                value: rights,
                onChanged: (v) => setState(() => rights = v!),
              ),
              FilledButton(
                onPressed:
                    !saving && script && listened && rights && a.audioReady
                    ? () async {
                        setState(() => saving = true);
                        try {
                          await widget.appState.reviewJourney(
                            a,
                            approved: true,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  a.isCaregiver
                                      ? '보호자 안내의 검수를 기록했어요.'
                                      : '이 월령의 아이 홈에서 놀이를 열 수 있어요.',
                                ),
                              ),
                            );
                          }
                        } catch (_) {
                          if (mounted) {
                            setState(() => error = '검수 기록을 저장하지 못했어요.');
                          }
                        } finally {
                          if (mounted) setState(() => saving = false);
                        }
                      }
                    : null,
                child: Text(a.isCaregiver ? '보호자 안내 검수 기록' : '이 기기 아이 홈에 공개'),
              ),
              if (widget.appState.journeyApproved(a))
                TextButton(
                  onPressed: () async {
                    await widget.appState.reviewJourney(a, approved: false);
                    if (mounted) setState(() {});
                  },
                  child: const Text('이 기기에서 숨기기'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
