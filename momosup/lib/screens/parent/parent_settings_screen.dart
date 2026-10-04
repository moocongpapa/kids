import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'parent_care_summary.dart';

import '../../models/child_profile.dart';
import '../../state/app_state.dart';

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({
    required this.appState,
    required this.profile,
    super.key,
  });

  final AppState appState;
  final ChildProfile profile;

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  late int limit = widget.profile.dailyLimitMinutes;
  late bool music = widget.profile.musicOn;
  late bool voice = widget.profile.voiceOn, effects = widget.profile.effectsOn;
  late bool lowStimulation = widget.profile.lowStimulation;

  bool saving = false;
  Future<void> save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await widget.appState.updateProfile(
        widget.profile.copyWith(
          dailyLimitMinutes: limit,
          musicOn: music,
          voiceOn: voice,
          effectsOn: effects,
          lowStimulation: lowStimulation,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정을 저장하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${widget.profile.nickname} 설정')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                '하루 놀이 최대 $limit분',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('놀이와 영상에 함께 적용돼요. 한도에 도달하면 쉬는 화면으로 이동해요.'),
              Slider(
                value: limit.toDouble(),
                min: 5,
                max: 30,
                divisions: 5,
                label: '$limit분',
                onChanged: (value) => setState(() => limit = value.round()),
              ),
              SwitchListTile(
                value: music,
                title: const Text('배경음악'),
                subtitle: const Text('숲에서 들리는 배경음악을 켭니다.'),
                onChanged: (value) => setState(() => music = value),
              ),
              SwitchListTile(
                value: voice,
                title: const Text('안내 음성'),
                subtitle: const Text('놀이 방법을 말로 들려줍니다.'),
                onChanged: (v) => setState(() => voice = v),
              ),
              SwitchListTile(
                value: effects,
                title: const Text('악기와 효과음'),
                subtitle: const Text('연주·물건 조작·캐릭터 반응 소리입니다.'),
                onChanged: (v) => setState(() => effects = v),
              ),
              SwitchListTile(
                value: lowStimulation,
                title: const Text('차분한 움직임'),
                subtitle: const Text('캐릭터 움직임을 줄입니다.'),
                onChanged: (value) => setState(() => lowStimulation = value),
              ),
              const SizedBox(height: 16),
              const Text('홈의 소리 끄기는 모든 소리를 잠시 끕니다. 저장한 설정은 유지됩니다.'),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: saving ? null : save,
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class TrustScreen extends StatefulWidget {
  const TrustScreen({required this.appState, super.key});
  final AppState appState;
  @override
  State<TrustScreen> createState() => _TrustScreenState();
}

class _TrustScreenState extends State<TrustScreen> {
  late final Future<Map<String, dynamic>> catalog = rootBundle
      .loadString('assets/content/story_catalog.json')
      .then((raw) => jsonDecode(raw) as Map<String, dynamic>);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('보호 설정과 콘텐츠 상태')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                '믿음은 확인할 수 있게',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF284E3D),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '비공개 시제품이에요. 아래는 현재 앱에서 확인할 수 있는 설정과 준비 상태예요. 보호자가 먼저 살펴보고 아이 반응에 맞춰 함께 이용해 주세요.',
                style: TextStyle(height: 1.6),
              ),
              const SizedBox(height: 24),
              ListenableBuilder(
                listenable: widget.appState,
                builder: (_, _) {
                  final profile = widget.appState.activeProfile;
                  return profile == null
                      ? const SizedBox.shrink()
                      : ParentCareSummary(
                          appState: widget.appState,
                          profile: profile,
                        );
                },
              ),
              const _TrustSection(
                icon: Icons.play_circle_outline_rounded,
                title: '아이 화면의 약속',
                text: '광고·채팅·결제·외부 링크가 없어요. 영상은 한 편이 끝나면 멈추고, 앱을 잠시 떠나도 다시 재생 버튼을 눌러야 해요. 영상과 놀이는 같은 하루 한도에 합산돼요.',
              ),
              FutureBuilder<Map<String, dynamic>>(
                future: catalog,
                builder: (_, snapshot) {
                  if (snapshot.hasError) {
                    return const _TrustSection(
                      icon: Icons.info_outline_rounded,
                      title: '영상 준비 상태',
                      text: '콘텐츠 상태를 읽지 못했어요. 확인되지 않은 영상을 검수 완료로 표시하지 않아요.',
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('영상 준비 상태 확인 중…'),
                    );
                  }
                  final published = List<Map<String, dynamic>>.from(
                    (snapshot.data!['episodes'] as List).map(
                      (e) => Map<String, dynamic>.from(e as Map),
                    ),
                  );
                  final previews = List<Map<String, dynamic>>.from(
                    (snapshot.data!['previews'] as List? ?? []).map(
                      (e) => Map<String, dynamic>.from(e as Map),
                    ),
                  );
                  final all = [...published, ...previews];
                  final full = previews
                      .where((e) => e['fullFilmPreview'] == true)
                      .length;
                  final reviewed = all
                      .where((e) => e['humanReviewedAt'] != null)
                      .length;
                  return _TrustSection(
                    icon: Icons.fact_check_outlined,
                    title: '영상 준비 상태',
                    text:
                        '아이에게 공개된 영상 ${published.length}편\n보호자 전용 전체 편집본 $full편 · 첫 장면 ${previews.length - full}편\n사람의 최종 검수 기록 $reviewed / ${all.length}편\n\n자동 검사는 사람의 내용 검수를 대신하지 않아요. 미리보기는 아이 목록에 나오지 않으며, 보호자가 살펴봐도 아이의 이용 기록에는 남지 않아요.',
                  );
                },
              ),
              const _TrustSection(
                icon: Icons.child_care_rounded,
                title: '월령은 출발점이에요',
                text: '24개월 미만은 보호자가 안내를 보고 화면 밖에서 함께 놀아요. 그 이후에도 아이마다 흥미와 속도가 달라요. 피곤해하거나 고개를 돌리면 중단하고 쉬어 주세요. 앱은 발달 평가나 치료 도구가 아니에요.',
              ),
              const _TrustSection(
                icon: Icons.phone_iphone_rounded,
                title: '이 기기에 보관해요',
                text: '프로필·그림·놀이 기록을 앱의 자체 서버로 전송하지 않아요. 기기 백업과 복원은 운영체제 설정의 영향을 받아요. 카카오 로그인을 선택하면 카카오 인증 서비스를 이용해요. 가족 공유는 준비 중이며, 지금은 기기 사이의 기록·시간 제한이 동기화되지 않아요.',
              ),
              const _TrustSection(
                icon: Icons.visibility_outlined,
                title: '보호자가 직접 살펴봐 주세요',
                text: '놀이 목록에서 음성·난이도를 미리 보고 아이에게 보여 줄 놀이를 조절할 수 있어요. 새로운 영상은 사람의 검수와 실제 기기 재생 확인을 거쳐 공개해요. 실제 가족 관찰과 외부 전문가 평가는 아직 완료되지 않았어요.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TrustSection extends StatelessWidget {
  const _TrustSection({
    required this.icon,
    required this.title,
    required this.text,
  });
  final IconData icon;
  final String title, text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF477A53)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF284E3D),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          text,
          style: const TextStyle(height: 1.7, color: Color(0xFF455348)),
        ),
      ],
    ),
  );
}
