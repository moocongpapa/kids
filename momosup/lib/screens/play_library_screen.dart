import 'package:flutter/material.dart';

import '../data/play_catalog.dart';
import '../models/activity.dart';
import '../models/child_profile.dart';
import '../state/app_state.dart';
import '../widgets/forest_background.dart';
import '../widgets/forest_game_ui.dart';
import 'dynamic_toy_screen.dart';
import 'journey_screen.dart';
import 'play_screen.dart';

Future<void> openPlay(
  BuildContext context,
  PlayEntry e,
  AppState state,
  ChildProfile profile, {
  bool preview = false,
  bool restoreSaved = false,
}) async {
  if (!preview && (!e.eligible(profile) || !e.approved(state))) return;
  final p = preview
      ? profile.copyWith(ageMonths: e.minAge, preschool: true)
      : profile;
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => e.journey != null
          ? JourneyPlayScreen(
              journey: e.journey!,
              appState: state,
              profile: p,
              preview: preview,
              restoreSaved: restoreSaved,
            )
          : e.activity != null
          ? PlayScreen(
              activity: e.activity!,
              appState: state,
              profile: p,
              isParentPreview: preview,
              restoreSaved: restoreSaved,
            )
          : DynamicToyScreen(
              toyType: e.toy!,
              appState: state,
              profile: p,
              preview: preview,
            ),
    ),
  );
}

class PlayLibraryScreen extends StatefulWidget {
  const PlayLibraryScreen({
    required this.appState,
    required this.catalog,
    required this.profile,
    this.parent = false,
    this.initialArea,
    super.key,
  });
  final AppState appState;
  final List<Activity> catalog;
  final ChildProfile profile;
  final bool parent;
  final PlayArea? initialArea;
  @override
  State<PlayLibraryScreen> createState() => _PlayLibraryScreenState();
}

class _PlayLibraryScreenState extends State<PlayLibraryScreen> {
  late PlayArea? area = widget.initialArea;
  int collection = 0;
  bool allAges = false;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.appState,
    builder: (context, _) {
      final state = widget.appState;
      final p =
          state.profiles.where((p) => p.id == widget.profile.id).firstOrNull ??
          widget.profile;
      final recent = state.records
          .where((r) => r.profileId == p.id)
          .map((r) => r.activityId)
          .toSet();
      final all = widget.parent && allAges
          ? playCatalog(state, widget.catalog)
          : availablePlay(state, widget.catalog, p);
      final entries = all
          .where(
            (e) =>
                (area == null || area == e.area) &&
                (collection == 0 ||
                    (collection == 1
                        ? p.favoriteJourneys.contains(e.id)
                        : collection == 2
                        ? recent.contains(e.id)
                        : state.workFor(p.id, e.id) != null)),
          )
          .toList();
      return Scaffold(
        appBar: widget.parent ? AppBar(title: const Text('전체 놀이·이어하기')) : null,
        body: ForestBackground(
          lowStimulation: p.lowStimulation,
          child: SafeArea(
            child: Column(
              children: [
                if (!widget.parent)
                  ForestHeader(
                    title: '놀이숲',
                    onExit: () => Navigator.pop(context),
                  ),
                if (widget.parent)
                  SwitchListTile(
                    title: Text(
                      '모든 월령의 디지털 놀이 ${playCatalog(state, widget.catalog).length}개',
                    ),
                    subtitle: const Text('미리보기는 이용시간·작품·관찰 기록에 포함되지 않아요.'),
                    value: allAges,
                    onChanged: (v) => setState(() => allAges = v),
                  ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  children: [
                    for (var i = 0; i < 4; i++)
                      _filter(
                        ['모두', '탐색', '만들기', '소리'][i],
                        [
                          Icons.forest_rounded,
                          Icons.pets_rounded,
                          Icons.palette_rounded,
                          Icons.music_note_rounded,
                        ][i],
                        i == 0 ? area == null : area == PlayArea.values[i - 1],
                        () => setState(
                          () => area = i == 0 ? null : PlayArea.values[i - 1],
                        ),
                      ),
                  ],
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  children: [
                    for (var i = 0; i < 4; i++)
                      _filter(
                        ['모든 놀이', '좋아하는 놀이', '최근 놀이', '저장된 놀이'][i],
                        [
                          Icons.apps_rounded,
                          Icons.favorite_rounded,
                          Icons.history_rounded,
                          Icons.collections_rounded,
                        ][i],
                        collection == i,
                        () => setState(() => collection = i),
                      ),
                  ],
                ),
                Expanded(
                  child: entries.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.spa_rounded,
                            size: 80,
                            color: forestInk,
                          ),
                        )
                      : widget.parent
                      ? ListView(
                          children: [
                            for (final e in entries)
                              ListTile(
                                minVerticalPadding: 12,
                                leading: ForestProp(
                                  journeyProp(e.symbol),
                                  size: 52,
                                ),
                                title: Text(e.title),
                                subtitle: Text(
                                  '${e.minAge}~${e.maxAge}개월 · ${e.approved(state) ? '승인' : '검수 대기'} · 도움 ${p.stageFor(e.id) + 1}${state.workFor(p.id, e.id) != null ? ' · 저장 있음' : ''}',
                                ),
                                onTap: () => openPlay(
                                  context,
                                  e,
                                  state,
                                  p,
                                  preview: true,
                                  restoreSaved: collection == 3,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PopupMenuButton<int>(
                                      tooltip: '이 놀이의 도움 단계',
                                      icon: const Icon(Icons.tune_rounded),
                                      initialValue:
                                          p.activityStages[e.id] ?? -1,
                                      itemBuilder: (_) => [
                                        for (var i = -1; i < 3; i++)
                                          PopupMenuItem(
                                            value: i,
                                            child: Text(
                                              [
                                                '월령·프로필 설정 따르기',
                                                '함께 시작 · 그림 도움',
                                                '혼자 탐색 · 도움 선택',
                                                '비교·규칙 바꾸기',
                                              ][i + 1],
                                            ),
                                          ),
                                      ],
                                      onSelected: (stage) async {
                                        final stages = {...p.activityStages};
                                        if (stage < 0) {
                                          stages.remove(e.id);
                                        } else {
                                          stages[e.id] = stage;
                                        }
                                        try {
                                          await state.updateProfile(
                                            p.copyWith(activityStages: stages),
                                          );
                                        } catch (_) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '단계를 저장하지 못했어요. 다시 시도해 주세요.',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                    IconButton(
                                      tooltip: '좋아하는 놀이',
                                      icon: Icon(
                                        p.favoriteJourneys.contains(e.id)
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                      ),
                                      onPressed: () => _favorite(p, e),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        )
                      : GridView.extent(
                          maxCrossAxisExtent: 190,
                          mainAxisExtent: 174,
                          padding: const EdgeInsets.all(18),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          children: [
                            for (final e in entries)
                              Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ForestAction(
                                      label: e.title,
                                      size: 128,
                                      leaf: true,
                                      quiet: p.lowStimulation,
                                      onPressed: () =>
                                          openPlay(context, e, state, p),
                                      child: ForestProp(
                                        journeyProp(e.symbol),
                                        size: 86,
                                      ),
                                    ),
                                    if (state.workFor(p.id, e.id) != null)
                                      const Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: IgnorePointer(
                                          child: Icon(
                                            Icons.collections_rounded,
                                            color: forestInk,
                                            size: 25,
                                          ),
                                        ),
                                      ),
                                  ],
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
    },
  );
  Widget _filter(
    String label,
    IconData icon,
    bool selected,
    VoidCallback action,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: ForestAction(
      label: label,
      icon: icon,
      size: 58,
      quiet: widget.profile.lowStimulation,
      leaf: selected,
      onPressed: action,
    ),
  );
  Future<void> _favorite(ChildProfile p, PlayEntry e) async {
    final ids = [...p.favoriteJourneys];
    ids.contains(e.id) ? ids.remove(e.id) : ids.add(e.id);
    try {
      await widget.appState.updateProfile(p.copyWith(favoriteJourneys: ids));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('즐겨찾기를 저장하지 못했어요.')));
      }
    }
  }
}
