import '../forest_landscape.dart';
import 'toy_habitat.dart';
import '../woodland_art.dart';

import 'package:flutter/material.dart';

import '../../utils/sound_effects.dart';
import '../avatar_image.dart';
import '../forest_game_ui.dart';
import '../game_particles.dart';
import '../cute_game_effects.dart';

enum GameMode { freePlay, follow }

class _FloatingNote {
  final int id;
  final int barIndex;
  final double startX;
  final double startY;

  _FloatingNote(this.id, this.barIndex, this.startX, this.startY);
}

class XylophoneGame extends StatefulWidget {
  const XylophoneGame({
    this.onComplete,
    this.onModeChanged,
    this.onNote,
    this.lowStimulation = false,
    this.stage = 1,
    super.key,
  });
  final VoidCallback? onComplete;
  final ValueChanged<bool>? onModeChanged;
  final VoidCallback? onNote;
  final bool lowStimulation;
  final int stage;

  @override
  State<XylophoneGame> createState() => _XylophoneGameState();
}

class _XylophoneGameState extends State<XylophoneGame>
    with TickerProviderStateMixin {
  final _playedNotes = <int>{};
  GameMode _currentMode = GameMode.freePlay;
  bool _unlockedFollowMode = false;

  int _melodyIndex = 0;
  List<int> get _melodySequence {
    final melodies = widget.stage == 0
        ? [
            [0, 1],
            [0, 2],
            [2, 1, 0],
          ]
        : widget.stage == 2
        ? [
            [0, 2, 4, 4, 2, 0],
            [4, 4, 5, 4, 2, 0],
            [0, 2, 4, 5, 4, 2, 0],
          ]
        : [
            [0, 1, 2, 0],
            [2, 2, 1, 0],
            [0, 2, 4, 2],
          ];
    return melodies[_melodyIndex % melodies.length];
  }

  int _melodyProgress = 0;

  int? _activeBar;
  final _pointerBars = <int, int>{};

  late final AnimationController _dancerController;
  late final List<AnimationController> _rippleControllers;
  late final List<AnimationController> _squeezeControllers;

  final _barKeys = List.generate(8, (_) => GlobalKey());
  final _stackKey = GlobalKey();
  final _particlesKey = GlobalKey<GameParticlesState>();

  final List<_FloatingNote> _floaters = [];
  int _floaterIdCounter = 0;

  static const _notes = ['도', '레', '미', '파', '솔', '라', '시', '도'];
  static const _noteLabels = ['도', '레', '미', '파', '솔', '라', '시', '높은 도'];
  static const _fairyIcons = ['🍓', '🍊', '🍋', '🌱', '💧', '🐦', '🍇', '💖'];
  static const _colors = [
    Color(0xFFD98C76),
    Color(0xFFE6A766),
    Color(0xFFD7BF60),
    Color(0xFF91B56D),
    Color(0xFF73AAA2),
    Color(0xFF75A2B7),
    Color(0xFF9B98BA),
    Color(0xFFC197AF),
  ];
  static const _barHeights = [
    180.0,
    168.0,
    156.0,
    144.0,
    132.0,
    120.0,
    108.0,
    96.0,
  ];

  @override
  void initState() {
    super.initState();
    _dancerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _rippleControllers = List.generate(
      8,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _squeezeControllers = List.generate(
      8,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100),
      ),
    );
  }

  @override
  void dispose() {
    _dancerController.dispose();
    for (final c in _rippleControllers) {
      c.dispose();
    }
    for (final c in _squeezeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _handlePointer(PointerEvent event) {
    if (event is! PointerMoveEvent ||
        !_pointerBars.containsKey(event.pointer)) {
      return;
    }
    var barIndex = -1;
    for (var i = 0; i < _barKeys.length; i++) {
      final box = _barKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box != null &&
          (Offset.zero & box.size).contains(
            box.globalToLocal(event.position),
          )) {
        barIndex = i;
        break;
      }
    }
    if (barIndex < 0) {
      _pointerBars[event.pointer] = -1;
      return;
    }
    if (barIndex != _pointerBars[event.pointer]) {
      _pointerBars[event.pointer] = barIndex;
      _playNote(barIndex);
    }
  }

  void _handlePointerUp(PointerEvent event) {
    _pointerBars.remove(event.pointer);
    if (_pointerBars.isEmpty) setState(() => _activeBar = null);
  }

  Offset _getBarTopPos(int index) {
    final barBox =
        _barKeys[index].currentContext?.findRenderObject() as RenderBox?;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (barBox == null || stackBox == null) return Offset.zero;
    return stackBox.globalToLocal(
      barBox.localToGlobal(Offset(barBox.size.width / 2, 0)),
    );
  }

  void _playNote(int index) {
    if (!mounted) return;

    setState(() {
      _activeBar = index;
      _playedNotes.add(index);
    });

    GameFeedback.light(lowStimulation: widget.lowStimulation);
    widget.onNote?.call();
    SoundEffects.instance.playNote(index);

    if (!widget.lowStimulation) {
      _squeezeControllers[index].forward(from: 0).then((_) {
        if (mounted) _squeezeControllers[index].reverse();
      });
      _rippleControllers[index].forward(from: 0);
      _dancerController.forward(from: 0).then((_) {
        if (mounted) _dancerController.reverse();
      });

      final origin = _getBarTopPos(index);
      _spawnFloater(index, origin.dx - 16, origin.dy);

      _particlesKey.currentState?.burst(
        origin: origin,
        count: 4,
        style: ParticleStyle.drops,
        spread: 60,
      );
    }

    if (_currentMode == GameMode.freePlay) {
      if (_playedNotes.length >=
              (widget.stage == 0
                  ? 2
                  : widget.stage == 1
                  ? 4
                  : 8) &&
          !_unlockedFollowMode) {
        setState(() => _unlockedFollowMode = true);
        GameFeedback.celebration(lowStimulation: widget.lowStimulation);
        if (!widget.lowStimulation) {
          final stackBox =
              _stackKey.currentContext?.findRenderObject() as RenderBox?;
          if (stackBox != null) {
            final center = Offset(
              stackBox.size.width / 2,
              stackBox.size.height / 2,
            );
            _particlesKey.currentState?.celebrate(center);
          }
        }
      }
    } else if (_currentMode == GameMode.follow) {
      if (_melodyProgress < _melodySequence.length &&
          index == _melodySequence[_melodyProgress]) {
        GameFeedback.success(lowStimulation: widget.lowStimulation);
        setState(() {
          _melodyProgress++;
        });
        if (_melodyProgress >= _melodySequence.length) {
          _completeMelody();
        }
      }
    }
  }

  bool _melodyCompleted = false;

  void _completeMelody() {
    if (_melodyCompleted) return;
    _melodyCompleted = true;
    GameFeedback.celebration(lowStimulation: widget.lowStimulation);
    widget.onComplete?.call();
    if (!widget.lowStimulation) {
      final stackBox =
          _stackKey.currentContext?.findRenderObject() as RenderBox?;
      if (stackBox != null) {
        final center = Offset(
          stackBox.size.width / 2,
          stackBox.size.height / 2,
        );
        _particlesKey.currentState?.celebrate(center);
      }
    }
  }

  void _spawnFloater(int index, double startX, double startY) {
    final note = _FloatingNote(_floaterIdCounter++, index, startX, startY);
    setState(() => _floaters.add(note));
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _floaters.remove(note));
      }
    });
  }

  Widget _buildBar(int index, {double? width, double? height}) {
    final bool isFollowMode = _currentMode == GameMode.follow;
    final bool isNextInMelody =
        isFollowMode &&
        _melodyProgress < _melodySequence.length &&
        _melodySequence[_melodyProgress] == index;
    final bool isActive = _activeBar == index;
    final barHeight = height ?? _barHeights[index];

    final bar = AnimatedBuilder(
      animation: Listenable.merge([
        _squeezeControllers[index],
        _rippleControllers[index],
      ]),
      builder: (context, child) {
        final squeeze = _squeezeControllers[index].value;
        final ripple = _rippleControllers[index].value;

        Color baseColor = _colors[index];
        if (isActive) baseColor = Color.lerp(baseColor, Colors.white, 0.2)!;
        final barColor = Color.lerp(baseColor, Colors.white, squeeze * 0.4);

        return Transform.scale(
          scaleY: 1.0 - (squeeze * 0.08),
          alignment: Alignment.bottomCenter,
          child: Container(
            width: width,
            height: barHeight,
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(barColor, const Color(0xFFFFF1CE), .28)!,
                  barColor!,
                  Color.lerp(barColor, const Color(0xFF714C34), .20)!,
                ],
                stops: const [0, .45, 1],
              ),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(
                color: isNextInMelody ? Colors.white : const Color(0xFFD09C72),
                width: isNextInMelody ? 3 : 2,
              ),
              boxShadow: isNextInMelody
                  ? [
                      BoxShadow(
                        color: Colors.white.withAlpha(150),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : [
                      const BoxShadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: WoodlandGrainPainter()),
                  ),
                ),
                Positioned(
                  top: 8,
                  child: forestIsWide(context)
                      ? ForestProp(
                          const [
                            ForestObject.berry,
                            ForestObject.sun,
                            ForestObject.flower,
                            ForestObject.leaf,
                            ForestObject.cloud,
                            ForestObject.paw,
                            ForestObject.acorn,
                            ForestObject.heart,
                          ][index],
                          size: barHeight > 100 ? 22 : 18,
                        )
                      : Text(
                          _fairyIcons[index],
                          style: TextStyle(fontSize: barHeight > 100 ? 16 : 13),
                        ),
                ),
                if (barHeight > 100)
                  Positioned(
                    top: 30,
                    child: CuteFace(
                      mood: isActive ? FaceMood.singing : FaceMood.happy,
                      size: 14,
                      animateBlink: !widget.lowStimulation,
                    ),
                  ),
                Positioned(
                  bottom: 12,
                  child: Text(
                    index == 7 ? '도' : _notes[index],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (ripple > 0 && ripple < 1)
                  Positioned(
                    top: barHeight / 2 - 30,
                    child: Opacity(
                      opacity: 1.0 - ripple,
                      child: Container(
                        width: ripple * 60,
                        height: ripple * 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
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

    final interactiveBar = Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        _pointerBars[event.pointer] = index;
        _playNote(index);
      },
      // Pointer up is handled by the shared listener so sliding across keys
      // keeps the last played key visible after the tap recognizer cancels.

      child: IdleNudge(
        active: isNextInMelody,
        enabled: !widget.lowStimulation,
        child: bar,
      ),
    );

    final semanticBar = Semantics(
      key: _barKeys[index],
      label: '${_noteLabels[index]} 음 연주',
      button: true,
      onTap: () => _playNote(index),
      child: width != null
          ? SizedBox(width: width, height: barHeight, child: interactiveBar)
          : interactiveBar,
    );

    return width != null ? semanticBar : Expanded(child: semanticBar);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: _handlePointer,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerUp,
      child: Stack(
        key: _stackKey,
        children: [
          if (!widget.lowStimulation)
            CuteBubblesLayer(particlesKey: _particlesKey),
          ForestToyComposition(
            children: [
              if (!widget.lowStimulation) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _currentMode == GameMode.freePlay
                              ? ToyDiscoverySprig(
                                  count: _playedNotes.length,
                                  total: 8,
                                )
                              : ToyDiscoverySprig(
                                  count: _melodyProgress,
                                  total: _melodySequence.length,
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedBuilder(
                        animation: _dancerController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _dancerController.value * 0.05,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const AvatarImage(
                                  avatar: 'momo',
                                  size: 60,
                                  interactive: true,
                                ),
                                CharacterBlushOverlay(
                                  size: 60,
                                  isBlushing: _activeBar != null,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 500;
                  if (isNarrow) {
                    final barW = ((constraints.maxWidth - 36) / 4).clamp(
                      forestIsWide(context) ? 64.0 : 60.0,
                      84.0,
                    );
                    return Center(
                      child: ToyHabitat(
                        kind: ToyHabitatKind.music,
                        discoveries: _playedNotes.length,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                4,
                                (i) => _buildBar(i, width: barW, height: 110.0),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                4,
                                (i) => _buildBar(
                                  i + 4,
                                  width: barW,
                                  height: 110.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ToyHabitat(
                    kind: ToyHabitatKind.music,
                    discoveries: _playedNotes.length,
                    child: SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Positioned(
                            bottom: 10,
                            left: 16,
                            right: 16,
                            height: 12,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5A2B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              height: 180,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(8, (i) => _buildBar(i)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (_currentMode == GameMode.follow)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  children: [
                    for (var i = 0; i < _melodySequence.length; i++)
                      ToySelectionGlow(
                        selected: i == _melodyProgress,
                        child: Opacity(
                          opacity: i < _melodyProgress ? .4 : 1,
                          child: ForestProp(
                            const [
                              ForestObject.berry,
                              ForestObject.sun,
                              ForestObject.flower,
                              ForestObject.leaf,
                              ForestObject.cloud,
                              ForestObject.paw,
                              ForestObject.acorn,
                              ForestObject.heart,
                            ][_melodySequence[i]],
                            size: 28,
                          ),
                        ),
                      ),
                  ],
                ),
              if (_currentMode == GameMode.follow &&
                  _melodyProgress == _melodySequence.length)
                ForestAction(
                  label: '다른 노래 불러보기',
                  icon: Icons.replay_rounded,
                  size: 64,
                  leaf: true,
                  quiet: widget.lowStimulation,
                  onPressed: () => setState(() {
                    _melodyIndex++;
                    _melodyProgress = 0;
                    _melodyCompleted = false;
                  }),
                ),
              const SizedBox(height: 24),
              if (_unlockedFollowMode)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildModeButton(
                      GameMode.freePlay,
                      '자유 연주',
                      Icons.music_note_rounded,
                    ),
                    const SizedBox(width: 16),
                    _buildModeButton(
                      GameMode.follow,
                      '따라하기',
                      Icons.library_music_rounded,
                    ),
                  ],
                )
              else
                const SizedBox(height: 98),
              const SizedBox(height: 16),
            ],
          ),

          ..._floaters.map(
            (f) => TweenAnimationBuilder<double>(
              key: ValueKey(f.id),
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, val, child) {
                return Positioned(
                  left: f.startX,
                  top: f.startY - (val * 80),
                  child: Opacity(
                    opacity: 1.0 - val,
                    child: Text(
                      '♪',
                      style: TextStyle(
                        fontSize: 32,
                        color: _colors[f.barIndex],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (!widget.lowStimulation) GameParticles(key: _particlesKey),
        ],
      ),
    );
  }

  Widget _buildModeButton(GameMode mode, String text, IconData icon) {
    final isSelected = _currentMode == mode;
    final shouldNudge =
        mode == GameMode.follow &&
        _unlockedFollowMode &&
        _currentMode == GameMode.freePlay &&
        !widget.lowStimulation;
    return IdleNudge(
      active: shouldNudge,
      child: ForestAction(
        label: text,
        onPressed: () {
          if (_currentMode != mode) {
            setState(() {
              _currentMode = mode;
              _melodyProgress = 0;
              _melodyCompleted = false;
            });
            widget.onModeChanged?.call(mode == GameMode.follow);
          }
        },
        leaf: true,
        selected: isSelected,
        size: 72,
        quiet: widget.lowStimulation,
        child: Icon(icon, color: forestCream, size: 36),
      ),
    );
  }
}
