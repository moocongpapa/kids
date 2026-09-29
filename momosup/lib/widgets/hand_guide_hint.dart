import 'package:flutter/material.dart';

/// Gentle animated finger guide for toddlers who cannot read text yet.
class HandGuideHint extends StatefulWidget {
  const HandGuideHint({
    required this.start,
    required this.end,
    this.visible = true,
    super.key,
  });

  final Offset start;
  final Offset end;
  final bool visible;

  @override
  State<HandGuideHint> createState() => _HandGuideHintState();
}

class _HandGuideHintState extends State<HandGuideHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _progress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.easeInOutCubic),
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final currentPos = Offset.lerp(
            widget.start,
            widget.end,
            _progress.value,
          )!;

          return Transform.translate(
            offset: currentPos,
            child: Opacity(
              opacity: _opacity.value * 0.85,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(220),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '👆',
                    style: TextStyle(fontSize: 26),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
