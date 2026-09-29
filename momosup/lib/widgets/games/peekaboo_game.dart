import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../utils/sound_effects.dart';
import '../../widgets/avatar_image.dart';

class PeekabooGame extends StatefulWidget {
  const PeekabooGame({
    this.onComplete,
    this.lowStimulation = false,
    super.key,
  });

  final VoidCallback? onComplete;
  final bool lowStimulation;

  @override
  State<PeekabooGame> createState() => _PeekabooGameState();
}

class _PeekabooGameState extends State<PeekabooGame>
    with SingleTickerProviderStateMixin {
  final Map<int, bool> _revealed = {0: false, 1: false, 2: false};
  int _foundCount = 0;
  String _message = '살랑살랑 풀숲과 나무 뒤에 누가 숨었을까? 톡! 눌러봐!';

  late final AnimationController _swayController;

  @override
  void initState() {
    super.initState();
    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _swayController.dispose();
    super.dispose();
  }

  void _onSpotTapped(int index) {
    final wasRevealed = _revealed[index] ?? false;

    if (!wasRevealed) {
      SoundEffects.instance.whoosh();
      setState(() {
        _revealed[index] = true;
        _foundCount++;
        _message = switch (index) {
          0 => '까꿍! 덤불 뒤에서 아기 곰 모모가 나타났어! 🐻',
          1 => '호호! 나무 구멍에서 부엉이 누리가 까꿍! 🦉',
          _ => '개굴개굴! 연못에서 아기 개구리가 퐁당! 🐸',
        };
      });

      if (_foundCount >= 3) {
        SoundEffects.instance.tada();
        setState(() {
          _message = '우와아! 숲속 친구들을 모두 찾았어! 대단해! 💮';
        });
        widget.onComplete?.call();
      }
    } else {
      // Tap again to tickle the character
      SoundEffects.instance.pop();
      setState(() {
        _message = switch (index) {
          0 => '간질간질~ 모모가 까르르 웃어요! ✨',
          1 => '누리가 날개를 파닥파닥 반가워해요! 🪶',
          _ => '개구리가 신나서 폴짝폴짝 뛰어요! 💧',
        };
      });
    }
  }

  void _resetGame() {
    setState(() {
      _revealed[0] = false;
      _revealed[1] = false;
      _revealed[2] = false;
      _foundCount = 0;
      _message = '쉿! 친구들이 다시 꽁꽁 숨었어요! 어디 있을까?';
    });
    SoundEffects.instance.pop();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top: Header & Status
            _buildTopStatus(),

            // Middle: Interactive 3 Peekaboo Forest Spots
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildSpot(
                          index: 0,
                          title: '초록 풀숲',
                          emoji: '🌿',
                          characterAvatar: 'momo',
                          characterEmoji: '🐻',
                          characterName: '모모',
                          bgColor: const Color(0xFFC8E6C9),
                        ),
                        _buildSpot(
                          index: 1,
                          title: '큰 떡갈나무',
                          emoji: '🌳',
                          characterAvatar: 'nuri',
                          characterEmoji: '🦉',
                          characterName: '누리',
                          bgColor: const Color(0xFFFFE0B2),
                        ),
                        _buildSpot(
                          index: 2,
                          title: '퐁퐁 연못',
                          emoji: '🪷',
                          characterAvatar: null,
                          characterEmoji: '🐸',
                          characterName: '개구리',
                          bgColor: const Color(0xFFB3E5FC),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom: Reset & Help
            _buildBottomBar(),
          ],
        );
      },
    );
  }

  Widget _buildTopStatus() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFFD166), width: 1.5),
            ),
            child: Text(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Satiety / Discovery star count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (idx) {
              final isFound = _revealed[idx] ?? false;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  isFound ? '⭐' : '⚪',
                  style: const TextStyle(fontSize: 22),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSpot({
    required int index,
    required String title,
    required String emoji,
    required String? characterAvatar,
    required String characterEmoji,
    required String characterName,
    required Color bgColor,
  }) {
    final isOpen = _revealed[index] ?? false;

    return AnimatedBuilder(
      animation: _swayController,
      builder: (context, child) {
        final swayAngle = isOpen
            ? 0.0
            : (math.sin(_swayController.value * math.pi) * 0.06);

        return GestureDetector(
          onTap: () => _onSpotTapped(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            width: 140,
            height: 170,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isOpen ? Colors.white : Colors.green.shade700.withAlpha(120),
                width: isOpen ? 3.5 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isOpen ? 45 : 20),
                  blurRadius: isOpen ? 14 : 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E4F28),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: child,
                      ),
                      child: isOpen
                          ? Column(
                              key: const ValueKey('open'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (characterAvatar != null)
                                  AvatarImage(
                                    avatar: characterAvatar,
                                    size: 64,
                                    lowStimulation: widget.lowStimulation,
                                  )
                                else
                                  Text(
                                    characterEmoji,
                                    style: const TextStyle(fontSize: 48),
                                  ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '까꿍! $characterName',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E4F28),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Transform.rotate(
                              key: const ValueKey('closed'),
                              angle: swayAngle,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 52),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '누구게? 톡!',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF558B2F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '풀숲을 톡톡 건드려보세요 🌿',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A7258),
            ),
          ),
          if (_foundCount >= 3)
            InkWell(
              onTap: _resetGame,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF558B2F),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      '다시 숨기기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
