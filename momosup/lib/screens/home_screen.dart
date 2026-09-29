import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/recommendation.dart';
import '../models/activity.dart';
import '../models/child_profile.dart';
import '../state/app_state.dart';
import '../utils/forest_audio.dart';
import '../utils/sound_effects.dart';
import '../widgets/avatar_image.dart';
import '../widgets/forest_background.dart';
import '../widgets/forest_game_ui.dart';
import 'dynamic_toy_screen.dart';
import 'parent_screen.dart';
import 'play_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.appState, required this.catalog, super.key});
  final AppState appState;
  final List<Activity> catalog;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int area = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ForestAudio.instance.startBgm(
        enabled: widget.appState.activeProfile?.musicOn ?? true,
      );
    });
  }

  @override
  void dispose() {
    ForestAudio.instance.stopBgm();
    super.dispose();
  }

  void openParent() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => widget.appState.hasPin
          ? ParentGateScreen(appState: widget.appState, catalog: widget.catalog)
          : ParentSetupScreen(appState: widget.appState),
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.appState,
    builder: (context, _) {
      final profile = widget.appState.activeProfile;
      final quiet = profile?.lowStimulation ?? false;
      return Scaffold(
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
                          size: 58,
                          quiet: quiet,
                          onPressed: ForestAudio.instance.toggleMute,
                        ),
                      ),
                      const Spacer(),
                      const ForestSign('모모숲', large: true),
                      const Spacer(),
                      ForestAction(
                        label: '보호자 영역',
                        icon: Icons.lock_rounded,
                        size: 58,
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
                if (widget.appState.hasPin && profile != null) _dock(quiet),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _welcome() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ForestFloat(child: AvatarImage(avatar: 'momo', size: 230)),
          const SizedBox(height: 12),
          const Text(
            '우리 같이 놀자!',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              color: forestInk,
            ),
          ),
          const SizedBox(height: 22),
          ForestAction(
            label: '보호자 설정 시작',
            onPressed: openParent,
            leaf: true,
            icon: Icons.lock_person_rounded,
            size: 88,
            caption: '보호자 시작',
          ),
          const SizedBox(height: 18),
          const Text(
            '보호자가 먼저 아이의 놀이를 준비해 주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: forestInk, fontSize: 13),
          ),
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
  );

  Widget _world(ChildProfile profile) {
    final reachedLimit =
        widget.appState.minutesToday(profile.id) >= profile.dailyLimitMinutes;
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
    final visible = recommendedFor(
      profile,
      widget.catalog.where((a) => a.isFullyApproved),
      count: widget.catalog.length,
    );
    final entries = <_WorldEntry>[];
    if (area == 0) {
      const toys = [
        (DynamicToyType.feeding, ForestObject.berry, '냠냠', '열매 먹이기'),
        (DynamicToyType.sorting, ForestObject.basket, '쏙쏙', '도토리 분류'),
        (DynamicToyType.peekaboo, ForestObject.bush, '까꿍', '풀숲 까꿍'),
        (DynamicToyType.xylophone, ForestObject.music, '딩동', '물방울 실로폰'),
        (DynamicToyType.puzzle, ForestObject.puzzle, '착착', '그림자 퍼즐'),
      ];
      for (final toy in toys) {
        entries.add(
          _WorldEntry(toy.$2, toy.$3, toy.$4, () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DynamicToyScreen(
                  toyType: toy.$1,
                  appState: widget.appState,
                  profile: profile,
                ),
              ),
            );
          }),
        );
      }
    } else {
      final mode = [PlayMode.touch, PlayMode.color, PlayMode.move][area - 1];
      for (final activity in visible.where((a) => a.mode == mode)) {
        final art = activityArt(activity);
        entries.add(
          _WorldEntry(art.$1, art.$2, activity.title, () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlayScreen(
                  activity: activity,
                  appState: widget.appState,
                  profile: profile,
                  isParentPreview: false,
                ),
              ),
            );
          }),
        );
      }
    }
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
      duration: profile.lowStimulation
          ? Duration.zero
          : const Duration(milliseconds: 300),
      child: LayoutBuilder(
        key: ValueKey(area),
        builder: (context, box) {
          final landscape = box.maxWidth > box.maxHeight * 1.45;
          final boardSize = landscape
              ? const Size(800, 250)
              : const Size(420, 535);
          final positions = landscape
              ? List.generate(
                  entries.length,
                  (i) => Offset(20 + i * (650 / entries.length), 55),
                )
              : switch (entries.length) {
                  1 => const [Offset(140, 250)],
                  2 => const [Offset(50, 250), Offset(235, 250)],
                  3 => const [
                    Offset(140, 165),
                    Offset(30, 340),
                    Offset(250, 340),
                  ],
                  4 => const [
                    Offset(40, 165),
                    Offset(240, 165),
                    Offset(40, 345),
                    Offset(240, 345),
                  ],
                  _ => const [
                    Offset(40, 170),
                    Offset(240, 170),
                    Offset(4, 345),
                    Offset(142, 328),
                    Offset(278, 345),
                  ],
                };
          return Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: boardSize.width,
                height: boardSize.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (!landscape)
                      Positioned(
                        left: 140,
                        top: 5,
                        width: 140,
                        height: 160,
                        child: Semantics(
                          button: true,
                          label: '모모에게 인사하기',
                          child: GestureDetector(
                            onTap: () => SoundEffects.instance.pop(),
                            child: ForestFloat(
                              still: profile.lowStimulation,
                              child: AvatarImage(
                                avatar: profile.avatar,
                                size: 145,
                                lowStimulation: profile.lowStimulation,
                              ),
                            ),
                          ),
                        ),
                      ),
                    for (var i = 0; i < entries.length; i++)
                      Positioned(
                        left: positions[i].dx,
                        top: positions[i].dy,
                        child: _ForestPortal(
                          entry: entries[i],
                          quiet: profile.lowStimulation,
                          phase: i.toDouble(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
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
                  size: 60,
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
                    if (area != i) setState(() => area = i);
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
  const _WorldEntry(this.object, this.caption, this.label, this.onTap);
  final ForestObject object;
  final String caption, label;
  final VoidCallback onTap;
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
  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.entry.label,
    button: true,
    onTap: widget.entry.onTap,
    child: ExcludeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => pressed = true),
        onTapCancel: () => setState(() => pressed = false),
        onTapUp: (_) => setState(() => pressed = false),
        onTap: widget.entry.onTap,
        child: AnimatedScale(
          scale: pressed && !widget.quiet ? .93 : 1,
          duration: const Duration(milliseconds: 140),
          child: SizedBox(
            width: 138,
            height: 164,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 34,
                  child: Container(
                    width: 122,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8DA765),
                      borderRadius: BorderRadius.all(Radius.elliptical(70, 24)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  child: Container(
                    width: 128,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFADC780),
                      borderRadius: BorderRadius.all(Radius.elliptical(70, 24)),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  child: ForestFloat(
                    still: widget.quiet,
                    offset: widget.phase,
                    child: ForestProp(widget.entry.object, size: 115),
                  ),
                ),
                Positioned(bottom: 6, child: ForestSign(widget.entry.caption)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
