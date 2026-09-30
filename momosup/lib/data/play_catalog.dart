import '../models/activity.dart';
import '../models/age_journey.dart';
import '../models/child_profile.dart';
import '../state/app_state.dart';
import 'journey_recommendation.dart';

enum DynamicToyType { feeding, sorting, peekaboo, xylophone, puzzle }

enum PlayArea { explore, create, music }

/// The home, library and parent inventory all use the same eligibility rules.
class PlayEntry {
  const PlayEntry({
    required this.id,
    required this.title,
    required this.symbol,
    required this.area,
    this.journey,
    this.activity,
    this.toy,
  });
  final String id, title, symbol;
  final PlayArea area;
  final AgeJourney? journey;
  final Activity? activity;
  final DynamicToyType? toy;
  String get avatar => journey?.avatar ?? activity?.avatar ?? 'momo';
  int get minAge => journey?.minAge ?? activity?.minAgeMonths ?? 36;
  int get maxAge => journey?.maxAge ?? activity?.maxAgeMonths ?? 71;
  bool approved(AppState state) => journey != null
      ? state.journeyApproved(journey!)
      : activity?.isFullyApproved ?? true;
  bool eligible(ChildProfile profile) =>
      !profile.caregiverMode &&
      (profile.ageMonths < 84 || profile.preschool) &&
      (journey != null
          ? journeyEligible(journey!, profile)
          : profile.ageMonths >= minAge && profile.ageMonths <= maxAge);
}

List<PlayEntry> playCatalog(AppState state, List<Activity> classics) => [
  for (final a in state.journeys.where((a) => !a.isCaregiver))
    PlayEntry(
      id: a.id,
      title: a.title,
      symbol: a.symbols.first,
      journey: a,
      area: a.mechanic == 'draw' || a.mechanic == 'build'
          ? PlayArea.create
          : a.mechanic == 'rhythm'
          ? PlayArea.music
          : PlayArea.explore,
    ),
  for (final a in classics)
    PlayEntry(
      id: a.id,
      title: a.title,
      activity: a,
      symbol: a.mode == PlayMode.color
          ? 'flower'
          : a.mode == PlayMode.move
          ? 'music'
          : 'bush',
      area: a.mode == PlayMode.color
          ? PlayArea.create
          : a.mode == PlayMode.move
          ? PlayArea.music
          : PlayArea.explore,
    ),
  for (final t in DynamicToyType.values)
    PlayEntry(
      id: 'toy_${t.name}',
      toy: t,
      title: ['냠냠 열매', '도토리 쏙쏙', '풀숲 까꿍', '숲속 딩동', '그림자 착착'][t.index],
      symbol: ['berry', 'basket', 'bush', 'music', 'puzzle'][t.index],
      area: t == DynamicToyType.xylophone ? PlayArea.music : PlayArea.explore,
    ),
];

List<PlayEntry> availablePlay(
  AppState state,
  List<Activity> classics,
  ChildProfile p,
) => playCatalog(
  state,
  classics,
).where((e) => e.eligible(p) && e.approved(state)).toList();

List<PlayEntry> recommendPlay(
  AppState state,
  List<Activity> classics,
  ChildProfile p,
) {
  final entries = availablePlay(state, classics, p);
  final played = state.records
      .where((r) => r.profileId == p.id)
      .map((r) => r.activityId)
      .toSet();
  final ranked = recommendJourneys(
    p,
    state.journeys,
    played: played,
  ).map((a) => a.id).toList();
  entries.sort((a, b) {
    int score(PlayEntry e) =>
        (p.favoriteJourneys.contains(e.id) ? 8 : 0) +
        (ranked.contains(e.id) ? 4 : 0) +
        (!played.contains(e.id) ? 2 : 0);
    final rank = score(b).compareTo(score(a));
    return rank == 0 ? a.id.compareTo(b.id) : rank;
  });
  final result = <PlayEntry>[];
  void take(bool Function(PlayEntry) matches) {
    for (final e in entries) {
      if (!result.contains(e) && matches(e)) {
        result.add(e);
        break;
      }
    }
  }

  take((e) => played.contains(e.id) || p.favoriteJourneys.contains(e.id));
  take((e) => !played.contains(e.id));
  take((e) => !result.any((r) => r.area == e.area));
  for (final e in entries) {
    if (result.length >= 3) break;
    if (!result.contains(e)) result.add(e);
  }
  return result.take(3).toList();
}
