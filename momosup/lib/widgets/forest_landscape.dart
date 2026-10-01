import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'forest_background.dart';
import 'forest_game_ui.dart';

bool forestIsWide(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= 600 ||
    MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;

/// Scene dimensions follow the actual play area, including safe areas and the
/// control rail. Buttons keep their own sizes rather than scaling the whole UI.
class ForestSceneViewport extends InheritedWidget {
  const ForestSceneViewport({
    required this.size,
    required super.child,
    super.key,
  });
  final Size size;
  static Size? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ForestSceneViewport>()?.size;
  static double heightOf(BuildContext context, double fallback) =>
      math.min(fallback, of(context)?.height ?? fallback);
  @override
  bool updateShouldNotify(ForestSceneViewport oldWidget) =>
      size != oldWidget.size;
}

class ForestLandscapeFrame extends StatelessWidget {
  const ForestLandscapeFrame({
    required this.child,
    required this.onExit,
    required this.onReplay,
    this.onFinish,
    this.preview = false,
    this.quiet = false,
    super.key,
  });
  final Widget child;
  final VoidCallback onExit, onReplay;
  final VoidCallback? onFinish;
  final bool preview, quiet;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: ForestBackground(
      lowStimulation: quiet,
      clearing: true,
      child: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      ForestAction(
                        label: '놀이 닫기',
                        icon: Icons.close_rounded,
                        size: 64,
                        quiet: quiet,
                        onPressed: onExit,
                      ),
                      const SizedBox(height: 12),
                      ForestAction(
                        label: '안내 다시 듣기',
                        icon: Icons.volume_up_rounded,
                        size: 64,
                        quiet: quiet,
                        onPressed: onReplay,
                      ),
                      if (onFinish != null) ...[
                        const SizedBox(height: 12),
                        ForestAction(
                          label: '놀이 마치기',
                          icon: Icons.spa_rounded,
                          size: 64,
                          leaf: true,
                          quiet: quiet,
                          onPressed: onFinish,
                        ),
                      ],
                      if (preview)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '보호자\n미리보기',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: forestInk, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
                child: LayoutBuilder(
                  builder: (_, box) =>
                      ForestSceneViewport(size: box.biggest, child: child),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Portrait fallback remains usable during rotation and in restricted windows.
/// In landscape, the stage and tools are side by side with no scrolling stage.
class ForestSceneComposition extends StatelessWidget {
  const ForestSceneComposition({
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.controlsWidth = 136,
    super.key,
  });
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final double controlsWidth;
  @override
  Widget build(BuildContext context) {
    if (!forestIsWide(context) || ForestSceneViewport.of(context) == null) {
      return Column(mainAxisAlignment: mainAxisAlignment, children: children);
    }
    final visible = children
        .where((w) => !(w is SizedBox && w.child == null))
        .toList();
    if (visible.isEmpty) return const SizedBox();
    return Row(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (_, box) => ForestSceneViewport(
              size: box.biggest,
              child: Center(child: visible.first),
            ),
          ),
        ),
        if (visible.length > 1) ...[
          const SizedBox(width: 12),
          SizedBox(
            width: controlsWidth,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final tool in visible.skip(1))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: tool,
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class ForestChoiceTray extends StatelessWidget {
  const ForestChoiceTray({
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.spaceEvenly,
    this.extent = 88,
    super.key,
  });
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final double extent;
  @override
  Widget build(BuildContext context) =>
      forestIsWide(context) && ForestSceneViewport.of(context) != null
      ? Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in children)
              SizedBox(
                width: extent,
                height: extent,
                child: item is Expanded ? item.child : item,
              ),
          ],
        )
      : Row(mainAxisAlignment: mainAxisAlignment, children: children);
}

/// The five sensory toys already have a bounded main area. Move their tray to
/// the side while keeping drag targets, pieces and keyboard keys at full size.
class ForestToyComposition extends StatelessWidget {
  const ForestToyComposition({required this.children, super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    if (!forestIsWide(context) || ForestSceneViewport.of(context) == null) {
      return Column(children: children);
    }
    final primary = children.firstWhere(
      (w) => w is Expanded || w is LayoutBuilder,
    );
    final tools = children
        .where(
          (w) =>
              w != primary &&
              w is! Spacer &&
              !(w is SizedBox && w.child == null) &&
              w is! AnimatedSwitcher,
        )
        .toList();
    return Row(
      children: [
        Expanded(
          child: primary is Expanded ? primary.child : Center(child: primary),
        ),
        if (tools.isNotEmpty) const SizedBox(width: 12),
        if (tools.isNotEmpty)
          SizedBox(
            width: 184,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final tool in tools)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: tool is SizedBox ? tool.child : tool,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ForestTrayScroll extends StatelessWidget {
  const ForestTrayScroll({
    required this.child,
    this.padding,
    this.scrollDirection = Axis.horizontal,
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Axis scrollDirection;
  @override
  Widget build(BuildContext context) =>
      forestIsWide(context) && ForestSceneViewport.of(context) != null
      ? Padding(padding: padding ?? EdgeInsets.zero, child: child)
      : SingleChildScrollView(
          padding: padding,
          scrollDirection: scrollDirection,
          child: child,
        );
}
