import '../forest_landscape.dart';
import 'toy_habitat.dart';

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../utils/sound_effects.dart';
import '../avatar_image.dart';
import '../woodland_art.dart';
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _chewController;
  late final AnimationController _blinkController;
  late final AnimationController _jumpController;
  Timer? _blinkTimer;
  bool _away = false;

  final GlobalKey<GameParticlesState> _particlesKey = GlobalKey();
  final GlobalKey _momoKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();
  final _fruitKeys = List.generate(4, (_) => GlobalKey());

  int totalEaten = 0;
  int currentRound = 0;
  List<ForestObject> roundFruits = [];
  Set<int> eatenIndices = {};

  bool hovering = false;
  bool _chewing = false;
  String currentText = '함께 냠냠';

  FlyingFruit? flyingFruit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

    initRound(0);
  }

  bool get _quiet =>
      widget.lowStimulation || MediaQuery.disableAnimationsOf(context);
  WoodlandMood _look = WoodlandMood.idle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(FeedingGame oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    _blinkTimer?.cancel();
    if (_quiet || _away || !TickerMode.valuesOf(context).enabled) {
      _blinkController.reset();
    } else {
      _scheduleBlink();
    }
  }

  void _scheduleBlink() {
    if (_quiet || _away || !TickerMode.valuesOf(context).enabled) return;
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _away = state != AppLifecycleState.resumed;
    if (mounted) _syncMotion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _blinkTimer?.cancel();
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
    currentText = '함께 냠냠';
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
    if (eatenIndices.contains(index) || _chewing || flyingFruit != null) return;

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
    if (_quiet) {
      _onFruitArrived(roundFruits[index]);
      return;
    }

    final dropCenter = stackBox.globalToLocal(
      details.offset + const Offset(38, 38),
    );
    final momoCenter = stackBox.globalToLocal(
      momoBox.localToGlobal(
        Offset(momoBox.size.width * .61, momoBox.size.height * .40),
      ),
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
    final fruitBox =
        _fruitKeys[index].currentContext?.findRenderObject() as RenderBox?;
    final momoBox = _momoKey.currentContext?.findRenderObject() as RenderBox?;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (_quiet || fruitBox == null || momoBox == null || stackBox == null) {
      _onFruitArrived(roundFruits[index]);
      return;
    }
    setState(
      () => flyingFruit = FlyingFruit(
        fruit: roundFruits[index],
        start: stackBox.globalToLocal(
          fruitBox.localToGlobal(fruitBox.size.center(Offset.zero)),
        ),
        end: stackBox.globalToLocal(
          momoBox.localToGlobal(
            Offset(momoBox.size.width * .61, momoBox.size.height * .40),
          ),
        ),
      ),
    );
  }

  void _onFruitArrived(ForestObject fruitObj) {
    if (!mounted) return;
    setState(() {
      flyingFruit = null;
      _chewing = true;
      currentText = '냠냠!';
    });
    GameFeedback.success(lowStimulation: _quiet);
    SoundEffects.instance.chew();
    _chewController.forward(from: 0.0).then((_) {
      if (!mounted) return;

      _jumpController.forward(from: 0.0);

      if (!_quiet) {
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
        _look = WoodlandMood.happy;
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
      GameFeedback.celebration(lowStimulation: _quiet);
      SoundEffects.instance.snap();

      if (!_quiet) {
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

  Widget buildMomo(double size) => AnimatedBuilder(
    animation: Listenable.merge([
      _chewController,
      _blinkController,
      _jumpController,
    ]),
    builder: (_, _) {
      final mood = hovering || flyingFruit != null
          ? WoodlandMood.open
          : _chewing
          ? (_quiet || (_chewController.value * 4).floor().isEven
                ? WoodlandMood.chew
                : WoodlandMood.blink)
          : !_quiet && _jumpController.isAnimating
          ? WoodlandMood.happy
          : !_quiet && _blinkController.value > .4
          ? WoodlandMood.blink
          : _look;
      return AvatarImage(
        key: _momoKey,
        avatar: 'momo',
        size: size,
        interactive: false,
        lowStimulation: _quiet,
        mood: mood,
      );
    },
  );

  Widget fruitWidget(
    ForestObject fruit, {
    bool faded = false,
    double size = 76,
    FaceMood mood = FaceMood.idle,
  }) => Opacity(
    opacity: faded ? .16 : 1,
    child: SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 0,
            child: WoodlandContactShadow(width: size * .62, height: 9),
          ),
          ForestProp(fruit, size: size - 4),
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
        ForestToyComposition(
          children: [
            ToyDiscoverySprig(
              count: eatenIndices.length,
              total: roundFruits.length,
            ),
            Expanded(
              child: ToyHabitat(
                kind: ToyHabitatKind.picnic,
                discoveries: totalEaten,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    LayoutBuilder(
                      builder: (_, box) {
                        final size = math
                            .min(box.maxWidth * .68, box.maxHeight * .88)
                            .clamp(110.0, 290.0);
                        return DragTarget<int>(
                          onWillAcceptWithDetails: (details) {
                            _onFruitHover();
                            return !_chewing && flyingFruit == null;
                          },
                          onLeave: (_) {
                            if (hovering) {
                              setState(() {
                                hovering = false;
                                currentText = '함께 냠냠';
                              });
                            }
                          },
                          onAcceptWithDetails: _onFruitDropped,
                          builder: (_, _, _) => SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [buildMomo(size)],
                            ),
                          ),
                        );
                      },
                    ),
                    if (!_quiet) GameParticles(key: _particlesKey),
                    if (totalEaten == 0 && !_quiet && flyingFruit == null)
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
              child: ForestChoiceTray(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(roundFruits.length, (i) {
                  final fruitObj = roundFruits[i];
                  final isEaten = eatenIndices.contains(i);
                  final isDisabled = isEaten || _chewing || flyingFruit != null;

                  return Expanded(
                    child: Semantics(
                      key: _fruitKeys[i],
                      button: true,
                      label: _semanticLabelFor(fruitObj),
                      enabled: !isDisabled,
                      onTap: isDisabled ? null : () => _triggerEat(i),
                      child: ExcludeSemantics(
                        child: IdleNudge(
                          active: !isDisabled && eatenIndices.isEmpty && i == 0,
                          enabled: !_quiet,
                          child: Draggable<int>(
                            data: i,
                            maxSimultaneousDrags: isDisabled ? 0 : 1,
                            onDragStarted: () {
                              setState(() => _look = WoodlandMood.lookRight);
                              GameFeedback.tap(lowStimulation: _quiet);
                            },
                            onDragUpdate: (details) {
                              if (_quiet || hovering || flyingFruit != null) {
                                return;
                              }
                              final box =
                                  _momoKey.currentContext?.findRenderObject()
                                      as RenderBox?;
                              if (box == null) return;
                              final left =
                                  details.globalPosition.dx <
                                  box
                                      .localToGlobal(
                                        box.size.center(Offset.zero),
                                      )
                                      .dx;
                              final next = left
                                  ? WoodlandMood.lookLeft
                                  : WoodlandMood.lookRight;
                              if (_look != next) setState(() => _look = next);
                            },
                            onDragEnd: (_) {
                              if (mounted) {
                                setState(() => _look = WoodlandMood.idle);
                              }
                            },
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
                      quiet: _quiet,
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
        CuteBubblesLayer(particlesKey: _particlesKey, enabled: !_quiet),
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
              double curveY = math.sin(val * math.pi) * -32.0;
              double scale = 1.0 - Curves.easeIn.transform(val) * .92;

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
