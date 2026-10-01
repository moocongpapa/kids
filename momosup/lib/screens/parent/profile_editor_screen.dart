import 'package:flutter/material.dart';

import '../../models/age_journey.dart';
import '../../models/child_profile.dart';
import '../../state/app_state.dart';
import '../../utils/child_birth_date_picker.dart';
import '../../widgets/avatar_image.dart';
import 'parent_common_widgets.dart';

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
  late String? birthDate;
  late List<int> answers;
  late bool preschool;
  late int playStage;
  String? error;
  bool busy = false;

  static const infantQuestions = [
    ('지금 관심을 보이는 것은?', ['사람 얼굴', '소리', '큰 장난감', '잘 모르겠어요']),
    ('편안한 놀이 자세는?', ['현재 누운 자세', '보호자 품', '편안히 앉은 자세', '상황마다 달라요']),
    ('준비 가능한 것은?', ['준비물 없이', '큰 장난감', '그림책·안전 거울', '상황마다 달라요']),
    ('함께 놀아줄 사람은?', ['보호자 한 명', '가족과 함께', '돌보는 어른', '상황마다 달라요']),
    ('편안해하는 자극은?', ['조용한 인사', '작은 소리', '부드러운 촉감', '잘 모르겠어요']),
  ];
  List<(String, List<String>)> get questions =>
      ageMonths < 24 ? infantQuestions : olderQuestions;
  static const olderQuestions = [
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
    ageMonths = (initial?.ageMonths ?? 36).clamp(6, 95);
    birthDate = initial?.birthDate;
    preschool = initial?.preschool ?? true;
    playStage = initial?.playStage ?? -1;
    avatar = initial?.avatar ?? 'momo';
    gender = initial?.gender ?? '선택하지 않음';
    answers = initial?.answers.length == 5
        ? List<int>.from(initial!.answers)
        : List<int>.filled(5, 3);
  }

  Future<void> _pickBirthDate() async {
    DateTime initialDate;
    if (birthDate != null && birthDate!.isNotEmpty) {
      try {
        initialDate = DateTime.parse(birthDate!);
      } catch (_) {
        initialDate = DateTime.now().subtract(Duration(days: ageMonths * 30));
      }
    } else {
      initialDate = DateTime.now().subtract(Duration(days: ageMonths * 30));
    }

    final picked = await showChildBirthDatePicker(
      context: context,
      initialDate: initialDate,
    );
    if (picked != null && mounted) {
      final y = picked.year;
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      final calculated = ChildProfile.calculateAgeMonths(picked);
      setState(() {
        birthDate = '$y-$m-$d';
        ageMonths = calculated.clamp(6, 95);
      });
    }
  }

  @override
  void dispose() {
    nickname.dispose();
    super.dispose();
  }

  String recommendLevel() => '기본';

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
        birthDate: birthDate,
        ageMonths: ageMonths,
        avatar: avatar,
        gender: gender,
        level: recommendLevel(),
        preschool: preschool,
        playStage: playStage,
        familyId: widget.initial?.familyId,
        ownerParentId: widget.initial?.ownerParentId,
        ownerName: widget.initial?.ownerName,
        isShared: widget.initial?.isShared ?? false,
        sharedMembers: widget.initial?.sharedMembers ?? const [],
        inviteCode: widget.initial?.inviteCode,
        favoriteJourneys: widget.initial?.favoriteJourneys ?? const [],
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
              const ParentNoticeCard(
                text: '개월 수는 기기에만 저장하며 자동으로 증가하지 않아요. 자라면 이곳에서 바꿔 주세요. 실명은 입력하지 마세요.',
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
              InkWell(
                onTap: _pickBirthDate,
                borderRadius: BorderRadius.circular(20),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '아이 생년월일',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF477A53),
                    ),
                  ),
                  child: Text(
                    birthDate != null && birthDate!.isNotEmpty
                        ? '$birthDate ($ageMonths개월)'
                        : '생년월일을 선택해 주세요 (달력 열기)',
                    style: TextStyle(
                      color: birthDate != null && birthDate!.isNotEmpty
                          ? Colors.black87
                          : Colors.black45,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: ageMonths,
                decoration: const InputDecoration(
                  labelText: '현재 개월 수',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (var month = 6; month <= 95; month++)
                    DropdownMenuItem(
                      value: month,
                      child: Text(
                        month < 36
                            ? '$month개월'
                            : '만 ${month ~/ 12}세 · $month개월',
                      ),
                    ),
                ],
                onChanged: (value) => setState(() {
                  if ((ageMonths < 24) != (value! < 24)) {
                    answers = List<int>.filled(5, 3);
                  }
                  ageMonths = value;
                }),
              ),
              const SizedBox(height: 20),
              if (ageMonths >= 84)
                SwitchListTile(
                  title: const Text('아직 초등학교 입학 전이에요'),
                  value: preschool,
                  onChanged: (v) => setState(() => preschool = v),
                ),
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
                  key: ValueKey('question_${ageMonths < 24}_$index'),
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
              const Text(
                '월령 추천은 월령과 도움 필요 답변으로 시작 방법을 골라요. 발달 등급이 아니며 직접 바꿀 수 있습니다.',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: playStage,
                decoration: const InputDecoration(labelText: '처음 시작할 놀이 방법'),
                items: [
                  const DropdownMenuItem(
                    value: -1,
                    child: Text('월령과 답변에 맞춰 추천'),
                  ),
                  for (var i = 0; i < 3; i++)
                    DropdownMenuItem(value: i, child: Text(journeyStages[i])),
                ],
                onChanged: (v) => setState(() => playStage = v!),
              ),
              const SizedBox(height: 16),
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
