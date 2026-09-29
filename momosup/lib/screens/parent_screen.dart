import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/activity.dart';
import '../models/child_profile.dart';
import '../state/app_state.dart';
import '../widgets/avatar_image.dart';
import 'play_screen.dart';

class ParentSetupScreen extends StatefulWidget {
  const ParentSetupScreen({required this.appState, super.key});

  final AppState appState;

  @override
  State<ParentSetupScreen> createState() => _ParentSetupScreenState();
}

class _ParentSetupScreenState extends State<ParentSetupScreen> {
  final pin = TextEditingController();
  final confirm = TextEditingController();
  String? error;
  bool busy = false;

  @override
  void dispose() {
    pin.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (widget.appState.hasPin) {
      setState(() => error = '이미 보호자 PIN이 있습니다. 보호자 인증으로 들어가세요.');
      return;
    }
    if (pin.text != confirm.text || !RegExp(r'^\d{4,8}$').hasMatch(pin.text)) {
      setState(() => error = '숫자 4~8자리 PIN을 두 번 똑같이 입력하세요.');
      return;
    }
    setState(() => busy = true);
    try {
      await widget.appState.setParentPin(pin.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ParentSessionGuard(
            child: ProfileEditorScreen(appState: widget.appState),
          ),
        ),
      );
    } catch (_) {
      setState(() => error = 'PIN을 저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('보호자 시작')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const AvatarImage(avatar: 'duri', size: 160),
              const SizedBox(height: 12),
              Text(
                '보호자 PIN 만들기',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                '아이 모드에서 설정으로 넘어가지 못하도록 막는 시제품용 PIN입니다. 법정대리인 확인이나 카카오 로그인을 대신하지 않습니다.',
              ),
              const SizedBox(height: 24),
              TextField(
                controller: pin,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: const InputDecoration(
                  labelText: 'PIN 숫자 4~8자리',
                  border: OutlineInputBorder(),
                ),
              ),
              TextField(
                controller: confirm,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: const InputDecoration(
                  labelText: 'PIN 다시 입력',
                  border: OutlineInputBorder(),
                ),
              ),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: busy ? null : save,
                child: const Text('다음: 아이 프로필'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ParentGateScreen extends StatefulWidget {
  const ParentGateScreen({
    required this.appState,
    required this.catalog,
    super.key,
  });

  final AppState appState;
  final List<Activity> catalog;

  @override
  State<ParentGateScreen> createState() => _ParentGateScreenState();
}

class _ParentGateScreenState extends State<ParentGateScreen> {
  final pin = TextEditingController();
  String? error;
  bool busy = false;

  @override
  void dispose() {
    pin.dispose();
    super.dispose();
  }

  Future<void> unlock() async {
    setState(() => busy = true);
    final ok = await widget.appState.verifyPin(pin.text);
    if (!mounted) return;
    setState(() => busy = false);
    if (!ok) {
      pin.clear();
      setState(() => error = 'PIN이 맞지 않아요.');
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ParentSessionGuard(
          child: ParentHubScreen(
            appState: widget.appState,
            catalog: widget.catalog,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('보호자 확인')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_person_rounded,
                  size: 64,
                  color: Color(0xFF78966A),
                ),
                const SizedBox(height: 16),
                Text(
                  '보호자만 들어갈 수 있어요',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: pin,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => unlock(),
                  decoration: const InputDecoration(
                    labelText: '보호자 PIN',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: busy ? null : unlock,
                  child: const Text('보호자 화면 열기'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Closes the parent route stack after backgrounding or a short session.
class ParentSessionGuard extends StatefulWidget {
  const ParentSessionGuard({required this.child, super.key});

  final Widget child;

  @override
  State<ParentSessionGuard> createState() => _ParentSessionGuardState();
}

class _ParentSessionGuardState extends State<ParentSessionGuard>
    with WidgetsBindingObserver {
  Timer? expiry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    expiry = Timer(const Duration(minutes: 5), lock);
  }

  void lock() {
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      lock();
    }
  }

  @override
  void dispose() {
    expiry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class ParentHubScreen extends StatelessWidget {
  const ParentHubScreen({
    required this.appState,
    required this.catalog,
    super.key,
  });

  final AppState appState;
  final List<Activity> catalog;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: appState,
    builder: (context, _) {
      final profile = appState.activeProfile;
      return Scaffold(
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
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const _NoticeCard(
                    text: '비공개 시제품 · 계정 로그인, 결제, 서버 동기화는 준비 중입니다.',
                  ),
                  const SizedBox(height: 16),
                  Text('자녀 프로필', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ...appState.profiles.map(
                    (item) => _ParentRow(
                      child: ListTile(
                        leading: AvatarImage(avatar: item.avatar, size: 48),
                        title: Text(item.nickname),
                        subtitle: Text(
                          '${item.ageLabel} · ${item.level} 시작 단계',
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
                      if (profile != null)
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
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (profile != null) ...[
                    Text(
                      '오늘 ${appState.minutesToday(profile.id)}분 / '
                      '${profile.dailyLimitMinutes}분 이용',
                    ),
                    const SizedBox(height: 12),
                    _HubTile(
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
                    _HubTile(
                      icon: Icons.auto_stories_rounded,
                      title: '놀이 10개 미리보기',
                      subtitle: '아직 아이 모드에 공개되지 않은 초안',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PreviewCatalogScreen(
                            appState: appState,
                            profile: profile,
                            catalog: catalog,
                          ),
                        ),
                      ),
                    ),
                    _HubTile(
                      icon: Icons.palette_outlined,
                      title: '기기에 저장된 그림',
                      subtitle: '아이별로 보기·삭제하기',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ParentGalleryScreen(profile: profile),
                        ),
                      ),
                    ),
                    _HubTile(
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
              ),
            ),
          ),
        ),
      );
    },
  );
}

class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({required this.appState, this.initial, super.key});

  final AppState appState;
  final ChildProfile? initial;

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  late final TextEditingController nickname;
  late int ageMonths;
  late String avatar;
  late String gender;
  late List<int> answers;
  String? error;
  bool busy = false;

  static const questions = [
    ('화면을 누르거나 끌어본 경험은?', ['처음이에요', '조금 해봤어요', '익숙해요', '모르겠어요']),
    ('짧은 말 안내를 이해하는 편인가요?', ['천천히 안내가 좋아요', '한 문장씩 좋아요', '금방 이해해요', '모르겠어요']),
    ('한 놀이에 머무는 시간은?', ['아주 짧게', '몇 분 정도', '조금 더 길게', '모르겠어요']),
    ('좋아하는 놀이는?', ['만져 보기', '그리기', '노래·몸놀이', '모르겠어요']),
    ('소리와 움직임은?', ['조용한 편이 좋아요', '보통이 좋아요', '움직임을 좋아해요', '모르겠어요']),
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    nickname = TextEditingController(text: initial?.nickname ?? '');
    ageMonths = initial?.ageMonths ?? 36;
    avatar = initial?.avatar ?? 'momo';
    gender = initial?.gender ?? '선택하지 않음';
    answers = initial?.answers.length == 5
        ? List<int>.from(initial!.answers)
        : List<int>.filled(5, 3);
  }

  @override
  void dispose() {
    nickname.dispose();
    super.dispose();
  }

  String recommendLevel() {
    final known = answers.where((answer) => answer != 3).toList();
    if (known.isEmpty) return '기본';
    final score = known.fold<int>(0, (sum, answer) => sum + answer);
    if (score <= 2) return '찬찬히';
    if (score >= 7) return '더 탐색';
    return '기본';
  }

  Future<void> save() async {
    final name = nickname.text.trim();
    if (name.isEmpty || name.length > 12) {
      setState(() => error = '별명은 1~12자로 입력해 주세요.');
      return;
    }
    setState(() => busy = true);
    try {
      final profile = ChildProfile(
        id:
            widget.initial?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        nickname: name,
        ageMonths: ageMonths,
        avatar: avatar,
        gender: gender,
        level: recommendLevel(),
        answers: List<int>.from(answers),
        dailyLimitMinutes: widget.initial?.dailyLimitMinutes ?? 15,
        musicOn: widget.initial?.musicOn ?? true,
        lowStimulation: widget.initial?.lowStimulation ?? false,
      );
      if (widget.initial == null) {
        await widget.appState.addProfile(profile);
      } else {
        await widget.appState.updateProfile(profile);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => error = '저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> deleteProfile() async {
    final initial = widget.initial;
    if (initial == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('프로필을 삭제할까요?'),
        content: const Text('이 기기의 프로필, 놀이 기록, 저장된 그림을 삭제합니다. 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.appState.deleteProfile(initial.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => error = '완전히 삭제하지 못했어요. 다시 시도해 주세요.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.initial == null ? '아이 프로필 만들기' : '프로필 수정'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _NoticeCard(
                text: '시제품에는 정확한 생년월일 대신 테스트용 나이 구간만 기기에 저장합니다. 실명은 입력하지 마세요.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nickname,
                maxLength: 12,
                decoration: const InputDecoration(
                  labelText: '아이 별명',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: ageMonths,
                decoration: const InputDecoration(
                  labelText: '테스트용 나이 구간',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 36, child: Text('만 3세')),
                  DropdownMenuItem(value: 48, child: Text('만 4세')),
                  DropdownMenuItem(value: 60, child: Text('만 5세')),
                ],
                onChanged: (value) => setState(() => ageMonths = value ?? 36),
              ),
              const SizedBox(height: 20),
              Text('함께 놀 친구', style: Theme.of(context).textTheme.titleMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['momo', 'duri', 'nuri']
                    .map(
                      (name) => InkWell(
                        onTap: () => setState(() => avatar = name),
                        child: Column(
                          children: [
                            AvatarImage(avatar: name, size: 84),
                            Icon(
                              avatar == name
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: const Color(0xFF78966A),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: gender,
                decoration: const InputDecoration(
                  labelText: '성별 (선택, 추천에 사용하지 않음)',
                  border: OutlineInputBorder(),
                ),
                items: ['선택하지 않음', '여아', '남아']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => gender = value ?? '선택하지 않음'),
              ),
              const SizedBox(height: 24),
              Text(
                '아이에게 편한 시작 방법 찾기',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Text('진단이나 또래 비교가 아닙니다. 언제든 다시 답할 수 있어요.'),
              const SizedBox(height: 12),
              for (var index = 0; index < questions.length; index++) ...[
                Text(
                  questions[index].$1,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  key: ValueKey('question_$index'),
                  initialValue: answers[index],
                  items: [
                    for (var option = 0; option < 4; option++)
                      DropdownMenuItem(
                        value: option,
                        child: Text(questions[index].$2[option]),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => answers[index] = value ?? 3),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                '추천 시작: ${recommendLevel()} · '
                '${recommendLevel() == '찬찬히'
                    ? '짧고 단순한 놀이부터'
                    : recommendLevel() == '더 탐색'
                    ? '조금 더 탐색하는 놀이부터'
                    : '다양한 놀이를 고르게'} 보여드려요.',
              ),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: busy ? null : save,
                child: const Text('프로필 저장'),
              ),
              if (widget.initial != null) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: busy ? null : deleteProfile,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('이 기기의 프로필·그림 삭제'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

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
  late bool lowStimulation = widget.profile.lowStimulation;

  Future<void> save() async {
    await widget.appState.updateProfile(
      widget.profile.copyWith(
        dailyLimitMinutes: limit,
        musicOn: music,
        lowStimulation: lowStimulation,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${widget.profile.nickname} 설정')),
    body: SafeArea(
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
            title: const Text('음악 사용'),
            subtitle: const Text('첫 시제품에는 실제 음원 파일이 없습니다.'),
            onChanged: (value) => setState(() => music = value),
          ),
          SwitchListTile(
            value: lowStimulation,
            title: const Text('차분한 움직임'),
            subtitle: const Text('캐릭터 움직임을 줄입니다.'),
            onChanged: (value) => setState(() => lowStimulation = value),
          ),
          const SizedBox(height: 16),
          const Text('음성·효과음의 별도 조절과 이용 가능 시간대는 공개 MVP 전에 추가합니다.'),
          const SizedBox(height: 20),
          FilledButton(onPressed: save, child: const Text('저장')),
        ],
      ),
    ),
  );
}

class PreviewCatalogScreen extends StatelessWidget {
  const PreviewCatalogScreen({
    required this.appState,
    required this.profile,
    required this.catalog,
    super.key,
  });

  final AppState appState;
  final ChildProfile profile;
  final List<Activity> catalog;

  @override
  Widget build(BuildContext context) {
    final items = catalog
        .where((activity) => activity.supportsAge(profile.ageMonths))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('콘텐츠 검토·미리보기')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const _NoticeCard(text: '검수와 사용권 확인이 기록된 놀이만 아이 화면에 나타납니다.'),
            const SizedBox(height: 12),
            for (final activity in items)
              _ParentRow(
                child: ListTile(
                  leading: AvatarImage(avatar: activity.avatar, size: 54),
                  title: Text(activity.title),
                  subtitle: Text(
                    '${activity.theme} · ${activity.modeLabel} · '
                    '${activity.isFullyApproved ? '검수 완료' : '검수 대기'}',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ContentDetailScreen(
                        appState: appState,
                        profile: profile,
                        activity: activity,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ContentDetailScreen extends StatelessWidget {
  const ContentDetailScreen({
    required this.appState,
    required this.profile,
    required this.activity,
    super.key,
  });

  final AppState appState;
  final ChildProfile profile;
  final Activity activity;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(activity.title)),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          AvatarImage(avatar: activity.avatar, size: 148),
          const SizedBox(height: 8),
          Text(
            '${activity.theme} · ${activity.modeLabel} · 약 ${activity.minutes}분',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text('시작 대본', style: Theme.of(context).textTheme.titleMedium),
          Text(activity.intro),
          const SizedBox(height: 12),
          Text('아이 행동', style: Theme.of(context).textTheme.titleMedium),
          Text(activity.prompt),
          if (activity.choices.isNotEmpty) Text(activity.choices.join(' / ')),
          if (activity.verses.isNotEmpty) Text(activity.verses.join('\n')),
          const SizedBox(height: 12),
          Text('마무리', style: Theme.of(context).textTheme.titleMedium),
          Text('${activity.outro}\n화면 밖: ${activity.offscreen}'),
          const SizedBox(height: 12),
          Text('안전 점검', style: Theme.of(context).textTheme.titleMedium),
          ...activity.safety.map((note) => Text('• $note')),
          const SizedBox(height: 16),
          const _NoticeCard(
            text: '보호자 전용 조작 미리보기에서는 안내 음성을 재생하지 않습니다. 아이 화면에서 실제 음성 재생을 확인할 수 있습니다.',
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlayScreen(
                  activity: activity,
                  appState: appState,
                  profile: profile,
                  isParentPreview: true,
                ),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('보호자 조작 미리보기'),
          ),
        ],
      ),
    ),
  );
}

class ParentGalleryScreen extends StatefulWidget {
  const ParentGalleryScreen({required this.profile, super.key});

  final ChildProfile profile;

  @override
  State<ParentGalleryScreen> createState() => _ParentGalleryScreenState();
}

class _ParentGalleryScreenState extends State<ParentGalleryScreen> {
  late Future<List<File>> drawings = loadDrawings();

  Future<List<File>> loadDrawings() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/momosup_drawings');
    if (!await directory.exists()) return [];
    final files = await directory
        .list(followLinks: false)
        .where(
          (entry) =>
              entry is File &&
              entry.uri.pathSegments.last.startsWith('${widget.profile.id}_') &&
              entry.path.endsWith('.png'),
        )
        .cast<File>()
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  Future<void> deleteDrawing(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('이 그림을 삭제할까요?'),
        content: const Text('이 기기에서 영구적으로 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await file.delete();
      if (mounted) setState(() => drawings = loadDrawings());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('그림을 삭제하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${widget.profile.nickname}의 그림')),
    body: SafeArea(
      child: FutureBuilder<List<File>>(
        future: drawings,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('그림을 불러오지 못했어요.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final files = snapshot.data!;
          if (files.isEmpty) {
            return const Center(child: Text('아직 이 기기에 저장된 그림이 없어요.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .82,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) => Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Expanded(
                    child: Image.file(
                      files[index],
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                  IconButton(
                    tooltip: '그림 삭제',
                    onPressed: () => deleteDrawing(files[index]),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          );
        },
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

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _ParentRow(
    child: ListTile(
      leading: Icon(icon, color: const Color(0xFF78966A)),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    ),
  );
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFFFFF1D8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF8D6438)),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}

class _ParentRow extends StatelessWidget {
  const _ParentRow({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 5),
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFD0DAB8))),
    ),
    child: child,
  );
}
