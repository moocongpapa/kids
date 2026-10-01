import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/child_profile.dart';
import '../models/parent_account.dart';
import '../services/kakao_auth_service.dart';
import '../state/app_state.dart';
import '../utils/development_access.dart';
import '../widgets/avatar_image.dart';
import '../widgets/forest_background.dart';
import '../widgets/kakao_share_modal.dart';
import 'family_invite_screen.dart';

class ParentOnboardingScreen extends StatefulWidget {
  const ParentOnboardingScreen({
    required this.appState,
    this.startWithoutLogin = false,
    this.authService,
    super.key,
  });

  final AppState appState;
  final bool startWithoutLogin;
  final KakaoAuthService? authService;

  @override
  State<ParentOnboardingScreen> createState() => _ParentOnboardingScreenState();
}

class _ParentOnboardingScreenState extends State<ParentOnboardingScreen> {
  int step = 0; // 0: 카카오로그인, 1: 아이정보등록, 2: 보호자PIN, 3: 완료

  // Step 0: Kakao
  bool agreeAge = true;
  bool agreeTerms = true;
  bool agreePrivacy = true;
  bool agreeParentalConsent = true;
  final parentNicknameController = TextEditingController(text: '모모보호자');
  ParentAccount? connectedAccount;
  bool kakaoBusy = false;

  // Step 1: Child info
  final childNameController = TextEditingController(text: '우리 아이');
  String gender = '선택하지 않음';
  DateTime birthDate = DateTime.now().subtract(const Duration(days: 365 * 3));
  String avatar = 'momo';

  // Step 2: Parent PIN
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();

  // Created profile for Step 3
  ChildProfile? createdProfile;
  String? error;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.appState.hasParentAccount) {
      connectedAccount = widget.appState.parentAccount;
      step = 1;
    }
    if (widget.startWithoutLogin && developmentAccessEnabled) {
      _handleDevelopmentStart();
    }
  }

  @override
  void dispose() {
    parentNicknameController.dispose();
    childNameController.dispose();
    pinController.dispose();
    confirmPinController.dispose();
    super.dispose();
  }

  int get calculatedMonths => ChildProfile.calculateAgeMonths(birthDate);

  String get birthDateString =>
      '${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}';

  bool get canProceedKakao =>
      agreeAge && agreeTerms && agreePrivacy && agreeParentalConsent;

  Future<void> _handleDevelopmentStart() async {
    if (!developmentAccessEnabled || kakaoBusy) return;
    setState(() {
      kakaoBusy = true;
      error = null;
    });
    try {
      final account =
          widget.appState.parentAccount ??
          ParentAccount(
            id: 'local_dev_${DateTime.now().microsecondsSinceEpoch}',
            nickname: parentNicknameController.text.trim().isEmpty
                ? '모모보호자'
                : parentNicknameController.text.trim(),
            provider: 'local_dev',
            connectedAt: DateTime.now(),
          );
      if (!widget.appState.hasParentAccount) {
        await widget.appState.setParentAccount(account);
      }
      if (!mounted) return;
      setState(() {
        connectedAccount = account;
        step = 1;
      });
    } catch (_) {
      if (mounted) {
        setState(() => error = '이 기기에 접속 정보를 저장하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => kakaoBusy = false);
    }
  }

  Future<void> _handleKakaoLogin() async {
    if (!canProceedKakao) {
      setState(() => error = '모든 필수 약관에 동의해 주세요.');
      return;
    }
    setState(() {
      kakaoBusy = true;
      error = null;
    });

    try {
      final name = parentNicknameController.text.trim().isEmpty
          ? '모모보호자'
          : parentNicknameController.text.trim();
      final account = await (widget.authService ?? KakaoAuthService.instance)
          .loginWithKakao(nickname: name);
      if (!mounted) return;
      await widget.appState.setParentAccount(account);
      if (!mounted) return;
      setState(() {
        connectedAccount = account;
        step = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(
        () => error = KakaoAuthService.isLoginCancelled(e)
            ? developmentAccessEnabled
                  ? '카카오 로그인을 취소했어요. 로그인 없이 시작하거나 다시 시도해 주세요.'
                  : '카카오 로그인을 취소했어요. 다시 시도해 주세요.'
            : '카카오 로그인에 실패했어요. 다시 시도해 주세요.',
      );
    } finally {
      if (mounted) setState(() => kakaoBusy = false);
    }
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
      helpText: '아이 생년월일 선택',
      cancelText: '취소',
      confirmText: '확인',
    );
    if (picked != null && mounted) {
      setState(() => birthDate = picked);
    }
  }

  void _proceedToPin() {
    final name = childNameController.text.trim();
    if (name.isEmpty) {
      setState(() => error = '아이 이름을 입력해 주세요.');
      return;
    }
    setState(() {
      error = null;
      step = 2;
    });
  }

  Future<void> _saveAndFinish() async {
    final pin = pinController.text.trim();
    final confirm = confirmPinController.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(pin) || pin != confirm) {
      setState(() => error = '4자리 숫자로 된 보호자 PIN을 똑같이 입력해 주세요.');
      return;
    }

    setState(() {
      saving = true;
      error = null;
    });

    try {
      await widget.appState.setParentPin(pin);

      final childName = childNameController.text.trim();
      final childId = 'child_${DateTime.now().millisecondsSinceEpoch}';
      final parentName = connectedAccount?.nickname ?? '모모보호자';

      final profile = ChildProfile(
        id: childId,
        nickname: childName,
        birthDate: birthDateString,
        gender: gender,
        avatar: avatar,
        ageMonths: calculatedMonths,
        level: '기본',
        answers: const [3, 3, 3, 3, 3],
        ownerParentId: connectedAccount?.id,
        ownerName: parentName,
      );

      await widget.appState.addProfile(profile);
      await widget.appState.selectProfile(profile.id);

      if (!mounted) return;
      setState(() {
        createdProfile = profile;
        step = 3;
      });
    } catch (e) {
      if (mounted) setState(() => error = '프로필을 저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _shareWithFamily() async {
    if (createdProfile == null) return;
    final payload = await widget.appState.createFamilyInvite(
      createdProfile!,
      inviterRole: '보호자',
    );
    if (!mounted) return;
    KakaoShareModal.show(
      context,
      profile: createdProfile!,
      payload: payload,
      parentAccount: connectedAccount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          step == 0
              ? '보호자 카카오 시작'
              : step == 1
              ? '아이 정보 등록'
              : step == 2
              ? '보호자 안전 PIN'
              : '등록 완료',
        ),
        automaticallyImplyLeading: step > 0 && step < 3,
        leading: step > 0 && step < 3
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => step--),
              )
            : null,
      ),
      body: ForestBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildStepIndicator(),
                  const SizedBox(height: 24),
                  if (step == 0) _buildKakaoStep(),
                  if (step == 1) _buildChildInfoStep(),
                  if (step == 2) _buildPinStep(),
                  if (step == 3) _buildCompletionStep(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(4, (index) {
        final isActive = index <= step;
        final isCurrent = index == step;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            decoration: BoxDecoration(
              color: isCurrent
                  ? const Color(0xFF477A53)
                  : isActive
                  ? const Color(0xFF88AB7F)
                  : const Color(0xFFD7DDBE),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKakaoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: AvatarImage(avatar: 'momo', size: 120)),
        const SizedBox(height: 16),
        const Text(
          '모모숲에 오신 것을 환영해요!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF284E3D),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '우리 아이의 안전한 놀이를 위해\n보호자(부모님)의 카카오 계정으로 시작합니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
        ),
        if (developmentAccessEnabled) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: kakaoBusy ? null : _handleDevelopmentStart,
            icon: const Icon(Icons.forest_rounded),
            label: const Text('로그인 없이 시작하기'),
          ),
          const SizedBox(height: 8),
          const Text(
            '개발 중에는 이 기기에서 바로 사용할 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
        ],
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFD7DDBE)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: parentNicknameController,
                  decoration: const InputDecoration(
                    labelText: '보호자 닉네임 (카카오 이름)',
                    hintText: '예: 민준아빠, 은서엄마',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '서비스 이용 동의',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF284E3D),
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: canProceedKakao,
                  title: const Text(
                    '전체 동의하기',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onChanged: (v) {
                    final val = v ?? false;
                    setState(() {
                      agreeAge = val;
                      agreeTerms = val;
                      agreePrivacy = val;
                      agreeParentalConsent = val;
                    });
                  },
                ),
                const Divider(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: agreeAge,
                  title: const Text('[필수] 만 14세 이상 보호자 본인 확인'),
                  onChanged: (v) => setState(() => agreeAge = v ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: agreeTerms,
                  title: const Text('[필수] 모모숲 서비스 이용약관 동의'),
                  onChanged: (v) => setState(() => agreeTerms = v ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: agreePrivacy,
                  title: const Text('[필수] 개인정보 수집 및 이용 동의'),
                  onChanged: (v) => setState(() => agreePrivacy = v ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: agreeParentalConsent,
                  title: const Text('[필수] 아동 개인정보 처리에 관한 법정대리인 동의'),
                  onChanged: (v) =>
                      setState(() => agreeParentalConsent = v ?? false),
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEE500),
              foregroundColor: const Color(0xFF191919),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: kakaoBusy ? null : _handleKakaoLogin,
            icon: kakaoBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.chat_bubble, size: 22),
            label: const Text(
              '카카오로 3초 만에 시작하기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      FamilyInviteAcceptScreen(appState: widget.appState),
                ),
              );
            },
            icon: const Icon(Icons.link_rounded, size: 18),
            label: const Text('💌 가족에게 초대 링크를 받으셨나요?'),
          ),
        ),
      ],
    );
  }

  Widget _buildChildInfoStep() {
    final months = calculatedMonths;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '우리 아이를 소개해 주세요!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF284E3D),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '입력하신 생년월일을 바탕으로 아이에게 꼭 맞는 숲속 놀이가 제공됩니다.',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: childNameController,
          decoration: const InputDecoration(
            labelText: '아이 이름 또는 별명 *',
            hintText: '예: 민준, 서아',
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '성별',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF284E3D),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['남아', '여아', '선택하지 않음'].map((item) {
            final isSelected = gender == item;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isSelected
                        ? const Color(0xFF477A53)
                        : Colors.white,
                    foregroundColor: isSelected
                        ? Colors.white
                        : const Color(0xFF284E3D),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF477A53)
                          : const Color(0xFFD7DDBE),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => setState(() => gender = item),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        const Text(
          '생년월일',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF284E3D),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectBirthDate,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFC6D2AD)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFF477A53),
                ),
                const SizedBox(width: 12),
                Text(
                  birthDateString,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF284E3D),
                  ),
                ),
                const Spacer(),
                const Text(
                  '변경',
                  style: TextStyle(
                    color: Color(0xFF477A53),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2E3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.eco_rounded, color: Color(0xFF477A53), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '현재 만 ${months ~/ 12}세 ($months개월) 아동입니다 🌱\n아이의 월령 발달에 맞는 놀이가 준비됩니다.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF284E3D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '함께 놀 캐릭터 친구',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF284E3D),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _avatarOption('momo', '모모 (아기새)'),
            _avatarOption('duri', '두리 (아기곰)'),
            _avatarOption('nuri', '누리 (다람쥐)'),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _proceedToPin,
          child: const Text('다음: 보호자 안전 PIN 설정'),
        ),
      ],
    );
  }

  Widget _avatarOption(String key, String label) {
    final isSelected = avatar == key;
    return InkWell(
      onTap: () => setState(() => avatar = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F0E2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF477A53) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            AvatarImage(avatar: key, size: 76),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: const Color(0xFF284E3D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: AvatarImage(avatar: 'duri', size: 100)),
        const SizedBox(height: 16),
        const Text(
          '보호자 안전 PIN 만들기',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF284E3D),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '아이가 놀이 중에 부모님 설정 화면으로 넘어오지 않도록 보호하는 4자리 숫자 비밀번호입니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: '보호자 PIN 숫자 (4~8자리)',
            hintText: '숫자 4자리 권장',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: confirmPinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'PIN 확인 (한 번 더 입력)'),
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: saving ? null : _saveAndFinish,
          child: saving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('등록 완료 및 모모숲 열기'),
        ),
      ],
    );
  }

  Widget _buildCompletionStep() {
    final profile = createdProfile;
    final childName = profile?.nickname ?? '아이';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: AvatarImage(avatar: avatar, size: 140)),
        const SizedBox(height: 16),
        Text(
          '환영해요! $childName의\n모모숲이 완성되었어요 🎉',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF284E3D),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          connectedAccount?.isDevelopment == true
              ? '로그인 없이 등록했어요. 이 기기에서 바로 놀이를 시작할 수 있어요.'
              : '카카오 계정(${connectedAccount?.nickname ?? '보호자'})으로 연결되었습니다.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD7DDBE)),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.family_restroom_rounded, color: Color(0xFF477A53)),
                  SizedBox(width: 8),
                  Text(
                    '아이 프로필 가족 공유',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF284E3D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                '배우자나 조부모님께 카카오톡으로 아이 프로필 링크를 보내 함께 놀이와 관찰 기록을 볼 수 있어요.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE500),
                    foregroundColor: const Color(0xFF191919),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _shareWithFamily,
                  icon: const Icon(Icons.chat_bubble, size: 20),
                  label: const Text(
                    '카카오톡으로 가족 초대하기',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('모모숲 놀이터 입장하기'),
        ),
      ],
    );
  }
}
