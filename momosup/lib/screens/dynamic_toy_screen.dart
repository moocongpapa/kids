import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../state/app_state.dart';
import '../utils/forest_audio.dart';
import '../utils/sound_effects.dart';
import '../widgets/avatar_image.dart';
import '../widgets/jelly_button.dart';
import '../widgets/touch_sparkles.dart';
import '../widgets/games/feeding_game.dart';
import '../widgets/games/sorting_game.dart';
import '../widgets/games/peekaboo_game.dart';
import '../widgets/games/xylophone_game.dart';
import '../widgets/games/silhouette_puzzle_game.dart';

enum DynamicToyType {
  feeding,
  sorting,
  peekaboo,
  xylophone,
  puzzle,
}

class DynamicToyScreen extends StatefulWidget {
  const DynamicToyScreen({
    required this.toyType,
    required this.appState,
    required this.profile,
    super.key,
  });

  final DynamicToyType toyType;
  final AppState appState;
  final ChildProfile profile;

  @override
  State<DynamicToyScreen> createState() => _DynamicToyScreenState();
}

class _DynamicToyScreenState extends State<DynamicToyScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  int _phase = 1; // 1: playing, 2: celebratory ending
  bool _recorded = false;
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    ForestAudio.instance.pauseBgm();
    _stopwatch.start();
    _sessionTimer = Timer(const Duration(minutes: 3), () {
      if (mounted && _phase != 2) _finishPlay();
    });
  }

  @override
  void dispose() {
    ForestAudio.instance.startBgm(enabled: widget.profile.musicOn);
    _sessionTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _finishPlay() {
    if (_phase == 2) return;
    _sessionTimer?.cancel();
    _stopwatch.stop();

    setState(() => _phase = 2);
    SoundEffects.instance.tada();

    if (!_recorded) {
      _recorded = true;
      widget.appState.recordPlay(
        profileId: widget.profile.id,
        activityId: 'toy_${widget.toyType.name}',
        seconds: math.max(60, _stopwatch.elapsed.inSeconds),
      );
    }
  }

  String get _title => switch (widget.toyType) {
    DynamicToyType.feeding => '🥕 냠냠 열매 먹이기',
    DynamicToyType.sorting => '🧺 도토리 쏙쏙 분류함',
    DynamicToyType.peekaboo => '🌿 살랑살랑 풀숲 까꿍',
    DynamicToyType.xylophone => '💧 숲속 물방울 실로폰',
    DynamicToyType.puzzle => '🧩 그림자 맞추기 퍼즐',
  };

  String get _avatar => switch (widget.toyType) {
    DynamicToyType.feeding => 'momo',
    DynamicToyType.sorting => 'duri',
    DynamicToyType.peekaboo => 'nuri',
    DynamicToyType.xylophone => 'momo',
    DynamicToyType.puzzle => 'duri',
  };

  String get _outroText => switch (widget.toyType) {
    DynamicToyType.feeding => '모모의 배가 든든하고 행복해졌어! 고마워 친구야!',
    DynamicToyType.sorting => '바구니에 도토리가 가득 찼어! 두리가 정말 기뻐해!',
    DynamicToyType.peekaboo => '숲속 친구들을 모두 찾았어! 까꿍 놀이 정말 신났지?',
    DynamicToyType.xylophone => '맑고 고운 숲속 멜로디가 울려 퍼졌어! 참 아름다웠어!',
    DynamicToyType.puzzle => '퍼즐 조각들이 제자리를 쏙 찾았어! 정말 대단해!',
  };

  String get _offscreenPrompt => switch (widget.toyType) {
    DynamicToyType.feeding => '이제 우리도 시원하고 달콤한 물 한 잔 마시러 가볼까?',
    DynamicToyType.sorting => '방에 있는 내 장난감이나 신발도 바구니처럼 제자리에 놓아볼까?',
    DynamicToyType.peekaboo => '가족에게 살금살금 다가가서 "까꿍!" 하고 안아줄까?',
    DynamicToyType.xylophone => '손뼉을 짝짝 치며 오늘 들은 예쁜 소리를 가족에게 들려줄까?',
    DynamicToyType.puzzle => '두 팔을 하늘 높이 쭉 뻗고 하품하며 기지개를 켜볼까?',
  };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase == 2,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _phase != 2) _finishPlay();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title),
          actions: [
            if (_phase == 1)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: _finishPlay,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: const Text('마치기', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: TouchSparkles(
            lowStimulation: widget.profile.lowStimulation,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: _phase == 1 ? _buildGamePlay() : _buildEnding(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGamePlay() {
    return Column(
      children: [
        Expanded(
          child: switch (widget.toyType) {
            DynamicToyType.feeding => FeedingGame(
              lowStimulation: widget.profile.lowStimulation,
              onComplete: () {},
            ),
            DynamicToyType.sorting => SortingGame(
              lowStimulation: widget.profile.lowStimulation,
              onComplete: () {},
            ),
            DynamicToyType.peekaboo => PeekabooGame(
              lowStimulation: widget.profile.lowStimulation,
              onComplete: () {},
            ),
            DynamicToyType.xylophone => XylophoneGame(
              lowStimulation: widget.profile.lowStimulation,
              onComplete: () {},
            ),
            DynamicToyType.puzzle => SilhouettePuzzleGame(
              lowStimulation: widget.profile.lowStimulation,
              onComplete: () {},
            ),
          },
        ),
        const SizedBox(height: 8),
        JellyButton(
          onPressed: _finishPlay,
          semanticsLabel: '놀이 마치기',
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stop_circle_outlined, size: 20, color: Color(0xFF2E4F28)),
              SizedBox(width: 8),
              Text(
                '놀이 마치기 (도장 쾅!)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E4F28),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnding(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D6),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFFD166), width: 2),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('💮', style: TextStyle(fontSize: 24)),
                SizedBox(width: 8),
                Text(
                  '숲 탐험 도장 쾅! 참 잘했어요',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF8A5A00),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AvatarImage(avatar: _avatar, size: 160),
          const SizedBox(height: 16),
          Text(
            _outroText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: const Color(0xFFE9F2E2),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFCCE2C3), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.nature_people_outlined,
                    size: 38,
                    color: Color(0xFF386641),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '이제 화면 밖에서',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Color(0xFF1E3F27),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _offscreenPrompt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            icon: const Icon(Icons.home_outlined),
            label: const Text(
              '숲으로 돌아가기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '다음 놀이는 자동으로 시작하지 않아요.',
            style: TextStyle(color: Color(0xFF6B756B)),
          ),
        ],
      ),
    );
  }
}
