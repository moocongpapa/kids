import 'package:flutter/material.dart';

import '../../utils/sound_effects.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/hand_guide_hint.dart';

class SilhouettePuzzleGame extends StatefulWidget {
  const SilhouettePuzzleGame({
    this.onComplete,
    this.lowStimulation = false,
    super.key,
  });

  final VoidCallback? onComplete;
  final bool lowStimulation;

  @override
  State<SilhouettePuzzleGame> createState() => _SilhouettePuzzleGameState();
}

class _SilhouettePuzzleGameState extends State<SilhouettePuzzleGame> {
  final List<_PuzzlePiece> _pieces = [
    _PuzzlePiece(id: 'momo', name: '모모', avatar: 'momo', emoji: '🐻', label: '아기 곰'),
    _PuzzlePiece(id: 'duri', name: '두리', avatar: 'duri', emoji: '🐿️', label: '다람쥐'),
    _PuzzlePiece(id: 'nuri', name: '누리', avatar: 'nuri', emoji: '🦉', label: '부엉이'),
  ];

  final Set<String> _matchedIds = {};
  bool _showHint = true;
  String _message = '숲속 나무 판에 깜장 그림자가 있어요! 알맞은 친구를 착! 맞춰볼까?';

  void _onPieceDropped(_PuzzlePiece piece, String targetId) {
    setState(() => _showHint = false);

    if (piece.id == targetId) {
      // Snapped into place!
      SoundEffects.instance.snap();

      setState(() {
        _matchedIds.add(piece.id);
        _message = '착! ${piece.name}가 쏙 들어맞았어요! 반가워! ✨';
      });

      if (_matchedIds.length >= _pieces.length) {
        SoundEffects.instance.tada();
        setState(() {
          _message = '우와아! 퍼즐을 모두 완성했어요! 모모숲 친구들이 활짝 웃어요! 💮';
        });
        widget.onComplete?.call();
      }
    } else {
      // Wrong slot - bounce back
      SoundEffects.instance.boing();
      setState(() {
        _message = '어라라? 요 자리는 다른 친구 자리인가 봐요~';
      });
    }
  }

  void _resetPuzzle() {
    setState(() {
      _matchedIds.clear();
      _message = '다시 한 번 맞춰볼까? 누구 그림자일까?';
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
            // Top: Header & Guide Message
            _buildTopStatus(),

            // Middle: Wooden Puzzle Board with Silhouettes
            _buildPuzzleBoard(),

            // Bottom: Puzzle Piece Tray
            _buildPieceTray(),
          ],
        ),

        // Initial hand guide hint pointing piece to first silhouette
        if (_showHint && _matchedIds.isEmpty)
          const Positioned(
            bottom: 70,
            child: HandGuideHint(
              start: Offset(-90, 0),
              end: Offset(-110, -170),
            ),
          ),
      ],
    );
  }

  Widget _buildTopStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pieces.length, (idx) {
              final done = idx < _matchedIds.length;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  done ? '🧩' : '⚪',
                  style: const TextStyle(fontSize: 20),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleBoard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8D7B8),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFBCA177), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _pieces.map((piece) {
          final isMatched = _matchedIds.contains(piece.id);

          return DragTarget<_PuzzlePiece>(
            onWillAcceptWithDetails: (details) => true,
            onAcceptWithDetails: (details) {
              _onPieceDropped(details.data, piece.id);
            },
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 96,
                height: 125,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMatched
                      ? Colors.white
                      : (isHovering
                          ? const Color(0xFFFFF3CD)
                          : const Color(0xFF7A6855).withAlpha(80)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isMatched
                        ? const Color(0xFF558B2F)
                        : (isHovering ? Colors.amber : const Color(0xFF5A4A3A)),
                    width: isMatched ? 3 : (isHovering ? 3 : 1.5),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isMatched) ...[
                      AvatarImage(
                        avatar: piece.avatar,
                        size: 64,
                        lowStimulation: widget.lowStimulation,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        piece.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ] else ...[
                      // Silhouette dark cutout representation
                      Opacity(
                        opacity: 0.35,
                        child: Text(
                          piece.emoji,
                          style: const TextStyle(fontSize: 44),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${piece.label} 자리',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4E342E),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPieceTray() {
    final remainingPieces =
        _pieces.where((p) => !_matchedIds.contains(p.id)).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0D8C3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withAlpha(20),
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
                  '🧩 나무 조각함 (손으로 끌어 맞춰봐요!)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ),
              if (_matchedIds.length >= _pieces.length)
                InkWell(
                  onTap: _resetPuzzle,
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
                          '다시 맞추기',
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
            height: 90,
            child: remainingPieces.isEmpty
                ? const Center(
                    child: Text(
                      '모든 퍼즐이 착! 들어맞았어요! 대단해! ✨',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: remainingPieces.map((piece) {
                      return Draggable<_PuzzlePiece>(
                        data: piece,
                        onDragStarted: () {
                          setState(() => _showHint = false);
                          SoundEffects.instance.pop();
                        },
                        feedback: Material(
                          color: Colors.transparent,
                          child: Transform.scale(
                            scale: 1.25,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
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
                                child: AvatarImage(
                                  avatar: piece.avatar,
                                  size: 64,
                                  lowStimulation: widget.lowStimulation,
                                ),
                              ),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.25,
                          child: AvatarImage(
                            avatar: piece.avatar,
                            size: 64,
                            lowStimulation: widget.lowStimulation,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFD7CCC8), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.brown.withAlpha(30),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AvatarImage(
                                avatar: piece.avatar,
                                size: 54,
                                lowStimulation: widget.lowStimulation,
                              ),
                              Text(
                                piece.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4E342E),
                                ),
                              ),
                            ],
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

class _PuzzlePiece {
  const _PuzzlePiece({
    required this.id,
    required this.name,
    required this.avatar,
    required this.emoji,
    required this.label,
  });

  final String id;
  final String name;
  final String avatar;
  final String emoji;
  final String label;
}
