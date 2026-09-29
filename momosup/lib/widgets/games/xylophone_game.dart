import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../utils/sound_effects.dart';

class XylophoneGame extends StatefulWidget {
  const XylophoneGame({
    this.onComplete,
    this.lowStimulation = false,
    super.key,
  });

  final VoidCallback? onComplete;
  final bool lowStimulation;

  @override
  State<XylophoneGame> createState() => _XylophoneGameState();
}

class _XylophoneGameState extends State<XylophoneGame>
    with TickerProviderStateMixin {
  final List<_WaterDropNote> _notes = [
    _WaterDropNote(index: 0, pitch: '도', color: const Color(0xFFFF5252), height: 160),
    _WaterDropNote(index: 1, pitch: '레', color: const Color(0xFFFF7A00), height: 150),
    _WaterDropNote(index: 2, pitch: '미', color: const Color(0xFFFFD600), height: 140),
    _WaterDropNote(index: 3, pitch: '파', color: const Color(0xFF00E676), height: 130),
    _WaterDropNote(index: 4, pitch: '솔', color: const Color(0xFF00B0FF), height: 120),
    _WaterDropNote(index: 5, pitch: '라', color: const Color(0xFF3D5AFE), height: 110),
    _WaterDropNote(index: 6, pitch: '높은도', color: const Color(0xFFAA00FF), height: 100),
  ];

  late final List<AnimationController> _dropControllers;
  int _tapCount = 0;
  bool _isPlayingSong = false;
  int? _activeAutoNote;
  String _message = '초록 연잎 위의 무지개 물방울을 톡톡 두드려보아요!';

  @override
  void initState() {
    super.initState();
    _dropControllers = List.generate(
      _notes.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _dropControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _playNote(int index) {
    if (index < 0 || index >= _notes.length) return;

    SoundEffects.instance.playNote(index);

    _dropControllers[index].forward(from: 0.0);

    setState(() {
      _tapCount++;
      _message = '맑은 물방울 퐁! [${_notes[index].pitch}] 🎵';
    });

    if (_tapCount == 10) {
      SoundEffects.instance.tada();
      setState(() {
        _message = '멋진 숲속 연주가 탄생했어요! 참 잘했어요! 💮';
      });
      widget.onComplete?.call();
    }
  }

  Future<void> _playStarSong() async {
    if (_isPlayingSong) return;
    setState(() {
      _isPlayingSong = true;
      _message = '🎶 숲속 반짝반짝 작은 별 연주 중...';
    });

    // Twinkle Twinkle: C C G G A A G (0, 0, 4, 4, 5, 5, 4)
    final melody = [0, 0, 4, 4, 5, 5, 4];
    for (final note in melody) {
      if (!mounted) return;
      setState(() => _activeAutoNote = note);
      _playNote(note);
      await Future.delayed(const Duration(milliseconds: 550));
    }

    if (!mounted) return;
    setState(() {
      _activeAutoNote = null;
      _isPlayingSong = false;
      _message = '우와아! 너무 예쁜 노래였어! 이제 직접 쳐볼까?';
    });
    SoundEffects.instance.tada();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top: Message Bubble & Auto-play button
        _buildTopArea(),

        // Middle: Large Water Lily Leaf with Rainbow Drops
        Expanded(
          child: Center(
            child: _buildLotusLeafXylophone(),
          ),
        ),

        // Bottom: Helpful guide
        _buildBottomGuide(),
      ],
    );
  }

  Widget _buildTopArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('💧', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isPlayingSong ? null : _playStarSong,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.music_note_rounded, color: Color(0xFF2E7D32)),
            label: Text(
              _isPlayingSong ? '연주 중...' : '🎵 반짝반짝 멜로디 듣기',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLotusLeafXylophone() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF81C784),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0xFF4CAF50), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade900.withAlpha(50),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _notes.map((note) {
            final isAuto = _activeAutoNote == note.index;
            final anim = _dropControllers[note.index];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedBuilder(
                animation: anim,
                builder: (context, child) {
                  final val = anim.value;
                  final squash = 1.0 - 0.22 * math.sin(val * math.pi);
                  final stretch = 1.0 + 0.18 * math.sin(val * math.pi);

                  return GestureDetector(
                    onTapDown: (_) => _playNote(note.index),
                    child: Transform.scale(
                      scaleX: isAuto ? 1.15 : stretch,
                      scaleY: isAuto ? 0.9 : squash,
                      child: Container(
                        width: 44,
                        height: note.height,
                        decoration: BoxDecoration(
                          color: note.color,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white,
                            width: isAuto ? 3.5 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: note.color.withAlpha(120),
                              blurRadius: isAuto ? 14 : 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                '• ◡ •',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                note.pitch,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
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
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBottomGuide() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        '물방울을 손가락으로 퐁퐁 누르면 맑은 실로폰 소리가 나요 🎶',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF388E3C),
        ),
      ),
    );
  }
}

class _WaterDropNote {
  const _WaterDropNote({
    required this.index,
    required this.pitch,
    required this.color,
    required this.height,
  });

  final int index;
  final String pitch;
  final Color color;
  final double height;
}
