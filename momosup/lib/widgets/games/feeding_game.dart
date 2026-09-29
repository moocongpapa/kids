import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../utils/sound_effects.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/hand_guide_hint.dart';

class FeedingGame extends StatefulWidget {
  const FeedingGame({
    this.onComplete,
    this.lowStimulation = false,
    super.key,
  });

  final VoidCallback? onComplete;
  final bool lowStimulation;

  @override
  State<FeedingGame> createState() => _FeedingGameState();
}

class _FeedingGameState extends State<FeedingGame>
    with TickerProviderStateMixin {
  final List<_FoodItem> _foods = [
    _FoodItem(id: 'strawberry', emoji: '🍓', name: '딸기', color: Color(0xFFFF6B6B)),
    _FoodItem(id: 'banana', emoji: '🍌', name: '바나나', color: Color(0xFFFFD93D)),
    _FoodItem(id: 'apple', emoji: '🍎', name: '사과', color: Color(0xFFFF4757)),
    _FoodItem(id: 'acorn', emoji: '🌰', name: '도토리', color: Color(0xFFC47B27)),
    _FoodItem(id: 'blueberry', emoji: '🫐', name: '블루베리', color: Color(0xFF5352ED)),
  ];

  final Set<String> _eaten = {};
  int _fedCount = 0;
  bool _isHovering = false;
  bool _isChewing = false;
  bool _showHint = true;
  String _momoStatus = '배가 꼬르륵~ 모모에게 맛있는 열매를 먹여줄까?';

  late final AnimationController _chewController;
  late final AnimationController _floatHeartController;

  @override
  void initState() {
    super.initState();
    _chewController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _floatHeartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _chewController.dispose();
    _floatHeartController.dispose();
    super.dispose();
  }

  void _onFoodDropped(_FoodItem food) async {
    setState(() {
      _showHint = false;
      _eaten.add(food.id);
      _fedCount++;
      _isHovering = false;
      _isChewing = true;
      _momoStatus = '오물오물 냠냠! ${food.name} 정말 꿀맛이야!';
    });

    SoundEffects.instance.pop();
    await Future.delayed(const Duration(milliseconds: 80));
    SoundEffects.instance.chew();

    _floatHeartController.forward(from: 0.0);
    _chewController.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 1100));

    if (!mounted) return;
    _chewController.stop();
    _chewController.reset();

    setState(() {
      _isChewing = false;
      if (_fedCount >= 4) {
        _momoStatus = '우와아! 배가 든든하고 행복해! 고마워 친구야! 💮';
        SoundEffects.instance.tada();
        widget.onComplete?.call();
      } else {
        _momoStatus = '다음엔 어떤 열매를 먹어볼까? 아~';
      }
    });
  }

  void _resetFoods() {
    setState(() {
      _eaten.clear();
      _fedCount = 0;
      _momoStatus = '또 먹고 싶어! 모모에게 열매를 줄까?';
    });
    SoundEffects.instance.pop();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight > 0
            ? constraints.maxHeight
            : 520.0;

        return Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top: Status Speech Bubble & Satiety gauge
                _buildTopStatus(),

                // Middle: Interactive Momo Character with DragTarget Mouth
                _buildMomoArea(),

                // Bottom: Food Plate with Draggable Fruits
                _buildFoodPlate(),
              ],
            ),

            // Floating hearts animation when eating
            if (_isChewing)
              Positioned(
                top: availableHeight * 0.22,
                child: AnimatedBuilder(
                  animation: _floatHeartController,
                  builder: (context, child) {
                    final dy = -70 * _floatHeartController.value;
                    final op = (1.0 - _floatHeartController.value).clamp(0.0, 1.0);
                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: Opacity(
                        opacity: op,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('❤️', style: TextStyle(fontSize: 28)),
                            SizedBox(width: 8),
                            Text('✨', style: TextStyle(fontSize: 32)),
                            SizedBox(width: 8),
                            Text('💖', style: TextStyle(fontSize: 26)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Hand guide hint for toddlers
            if (_showHint && _fedCount == 0)
              Positioned(
                bottom: 80,
                child: HandGuideHint(
                  start: const Offset(-80, 0),
                  end: const Offset(0, -180),
                  visible: _showHint,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTopStatus() {
    return Column(
      children: [
        // Satiety progress stars
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final isFilled = index < _fedCount;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 300),
                scale: isFilled ? 1.25 : 1.0,
                child: Text(
                  isFilled ? '🍓' : '⚪',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9E6),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFFD166), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            _momoStatus,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5A4010),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMomoArea() {
    return DragTarget<_FoodItem>(
      onWillAcceptWithDetails: (details) {
        setState(() {
          _isHovering = true;
          _showHint = false;
        });
        SoundEffects.instance.whoosh();
        return true;
      },
      onLeave: (_) {
        setState(() => _isHovering = false);
      },
      onAcceptWithDetails: (details) {
        _onFoodDropped(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedBuilder(
          animation: _chewController,
          builder: (context, child) {
            double scaleX = 1.0;
            double scaleY = 1.0;

            if (_isChewing) {
              final val = _chewController.value;
              scaleX = 1.0 + 0.12 * math.sin(val * math.pi);
              scaleY = 1.0 - 0.08 * math.sin(val * math.pi);
            } else if (_isHovering) {
              scaleX = 1.08;
              scaleY = 1.08;
            }

            return Transform.scale(
              scaleX: scaleX,
              scaleY: scaleY,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cute aura when ready to eat
                  if (_isHovering)
                    Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFEAA7).withAlpha(150),
                      ),
                    ),

                  // Avatar
                  Container(
                    width: 175,
                    height: 175,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF386641).withAlpha(30),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: AvatarImage(
                        avatar: 'momo',
                        size: 175,
                        lowStimulation: widget.lowStimulation,
                      ),
                    ),
                  ),

                  // Open mouth overlay indicator when hovering
                  if (_isHovering)
                    Positioned(
                      bottom: 35,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Text(
                          '아-! 😋',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFoodPlate() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E0),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5D5A5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text(
                  '🧺 달콤 열매 바구니 (손으로 쏙 끌어봐요!)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7A5826),
                  ),
                ),
              ),
              if (_fedCount >= 4)
                InkWell(
                  onTap: _resetFoods,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF558B2F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          '더 주기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _foods.map((food) {
                final isEaten = _eaten.contains(food.id);

                if (isEaten) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Opacity(
                      opacity: 0.25,
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(food.emoji, style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Draggable<_FoodItem>(
                    data: food,
                    onDragStarted: () {
                      setState(() => _showHint = false);
                      SoundEffects.instance.pop();
                    },
                    feedback: Material(
                      color: Colors.transparent,
                      child: Transform.scale(
                        scale: 1.25,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: food.color.withAlpha(220),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(60),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(food.emoji, style: const TextStyle(fontSize: 38)),
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: food.color.withAlpha(80),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(food.emoji, style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                    ),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: food.color.withAlpha(180), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: food.color.withAlpha(60),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(food.emoji, style: const TextStyle(fontSize: 30)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodItem {
  const _FoodItem({
    required this.id,
    required this.emoji,
    required this.name,
    required this.color,
  });

  final String id;
  final String emoji;
  final String name;
  final Color color;
}
