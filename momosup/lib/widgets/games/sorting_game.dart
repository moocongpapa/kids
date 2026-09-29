import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/sound_effects.dart';
import '../forest_game_ui.dart';
import '../game_particles.dart';
import '../hand_guide_hint.dart';

class Acorn {
  final int id;
  final bool isBig;
  final double size;
  final Color hue;
  final double float;
  Acorn(this.id, this.isBig, this.size, this.hue, this.float);
}

class FlyingAcorn {
  final int id;
  final Acorn acorn;
  final Offset start;
  final Offset end;
  final bool isCorrect;
  FlyingAcorn({
    required this.id,
    required this.acorn,
    required this.start,
    required this.end,
    required this.isCorrect,
  });
}

class SortingGame extends StatefulWidget {
  const SortingGame({this.onComplete, this.lowStimulation = false, super.key});
  final VoidCallback? onComplete;
  final bool lowStimulation;
  @override
  State<SortingGame> createState() => _SortingGameState();
}

class _SortingGameState extends State<SortingGame> with TickerProviderStateMixin {
  int round = 1;
  final Set<int> sorted = {};
  int totalSorted = 0;
  int bigSortedTotal = 0;
  int smallSortedTotal = 0;

  late List<Acorn> acorns;
  final List<FlyingAcorn> _flying = [];
  final Set<int> _flyingBack = {};

  late final AnimationController _bigBasketAnim;
  late final AnimationController _smallBasketAnim;
  late final AnimationController _msgAnim;

  String _msg = '';
  bool _msgError = false;
  Timer? _msgTimer;

  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _bigBasketKey = GlobalKey();
  final GlobalKey _smallBasketKey = GlobalKey();
  final GlobalKey<GameParticlesState> _particlesKey = GlobalKey();
  late final List<GlobalKey> _trayKeys;

  Acorn? selected;

  @override
  void initState() {
    super.initState();
    _trayKeys = List.generate(8, (_) => GlobalKey());
    _bigBasketAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _smallBasketAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _msgAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    startRound(1);
  }

  @override
  void dispose() {
    _bigBasketAnim.dispose();
    _smallBasketAnim.dispose();
    _msgAnim.dispose();
    _msgTimer?.cancel();
    super.dispose();
  }

  void startRound(int r) {
    round = r;
    sorted.clear();
    selected = null;
    final bigSize = r == 1 ? 74.0 : 64.0;
    final smallSize = r == 1 ? 44.0 : 54.0;
    
    final colors = [
      Colors.red, Colors.orange, Colors.yellow, Colors.green,
      Colors.blue, Colors.indigo, Colors.purple, Colors.pink
    ];
    
    final count = r == 1 ? 6 : 8;
    acorns = List.generate(count, (i) {
      final isBig = i.isEven;
      return Acorn(
        i,
        isBig,
        isBig ? bigSize : smallSize,
        colors[i % colors.length],
        math.Random().nextDouble() * math.pi * 2,
      );
    });
    if (!widget.lowStimulation) {
      acorns.shuffle();
    }
    setState(() {});
  }

  void showMessage(String text, bool isError) {
    _msg = text;
    _msgError = isError;
    _msgTimer?.cancel();
    _msgAnim.forward(from: 0);
    _msgTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) _msgAnim.reverse();
    });
  }

  Offset? getLocalCenter(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || stackBox == null) return null;
    return stackBox.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
  }

  Offset getLocalDrop(Offset globalDrop, Size feedbackSize) {
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) return globalDrop;
    return stackBox.globalToLocal(globalDrop + feedbackSize.center(Offset.zero));
  }

  void onAccept(Acorn acorn, Offset dropOffset, bool isBigBasket) {
    final start = getLocalDrop(dropOffset, Size(acorn.size, acorn.size));
    final targetKey = isBigBasket ? _bigBasketKey : _smallBasketKey;
    final end = getLocalCenter(targetKey) ?? start;

    if (acorn.isBig == isBigBasket) {
      setState(() {
        sorted.add(acorn.id);
        _flying.add(FlyingAcorn(
          id: DateTime.now().microsecondsSinceEpoch,
          acorn: acorn,
          start: start,
          end: end,
          isCorrect: true,
        ));
      });
      
      if (sorted.length > 4) {
        SoundEffects.instance.snap();
      } else {
        SoundEffects.instance.pop();
      }
      
      (isBigBasket ? _bigBasketAnim : _smallBasketAnim).forward(from: 0);
      showMessage(['좋아!', '잘했어!', '대박!', '멋져!', '우와!', '쏙!'][math.Random().nextInt(6)], false);
    } else {
      SoundEffects.instance.boing();
      showMessage('이쪽이 아니야~ 🤔', true);
      
      final trayEnd = getLocalCenter(_trayKeys[acorn.id]) ?? start;
      
      setState(() {
        _flyingBack.add(acorn.id);
        _flying.add(FlyingAcorn(
          id: DateTime.now().microsecondsSinceEpoch,
          acorn: acorn,
          start: start,
          end: trayEnd,
          isCorrect: false,
        ));
      });
    }
  }

  void handleRoundComplete() {
    SoundEffects.instance.tada();
    final size = MediaQuery.sizeOf(context);
    _particlesKey.currentState?.celebrate(Offset(size.width / 2, size.height / 2));
    
    if (round == 1) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) startRound(2);
      });
    } else {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) widget.onComplete?.call();
      });
    }
  }

  Animation<double> _getBasketScale(AnimationController ctrl) {
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.95).chain(CurveTween(curve: Curves.easeIn)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(ctrl);
  }

  void _onBasketTapped(bool isBig) {
    if (selected == null) return;
    final a = selected!;
    final start = getLocalCenter(_trayKeys[a.id]) ?? Offset.zero;
    if (a.isBig == isBig) {
      setState(() => selected = null);
      onAccept(a, start, isBig);
    } else {
      SoundEffects.instance.boing();
      showMessage('이쪽이 아니야~ 🤔', true);
    }
  }

  Widget buildBasket(bool isBig, double extent, AnimationController bounceCtrl, GlobalKey key) {
    return Expanded(
      child: DragTarget<Acorn>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (d) => onAccept(d.data, d.offset, isBig),
        builder: (_, candidates, _) {
          final isHovered = candidates.isNotEmpty && !widget.lowStimulation;
          final count = isBig ? bigSortedTotal : smallSortedTotal;
          
          return Semantics(
            label: isBig ? '큰 바구니' : '작은 바구니',
            button: true,
            onTap: () => _onBasketTapped(isBig),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _onBasketTapped(isBig),
              child: ScaleTransition(
              scale: _getBasketScale(bounceCtrl),
              child: AnimatedScale(
                scale: isHovered ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Container(
                  key: key,
                  decoration: BoxDecoration(
                    boxShadow: isHovered 
                      ? const [BoxShadow(color: Color(0x66FFFFFF), blurRadius: 20, spreadRadius: 5)] 
                      : [],
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ForestProp(ForestObject.acorn, size: isBig ? 32 : 22),
                      const SizedBox(height: 8),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ForestProp(ForestObject.basket, size: isBig ? extent : extent * 0.8),
                          Positioned(
                            bottom: isBig ? extent * 0.2 : extent * 0.16,
                            child: SizedBox(
                              width: isBig ? extent * 0.6 : extent * 0.5,
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                children: List.generate(
                                  count,
                                  (i) => const Padding(
                                    padding: EdgeInsets.all(1),
                                    child: ForestProp(ForestObject.acorn, size: 14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      ),
    );
  }

  Widget buildAcorn(Acorn a) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(a.hue.withAlpha(40), BlendMode.srcATop),
      child: ForestProp(ForestObject.acorn, size: a.size),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _stackKey,
      children: [
        Column(
          children: [
            ForestProgress(count: sorted.length, total: acorns.length),
            Expanded(
              child: LayoutBuilder(
                builder: (_, box) => Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        buildBasket(true, (box.maxHeight - 80).clamp(100, 200), _bigBasketAnim, _bigBasketKey),
                        buildBasket(false, (box.maxHeight - 80).clamp(100, 200), _smallBasketAnim, _smallBasketKey),
                      ],
                    ),
                    if (sorted.isEmpty && round == 1 && !widget.lowStimulation)
                      const Positioned(
                        bottom: 0,
                        child: HandGuideHint(start: Offset(-60, 20), end: Offset(-80, -70)),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: AnimatedBuilder(
                animation: _msgAnim,
                builder: (_, _) => Opacity(
                  opacity: _msgAnim.value,
                  child: Transform.scale(
                    scale: 0.8 + (_msgAnim.value * 0.2),
                    child: Text(
                      _msg,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _msgError ? Colors.orange : Colors.green,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: acorns.map((a) {
                  final isSorted = sorted.contains(a.id);
                  final isFlyingBack = _flyingBack.contains(a.id);
                  
                  return Container(
                    key: _trayKeys[a.id],
                    width: 80,
                    height: 80,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: (isSorted || isFlyingBack) 
                      ? Opacity(opacity: 0.2, child: buildAcorn(a))
                      : Semantics(
                          label: '${a.isBig ? '큰' : '작은'} 도토리 ${a.id + 1}',
                          button: true,
                          selected: selected?.id == a.id,
                          onTap: () {
                            setState(() => selected = a);
                          },
                          child: GestureDetector(
                            onTap: () {
                              setState(() => selected = a);
                            },
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: selected?.id == a.id ? const Color(0xFFF8E2A9) : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: ForestFloat(
                                offset: a.float,
                                child: Draggable<Acorn>(
                                  data: a,
                                  feedback: Material(color: Colors.transparent, child: buildAcorn(a)),
                                  childWhenDragging: Opacity(opacity: 0.2, child: buildAcorn(a)),
                                  child: buildAcorn(a),
                                ),
                              ),
                            ),
                          ),
                        ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        for (final f in _flying)
          FlyingAcornWidget(
            key: ValueKey(f.id),
            acorn: f.acorn,
            start: f.start,
            end: f.end,
            isCorrect: f.isCorrect,
            onComplete: () {
              if (mounted) {
                setState(() {
                  _flying.removeWhere((e) => e.id == f.id);
                  if (!f.isCorrect) {
                    _flyingBack.remove(f.acorn.id);
                  } else {
                    _particlesKey.currentState?.sparkle(f.end);
                    totalSorted++;
                    if (f.acorn.isBig) {
                      bigSortedTotal++;
                    } else {
                      smallSortedTotal++;
                    }
                    if (sorted.length == 8) handleRoundComplete();
                  }
                });
              }
            },
          ),
        GameParticles(key: _particlesKey),
      ],
    );
  }
}

class FlyingAcornWidget extends StatefulWidget {
  final Acorn acorn;
  final Offset start;
  final Offset end;
  final bool isCorrect;
  final VoidCallback onComplete;

  const FlyingAcornWidget({
    super.key,
    required this.acorn,
    required this.start,
    required this.end,
    required this.isCorrect,
    required this.onComplete,
  });

  @override
  State<FlyingAcornWidget> createState() => _FlyingAcornWidgetState();
}

class _FlyingAcornWidgetState extends State<FlyingAcornWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _xAnim;
  late Animation<double> _yAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onComplete();
    });
    
    if (widget.isCorrect) {
      _xAnim = Tween<double>(begin: widget.start.dx, end: widget.end.dx).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)
      );
      _yAnim = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: widget.start.dy, end: math.min(widget.start.dy, widget.end.dy) - 60)
            .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween(begin: math.min(widget.start.dy, widget.end.dy) - 60, end: widget.end.dy)
            .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50,
        ),
      ]).animate(_ctrl);
      _ctrl.forward();
    } else {
      _ctrl.duration = const Duration(milliseconds: 600);
      _xAnim = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: widget.start.dx, end: widget.start.dx - 15), weight: 5),
        TweenSequenceItem(tween: Tween(begin: widget.start.dx - 15, end: widget.start.dx + 15), weight: 10),
        TweenSequenceItem(tween: Tween(begin: widget.start.dx + 15, end: widget.start.dx - 15), weight: 10),
        TweenSequenceItem(tween: Tween(begin: widget.start.dx - 15, end: widget.start.dx + 15), weight: 10),
        TweenSequenceItem(tween: Tween(begin: widget.start.dx + 15, end: widget.start.dx), weight: 5),
        TweenSequenceItem(
          tween: Tween(begin: widget.start.dx, end: widget.end.dx).chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 60,
        ),
      ]).animate(_ctrl);
      
      _yAnim = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: widget.start.dy, end: widget.start.dy), weight: 40),
        TweenSequenceItem(
          tween: Tween(begin: widget.start.dy, end: widget.end.dy).chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 60,
        ),
      ]).animate(_ctrl);
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return Positioned(
          left: _xAnim.value - widget.acorn.size / 2,
          top: _yAnim.value - widget.acorn.size / 2,
          child: child!,
        );
      },
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(widget.acorn.hue.withAlpha(40), BlendMode.srcATop),
        child: SizedBox.square(
          dimension: widget.acorn.size,
          child: ForestProp(ForestObject.acorn, size: widget.acorn.size),
        ),
      ),
    );
  }
}
