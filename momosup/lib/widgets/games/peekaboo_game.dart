import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/sound_effects.dart';
import '../avatar_image.dart';
import '../cute_game_effects.dart';
import '../forest_game_ui.dart';
import '../forest_landscape.dart';
import 'toy_habitat.dart';

class PeekabooGame extends StatefulWidget {
  const PeekabooGame({
    this.onComplete,
    this.lowStimulation = false,
    this.stage = 1,
    super.key,
  });
  final VoidCallback? onComplete;
  final bool lowStimulation;
  final int stage;
  @override
  State<PeekabooGame> createState() => _PeekabooGameState();
}

class _PeekabooGameState extends State<PeekabooGame> {
  final _random = math.Random();
  Timer? _clueTimer;
  List<String> _friends = [];
  final _revealed = <int, int>{};
  int _round = 0;
  int? _clue;
  int get _found => _revealed.values.where((step) => step == 2).length;
  bool get _quiet =>
      widget.lowStimulation || MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _prepareRound();
  }

  void _prepareRound() {
    _friends = ['momo', 'duri', 'nuri'];
    if (!widget.lowStimulation) _friends.shuffle(_random);
    if (widget.stage == 0) _friends = _friends.take(1).toList();
    _revealed.clear();
    _clue = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleClue();
  }

  void _scheduleClue() {
    _clueTimer?.cancel();
    if (_quiet || _found == _friends.length) return;
    _clueTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      final hidden = List.generate(
        _friends.length,
        (i) => i,
      ).where((i) => (_revealed[i] ?? 0) < 2).toList();
      if (hidden.isEmpty) return;
      setState(() => _clue = hidden[_random.nextInt(hidden.length)]);
      // Only one friend hints at a time. Hints are silent and never reveal
      // anything for the child or impose a time limit.
    });
  }

  void _reveal(int index) {
    if (_revealed[index] == 2) return;
    GameFeedback.tap(lowStimulation: _quiet);
    final next = widget.stage == 2 && (_revealed[index] ?? 0) == 0 ? 1 : 2;
    setState(() {
      _revealed[index] = next;
      _clue = null;
    });
    if (next == 1) {
      SoundEffects.instance.pop();
    } else {
      SoundEffects.instance.playSuccessPitch(_found - 1);
      if (_found == _friends.length) widget.onComplete?.call();
    }
    _scheduleClue();
  }

  void _hideAgain() {
    setState(() {
      _round++;
      _prepareRound();
    });
    _scheduleClue();
  }

  @override
  void dispose() {
    _clueTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ForestToyComposition(
    children: [
      ToyDiscoverySprig(count: _found, total: _friends.length),
      Expanded(
        child: ToyHabitat(
          kind: ToyHabitatKind.hideaway,
          discoveries: _found,
          child: LayoutBuilder(
            builder: (context, box) {
              final single = _friends.length == 1;
              final inRow = box.maxWidth > box.maxHeight * 1.55;
              final size = math
                  .min(
                    single
                        ? box.maxWidth * .7
                        : box.maxWidth / (inRow ? 3.1 : 2.05),
                    single
                        ? box.maxHeight * .78
                        : box.maxHeight / (inRow ? 1.25 : 2.1),
                  )
                  .clamp(80.0, 180.0);
              final places = single
                  ? const [Offset(.5, .5)]
                  : inRow
                  ? const [Offset(.17, .51), Offset(.5, .46), Offset(.83, .53)]
                  : const [Offset(.25, .27), Offset(.75, .27), Offset(.5, .73)];
              return Stack(
                children: [
                  for (var i = 0; i < _friends.length; i++)
                    Positioned(
                      left: places[i].dx * box.maxWidth - size / 2,
                      top: places[i].dy * box.maxHeight - size * .55,
                      width: size,
                      height: size * 1.15,
                      child: _HidingFriend(
                        key: ValueKey('$_round-$i'),
                        character: _friends[i],
                        cover: [
                          ForestObject.bush,
                          ForestObject.leaf,
                          ForestObject.flower,
                        ][i],
                        step: _revealed[i] ?? 0,
                        clue: _clue == i,
                        quiet: _quiet,
                        onReveal: () => _reveal(i),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
      SizedBox(
        height: 80,
        child: _found == _friends.length
            ? ForestAction(
                label: '친구들 다시 숨기기',
                icon: Icons.visibility_off_rounded,
                size: 72,
                leaf: true,
                quiet: _quiet,
                onPressed: _hideAgain,
              )
            : const ForestProp(ForestObject.paw, size: 40),
      ),
    ],
  );
}

class _HidingFriend extends StatefulWidget {
  const _HidingFriend({
    required this.character,
    required this.cover,
    required this.step,
    required this.clue,
    required this.quiet,
    required this.onReveal,
    super.key,
  });
  final String character;
  final ForestObject cover;
  final int step;
  final bool clue, quiet;
  final VoidCallback onReveal;
  @override
  State<_HidingFriend> createState() => _HidingFriendState();
}

class _HidingFriendState extends State<_HidingFriend>
    with SingleTickerProviderStateMixin {
  late final _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  void _touch() {
    if (widget.step == 2) {
      if (!widget.quiet) _wave.forward(from: 0);
      GameFeedback.light(lowStimulation: widget.quiet);
    } else {
      widget.onReveal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = switch (widget.character) {
      'momo' => '모모',
      'duri' => '두리',
      _ => '누리',
    };
    final place = switch (widget.cover) {
      ForestObject.bush => '풀숲 속',
      ForestObject.leaf => '나무 뒤',
      _ => '꽃밭 속',
    };
    return Semantics(
      label: '$place $name 찾기',
      value: widget.step == 2
          ? '친구를 찾았어요'
          : widget.step == 1
          ? '친구가 살짝 보여요'
          : '친구가 숨어 있어요',
      button: true,
      onTap: _touch,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _touch,
          child: LayoutBuilder(
            builder: (_, box) {
              final size = box.maxWidth;
              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    bottom: size * .025,
                    child: Container(
                      width: size * .92,
                      height: size * .18,
                      decoration: const BoxDecoration(
                        color: Color(0x28748B51),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: widget.quiet
                        ? Duration.zero
                        : const Duration(milliseconds: 520),
                    curve: Curves.easeOutCubic,
                    bottom:
                        size *
                        (widget.step == 2
                            ? .23
                            : widget.step == 1 || widget.clue
                            ? .11
                            : -.13),
                    child: AnimatedBuilder(
                      animation: _wave,
                      child: AvatarImage(
                        avatar: widget.character,
                        size: size * .75,
                        interactive: widget.step == 2,
                        lowStimulation: widget.quiet,
                      ),
                      builder: (_, child) => Transform.rotate(
                        angle: widget.quiet
                            ? 0
                            : math.sin(_wave.value * math.pi * 4) * .08,
                        child: child,
                      ),
                    ),
                  ),
                  AnimatedSlide(
                    offset: widget.step == 2
                        ? const Offset(.20, .16)
                        : Offset.zero,
                    duration: widget.quiet
                        ? Duration.zero
                        : const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    child: ForestProp(widget.cover, size: size * .91),
                  ),
                  if (widget.step == 2)
                    Positioned(
                      top: 0,
                      child: Text(
                        '까꿍!',
                        style: TextStyle(
                          fontSize: (size * .15).clamp(16, 22),
                          fontWeight: FontWeight.w900,
                          color: forestInk,
                        ),
                      ),
                    ),
                  if (widget.step == 1)
                    Positioned(
                      top: 2,
                      child: ForestProp(ForestObject.paw, size: size * .2),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
