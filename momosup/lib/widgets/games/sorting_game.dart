import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../utils/sound_effects.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/hand_guide_hint.dart';

class SortingGame extends StatefulWidget {
  const SortingGame({
    this.onComplete,
    this.lowStimulation = false,
    super.key,
  });

  final VoidCallback? onComplete;
  final bool lowStimulation;

  @override
  State<SortingGame> createState() => _SortingGameState();
}

class _SortingGameState extends State<SortingGame>
    with TickerProviderStateMixin {
  final List<_AcornItem> _items = [
    _AcornItem(id: 'big_1', isBig: true, emoji: '🌰', size: 68),
    _AcornItem(id: 'small_1', isBig: false, emoji: '🌰', size: 42),
    _AcornItem(id: 'big_2', isBig: true, emoji: '🌰', size: 68),
    _AcornItem(id: 'small_2', isBig: false, emoji: '🌰', size: 42),
    _AcornItem(id: 'big_3', isBig: true, emoji: '🌰', size: 68),
    _AcornItem(id: 'small_3', isBig: false, emoji: '🌰', size: 42),
  ];

  final Set<String> _sortedIds = {};
  int _bigBasketCount = 0;
  int _smallBasketCount = 0;
  bool _showHint = true;
  String _guideText = '다람쥐 두리가 도토리를 모아요! 큰 것과 작은 것을 나눠 담아볼까?';

  late final AnimationController _bigBasketAnim;
  late final AnimationController _smallBasketAnim;

  @override
  void initState() {
    super.initState();
    _bigBasketAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _smallBasketAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _bigBasketAnim.dispose();
    _smallBasketAnim.dispose();
    super.dispose();
  }

  void _onItemDropped(_AcornItem item, bool targetIsBig) {
    setState(() => _showHint = false);

    if (item.isBig == targetIsBig) {
      // Correct Match!
      setState(() {
        _sortedIds.add(item.id);
        if (targetIsBig) {
          _bigBasketCount++;
          _guideText = '쏙! 커다란 도토리가 큰 바구니에 퐁당!';
          _bigBasketAnim.forward(from: 0.0);
        } else {
          _smallBasketCount++;
          _guideText = '쏙! 앙증맞은 작은 도토리가 작은 바구니에 퐁당!';
          _smallBasketAnim.forward(from: 0.0);
        }
      });

      SoundEffects.instance.pop();

      if (_sortedIds.length >= _items.length) {
        SoundEffects.instance.tada();
        setState(() {
          _guideText = '와아! 두리의 바구니가 가득 찼어! 정말 대단해! 💮';
        });
        widget.onComplete?.call();
      }
    } else {
      // Mismatch - gentle bounce back
      SoundEffects.instance.boing();
      setState(() {
        _guideText = targetIsBig
            ? '어라라? 요 도토리는 작은 바구니가 더 좋아할 것 같아~'
            : '어라라? 요 도토리는 큼직해서 큰 바구니에 딱 맞을 것 같아~';
      });
    }
  }

  void _resetGame() {
    setState(() {
      _sortedIds.clear();
      _bigBasketCount = 0;
      _smallBasketCount = 0;
      _guideText = '다시 신나게 나눠볼까? 큰 도토리, 작은 도토리!';
    });
    SoundEffects.instance.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top: Squirrel Duri Speech Bubble
            _buildTopHeader(),

            // Middle: Two Sorting Baskets (Big vs Small)
            _buildBasketsRow(),

            // Bottom: Fallen Acorns Log
            _buildAcornsTray(),
          ],
        ),

        // Initial visual hand hint pointing an acorn to the big basket
        if (_showHint && _sortedIds.isEmpty)
          const Positioned(
            bottom: 70,
            child: HandGuideHint(
              start: Offset(-80, 0),
              end: Offset(-110, -170),
            ),
          ),
      ],
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AvatarImage(
                avatar: 'duri',
                size: 64,
                lowStimulation: widget.lowStimulation,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD166), width: 1.5),
                  ),
                  child: Text(
                    _guideText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B481B),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_items.length, (idx) {
              final done = idx < _sortedIds.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? const Color(0xFF558B2F) : Colors.grey.shade300,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBasketsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Big Basket
          _buildBasketTarget(
            isBig: true,
            title: '큰 바구니',
            count: _bigBasketCount,
            anim: _bigBasketAnim,
            color: const Color(0xFFE8B074),
          ),

          // Small Basket
          _buildBasketTarget(
            isBig: false,
            title: '작은 바구니',
            count: _smallBasketCount,
            anim: _smallBasketAnim,
            color: const Color(0xFFD4A373),
          ),
        ],
      ),
    );
  }

  Widget _buildBasketTarget({
    required bool isBig,
    required String title,
    required int count,
    required AnimationController anim,
    required Color color,
  }) {
    return DragTarget<_AcornItem>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        _onItemDropped(details.data, isBig);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedBuilder(
          animation: anim,
          builder: (context, child) {
            final val = anim.value;
            final bounceScale = 1.0 + 0.18 * math.sin(val * math.pi);

            return Transform.scale(
              scale: (isHovering ? 1.08 : 1.0) * bounceScale,
              child: Container(
                width: isBig ? 142 : 124,
                height: isBig ? 152 : 136,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(isHovering ? 255 : 220),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: isHovering ? Colors.white : const Color(0xFF8B5A2B),
                    width: isHovering ? 3.5 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withAlpha(isHovering ? 90 : 40),
                      blurRadius: isHovering ? 16 : 8,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isBig ? '🧺 큰 바구니' : '🧺 아기 바구니',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '🌰',
                      style: TextStyle(fontSize: isBig ? 42 : 28),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count / 3개',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAcornsTray() {
    final remaining = _items.where((i) => !_sortedIds.contains(i.id)).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F2E2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC3D8BC), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                  '숲속 통나무 (도토리를 끌어 바구니에 쏙!)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E4F28),
                  ),
                ),
              ),
              if (_sortedIds.length >= _items.length)
                InkWell(
                  onTap: _resetGame,
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
                          '다시 하기',
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
          SizedBox(
            height: 80,
            child: remaining.isEmpty
                ? const Center(
                    child: Text(
                      '모든 도토리를 다 정리했어요! 최고야! ✨',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E4F28),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: remaining.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Draggable<_AcornItem>(
                            data: item,
                            onDragStarted: () {
                              setState(() => _showHint = false);
                              SoundEffects.instance.pop();
                            },
                            feedback: Material(
                              color: Colors.transparent,
                              child: Transform.scale(
                                scale: 1.25,
                                child: Text(
                                  item.emoji,
                                  style: TextStyle(fontSize: item.size),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.25,
                              child: Text(
                                item.emoji,
                                style: TextStyle(fontSize: item.size),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withAlpha(160),
                              ),
                              child: Text(
                                item.emoji,
                                style: TextStyle(fontSize: item.size),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AcornItem {
  const _AcornItem({
    required this.id,
    required this.isBig,
    required this.emoji,
    required this.size,
  });

  final String id;
  final bool isBig;
  final String emoji;
  final double size;
}
