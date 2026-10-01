import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../state/app_state.dart';
import '../utils/forest_orientation.dart';
import '../widgets/forest_background.dart';
import '../widgets/forest_coloring_studio.dart';
import '../widgets/forest_game_ui.dart';

class ColoringScreen extends StatelessWidget {
  const ColoringScreen({
    required this.profile,
    required this.appState,
    this.initialTemplateIndex = 0,
    super.key,
  });

  final ChildProfile profile;
  final AppState appState;
  final int initialTemplateIndex;

  @override
  Widget build(BuildContext context) => ForestOrientationScope(
    mode: ForestOrientation.landscape,
    child: Scaffold(
      body: ForestBackground(
        lowStimulation: profile.lowStimulation,
        child: SafeArea(
          child: Column(
            children: [
              ForestHeader(
                title: '톡톡 색칠하기',
                onExit: () => Navigator.pop(context),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ForestColoringStudio(
                      initialTemplateIndex: initialTemplateIndex,
                      quiet: profile.lowStimulation,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
