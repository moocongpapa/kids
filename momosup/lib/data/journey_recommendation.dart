import '../models/age_journey.dart';
import '../models/child_profile.dart';

bool journeyEligible(AgeJourney a, ChildProfile p) {
  if (p.ageMonths < 6 ||
      p.ageMonths > 95 ||
      (p.ageMonths >= 84 && !p.preschool)) {
    return false;
  }
  if (a.isCaregiver != p.caregiverMode) return false;
  return a.supports(p.ageMonths, preschool: p.preschool) ||
      (p.favoriteJourneys.contains(a.id) && p.ageMonths > a.maxAge);
}

/// Familiar, new, and shared play. Input preferences never become an age score.
List<AgeJourney> recommendJourneys(
  ChildProfile p,
  Iterable<AgeJourney> items, {
  Set<String> played = const {},
  int count = 3,
}) {
  final eligible = items.where((a) => journeyEligible(a, p)).toList();
  int score(AgeJourney a) {
    var s = 0;
    if (p.answers.length == 5) {
      if (p.caregiverMode) {
        if (p.answers[2] == 0 && a.materials == '없음') s += 4;
        if (p.answers[0] == 1 &&
            (a.title.contains('소리') ||
                a.title.contains('노래') ||
                a.title.contains('메아리'))) {
          s += 3;
        }
        if (p.answers[0] == 0 &&
            (a.title.contains('얼굴') || a.title.contains('인사'))) {
          s += 3;
        }
      } else {
        if (p.answers[3] == 1 && a.mechanic == 'draw') s += 4;
        if (p.answers[3] == 2 && a.mechanic == 'rhythm') s += 4;
        if (p.answers[3] == 0 &&
            ['reveal', 'sort', 'build'].contains(a.mechanic)) {
          s += 4;
        }
      }
    }
    if (p.favoriteJourneys.contains(a.id)) s += 2;
    return s;
  }

  eligible.sort((a, b) {
    final rank = score(b).compareTo(score(a));
    return rank == 0 ? a.id.compareTo(b.id) : rank;
  });
  final result = <AgeJourney>[];
  void takeWhere(bool Function(AgeJourney) test) {
    for (final a in eligible) {
      if (!result.contains(a) && test(a)) {
        result.add(a);
        break;
      }
    }
  }

  takeWhere((a) => played.contains(a.id) || p.favoriteJourneys.contains(a.id));
  takeWhere((a) => !played.contains(a.id));
  takeWhere(
    (a) =>
        a.title.contains('함께') ||
        a.title.contains('우리') ||
        a.title.contains('친구') ||
        a.mechanic == 'draw',
  );
  for (final a in eligible) {
    if (result.length >= count) break;
    if (!result.contains(a)) result.add(a);
  }
  return result.take(count).toList();
}
