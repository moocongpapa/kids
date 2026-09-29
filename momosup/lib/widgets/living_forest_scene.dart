import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../utils/sound_effects.dart';
import 'avatar_image.dart';

/// Interactive forest glade where Momo, Duri, and Nuri live, breathe,
/// and playfully respond with animations, voice bubbles, and joyful sounds.
class LivingForestScene extends StatefulWidget {
  const LivingForestScene({
    this.lowStimulation = false,
    super.key,
  });

  final bool lowStimulation;

  @override
  State<LivingForestScene> createState() => _LivingForestSceneState();
}

class _LivingForestSceneState extends State<LivingForestScene>
    with TickerProviderStateMixin {
  late final AnimationController _breatheController;
  late final AnimationController _tailController;
  late final AnimationController _butterflyController;

  Timer? _bubbleTimer;
  String? _activeBubble;
  int _activeCharIndex = -1;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _tailController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _butterflyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )..repeat();
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    _breatheController.dispose();
    _tailController.dispose();
    _butterflyController.dispose();
    super.dispose();
  }

  void _tapCharacter(int index) {
    SoundEffects.instance.pop();

    setState(() {
      _activeCharIndex = index;
      _activeBubble = switch (index) {
        0 => '짹짹! 모모숲에 온 걸 환영해! 🌿🐥',
        1 => '우와! 숲으로 신나는 모험을 가자! 🐻🌰',
        _ => '둥실둥실~ 솔솔 바람이 기분 좋아! ☁️✨',
      };
    });

    _bubbleTimer?.cancel();
    _bubbleTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted && _activeCharIndex == index) {
        setState(() {
          _activeBubble = null;
          _activeCharIndex = -1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8EE),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFCFE5CB), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF386641).withAlpha(25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Scene Title Header & Interactive Speech Bubble
          _buildSceneHeader(),

          const SizedBox(height: 12),

          // The 3 Living Characters in Forest Glade
          SizedBox(
            height: 155,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Mossy ground hills
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC7E2C2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                // Little flowers on grass
                Positioned(
                  bottom: 12,
                  left: 20,
                  child: const Text('🌸', style: TextStyle(fontSize: 16)),
                ),
                Positioned(
                  bottom: 14,
                  right: 30,
                  child: const Text('🌼', style: TextStyle(fontSize: 16)),
                ),
                Positioned(
                  bottom: 10,
                  right: 120,
                  child: const Text('🍄', style: TextStyle(fontSize: 15)),
                ),

                // Flying butterfly across the glade
                if (!widget.lowStimulation)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _butterflyController,
                        builder: (context, child) {
                          final t = _butterflyController.value;
                          final dx = 20.0 +
                              (MediaQuery.sizeOf(context).width.clamp(320.0, 680.0) - 80) *
                                  t;
                          final dy = 15.0 + 12.0 * math.sin(t * 6 * math.pi);
                          return Stack(
                            children: [
                              Positioned(
                                left: dx,
                                top: dy,
                                child: Transform.rotate(
                                  angle: math.sin(t * 8 * math.pi) * 0.2,
                                  child: const Text('🦋',
                                      style: TextStyle(fontSize: 20)),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                // Characters Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 1. Momo the Bird
                    _buildCharacter(
                      index: 0,
                      avatar: 'momo',
                      name: '모모',
                      badge: '🐥 아기새',
                      bgColor: const Color(0xFFE8F5E9),
                      tagColor: const Color(0xFF2E7D32),
                    ),

                    // 2. Duri the Bear
                    _buildCharacter(
                      index: 1,
                      avatar: 'duri',
                      name: '두리',
                      badge: '🐻 아기곰',
                      bgColor: const Color(0xFFFFE8D6),
                      tagColor: const Color(0xFF8D5B4C),
                    ),

                    // 3. Nuri the Cloud
                    _buildCharacter(
                      index: 2,
                      avatar: 'nuri',
                      name: '누리',
                      badge: '☁️ 구름이',
                      bgColor: const Color(0xFFE3F2FD),
                      tagColor: const Color(0xFF1976D2),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSceneHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('🍃', style: TextStyle(fontSize: 16)),
            SizedBox(width: 6),
            Text(
              '살아 숨쉬는 모모숲 친구들',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C5538),
              ),
            ),
            SizedBox(width: 6),
            Text('🌿', style: TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(_activeBubble ?? 'hint'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _activeBubble != null
                    ? const Color(0xFFFFB74D)
                    : const Color(0xFFD4E6D2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _activeBubble ?? '친구들을 톡! 만지면 반갑게 인사해요 ✨',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _activeBubble != null
                    ? const Color(0xFF7A4E00)
                    : const Color(0xFF5A7258),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCharacter({
    required int index,
    required String avatar,
    required String name,
    required String badge,
    required Color bgColor,
    required Color tagColor,
  }) {
    final isTapped = _activeCharIndex == index;

    return AnimatedBuilder(
      animation: _breatheController,
      builder: (context, child) {
        // Natural gentle breathing scale oscillation
        final breathe = widget.lowStimulation
            ? 1.0
            : (1.0 + 0.04 * math.sin((_breatheController.value + index * 0.3) * math.pi));

        // Tail / wing gentle tilt
        final tilt = widget.lowStimulation
            ? 0.0
            : (0.05 * math.sin((_tailController.value + index * 0.4) * math.pi));

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _tapCharacter(index),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: (isTapped ? 1.15 : 1.0) * breathe,
                child: Transform.rotate(
                  angle: tilt,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isTapped ? Colors.amber : Colors.white,
                        width: isTapped ? 3.5 : 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: tagColor.withAlpha(isTapped ? 90 : 35),
                          blurRadius: isTapped ? 14 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: AvatarImage(
                        avatar: avatar,
                        size: 78,
                        interactive: false,
                        lowStimulation: widget.lowStimulation,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tagColor.withAlpha(120), width: 1),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: tagColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
