import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../utils/audio_policy.dart';
import 'build_experiment.dart';

/// A finite Flame simulation: the friend stops before weak/gapped pieces;
/// wind transports loose leaves. No endless idle game loop or auto next trial.
class ForestExperimentGame extends FlameGame {
  ForestExperimentGame(this.onFinished);
  final VoidCallback onFinished;
  ui.Image? friend;
  BuildTrial? trial;
  bool running = false, quiet = false;
  double elapsed = 0;
  @override
  Color backgroundColor() => Colors.transparent;
  @override
  Future<void> onLoad() async {
    friend = await images.load('duri.png');
    AudioPolicy.instance.addListener(syncPause);
    if (!running) pauseEngine();
  }

  void syncPause() {
    if (AudioPolicy.instance.suspended || !running) {
      pauseEngine();
    } else {
      resumeEngine();
    }
  }

  void run(BuildTrial next, bool reducedMotion) {
    trial = next;
    quiet = reducedMotion;
    elapsed = 0;
    running = true;
    syncPause();
  }

  @override
  void update(double dt) {
    if (AudioPolicy.instance.suspended) {
      pauseEngine();
      return;
    }
    super.update(dt);
    if (!running) return;
    elapsed += dt.clamp(0, .05);
    if (elapsed >= (quiet ? .15 : 2.4)) {
      running = false;
      pauseEngine();
      WidgetsBinding.instance.addPostFrameCallback((_) => onFinished());
    }
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    if (trial == null || friend == null || size.x <= 0) return;
    final t = trial!;
    final result = t.evaluate();
    final progress = quiet ? 1.0 : (elapsed / 2.4).clamp(0.0, 1.0);
    final destination = result.success
        ? .83
        : ((result.problemSlot ?? 0) / t.count * .7 + .08);
    final x =
        size.x *
        (.03 + (destination - .03) * Curves.easeInOut.transform(progress));
    final y =
        size.y * (t.wind || t.garden ? .66 : .32) -
        (quiet ? 0 : math.sin(progress * math.pi * 6).abs() * 6);
    canvas.drawImageRect(
      friend!,
      Rect.fromLTWH(0, 0, friend!.width.toDouble(), friend!.height.toDouble()),
      Rect.fromLTWH(x.clamp(0.0, size.x - 66), y, 66, 66),
      Paint(),
    );
    if (t.wind && !quiet) {
      for (var i = 0; i < 9; i++) {
        final px = ((progress * size.x * 1.7 + i * 43) % (size.x + 40)) - 20;
        final py = 30 + i * 18.0 + math.sin(progress * 8 + i) * 12;
        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(progress * 4 + i);
        canvas.drawOval(
          const Rect.fromLTWH(-9, -4, 18, 8),
          Paint()..color = const Color(0xB57FA16C),
        );
        canvas.restore();
      }
    }
  }

  @override
  void onRemove() {
    AudioPolicy.instance.removeListener(syncPause);
    super.onRemove();
  }
}

class ForestExperimentScene extends StatefulWidget {
  const ForestExperimentScene({
    required this.trial,
    required this.quiet,
    required this.onFinished,
    super.key,
  });
  final BuildTrial? trial;
  final bool quiet;
  final VoidCallback onFinished;
  @override
  State<ForestExperimentScene> createState() => _ForestExperimentSceneState();
}

class _ForestExperimentSceneState extends State<ForestExperimentScene> {
  late final game = ForestExperimentGame(() {
    if (mounted) widget.onFinished();
  });
  @override
  void initState() {
    super.initState();
    if (widget.trial != null) game.run(widget.trial!, widget.quiet);
  }

  @override
  void didUpdateWidget(ForestExperimentScene old) {
    super.didUpdateWidget(old);
    if (widget.trial != null && widget.trial != old.trial) {
      game.run(widget.trial!, widget.quiet);
    }
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(child: GameWidget(game: game, autofocus: false)),
  );
}
