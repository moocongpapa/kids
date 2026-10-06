import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'avatar_image.dart';
import 'forest_game_ui.dart';
import 'forest_landscape.dart';
import 'woodland_art.dart';

/// A little clearing shared by the games; controls live in the landscape.
class ForestPlayStage extends StatelessWidget {
  const ForestPlayStage({
    required this.child,
    this.river = false,
    this.night = false,
    this.height = 330,
    this.quiet = false,
    super.key,
  });
  final Widget child;
  final bool river, night, quiet;
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: ForestSceneViewport.heightOf(context, height),
    width: double.infinity,
    child: RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          WoodlandGround(frame: river ? 1 : 0, night: night),
          child,
        ],
      ),
    ),
  );
}

/// Large physical-looking play pieces, with a tap alternative to dragging.
class PlayPiece extends StatelessWidget {
  const PlayPiece({
    required this.label,
    required this.child,
    required this.onTap,
    this.size = 88,
    this.selected = false,
    this.quiet = false,
    this.dragValue,
    this.enabled = true,
    super.key,
  });
  final String label;
  final Widget child;
  final VoidCallback onTap;
  final double size;
  final bool selected, quiet, enabled;
  final int? dragValue;
  @override
  Widget build(BuildContext context) {
    final picture = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 3,
            child: Container(
              width: size * .72,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0x26708043),
                shape: BoxShape.circle,
              ),
            ),
          ),
          AnimatedScale(
            scale: selected && !quiet ? 1.08 : 1.0,
            duration: quiet ? Duration.zero : const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: quiet
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0x99FFF3B9) : Colors.transparent,
                border: selected
                    ? Border.all(color: const Color(0xFFD8AF56), width: 3)
                    : null,
                boxShadow: selected && !quiet
                    ? [
                        BoxShadow(
                          color: const Color(0xFFD8AF56).withAlpha(120),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.all(6),
              child: child,
            ),
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: BouncyTap(
          quiet: quiet,
          squash: .96,
          onTap: enabled ? onTap : null,
          child: dragValue == null || !enabled
              ? picture
              : Draggable<int>(
                  data: dragValue,
                  maxSimultaneousDrags: 1,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Transform.scale(
                      scale: 1.15,
                      child: SizedBox(width: size, height: size, child: child),
                    ),
                  ),
                  childWhenDragging: Opacity(opacity: .25, child: picture),
                  child: picture,
                ),
        ),
      ),
    );
  }
}

/// A bounded reaction: it settles, and reduced-motion mode has no bounce.
class SceneReaction extends StatelessWidget {
  const SceneReaction({
    required this.event,
    required this.quiet,
    required this.child,
    super.key,
  });
  final Object event;
  final bool quiet;
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(event),
    tween: Tween(begin: 0, end: 1),
    duration: quiet ? Duration.zero : const Duration(milliseconds: 850),
    builder: (_, t, child) => Transform.translate(
      offset: Offset(0, quiet ? 0 : -math.sin(t * math.pi) * 15),
      child: Transform.scale(
        scale: quiet ? 1 : 1 + math.sin(t * math.pi) * .07,
        child: child,
      ),
    ),
    child: child,
  );
}

class WoodlandBus extends StatelessWidget {
  const WoodlandBus({
    this.passengers = const [],
    this.quiet = false,
    this.width = 300,
    super.key,
  });
  final List<String> passengers;
  final bool quiet;
  final double width;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: width * .58,
    child: Stack(
      children: [
        Positioned.fill(
          child: WoodlandSprite(
            asset: woodlandArtAssets[4],
            frame: 4,
            columns: 4,
            rows: 3,
            size: width,
            height: width * .58,
          ),
        ),
        for (var i = 0; i < passengers.length && i < 3; i++)
          Positioned(
            left: width * (.17 + i * .223),
            top: width * .145,
            child: SceneReaction(
              event: '$i-${passengers[i]}',
              quiet: quiet,
              child: AvatarImage(
                avatar: passengers[i],
                size: width * .18,
                interactive: false,
                lowStimulation: quiet,
                showBlush: !quiet,
              ),
            ),
          ),
      ],
    ),
  );
}

class StoryKeepsakes extends StatelessWidget {
  const StoryKeepsakes({required this.items, super.key});
  final List<ForestObject> items;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 12,
    children: [
      for (var i = 0; i < items.length; i++)
        Semantics(
          label: '${i + 1}번째 내가 고른 물건',
          child: SizedBox(
            width: 48,
            height: 48,
            child: ForestProp(items[i], size: 42),
          ),
        ),
    ],
  );
}
