import 'package:flutter/material.dart';

import '../utils/sound_effects.dart';
import 'cute_game_effects.dart';

class AvatarImage extends StatefulWidget {
  const AvatarImage({
    required this.avatar,
    this.size = 104,
    this.semanticLabel,
    this.interactive = true,
    this.lowStimulation = false,
    this.showBlush = false,
    super.key,
  });

  final String avatar;
  final double size;
  final String? semanticLabel;
  final bool interactive;
  final bool lowStimulation;
  final bool showBlush;

  @override
  State<AvatarImage> createState() => _AvatarImageState();
}

class _AvatarImageState extends State<AvatarImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotationAnimation;
  bool _showHeart = false;
  int _heartCounter = 0;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.86)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.86, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.18, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_tapController);

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.07),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.07, end: 0.07),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.07, end: 0.0),
        weight: 30,
      ),
    ]).animate(_tapController);
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.lowStimulation || !widget.interactive) return;
    SoundEffects.instance.pop();
    _tapController.forward(from: 0.0);

    setState(() {
      _showHeart = true;
      _heartCounter++;
    });
    final currentCount = _heartCounter;
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted && _heartCounter == currentCount) {
        setState(() => _showHeart = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shouldBlush =
        !widget.lowStimulation &&
        !widget.avatar.contains('upset') &&
        (widget.showBlush || (widget.interactive && _tapController.isAnimating));

    final imageWidget = Semantics(
      label: widget.semanticLabel ?? '${widget.avatar} 캐릭터',
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/${widget.avatar}.png',
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
          if (shouldBlush)
            CharacterBlushOverlay(size: widget.size, isBlushing: true),
          if (_showHeart && !widget.lowStimulation)
            Positioned(
              top: -widget.size * 0.18,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(_heartCounter),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 550),
                builder: (context, value, _) {
                  return Opacity(
                    opacity: (1.0 - value).clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, -value * 24.0),
                      child: Transform.scale(
                        scale: 0.6 + value * 0.6,
                        child: Text(
                          _heartCounter % 2 == 0 ? '✨' : '💖',
                          style: TextStyle(fontSize: widget.size * 0.32),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );

    if (!widget.interactive || widget.lowStimulation) {
      return imageWidget;
    }

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _tapController,
        builder: (context, child) => Transform.rotate(
          angle: _rotationAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        ),
        child: imageWidget,
      ),
    );
  }
}
