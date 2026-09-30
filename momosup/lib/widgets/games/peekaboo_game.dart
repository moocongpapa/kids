import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';

import '../../utils/sound_effects.dart';
import '../avatar_image.dart';
import '../forest_game_ui.dart';
import '../game_particles.dart';
import '../cute_game_effects.dart';

class PeekabooGame extends StatefulWidget {
  const PeekabooGame({this.onComplete, this.lowStimulation = false, super.key});
  final VoidCallback? onComplete;
  final bool lowStimulation;
  @override
  State<PeekabooGame> createState() => _PeekabooGameState();
}

class _PeekabooGameState extends State<PeekabooGame> {
  int round = 1;
  int totalFound = 0;

  List<int> activeSpots = [];
  Map<int, String> spotCharacter = {};
  Map<int, ForestObject> spotBush = {};
  Map<int, int> spotRevealState = {};
  Map<int, int> spotTeaseCount = {};

  Timer? _teaseTimer;
  final _rng = math.Random();
  final _particlesKey = GlobalKey<GameParticlesState>();

  static const spotPositions = [
    Offset(20, 20),
    Offset(210, 20),
    Offset(115, 120),
    Offset(20, 220),
    Offset(210, 220),
  ];

  @override
  void initState() {
    super.initState();
    _setupRound();
    _scheduleTease();
  }

  void _setupRound() {
    spotRevealState.clear();
    spotTeaseCount.clear();

    final chars = widget.lowStimulation
        ? ['momo', 'duri', 'nuri']
        : (['momo', 'duri', 'nuri']..shuffle(_rng));
    final bushes = widget.lowStimulation
        ? [ForestObject.bush, ForestObject.leaf, ForestObject.flower]
        : ([ForestObject.bush, ForestObject.leaf, ForestObject.flower]..shuffle(_rng));
    activeSpots = widget.lowStimulation
        ? [0, 1, 2]
        : (([0, 1, 2, 3, 4]..shuffle(_rng)).sublist(0, 3)..sort());

    for (int i = 0; i < 3; i++) {
      final spot = activeSpots[i];
      spotCharacter[spot] = chars[i];
      spotBush[spot] = bushes[i];
      spotRevealState[spot] = 0;
      spotTeaseCount[spot] = 0;
    }
  }

  void _scheduleTease() {
    _teaseTimer?.cancel();
    if (widget.lowStimulation) return;

    final waitTime = 2000 + _rng.nextInt(3000);
    _teaseTimer = Timer(Duration(milliseconds: waitTime), () {
      if (!mounted) return;

      final hidden = activeSpots.where((i) => spotRevealState[i] == 0).toList();
      if (hidden.isNotEmpty) {
        final target = hidden[_rng.nextInt(hidden.length)];
        setState(() {
          spotTeaseCount[target] = (spotTeaseCount[target] ?? 0) + 1;
        });
        SoundEffects.instance.whoosh();
      }

      _scheduleTease();
    });
  }

  @override
  void dispose() {
    _teaseTimer?.cancel();
    super.dispose();
  }

  Offset _getSpotCenter(int i) {
    final pos = spotPositions[i];
    return Offset(pos.dx + 75, pos.dy + 85);
  }

  void _handleTap(int i) {
    if (spotRevealState[i] == 2) return;

    if (widget.lowStimulation) {
      setState(() {
        spotRevealState[i] = 2;
        totalFound++;
      });
      SoundEffects.instance.snap();
      _particlesKey.currentState?.burst(
        origin: _getSpotCenter(i),
        count: 8,
        style: ParticleStyle.sparkles,
      );
      _checkRoundComplete();
    } else {
      if (spotRevealState[i] == 0) {
        setState(() => spotRevealState[i] = 1);
        SoundEffects.instance.pop();
      } else if (spotRevealState[i] == 1) {
        setState(() {
          spotRevealState[i] = 2;
          totalFound++;
        });
        SoundEffects.instance.snap();
        SoundEffects.instance.whoosh();
        _particlesKey.currentState?.burst(
          origin: _getSpotCenter(i),
          count: 8,
          style: ParticleStyle.sparkles,
        );
        _checkRoundComplete();
      }
    }
  }

  void _checkRoundComplete() {
    if (spotRevealState.values.where((v) => v == 2).length == 3) {
      widget.onComplete?.call();
      if (widget.lowStimulation) return;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        SoundEffects.instance.tada();
        _particlesKey.currentState?.burst(
          origin: const Offset(190, 210),
          count: 30,
          style: ParticleStyle.confetti,
          spread: 200,
        );

        if (round < 5) {
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (!mounted) return;
            setState(() {
              round++;
              _setupRound();
            });
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: ForestProgress(
                count: spotRevealState.values.where((v) => v == 2).length,
                total: 3,
              ),
            ),
            if (!widget.lowStimulation) ...[
              const SizedBox(height: 8),
              Text(
                '라운드 $round/5',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: forestInk,
                ),
              ),
            ],
            Expanded(
              child: LayoutBuilder(
                builder: (_, box) => Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 380,
                      height: 420,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (int i = 0; i < 5; i++)
                            if (activeSpots.contains(i))
                              Positioned(
                                left: spotPositions[i].dx,
                                top: spotPositions[i].dy,
                                child: _PeekabooSpot(
                                  revealState: spotRevealState[i] ?? 0,
                                  teaseCount: spotTeaseCount[i] ?? 0,
                                  character: spotCharacter[i] ?? 'momo',
                                  bush: spotBush[i] ?? ForestObject.bush,
                                  lowStimulation: widget.lowStimulation,
                                  onTap: () => _handleTap(i),
                                ),
                              ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: GameParticles(key: _particlesKey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 66,
              child: totalFound == 15
                  ? ForestAction(
                      label: '다시 하기',
                      icon: Icons.refresh_rounded,
                      size: 60,
                      onPressed: () {
                        setState(() {
                          round = 1;
                          totalFound = 0;
                          _setupRound();
                        });
                      },
                    )
                  : const Icon(
                      Icons.touch_app_rounded,
                      size: 32,
                      color: Color(0xFF779363),
                    ),
            ),
          ],
        ),
        CuteBubblesLayer(
          particlesKey: _particlesKey,
          enabled: !widget.lowStimulation,
        ),
      ],
    );
  }
}

class _PeekabooSpot extends StatefulWidget {
  final int revealState;
  final int teaseCount;
  final String character;
  final ForestObject bush;
  final VoidCallback onTap;
  final bool lowStimulation;

  const _PeekabooSpot({
    required this.revealState,
    required this.teaseCount,
    required this.character,
    required this.bush,
    required this.onTap,
    required this.lowStimulation,
  });

  @override
  State<_PeekabooSpot> createState() => _PeekabooSpotState();
}

class _PeekabooSpotState extends State<_PeekabooSpot> with TickerProviderStateMixin {
  late final AnimationController _teaseController;
  late final AnimationController _peekController;
  late final AnimationController _springController;
  late final AnimationController _waveController;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _teaseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _peekController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _springController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  }

  @override
  void didUpdateWidget(_PeekabooSpot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.teaseCount != oldWidget.teaseCount && widget.revealState == 0) {
      _teaseController.forward(from: 0);
    }
    if (widget.revealState == 1 && oldWidget.revealState == 0) {
      _peekController.forward();
    }
    if (widget.revealState == 2 && oldWidget.revealState != 2) {
      _springController.forward();
      _waveController.forward(from: 0);
      _scheduleIdle();
    }
    if (widget.revealState == 0 && oldWidget.revealState != 0) {
      _peekController.reset();
      _springController.reset();
      _waveController.reset();
      _idleTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _teaseController.dispose();
    _peekController.dispose();
    _springController.dispose();
    _waveController.dispose();
    _idleTimer?.cancel();
    super.dispose();
  }

  void _scheduleIdle() {
    _idleTimer?.cancel();
    if (widget.revealState != 2) return;
    _idleTimer = Timer(Duration(milliseconds: 4000 + math.Random().nextInt(2000)), () {
      if (mounted && widget.revealState == 2) {
        _waveController.forward(from: 0);
        _scheduleIdle();
      }
    });
  }

  String get _semanticsLabel {
    final b = widget.bush == ForestObject.flower
        ? '꽃밭 속'
        : (widget.bush == ForestObject.leaf ? '나무 뒤' : '풀숲 속');
    final c = widget.character == 'momo'
        ? '모모'
        : (widget.character == 'duri' ? '두리' : '누리');
    return '$b $c 찾기';
  }

  Widget _buildText() {
    if (widget.revealState == 1) {
      return Positioned(
        top: 0,
        child: FadeTransition(
          opacity: _peekController,
          child: const Text('어...?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: forestInk)),
        ),
      );
    } else if (widget.revealState == 2) {
      return Positioned(
        top: 0,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
          child: const Text('까꿍!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: forestInk)),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _semanticsLabel,
      onTap: widget.onTap,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 150,
          height: 170,
          child: AnimatedBuilder(
            animation: Listenable.merge([_teaseController, _peekController, _springController, _waveController]),
            builder: (context, child) {
              double baseBottom = widget.lowStimulation ? 0 : (_peekController.value * 45);
              double springDist = 80 - (widget.lowStimulation ? 0 : 45);
              double bottom = math.sin(_teaseController.value * math.pi) * 15 +
                              baseBottom +
                              Curves.elasticOut.transform(_springController.value) * springDist;

              double teaseAngle = math.sin(_teaseController.value * math.pi * 3) * 0.087;
              double waveAngle = math.sin(_waveController.value * math.pi * 6) * 0.08;

              return Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    bottom: bottom,
                    child: Transform.rotate(
                      angle: waveAngle,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AvatarImage(
                            avatar: widget.character,
                            size: 106,
                            interactive: widget.revealState == 2,
                          ),
                          if (!widget.lowStimulation && widget.revealState == 2)
                            const CharacterBlushOverlay(
                              isBlushing: true,
                              size: 106,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.revealState == 0 && !widget.lowStimulation && widget.teaseCount > 0)
                    Positioned(
                      bottom: 58 + math.sin(_teaseController.value * math.pi) * 16,
                      child: Opacity(
                        opacity: (_teaseController.value * 2).clamp(0.0, 1.0),
                        child: const CuteFace(size: 36, mood: FaceMood.surprised),
                      ),
                    ),
                  Transform.rotate(
                    angle: teaseAngle,
                    child: ForestFloat(
                      still: widget.lowStimulation || widget.revealState == 2,
                      offset: 0,
                      child: ForestProp(
                        widget.bush,
                        size: 143,
                      ),
                    ),
                  ),
                  _buildText(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
