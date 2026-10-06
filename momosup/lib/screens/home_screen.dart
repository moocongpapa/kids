import '../utils/forest_orientation.dart';
import '../game/forest_world_scene.dart';
import '../utils/development_access.dart';
import '../data/play_catalog.dart';
import 'play_library_screen.dart';
import '../utils/audio_policy.dart';
import '../widgets/forest_place_art.dart';
import '../models/age_journey.dart';
import '../data/journey_recommendation.dart';
import 'journey_screen.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../models/child_profile.dart';
import '../state/app_state.dart';
import '../utils/forest_audio.dart';
import '../utils/sound_effects.dart';
import '../widgets/avatar_image.dart';
import '../widgets/forest_background.dart';
import '../widgets/forest_game_ui.dart';
import 'parent_screen.dart';
import 'parent_onboarding_screen.dart';
import 'story_forest_screen.dart';
import 'coloring_screen.dart';
import '../widgets/touch_invitation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.appState, required this.catalog, super.key});
  final AppState appState;
  final List<Activity> catalog;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int area = 0;
  void syncAudio() {
    final p = widget.appState.activeProfile;
    if (p != null) AudioPolicy.instance.configure(p);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.appState.addListener(syncAudio);
    syncAudio();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ForestAudio.instance.startBgm(
        enabled:
            !(widget.appState.activeProfile?.caregiverMode ?? false) &&
            (widget.appState.activeProfile?.musicOn ?? true),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.appState.removeListener(syncAudio);
    ForestAudio.instance.stopBgm();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    if (state != AppLifecycleState.resumed) {
      AudioPolicy.instance.suspend(true);
    } else {
      AudioPolicy.instance.suspend(false);
      if (area == 1) {
        ForestAudio.instance.pauseBgm();
      } else {
        ForestAudio.instance.startBgm(
          enabled: widget.appState.activeProfile?.musicOn ?? false,
        );
      }
    }
  }

  void openParent([AgeJourney? initialJourney]) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => widget.appState.hasPin
          ? ParentGateScreen(
              appState: widget.appState,
              catalog: widget.catalog,
              initialJourney: initialJourney,
            )
          : ParentOnboardingScreen(appState: widget.appState),
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.appState,
    builder: (context, _) {
      final profile = widget.appState.activeProfile;
      final quiet =
          (profile?.caregiverMode ?? false) ||
          (profile?.lowStimulation ?? false);
      return ForestOrientationScope(
        mode:
            profile != null && widget.appState.hasPin && !profile.caregiverMode
            ? ForestOrientation.landscape
            : ForestOrientation.portrait,
        child: Scaffold(
          body: ForestBackground(
            lowStimulation: quiet,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                    child: Row(
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: ForestAudio.instance.isMuted,
                          builder: (_, muted, _) => ForestAction(
                            label: muted ? '숲속 소리 켜기' : '숲속 소리 끄기',
                            icon: muted
                                ? Icons.music_off_rounded
                                : Icons.music_note_rounded,
                            size: 64,
                            quiet: quiet,
                            onPressed: profile?.caregiverMode == true
                                ? null
                                : ForestAudio.instance.toggleMute,
                          ),
                        ),
                        const Spacer(),
                        BouncyTap(
                          onTap: () => SoundEffects.instance.snap(),
                          musicalSound: true,
                          child: const ForestSign('모모숲'),
                        ),
                        const Spacer(),
                        ForestAction(
                          label: '보호자 영역',
                          icon: Icons.lock_rounded,
                          size: 64,
                          quiet: quiet,
                          onPressed: openParent,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: !widget.appState.hasPin || profile == null
                        ? _welcome()
                        : _world(profile),
                  ),
                  if (widget.appState.hasPin &&
                      profile != null &&
                      !profile.caregiverMode &&
                      (profile.ageMonths < 84 || profile.preschool))
                    _dock(quiet),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _welcome() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          children: [
            ForestFloat(child: AvatarImage(avatar: 'momo', size: 210)),
            const SizedBox(height: 12),
            const Text(
              '모모숲에 오신 것을\n환영해요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: forestInk,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              developmentAccessEnabled
                  ? '로그인 없이 아이 정보를 등록하고\n맞춤 숲속 놀이를 시작해 보세요.'
                  : '보호자(부모님)의 카카오 계정으로 등록하고\n아이의 맞춤 숲속 놀이를 시작해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: forestInk, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 22),
            if (developmentAccessEnabled) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ParentOnboardingScreen(
                        appState: widget.appState,
                        startWithoutLogin: true,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.forest_rounded),
                  label: const Text('로그인 없이 시작하기'),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
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
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ParentOnboardingScreen(appState: widget.appState),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble, size: 22),
                label: const Text(
                  '카카오로 3초 만에 시작하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (kDebugMode && !widget.appState.hasPin)
              TextButton(
                onPressed: () async {
                  await widget.appState.setParentPin('1234');
                  await widget.appState.addProfile(
                    const ChildProfile(
                      id: 'demo_child',
                      nickname: '모모친구',
                      ageMonths: 48,
                      avatar: 'momo',
                      level: '기본',
                      answers: [3, 3, 3, 3, 3],
                    ),
                  );
                },
                child: const Text('개발용 둘러보기'),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _world(ChildProfile profile) {
    if (profile.caregiverMode ||
        (profile.ageMonths >= 84 && !profile.preschool)) {
      ForestAudio.instance.stopBgm();
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.spa_outlined, size: 72, color: forestInk),
              const SizedBox(height: 20),
              Text(
                profile.caregiverMode ? '오늘은 함께 노는 날' : '보호자와 놀이를 준비해요',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: forestInk,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                profile.caregiverMode
                    ? '${profile.ageLabel} · 보호자용 화면 밖 놀이\n안내를 읽고 휴대폰을 내려놓아 주세요.'
                    : '현재 콘텐츠는 미취학 시기까지 준비되어 있어요.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              if (profile.caregiverMode)
                for (final guide in recommendJourneys(
                  profile,
                  widget.appState.journeys,
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => openParent(guide),
                      icon: const Icon(Icons.lock_outline_rounded),
                      label: Text(guide.title),
                    ),
                  ),
              const SizedBox(height: 18),
              ForestAction(
                label: '보호자 놀이 준비',
                caption: '보호자 시작',
                icon: Icons.lock_person_rounded,
                size: 96,
                leaf: true,
                quiet: true,
                onPressed: openParent,
              ),
            ],
          ),
        ),
      );
    }
    final reachedLimit =
        widget.appState.secondsRemaining(
          profile.id,
          profile.dailyLimitMinutes,
        ) <=
        0;
    if (reachedLimit) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              AvatarImage(
                avatar: 'momo_quiet',
                size: 220,
                lowStimulation: true,
              ),
              const SizedBox(height: 16),
              const Text(
                '숲도 쉬는 시간',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: forestInk,
                ),
              ),
              const SizedBox(height: 12),
              const Icon(
                Icons.nights_stay_rounded,
                size: 50,
                color: Color(0xFFD8A758),
              ),
              const SizedBox(height: 12),
              const Text('이제 화면 밖에서 만나요', style: TextStyle(color: forestInk)),
            ],
          ),
        ),
      );
    }
    if (area == 1) {
      return StoryForestScreen(
        key: ValueKey('stories-${profile.id}'),
        appState: widget.appState,
        profile: profile,
      );
    }
    final available = availablePlay(widget.appState, widget.catalog, profile);
    final section = area == 0
        ? recommendPlay(widget.appState, widget.catalog, profile)
        : available
              .where((e) => e.area == PlayArea.values[area - 1])
              .take(3)
              .toList();
    final entries = <_WorldEntry>[
      if (area == 2)
        _WorldEntry(
          ForestObject.flower,
          '색칠하기',
          '톡톡 색칠하기',
          () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) =>
                  ColoringScreen(profile: profile, appState: widget.appState),
            ),
          ),
        ),
      for (final e in section)
        _WorldEntry(
          journeyProp(e.symbol),
          '',
          e.title,
          () => openPlay(context, e, widget.appState, profile),
          journeyId: e.journey?.id,
          avatar: e.avatar,
        ),
      if (available.isNotEmpty)
        _WorldEntry(
          ForestObject.home,
          '놀이숲',
          '다른 숲 놀이',
          () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => PlayLibraryScreen(
                appState: widget.appState,
                catalog: widget.catalog,
                profile: profile,
                initialArea: area == 0 ? null : PlayArea.values[area - 1],
              ),
            ),
          ),
        ),
    ];
    if (entries.isEmpty) {
      return Semantics(
        label: '보호자 검수가 끝나면 놀이가 나타나요',
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AvatarImage(
                avatar: 'momo',
                size: 190,
                lowStimulation: profile.lowStimulation,
              ),
              const SizedBox(height: 20),
              const Text(
                '곧 만나요',
                style: TextStyle(
                  fontSize: 24,
                  color: forestInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return AnimatedSwitcher(
      duration:
          profile.lowStimulation || MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 240),
      child: ForestWorldScene(
        key: ValueKey(area),
        count: entries.length,
        area: area,
        quiet: profile.lowStimulation,
        child: LayoutBuilder(
          builder: (context, box) {
            final layout = ForestWorldLayout(box.biggest, entries.length);
            return Stack(
              children: [
                for (var i = 0; i < entries.length; i++)
                  Positioned.fromRect(
                    rect: layout.portals[i],
                    child: TouchInvitation(
                      visible: i == 0 && area == 0 && !profile.lowStimulation,
                      delay: const Duration(seconds: 4),
                      quiet: profile.lowStimulation,
                      child: _ForestPortal(
                        entry: entries[i],
                        quiet: profile.lowStimulation,
                        phase: i.toDouble(),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _dock(bool quiet) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFEAD2A0),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(39),
            bottomLeft: Radius.circular(26),
            bottomRight: Radius.circular(25),
          ),
          border: Border.all(color: const Color(0xFFF9E8BD), width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0xFF9F8054), offset: Offset(0, 5)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < 4; i++)
                ForestAction(
                  key: ValueKey('forest-area-$i'),
                  label: ['감각 놀이숲', '이야기숲', '그림숲', '노래숲'][i],
                  caption: ['놀이', '이야기', '그림', '노래'][i],
                  size: 64,
                  selected: area == i,
                  leaf: area == i,
                  quiet: quiet,
                  child: ForestProp(
                    [
                      ForestObject.leaf,
                      ForestObject.paw,
                      ForestObject.paint,
                      ForestObject.music,
                    ][i],
                    size: 39,
                  ),
                  onPressed: () {
                    if (area != i) {
                      setState(() => area = i);
                      if (i == 1) {
                        ForestAudio.instance.pauseBgm();
                      } else {
                        ForestAudio.instance.startBgm(
                          enabled:
                              widget.appState.activeProfile?.musicOn ?? false,
                        );
                      }
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

(ForestObject, String) activityArt(Activity activity) => switch (activity.id) {
  'animal_tracks' => (ForestObject.paw, '발자국'),
  'animal_steps_song' => (ForestObject.music, '쿵쿵'),
  'feeling_cloud' => (ForestObject.cloud, '구름'),
  'momo_faces' => (ForestObject.heart, '표정'),
  'body_hello' => (ForestObject.music, '쭉쭉'),
  'hand_shapes' => (ForestObject.paint, '손그림'),
  'bus_stop' => (ForestObject.bus, '숲 버스'),
  'my_bus' => (ForestObject.bus, '버스'),
  'forest_weather' => (ForestObject.sun, '날씨'),
  _ => (ForestObject.flower, '꽃밭'),
};

class _WorldEntry {
  const _WorldEntry(
    this.object,
    this.caption,
    this.label,
    this.onTap, {
    this.journeyId,
    this.avatar,
  });
  final String? journeyId, avatar;
  final ForestObject object;
  final String caption, label;
  final Future<void> Function() onTap;
}

class _ForestPortal extends StatefulWidget {
  const _ForestPortal({
    required this.entry,
    required this.quiet,
    required this.phase,
  });
  final _WorldEntry entry;
  final bool quiet;
  final double phase;
  @override
  State<_ForestPortal> createState() => _ForestPortalState();
}

class _ForestPortalState extends State<_ForestPortal> {
  bool pressed = false;
  bool opening = false;

  Future<void> open() async {
    if (opening) return;
    setState(() => opening = true);
    try {
      await widget.entry.onTap();
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.entry.label,
    button: true,
    enabled: !opening,
    onTap: opening ? null : open,
    child: ExcludeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => pressed = true),
        onTapCancel: () => setState(() => pressed = false),
        onTapUp: (_) => setState(() => pressed = false),
        onTap: open,
        child: AnimatedScale(
          scale:
              pressed &&
                  !widget.quiet &&
                  !MediaQuery.disableAnimationsOf(context)
              ? .94
              : 1,
          duration: const Duration(milliseconds: 140),
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  bottom: 16,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ForestPlaceArt(switch (widget.entry.object) {
                      ForestObject.home ||
                      ForestObject.puzzle => ForestPlace.house,
                      ForestObject.music => ForestPlace.music,
                      ForestObject.paint => ForestPlace.art,
                      _ => ForestPlace.garden,
                    }, size: box.maxWidth),
                  ),
                ),
                if (widget.entry.avatar != null)
                  Positioned(
                    left: 0,
                    bottom: 10,
                    child: ForestFloat(
                      still: widget.quiet,
                      offset: widget.phase,
                      child: AvatarImage(
                        avatar: widget.entry.avatar!,
                        size: box.maxWidth * .42,
                        interactive: false,
                        lowStimulation: widget.quiet,
                      ),
                    ),
                  ),
                if (widget.entry.caption.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    child: Text(
                      widget.entry.caption,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: forestInk,
                        shadows: [Shadow(color: forestCream, blurRadius: 5)],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
