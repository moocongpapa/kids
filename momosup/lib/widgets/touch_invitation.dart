import 'package:flutter/material.dart';

/// Two gentle demonstrations, then silence. Never intercepts a child's touch.
class TouchInvitation extends StatefulWidget {
  const TouchInvitation({
    required this.child,
    required this.visible,
    required this.quiet,
    this.drag = false,
    super.key,
  });
  final Widget child;
  final bool visible, quiet, drag;
  @override
  State<TouchInvitation> createState() => _TouchInvitationState();
}

class _TouchInvitationState extends State<TouchInvitation>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(TouchInvitation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.visible && widget.visible) controller.reset();
    _sync();
  }

  void _sync() {
    if (widget.quiet ||
        MediaQuery.disableAnimationsOf(context) ||
        !widget.visible) {
      controller.stop();
    } else if (!controller.isCompleted && !controller.isAnimating) {
      controller.forward();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = widget.quiet || MediaQuery.disableAnimationsOf(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.child,
        if (widget.visible)
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final t = (controller.value * 2) % 1;
                    final opacity = still
                        ? 1.0
                        : controller.isCompleted
                        ? 0.0
                        : (t < .2
                              ? t / .2
                              : t > .8
                              ? (1 - t) / .2
                              : 1.0);
                    return Align(
                      alignment: const Alignment(.35, .55),
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: still
                              ? Offset.zero
                              : Offset(
                                  widget.drag ? t * 40 - 20 : 0,
                                  widget.drag ? 0 : 7 * t,
                                ),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xF2FFF9E9),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(9),
                              child: Icon(
                                Icons.touch_app_rounded,
                                size: 30,
                                color: Color(0xFF5F704B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
