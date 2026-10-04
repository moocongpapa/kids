import '../utils/forest_orientation.dart';

import 'package:flutter/material.dart';

import '../data/play_catalog.dart';
import '../models/activity.dart';
import '../models/child_profile.dart';
import '../state/app_state.dart';
import '../widgets/forest_background.dart';
import '../widgets/forest_game_ui.dart';
import '../widgets/forest_place_art.dart';
import '../widgets/avatar_image.dart';
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
  bool opening = false;

  Future<void> _open(PlayEntry entry, ChildProfile profile) async {
    if (opening || !mounted) return;
    opening = true;
    try {
      await openPlay(
        context,
        entry,
        widget.appState,
        profile,
        preview: widget.parent,
        restoreSaved: widget.parent && collection == 3,
      );
    } finally {
      opening = false;
    }
  }

  @override
  Widget build(BuildContext context) => ForestOrientationScope(
    mode: widget.parent
        ? ForestOrientation.portrait
        : ForestOrientation.landscape,
    child: AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final state = widget.appState;
        final p =
            state.profiles
                .where((p) => p.id == widget.profile.id)
                .firstOrNull ??
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
          appBar: widget.parent
              ? AppBar(title: const Text('전체 놀이·이어하기'))
              : null,
          body: ForestBackground(
            lowStimulation: p.lowStimulation,
            child: SafeArea(
              child: Column(
                children: [
                  if (widget.parent)
                    SwitchListTile(
                      title: Text(
                        '모든 월령의 디지털 놀이 ${playCatalog(state, widget.catalog).length}개',
                      ),
                      subtitle: const Text('미리보기는 이용시간·작품·관찰 기록에 포함되지 않아요.'),
                      value: allAges,
                      onChanged: (v) => setState(() => allAges = v),
                    ),
                  if (!widget.parent)
                    _childTrail(p)
                  else ...[
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
                            i == 0
                                ? area == null
                                : area == PlayArea.values[i - 1],
                            () => setState(
                              () =>
                                  area = i == 0 ? null : PlayArea.values[i - 1],
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
                  ],
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
                                  onTap: () => _open(e, p),
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
                                              p.copyWith(
                                                activityStages: stages,
                                              ),
                                            );
                                          } catch (_) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
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
                            maxCrossAxisExtent: 224,
                            mainAxisExtent: 194,
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 8,
                            children: [
                              for (final e in entries)
                                _WoodlandPlayPlace(
                                  entry: e,
                                  quiet:
                                      p.lowStimulation ||
                                      MediaQuery.disableAnimationsOf(context),
                                  saved: state.workFor(p.id, e.id) != null,
                                  favorite: p.favoriteJourneys.contains(e.id),
                                  onTap: () => _open(e, p),
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
    ),
  );
  Widget _childTrail(ChildProfile profile) => Semantics(
    label: '놀이숲',
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Row(
        children: [
          ForestAction(
            label: '놀이 마치기',
            size: 64,
            quiet: profile.lowStimulation,
            icon: Icons.close_rounded,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < 4; i++) ...[
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
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            toggled: collection == 1,
            child: _filter(
              '좋아하는 놀이',
              collection == 1
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              collection == 1,
              () => setState(() => collection = collection == 1 ? 0 : 1),
            ),
          ),
        ],
      ),
    ),
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
      size: 64,
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

/// A play destination is an illustrated place in the same woodland as home.
/// The friend and object identify the activity without requiring reading.
class _WoodlandPlayPlace extends StatefulWidget {
  const _WoodlandPlayPlace({
    required this.entry,
    required this.quiet,
    required this.saved,
    required this.favorite,
    required this.onTap,
  });
  final PlayEntry entry;
  final bool quiet, saved, favorite;
  final VoidCallback onTap;
  @override
  State<_WoodlandPlayPlace> createState() => _WoodlandPlayPlaceState();
}

class _WoodlandPlayPlaceState extends State<_WoodlandPlayPlace> {
  bool pressed = false;
  ForestPlace get place => widget.entry.area == PlayArea.music
      ? ForestPlace.music
      : widget.entry.journey?.mechanic == 'build'
      ? ForestPlace.house
      : widget.entry.area == PlayArea.create
      ? ForestPlace.art
      : widget.entry.journey?.mechanic == 'story' ||
            widget.entry.id == 'bus_stop'
      ? ForestPlace.house
      : ForestPlace.garden;
  ForestObject get object => switch (widget.entry.id) {
    'animal_tracks' => ForestObject.paw,
    'bus_stop' || 'my_bus' => ForestObject.bus,
    'feeling_cloud' => ForestObject.cloud,
    'momo_faces' => ForestObject.heart,
    'forest_weather' => ForestObject.sun,
    _ => journeyProp(widget.entry.symbol),
  };
  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.entry.title,
    button: true,
    child: Tooltip(
      message: widget.entry.title,
      excludeFromSemantics: true,
      child: AnimatedScale(
        scale: pressed && !widget.quiet ? .97 : 1,
        duration: widget.quiet
            ? Duration.zero
            : const Duration(milliseconds: 120),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(60),
            splashColor: const Color(0x24E9E7B4),
            highlightColor: const Color(0x14FFF5D8),
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => pressed = true),
            onTapUp: (_) => setState(() => pressed = false),
            onTapCancel: () => setState(() => pressed = false),
            child: ExcludeSemantics(
              child: LayoutBuilder(
                builder: (_, box) {
                  final size = (box.maxWidth - 8).clamp(120.0, 188.0);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: 5,
                        child: Container(
                          width: size * .84,
                          height: 19,
                          decoration: const BoxDecoration(
                            color: Color(0x2862804A),
                            borderRadius: BorderRadius.all(
                              Radius.elliptical(90, 12),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        child: ForestPlaceArt(place, size: size),
                      ),
                      Positioned(
                        left: 2,
                        bottom: 2,
                        child: AvatarImage(
                          avatar: widget.entry.avatar,
                          size: 64,
                          interactive: false,
                          lowStimulation: true,
                          showBlush: false,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 6,
                        child: ForestProp(object, size: 65),
                      ),
                      if (widget.favorite)
                        const Positioned(
                          top: 8,
                          left: 8,
                          child: Icon(
                            Icons.favorite_rounded,
                            color: Color(0xFFB96F66),
                            size: 22,
                          ),
                        ),
                      if (widget.saved)
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(
                            Icons.collections_rounded,
                            color: forestInk,
                            size: 22,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
