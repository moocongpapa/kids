import 'package:flutter/material.dart';

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

  Future<void> save() async {
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
          FilledButton(onPressed: save, child: const Text('저장')),
        ],
      ),
    ),
  ),
),
);
}

class TrustScreen extends StatelessWidget {
  const TrustScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('안전과 검수')),
    body: const SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '현재 공개 상태: 비공개 시제품',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('광고, 외부 링크, 결제, 자동 다음 재생, 공개 프로필, 채팅을 아이 화면에 넣지 않습니다.'),
            SizedBox(height: 12),
            Text('AI는 대본·그림 초안을 만들 수 있지만 사람의 최종 검수 없이 아이 모드에 게시하지 않습니다.'),
            SizedBox(height: 12),
            Text('현재 음성·노래 파일이 없어 독립적인 유아용 경험이 완성되지 않았습니다. 보호자 미리보기로만 보세요.'),
            SizedBox(height: 12),
            Text(
              '앱은 현재 자녀 프로필과 그림을 자체 서버로 전송하지 않습니다. 기기 백업·복원은 운영체제 설정의 영향을 받을 수 있습니다. 카카오 로그인과 Render의 자녀 데이터 저장은 아직 구현되지 않았습니다.',
            ),
            SizedBox(height: 12),
            Text('안전 100% 보장 같은 표현 대신 예방·검수·신고·회수 체계를 검증하겠습니다.'),
          ],
        ),
      ),
    ),
  );
}
