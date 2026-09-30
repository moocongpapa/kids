import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/sound_effects.dart';
import '../avatar_image.dart';
import '../forest_game_ui.dart';
import '../hand_guide_hint.dart';
import '../game_particles.dart';
import '../cute_game_effects.dart';

class SilhouettePuzzleGame extends StatefulWidget {
  final VoidCallback? onComplete;
  final bool lowStimulation;
  final int stage;

  const SilhouettePuzzleGame({
    this.onComplete,
    this.lowStimulation = false,
    this.stage = 1,
    super.key,
  });

  @override
  State<SilhouettePuzzleGame> createState() => _SilhouettePuzzleGameState();
}

class _SilhouettePuzzleGameState extends State<SilhouettePuzzleGame>
    with TickerProviderStateMixin {
  int _currentRound = 1;
  late List<String> _currentTargets;
  late List<String> _shuffledTray;
  final Set<String> _matched = {};
  int _totalMatched = 0;
  String? _hoveredWrongTarget;
  String? _selected;

  final Map<String, GlobalKey<_PuzzleTargetState>> _targetKeys = {};
  final Map<String, GlobalKey> _pieceKeys = {};
  final GlobalKey<GameParticlesState> _particlesKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();

  Offset _guideStart = Offset.zero;
  Offset _guideEnd = Offset.zero;
  final List<Timer> _activeTimers = [];

  void _addTimer(Duration d, VoidCallback fn) {
    late Timer t;
    t = Timer(d, () {
      _activeTimers.remove(t);
      if (mounted) fn();
    });
    _activeTimers.add(t);
  }

  @override
  void dispose() {
    for (final t in _activeTimers) {
      t.cancel();
    }
    _activeTimers.clear();
    super.dispose();
  }

  static String _getName(String id) {
    switch (id) {
      case 'momo':
        return '모모';
      case 'duri':
        return '두리';
      case 'nuri':
        return '누리';
      case 'berry':
        return '열매';
      case 'acorn':
        return '도토리';
      default:
        return id;
    }
  }

  void _onTargetTapped(String targetId) {
    if (_matched.contains(targetId)) return;
    if (_selected == null) return;
    if (_selected == targetId) {
      final matchedId = _selected!;
      setState(() => _selected = null);
      _onMatch(matchedId);
    } else {
      SoundEffects.instance.boing();
      _targetKeys[targetId]?.currentState?.shake();
    }
  }

  @override
  void initState() {
    super.initState();
    _initRound();
  }

  void _initRound() {
    _currentTargets = widget.stage == 0
        ? ['momo', 'duri']
        : _currentRound == 1 && widget.stage == 1
        ? ['momo', 'duri', 'nuri']
        : ['momo', 'duri', 'nuri', 'berry', 'acorn'];
    _shuffledTray = widget.lowStimulation
        ? List.from(_currentTargets)
        : (List.from(_currentTargets)..shuffle(math.Random()));
    _matched.clear();
    _selected = null;
    _hoveredWrongTarget = null;

    for (var id in _currentTargets) {
      _targetKeys[id] = GlobalKey<_PuzzleTargetState>();
      _pieceKeys[id] = GlobalKey();
    }
    _scheduleGuideUpdate();
  }

  bool get _showGuide =>
      _totalMatched == 0 && _shuffledTray.isNotEmpty && !widget.lowStimulation;

  void _scheduleGuideUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_showGuide) return;

      final targetId = _shuffledTray.firstWhere(
        (id) => !_matched.contains(id),
        orElse: () => '',
      );
      if (targetId.isEmpty) return;

      final targetKey = _targetKeys[targetId];
      final pieceKey = _pieceKeys[targetId];
      if (targetKey != null && pieceKey != null) {
        final start = _getStackPos(pieceKey);
        final end = _getStackPos(targetKey);
        if ((start - _guideStart).distance > 1 ||
            (end - _guideEnd).distance > 1) {
          setState(() {
            _guideStart = start;
            _guideEnd = end;
          });
        }
      }
    });
  }

  Offset _getStackPos(GlobalKey key) {
    final ctx = key.currentContext;
    final stackCtx = _stackKey.currentContext;
    if (ctx == null || stackCtx == null) return Offset.zero;
    final box = ctx.findRenderObject() as RenderBox;
    final stackBox = stackCtx.findRenderObject() as RenderBox;
    return stackBox.globalToLocal(
      box.localToGlobal(box.size.center(Offset.zero)),
    );
  }

  void _onMatch(String id) {
    setState(() {
      _matched.add(id);
      _totalMatched++;
    });

    SoundEffects.instance.snap();

    if (!widget.lowStimulation) {
      final key = _targetKeys[id];
      if (key?.currentContext != null) {
        final box = key!.currentContext!.findRenderObject() as RenderBox;
        final pos = box.localToGlobal(box.size.center(Offset.zero));
        _particlesKey.currentState?.burst(
          origin: pos,
          count: 6,
          style: ParticleStyle.stars,
        );
      }
    }

    if (_matched.length == _currentTargets.length) {
      _onRoundComplete();
    } else {
      _scheduleGuideUpdate();
    }
  }

  void _onRoundComplete() {
    _addTimer(const Duration(milliseconds: 600), () {
      SoundEffects.instance.tada();

      if (!widget.lowStimulation) {
        final size = MediaQuery.of(context).size;
        _particlesKey.currentState?.celebrate(
          Offset(size.width / 2, size.height / 3),
        );
      }

      int index = 0;
      for (var id in _currentTargets) {
        _targetKeys[id]?.currentState?.celebrate(
          Duration(milliseconds: index * 150),
        );
        index++;
      }

      widget.onComplete?.call();
    });
  }

  Widget _buildItem(
    String id, {
    required double size,
    bool silhouette = false,
    FaceMood? faceMood,
  }) {
    Widget item;
    if (['momo', 'duri', 'nuri'].contains(id)) {
      item = Stack(
        alignment: Alignment.center,
        children: [
          AvatarImage(
            avatar: id,
            size: size,
            interactive: false,
            lowStimulation: widget.lowStimulation,
          ),
          if (!silhouette) CharacterBlushOverlay(size: size, isBlushing: true),
        ],
      );
    } else {
      item = Stack(
        alignment: Alignment.center,
        children: [
          ForestProp(
            id == 'berry' ? ForestObject.berry : ForestObject.acorn,
            size: size,
          ),
          if (!silhouette && !widget.lowStimulation)
            Positioned(
              top: size * (id == 'berry' ? 0.32 : 0.38),
              child: CuteFace(
                mood: faceMood ?? FaceMood.happy,
                size: size * 0.36,
                animateBlink: !widget.lowStimulation,
              ),
            ),
        ],
      );
    }

    if (silhouette) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(Color(0xFF6B5234), BlendMode.srcIn),
        child: item,
      );
    }
    return item;
  }

  Widget _buildTrayBase(String id, bool isEmpty, {double size = 90}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF8B6B4A),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 4)),
        ],
      ),
      alignment: Alignment.center,
      child: isEmpty
          ? null
          : _buildItem(id, size: size * 0.8, faceMood: FaceMood.idle),
    );
  }

  Widget _buildDraggableFeedback(String id, double size) {
    return Material(
      color: Colors.transparent,
      child: Transform.scale(
        scale: 1.15,
        child: _buildItem(id, size: size * 0.9, faceMood: FaceMood.surprised),
      ),
    );
  }

  Widget _buildPiece(String id, {double size = 90}) {
    bool isMatched = _matched.contains(id);
    final name = _getName(id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Container(
        key: _pieceKeys[id],
        child: isMatched
            ? Opacity(opacity: 0.3, child: _buildTrayBase(id, true, size: size))
            : Semantics(
                label: '$name 퍼즐 조각',
                button: true,
                selected: _selected == id,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isMatched
                      ? null
                      : () {
                          setState(() => _selected = id);
                        },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _selected == id
                          ? const Color(0xFFFBE5AE)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Draggable<String>(
                      data: id,
                      maxSimultaneousDrags: isMatched ? 0 : 1,
                      feedback: _buildDraggableFeedback(id, size),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _buildTrayBase(id, true, size: size),
                      ),
                      onDraggableCanceled: (velocity, offset) {
                        SoundEffects.instance.boing();
                        if (_hoveredWrongTarget != null) {
                          _targetKeys[_hoveredWrongTarget]?.currentState
                              ?.shake();
                        }
                      },
                      child: ForestFloat(
                        still: widget.lowStimulation,
                        child: _buildTrayBase(id, false, size: size),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _scheduleGuideUpdate();
    final media = MediaQuery.sizeOf(context);
    final compact = media.height < 650;
    final targetWidth = compact
        ? ((media.width - 48) / _currentTargets.length.clamp(3, 5)).clamp(
            64.0,
            92.0,
          )
        : 110.0;
    final targetHeight = compact ? targetWidth * 1.15 : 110.0;
    final targetIconSize = compact ? targetWidth * 0.72 : 80.0;
    final pieceSize = compact ? 72.0 : 90.0;

    return Stack(
      key: _stackKey,
      children: [
        if (!widget.lowStimulation)
          CuteBubblesLayer(particlesKey: _particlesKey),
        Column(
          children: [
            SizedBox(height: compact ? 6 : 16),
            ForestProgress(
              count: _matched.length,
              total: _currentTargets.length,
            ),
            SizedBox(height: compact ? 8 : 24),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: compact ? 8 : 16,
                    runSpacing: compact ? 8 : 16,
                    children: _currentTargets
                        .map(
                          (id) => _PuzzleTarget(
                            key: _targetKeys[id],
                            id: id,
                            isMatched: _matched.contains(id),
                            onMatch: () => _onMatch(id),
                            onWrongHover: (targetId) =>
                                _hoveredWrongTarget = targetId,
                            buildItem: _buildItem,
                            onTap: () => _onTargetTapped(id),
                            width: targetWidth,
                            height: targetHeight,
                            iconSize: targetIconSize,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: compact ? 12.0 : 32.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _shuffledTray
                      .map((id) => _buildPiece(id, size: pieceSize))
                      .toList(),
                ),
              ),
            ),
          ],
        ),

        if (_showGuide) HandGuideHint(start: _guideStart, end: _guideEnd),

        Positioned.fill(child: GameParticles(key: _particlesKey)),

        if (_matched.length == _currentTargets.length && _currentRound == 1)
          Center(
            child: ForestAction(
              label: '다른 그림자로 한 번 더',
              icon: Icons.replay_rounded,
              size: 90,
              quiet: widget.lowStimulation,
              onPressed: () => setState(() {
                _currentRound = 2;
                _initRound();
              }),
            ),
          ),
      ],
    );
  }
}

class _PuzzleTarget extends StatefulWidget {
  final String id;
  final bool isMatched;
  final VoidCallback onMatch;
  final Function(String?) onWrongHover;
  final Widget Function(String, {required double size, bool silhouette})
  buildItem;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final double iconSize;

  const _PuzzleTarget({
    required this.id,
    required this.isMatched,
    required this.onMatch,
    required this.onWrongHover,
    required this.buildItem,
    this.onTap,
    this.width = 110,
    this.height = 110,
    this.iconSize = 80,
    super.key,
  });

  @override
  _PuzzleTargetState createState() => _PuzzleTargetState();
}

class _PuzzleTargetState extends State<_PuzzleTarget>
    with TickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _snapController;
  late AnimationController _wobbleController;
  late AnimationController _shakeController;
  late AnimationController _celebrateController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  Timer? _wobbleTimer;
  Timer? _celebrateTimer;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _celebrateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.15,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_snapController);

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_snapController);
  }

  @override
  void didUpdateWidget(_PuzzleTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMatched && !oldWidget.isMatched) {
      _snapController.forward(from: 0.0);
      _wobbleTimer?.cancel();
      _wobbleTimer = Timer(const Duration(milliseconds: 400), () {
        if (mounted) _wobbleController.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    _wobbleTimer?.cancel();
    _celebrateTimer?.cancel();
    _snapController.dispose();
    _wobbleController.dispose();
    _shakeController.dispose();
    _celebrateController.dispose();
    super.dispose();
  }

  void shake() {
    _shakeController.forward(from: 0.0);
  }

  void celebrate(Duration delay) {
    _celebrateTimer?.cancel();
    _celebrateTimer = Timer(delay, () {
      if (mounted) _celebrateController.forward(from: 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _shakeController,
        _snapController,
        _wobbleController,
        _celebrateController,
      ]),
      builder: (context, child) {
        final shakeVal = math.sin(_shakeController.value * math.pi * 4) * 3.0;
        final scaleVal = widget.isMatched ? _scaleAnimation.value : 1.0;
        final opacity = widget.isMatched ? _opacityAnimation.value : 0.0;

        double rotation = 0.0;
        if (_celebrateController.isAnimating) {
          rotation = math.sin(_celebrateController.value * math.pi * 4) * 0.1;
        } else if (widget.isMatched) {
          rotation = math.sin(_wobbleController.value * math.pi * 2) * 0.03;
        }

        return Transform.translate(
          offset: Offset(shakeVal, 0),
          child: DragTarget<String>(
            onWillAcceptWithDetails: (details) {
              if (details.data == widget.id) {
                setState(() => _isHovered = true);
                return true;
              } else {
                widget.onWrongHover(widget.id);
                return false;
              }
            },
            onLeave: (data) {
              setState(() => _isHovered = false);
              widget.onWrongHover(null);
            },
            onAcceptWithDetails: (details) {
              setState(() => _isHovered = false);
              widget.onMatch();
            },
            builder: (context, candidateData, rejectedData) {
              final container = Container(
                width: widget.width,
                height: widget.height,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isHovered
                        ? Colors.orangeAccent
                        : const Color(0xFF8B6B4A),
                    width: _isHovered ? 4 : 2,
                  ),
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: Colors.orangeAccent.withAlpha(128),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : const [
                          BoxShadow(color: Colors.black54),
                          BoxShadow(
                            color: Color(0xFFC4A47C),
                            spreadRadius: -2.0,
                            blurRadius: 4.0,
                          ),
                        ],
                ),
                alignment: Alignment.center,
                child: Transform.scale(
                  scale: scaleVal,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!widget.isMatched || opacity < 1.0)
                        Opacity(
                          opacity: widget.isMatched ? (1.0 - opacity) : 1.0,
                          child: widget.buildItem(
                            widget.id,
                            size: widget.iconSize,
                            silhouette: true,
                          ),
                        ),
                      if (widget.isMatched)
                        Opacity(
                          opacity: opacity,
                          child: Transform.rotate(
                            angle: rotation,
                            child: widget.buildItem(
                              widget.id,
                              size: widget.iconSize,
                              silhouette: false,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );

              return Semantics(
                label: '${_SilhouettePuzzleGameState._getName(widget.id)} 그림자',
                button: true,
                onTap: widget.onTap,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onTap,
                  child: container,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
