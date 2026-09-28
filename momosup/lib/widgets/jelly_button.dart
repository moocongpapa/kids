import 'package:flutter/material.dart';

class JellyButton extends StatefulWidget {
  const JellyButton({
    required this.onPressed,
    required this.child,
    this.isSelected = false,
    this.selectedBorderColor = const Color(0xFF4A7C59),
    this.selectedBackgroundColor,
    this.borderRadius = 22.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.semanticsLabel,
    this.lowStimulation = false,
    super.key,
  });

  final VoidCallback onPressed;
  final Widget child;
  final bool isSelected;
  final Color selectedBorderColor;
  final Color? selectedBackgroundColor;
  final double borderRadius;
  final EdgeInsets padding;
  final String? semanticsLabel;
  final bool lowStimulation;

  @override
  State<JellyButton> createState() => _JellyButtonState();
}

class _JellyButtonState extends State<JellyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.90)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.90, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.lowStimulation) {
      _controller.forward(from: 0.0);
    }
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      selected: widget.isSelected,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: widget.lowStimulation ? 1.0 : _scaleAnimation.value,
          child: child,
        ),
        child: GestureDetector(
          onTap: _handleTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? (widget.selectedBackgroundColor ?? const Color(0xFFE2F0D9))
                  : const Color(0xFFF7FBF4),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: widget.isSelected
                    ? widget.selectedBorderColor
                    : const Color(0xFFD6E5D1),
                width: widget.isSelected ? 3.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isSelected
                      ? widget.selectedBorderColor.withAlpha(50)
                      : Colors.black.withAlpha(12),
                  offset: const Offset(0, 4),
                  blurRadius: widget.isSelected ? 10 : 6,
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

