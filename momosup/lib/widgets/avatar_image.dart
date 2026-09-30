import 'package:flutter/material.dart';

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
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.88)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.88, end: 1.14)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.14, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_controller);

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.06),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.06, end: 0.06),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.06, end: 0.0),
        weight: 30,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.lowStimulation || !widget.interactive) return;
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final shouldBlush = !widget.lowStimulation &&
        !widget.avatar.contains('upset') &&
        (widget.showBlush || (widget.interactive && _controller.isAnimating));

    final imageWidget = Semantics(
      label: widget.semanticLabel ?? '${widget.avatar} 캐릭터',
      child: Stack(
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
            CharacterBlushOverlay(
              size: widget.size,
              isBlushing: true,
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
        animation: _controller,
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
