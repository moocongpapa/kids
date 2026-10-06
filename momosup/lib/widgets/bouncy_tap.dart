import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/sound_effects.dart';

/// A delightfully juicy, bouncy spring button wrapper.
/// When pressed, it squashes down like jelly, and on release it springs back
/// with an elastic overshoot and gentle tactile haptic feedback.
class BouncyTap extends StatefulWidget {
  const BouncyTap({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.haptic = true,
    this.musicalSound = false,
    this.popSound = false,
    this.squash = 0.90,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool haptic;
  final bool musicalSound;
  final bool popSound;
  final double squash;
  final bool enabled;

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.squash).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled || widget.onTap == null) return;
    _controller.forward();
    if (widget.haptic) {
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (!widget.enabled) return;
    _controller.reverse();
  }

  void _onTapCancel() {
    if (!widget.enabled) return;
    _controller.reverse();
  }

  void _onTap() {
    if (!widget.enabled || widget.onTap == null) return;
    if (widget.musicalSound) {
      SoundEffects.instance.musicalTap();
    } else if (widget.popSound) {
      SoundEffects.instance.pop();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.onTap == null) {
      return widget.child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
