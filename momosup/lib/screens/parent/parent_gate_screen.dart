import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../../models/age_journey.dart';
import '../../state/app_state.dart';
import '../../utils/forest_audio.dart';
import '../../widgets/avatar_image.dart';
import '../journey_screen.dart';
import 'parent_hub_screen.dart';
import 'profile_editor_screen.dart';

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
            appState: widget.appState,
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
    this.initialJourney,
    super.key,
  });

  final AppState appState;
  final List<Activity> catalog;
  final AgeJourney? initialJourney;

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
          appState: widget.appState,
          child:
              widget.initialJourney != null &&
                  widget.appState.activeProfile != null
              ? JourneyDetailScreen(
                  journey: widget.initialJourney!,
                  appState: widget.appState,
                  profile: widget.appState.activeProfile!,
                )
              : ParentHubScreen(
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
  const ParentSessionGuard({required this.child, this.appState, super.key});

  final Widget child;
  final AppState? appState;

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
    ForestAudio.instance.pauseBgm();
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
    final profile = widget.appState?.activeProfile;
    ForestAudio.instance.startBgm(
      enabled: profile != null && !profile.caregiverMode && profile.musicOn,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
