import '../models/activity.dart';
import '../models/child_profile.dart';

/// Deterministic, explainable starting order; never a diagnostic score.
List<Activity> recommendedFor(
  ChildProfile profile,
  Iterable<Activity> candidates, {
  int count = 3,
}) {
  final eligible = candidates
      .where((item) => item.supportsAge(profile.ageMonths))
      .where((item) => profile.musicOn || item.mode != PlayMode.move)
      .toList();

  PlayMode? preferred;
  if (profile.answers.length >= 4) {
    preferred = switch (profile.answers[3]) {
      0 => PlayMode.touch,
      1 => PlayMode.color,
      2 => PlayMode.move,
      _ => null,
    };
  }
  int score(Activity item) {
    var value = 0;
    if (item.mode == preferred) value += 4;
    if (profile.level == '찬찬히') {
      if (item.mode == PlayMode.touch) value += 2;
      if (item.minutes <= 3) value += 2;
    }
    if (profile.level == '더 탐색' && item.mode == PlayMode.color) {
      value += 2;
    }
    if (profile.answers.length >= 3 &&
        profile.answers[2] == 0 &&
        item.minutes <= 3) {
      value += 3;
    }
    return value;
  }

  eligible.sort((a, b) {
    final ranking = score(b).compareTo(score(a));
    return ranking != 0 ? ranking : a.id.compareTo(b.id);
  });

  final selected = <Activity>[];
  final usedThemes = <String>{};
  for (final item in eligible) {
    if (selected.length >= count) break;
    if (usedThemes.add(item.theme)) selected.add(item);
  }
  for (final item in eligible) {
    if (selected.length >= count) break;
    if (!selected.contains(item)) selected.add(item);
  }
  return selected;
}
