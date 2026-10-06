import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/sound_effects.dart';
import 'woodland_art.dart';

class AvatarImage extends StatefulWidget {
  const AvatarImage({
    required this.avatar,
    this.size = 104,
    this.semanticLabel,
    this.interactive = true,
    this.lowStimulation = false,
    this.showBlush = false,
    this.mood = WoodlandMood.idle,
    super.key,
  });
  final String avatar;
  final double size;
  final String? semanticLabel;
  final bool interactive, lowStimulation, showBlush;
  final WoodlandMood mood;
  @override
  State<AvatarImage> createState() => _AvatarImageState();
}

class _AvatarImageState extends State<AvatarImage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _greeting = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 680),
  );
  bool _away = false;
  bool get _quiet =>
      widget.lowStimulation || MediaQuery.disableAnimationsOf(context);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(AvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (_quiet ||
        !widget.interactive ||
        _away ||
        !TickerMode.valuesOf(context).enabled) {
      _greeting.reset();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _away = state != AppLifecycleState.resumed;
    if (mounted) _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _greeting.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painted = const ['momo', 'duri', 'nuri'].contains(widget.avatar);
    return Semantics(
      label: widget.semanticLabel ?? '${widget.avatar} 캐릭터',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: !widget.interactive || _quiet || _away
            ? null
            : () {
                if (_greeting.isAnimating) return;
                unawaited(SoundEffects.instance.pop());
                _greeting.forward(from: 0);
              },
        child: AnimatedBuilder(
          animation: _greeting,
          builder: (_, _) {
            final greeting = !_quiet && _greeting.isAnimating;
            final mood = greeting
                ? (_greeting.value < .18
                      ? WoodlandMood.lookRight
                      : WoodlandMood.wave)
                : (widget.showBlush && widget.mood == WoodlandMood.idle
                      ? WoodlandMood.happy
                      : widget.mood);
            return SizedBox.square(
              dimension: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (painted)
                    Positioned(
                      bottom: 0,
                      child: WoodlandContactShadow(
                        width: widget.size * .58,
                        height: widget.size * .065,
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.all(painted ? widget.size * .025 : 0),
                    child: painted
                        ? WoodlandCharacter(
                            avatar: widget.avatar,
                            size: widget.size * .95,
                            mood: mood,
                          )
                        : Image.asset(
                            'assets/images/${widget.avatar}.png',
                            width: widget.size,
                            height: widget.size,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
