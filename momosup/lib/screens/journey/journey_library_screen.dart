import '../../utils/forest_orientation.dart';

import 'package:flutter/material.dart';

import '../../data/journey_recommendation.dart';
import '../../models/age_journey.dart';
import '../../models/child_profile.dart';
import '../../state/app_state.dart';
import '../../widgets/forest_background.dart';
import '../../widgets/forest_game_ui.dart';
import 'journey_common.dart';
import 'journey_detail_screen.dart';
import 'journey_play_screen.dart';

class JourneyLibraryScreen extends StatefulWidget {
  const JourneyLibraryScreen({
    required this.appState,
    required this.profile,
    this.parent = false,
    super.key,
  });
  final AppState appState;
  final ChildProfile profile;
  final bool parent;
  @override
  State<JourneyLibraryScreen> createState() => _JourneyLibraryScreenState();
}

class _JourneyLibraryScreenState extends State<JourneyLibraryScreen> {
  late int age = widget.profile.ageMonths;
  @override
  Widget build(BuildContext context) => ForestOrientationScope(
    mode: widget.parent
        ? ForestOrientation.portrait
        : ForestOrientation.landscape,
    child: AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final items = widget.appState.journeys
            .where(
              (a) =>
                  (widget.parent
                      ? a.supports(age, preschool: true)
                      : journeyEligible(a, widget.profile)) &&
                  (widget.parent ||
                      (!a.isCaregiver && widget.appState.journeyApproved(a))),
            )
            .toList();
        if (!widget.parent) {
          return Scaffold(
            body: ForestBackground(
              lowStimulation: widget.profile.lowStimulation,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ForestAction(
                            label: '숲으로 돌아가기',
                            icon: Icons.close_rounded,
                            onPressed: () => Navigator.pop(context),
                            size: 58,
                          ),
                          const Spacer(),
                          const ForestSign('놀이숲'),
                          const Spacer(),
                          const SizedBox(width: 58),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.extent(
                        maxCrossAxisExtent: 190,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 20,
                        padding: const EdgeInsets.all(24),
                        children: [
                          for (final a in items)
                            Center(
                              child: ForestAction(
                                label: a.title,
                                size: 120,
                                leaf: true,
                                quiet: widget.profile.lowStimulation,
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => JourneyPlayScreen(
                                      journey: a,
                                      appState: widget.appState,
                                      profile: widget.profile,
                                    ),
                                  ),
                                ),
                                child: ForestProp(
                                  journeyProp(a.symbols.first),
                                  size: 88,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(widget.parent ? '월령별 놀이 공방' : '우리 놀이숲')),
          body: Material(
            color: forestCream,
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (widget.parent) ...[
                    const Text('72개 놀이 · 보호자 안내\n월령에 맞는 실제 놀이와 짧은 장면을 만나보세요.'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: journeyBands
                          .firstWhere((b) => age >= b.$1 && age <= b.$2)
                          .$1,
                      decoration: const InputDecoration(labelText: '살펴볼 월령'),
                      items: [
                        for (final b in journeyBands)
                          DropdownMenuItem(
                            value: b.$1,
                            child: Text(journeyBandLabel(b.$1)),
                          ),
                      ],
                      onChanged: (v) => setState(() => age = v!),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('이 월령의 놀이를 보호자 공방에서 먼저 준비해 주세요.'),
                    ),
                  for (final a in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        minVerticalPadding: 20,
                        leading: ForestProp(
                          journeyProp(a.symbols.first),
                          size: 58,
                        ),
                        title: Text(
                          a.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: widget.parent
                            ? Text(
                                '${a.world} · ${a.minutes}분 안팎\n${a.isCaregiver
                                    ? '화면 밖 놀이 안내'
                                    : widget.appState.journeyApproved(a)
                                    ? '검수 완료 · 이용 가능'
                                    : a.bundledApproved
                                    ? '이 기기에서 숨김'
                                    : '새 콘텐츠 검수 대기'}',
                              )
                            : null,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => widget.parent
                                ? JourneyDetailScreen(
                                    journey: a,
                                    appState: widget.appState,
                                    profile: widget.profile,
                                  )
                                : JourneyPlayScreen(
                                    journey: a,
                                    appState: widget.appState,
                                    profile: widget.profile,
                                  ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
