import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../utils/sound_effects.dart';
import '../avatar_image.dart';
import '../forest_game_ui.dart';
import '../hand_guide_hint.dart';
import '../game_particles.dart';
import '../cute_game_effects.dart';

class FeedingGame extends StatefulWidget {
  const FeedingGame({
    this.onComplete,
    this.lowStimulation = false,
    this.stage = 1,
    super.key,
  });

  final VoidCallback? onComplete;
  final bool lowStimulation;
  final int stage;

  @override
  State<FeedingGame> createState() => _FeedingGameState();
}

class FlyingFruit {
  final ForestObject fruit;
  final Offset start;
  final Offset end;
  FlyingFruit({required this.fruit, required this.start, required this.end});
}

class _FeedingGameState extends State<FeedingGame>
    with TickerProviderStateMixin {
  late final AnimationController _breatheController;
  late final AnimationController _chewController;
  late final AnimationController _blinkController;
  late final AnimationController _jumpController;
  Timer? _blinkTimer;

  final GlobalKey<GameParticlesState> _particlesKey = GlobalKey();
  final GlobalKey _momoKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();

  int totalEaten = 0;
  int currentRound = 0;
  List<ForestObject> roundFruits = [];
  Set<int> eatenIndices = {};

  bool hovering = false;
  bool _chewing = false;
  String currentText = '배고파~ 열매 줘!';

  FlyingFruit? flyingFruit;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (!widget.lowStimulation) {
      _breatheController.repeat(reverse: true);
    }

    _chewController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scheduleBlink();
    initRound(0);
  }

  void _scheduleBlink() {
    if (widget.lowStimulation) return;
    final delay = 3000 + math.Random().nextInt(2000);
    _blinkTimer = Timer(Duration(milliseconds: delay), () {
      if (mounted) {
        _blinkController.forward().then((_) {
          if (mounted) _blinkController.reverse();
        });
        _scheduleBlink();
      }
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _breatheController.dispose();
    _chewController.dispose();
    _blinkController.dispose();
    _jumpController.dispose();
    super.dispose();
  }

  void initRound(int round) {
    currentRound = round;
    eatenIndices.clear();
    List<ForestObject> baseFruits = [
      ForestObject.berry,
      ForestObject.raspberry,
      ForestObject.acorn,
      ForestObject.blueberry,
    ];
    if (round > 0) baseFruits.shuffle(math.Random());
    roundFruits = baseFruits.take(widget.stage == 0 ? 2 : 4).toList();
    currentText = '배고파~ 열매 줘!';
  }

  void _onFruitHover() {
    if (_chewing || flyingFruit != null) return;
    if (!hovering) {
      setState(() {
        hovering = true;
        currentText = '아아~ 👄';
      });
      SoundEffects.instance.pop();
    }
  }

  void _onFruitDropped(DragTargetDetails<int> details) {
    final index = details.data;
    if (eatenIndices.contains(index)) return;

    setState(() {
      hovering = false;
      eatenIndices.add(index);
    });

    final RenderBox? stackBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? momoBox =
        _momoKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || momoBox == null) {
      _onFruitArrived(roundFruits[index]);
      return;
    }

    final dropCenter = stackBox.globalToLocal(
      details.offset + const Offset(38, 38),
    );
    final momoCenter = stackBox.globalToLocal(
      momoBox.localToGlobal(momoBox.size.center(Offset.zero)),
    );

    setState(() {
      flyingFruit = FlyingFruit(
        fruit: roundFruits[index],
        start: dropCenter,
        end: momoCenter,
      );
    });
  }

  void _triggerEat(int index) {
    if (eatenIndices.contains(index) || _chewing || flyingFruit != null) return;
    setState(() {
      hovering = false;
      eatenIndices.add(index);
    });
    _onFruitArrived(roundFruits[index]);
  }

  void _onFruitArrived(ForestObject fruitObj) {
    if (!mounted) return;
    setState(() {
      flyingFruit = null;
      _chewing = true;
      currentText = '냠냠!';
    });
    GameFeedback.success(lowStimulation: widget.lowStimulation);
    SoundEffects.instance.chew();
    SoundEffects.instance.playSuccessPitch(eatenIndices.length - 1);
    _chewController.forward(from: 0.0).then((_) {
      if (!mounted) return;

      _jumpController.forward(from: 0.0);

      if (!widget.lowStimulation) {
        final box = _momoKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          final center = box.localToGlobal(box.size.center(Offset.zero));
          final local =
              (_stackKey.currentContext?.findRenderObject() as RenderBox?)
                  ?.globalToLocal(center);
          if (local != null) {
            _particlesKey.currentState?.burst(
              origin: local,
              count: 8,
              style: ParticleStyle.hearts,
              spread: 140,
            );
          }
        }
      }

      setState(() {
        totalEaten++;
        _chewing = false;
        switch (fruitObj) {
          case ForestObject.berry:
            currentText = '으~ 달콤해! 🍓';
            break;
          case ForestObject.raspberry:
            currentText = '새콤! 맛있다~ 😋';
            break;
          case ForestObject.acorn:
            currentText = '우와 고소해! 🌰';
            break;
          case ForestObject.blueberry:
            currentText = '냠냠 달아! 💜';
            break;
          default:
            currentText = '고마워!';
        }
      });
      _checkRoundCompletion();
    });
  }

  void _checkRoundCompletion() {
    if (eatenIndices.length == roundFruits.length) {
      setState(() {
        currentText = '배부르다! 😊';
      });
      GameFeedback.celebration(lowStimulation: widget.lowStimulation);
      SoundEffects.instance.snap();

      if (!widget.lowStimulation) {
        final box = _momoKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          final center = box.localToGlobal(box.size.center(Offset.zero));
          final local =
              (_stackKey.currentContext?.findRenderObject() as RenderBox?)
                  ?.globalToLocal(center);
          if (local != null) {
            _particlesKey.currentState?.celebrate(local);
          }
        }
      }

      widget.onComplete?.call();
    }
  }

  Widget buildMomo(double size) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _breatheController,
        _chewController,
        _blinkController,
        _jumpController,
      ]),
      builder: (context, child) {
        double scale = 1.0;
        if (!widget.lowStimulation) {
          if (hovering) {
            scale = 1.1;
          } else {
            scale = 1.0 + (_breatheController.value * 0.03);
          }
        }

        double t = _chewController.value;
        double chewSx = 1.0;
        double chewSy = 1.0;
        double rotateZ = 0.0;
        if (t > 0) {
          if (t < 0.2) {
            chewSx = lerpDouble(1.0, 1.15, t / 0.2)!;
            chewSy = lerpDouble(1.0, 0.88, t / 0.2)!;
          } else if (t < 0.5) {
            chewSx = lerpDouble(1.15, 0.9, (t - 0.2) / 0.3)!;
            chewSy = lerpDouble(0.88, 1.1, (t - 0.2) / 0.3)!;
          } else if (t < 0.8) {
            chewSx = lerpDouble(0.9, 1.1, (t - 0.5) / 0.3)!;
            chewSy = lerpDouble(1.1, 0.9, (t - 0.5) / 0.3)!;
          } else {
            chewSx = lerpDouble(1.1, 1.0, (t - 0.8) / 0.2)!;
            chewSy = lerpDouble(0.9, 1.0, (t - 0.8) / 0.2)!;
          }

          rotateZ = math.sin(t * math.pi * 4) * 0.1;
        }

        double blinkSy = 1.0 - (_blinkController.value * 0.15);
        double jumpY = math.sin(_jumpController.value * math.pi) * -40.0;

        if (widget.lowStimulation) {
          chewSx = 1.0;
          chewSy = 1.0;
          rotateZ = 0.0;
          jumpY = 0.0;
          blinkSy = 1.0;
          scale = 1.0;
        }

        return Transform.translate(
          offset: Offset(0, jumpY),
          child: Transform.scale(
            scale: scale,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(chewSx, chewSy * blinkSy, 1.0)
                ..rotateZ(rotateZ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AvatarImage(
                    key: _momoKey,
                    avatar: 'momo',
                    size: size,
                    interactive: true,
                    lowStimulation: widget.lowStimulation,
                  ),
                  if (!widget.lowStimulation)
                    CharacterBlushOverlay(
                      isBlushing: hovering || _chewing,
                      size: size,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget fruitWidget(
    ForestObject fruit, {
    bool faded = false,
    double size = 76,
    FaceMood mood = FaceMood.idle,
  }) => Opacity(
    opacity: faded ? 0.16 : 1.0,
    child: SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ForestProp(fruit, size: size - 4),
          if (!faded && !widget.lowStimulation)
            Positioned(
              top: size * 0.22,
              child: CuteFace(size: size * 0.58, mood: mood),
            ),
        ],
      ),
    ),
  );

  String _semanticLabelFor(ForestObject obj) {
    switch (obj) {
      case ForestObject.berry:
        return '딸기 먹이기';
      case ForestObject.raspberry:
        return '산딸기 먹이기';
      case ForestObject.acorn:
        return '도토리 먹이기';
      case ForestObject.blueberry:
        return '블루베리 먹이기';
      default:
        return '열매 먹이기';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _stackKey,
      children: [
        Column(
          children: [
            ForestProgress(
              count: eatenIndices.length,
              total: roundFruits.length,
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  LayoutBuilder(
                    builder: (_, box) {
                      final size = (box.maxHeight * .72).clamp(120.0, 250.0);
                      return DragTarget<int>(
                        onWillAcceptWithDetails: (details) {
                          _onFruitHover();
                          return !_chewing && flyingFruit == null;
                        },
                        onLeave: (_) {
                          if (hovering) {
                            setState(() {
                              hovering = false;
                              currentText = '배고파~ 열매 줘!';
                            });
                          }
                        },
                        onAcceptWithDetails: _onFruitDropped,
                        builder: (_, _, _) => SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (hovering && !widget.lowStimulation)
                                Container(
                                  width: size + 40,
                                  height: size + 40,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFF8DEA2),
                                  ),
                                ),
                              buildMomo(size),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (!widget.lowStimulation) GameParticles(key: _particlesKey),
                  if (totalEaten == 0 &&
                      !widget.lowStimulation &&
                      flyingFruit == null)
                    const Positioned(
                      bottom: 0,
                      child: HandGuideHint(
                        start: Offset(-70, 25),
                        end: Offset(0, -65),
                      ),
                    ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Text(
                currentText,
                key: ValueKey(currentText),
                style: const TextStyle(
                  fontSize: 24,
                  color: forestInk,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 98,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(roundFruits.length, (i) {
                  final fruitObj = roundFruits[i];
                  final isEaten = eatenIndices.contains(i);
                  final isDisabled = isEaten || _chewing || flyingFruit != null;

                  return Expanded(
                    child: Semantics(
                      button: true,
                      label: _semanticLabelFor(fruitObj),
                      enabled: !isDisabled,
                      onTap: isDisabled ? null : () => _triggerEat(i),
                      child: ExcludeSemantics(
                        child: IdleNudge(
                          active: !isDisabled,
                          enabled: !widget.lowStimulation,
                          child: Draggable<int>(
                            data: i,
                            maxSimultaneousDrags: isDisabled ? 0 : 1,
                            onDragStarted: () => GameFeedback.tap(
                              lowStimulation: widget.lowStimulation,
                            ),
                            feedback: Material(
                              color: Colors.transparent,
                              child: fruitWidget(
                                fruitObj,
                                size: 84,
                                mood: FaceMood.surprised,
                              ),
                            ),
                            childWhenDragging: fruitWidget(
                              fruitObj,
                              faded: true,
                            ),
                            child: GestureDetector(
                              onTap: isDisabled ? null : () => _triggerEat(i),
                              child: fruitWidget(
                                fruitObj,
                                faded: isEaten,
                                mood: isEaten ? FaceMood.idle : FaceMood.happy,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(
              height: 64,
              child:
                  eatenIndices.length == roundFruits.length && currentRound < 2
                  ? ForestAction(
                      label: '한 번 더 먹이기',
                      icon: Icons.replay_rounded,
                      size: 60,
                      quiet: widget.lowStimulation,
                      onPressed: () =>
                          setState(() => initRound(currentRound + 1)),
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
        if (flyingFruit != null)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            onEnd: () => _onFruitArrived(flyingFruit!.fruit),
            builder: (context, val, child) {
              final start = flyingFruit!.start;
              final end = flyingFruit!.end;
              double x = lerpDouble(start.dx, end.dx, val)!;
              double baseY = lerpDouble(start.dy, end.dy, val)!;
              double curveY = math.sin(val * math.pi) * -80.0;
              double scale = 1.0 - val;

              return Positioned(
                left: x - 38,
                top: baseY + curveY - 38,
                child: Transform.scale(
                  scale: scale,
                  child: fruitWidget(
                    flyingFruit!.fruit,
                    size: 76,
                    mood: FaceMood.happy,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
