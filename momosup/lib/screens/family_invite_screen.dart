import 'package:flutter/material.dart';
import '../models/family_share.dart';
import '../state/app_state.dart';
import '../widgets/avatar_image.dart';
import '../widgets/forest_background.dart';

class FamilyInviteAcceptScreen extends StatefulWidget {
  const FamilyInviteAcceptScreen({
    required this.appState,
    this.initialCodeOrUrl,
    super.key,
  });

  final AppState appState;
  final String? initialCodeOrUrl;

  @override
  State<FamilyInviteAcceptScreen> createState() =>
      _FamilyInviteAcceptScreenState();
}

class _FamilyInviteAcceptScreenState extends State<FamilyInviteAcceptScreen> {
  final inputController = TextEditingController();
  final nameController = TextEditingController();

  FamilyInvitePayload? payload;
  String selectedRole = '엄마';
  String? error;
  bool busy = false;

  final List<String> roleOptions = [
    '엄마',
    '아빠',
    '할머니',
    '할아버지',
    '이모/고모',
    '삼촌',
    '선생님/돌봄자',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCodeOrUrl != null) {
      inputController.text = widget.initialCodeOrUrl!;
      _tryParse(widget.initialCodeOrUrl!);
    }
    final parentNickname = widget.appState.parentAccount?.nickname;
    if (parentNickname != null) {
      nameController.text = parentNickname;
    }
  }

  @override
  void dispose() {
    inputController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void _tryParse(String raw) {
    setState(() => error = null);
    final parsed = FamilyInvitePayload.fromRaw(raw);
    if (parsed != null) {
      setState(() {
        payload = parsed;
        if (nameController.text.isEmpty) {
          nameController.text = selectedRole;
        }
      });
    } else if (raw.trim().isNotEmpty) {
      setState(() {
        payload = null;
        error = '올바른 모모숲 초대 링크나 코드를 입력해 주세요.';
      });
    }
  }

  Future<void> _accept() async {
    if (payload == null) {
      setState(() => error = '초대 정보를 먼저 확인해 주세요.');
      return;
    }
    final myName = nameController.text.trim().isEmpty
        ? selectedRole
        : nameController.text.trim();

    setState(() => busy = true);
    try {
      final profile = await widget.appState.acceptFamilyInvite(
        inputController.text.trim(),
        myName: myName,
        myRole: selectedRole,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "'${profile.nickname}' 아이의 가족 프로필이 성공적으로 등록되었습니다!",
          ),
          backgroundColor: const Color(0xFF477A53),
        ),
      );
      Navigator.of(context).pop(profile);
    } catch (e) {
      setState(() => error = '초대 수락 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('가족 초대 링크 등록'),
      ),
      body: ForestBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    '카카오톡으로 받은\n가족 초대 링크나 코드를 입력하세요',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF284E3D),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '다른 보호자(배우자, 조부모님 등)가 공유한 아이 프로필을 내 기기에 안전하게 연결합니다.',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: inputController,
                    decoration: InputDecoration(
                      labelText: '초대 링크 또는 코드 (예: MOMO-...)',
                      hintText: 'https://momosup.app/share?invite=...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded),
                        onPressed: () => _tryParse(inputController.text),
                      ),
                    ),
                    onChanged: _tryParse,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (payload != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFD7DDBE)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              AvatarImage(avatar: payload!.avatar, size: 72),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          payload!.childName,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF284E3D),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F0E2),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            payload!.gender,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF477A53),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      payload!.birthDate.isNotEmpty
                                          ? '${payload!.birthDate} (${payload!.ageMonths}개월)'
                                          : '${payload!.ageMonths}개월',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '초대자: ${payload!.inviterName} (${payload!.inviterRole})',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF5D7B65),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 28),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '아이와의 관계를 선택해 주세요',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF284E3D),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: roleOptions.map((role) {
                              final isSelected = selectedRole == role;
                              return ChoiceChip(
                                label: Text(role),
                                selected: isSelected,
                                selectedColor: const Color(0xFF477A53),
                                labelStyle: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() {
                                      selectedRole = role;
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: '가족 내 호칭/닉네임',
                              hintText: '예: 엄마, 은서할머니',
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton.icon(
                              onPressed: busy ? null : _accept,
                              icon: const Icon(Icons.group_add_rounded),
                              label: const Text(
                                '가족으로 함께하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
