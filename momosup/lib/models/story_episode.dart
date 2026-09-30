import 'child_profile.dart';

class StoryEpisode {
  const StoryEpisode({
    required this.id,
    required this.title,
    required this.series,
    required this.theme,
    required this.parentPrompt,
    required this.minAgeMonths,
    required this.maxAgeMonths,
    required this.durationSeconds,
    required this.videoAsset,
    required this.posterAsset,
    required this.titleAudioAsset,
    required this.musicAsset,
    this.productionPreview = false,
  });
  final String id, title, series, theme, parentPrompt;
  final String videoAsset, posterAsset, titleAudioAsset, musicAsset;
  final int minAgeMonths, maxAgeMonths, durationSeconds;
  final bool productionPreview;
  bool recommendedFor(ChildProfile p) =>
      p.ageMonths >= minAgeMonths && p.ageMonths <= maxAgeMonths;
  bool availableFor(ChildProfile p) =>
      !productionPreview &&
      !p.caregiverMode &&
      p.ageMonths >= minAgeMonths &&
      (p.ageMonths < 84 || p.preschool) &&
      p.ageMonths <= 95;
  String get ageLabel => minAgeMonths < 36
      ? '$minAgeMonths–$maxAgeMonths개월'
      : '${minAgeMonths ~/ 12}–${maxAgeMonths ~/ 12}세';
  String get durationLabel =>
      '${durationSeconds ~/ 60}:${(durationSeconds % 60).toString().padLeft(2, '0')}';
  factory StoryEpisode.fromJson(
    Map<String, dynamic> j, {
    bool allowPreview = false,
  }) {
    String asset(String name, String extension) {
      final value = j[name] as String;
      if (!RegExp(r'^assets/stories/[a-z0-9_]+\.[a-z0-9]+$').hasMatch(value) ||
          !value.endsWith(extension)) {
        throw const FormatException('Invalid story asset');
      }
      return value;
    }

    final duration = (j['durationSeconds'] as num).ceil();
    final draft = j['status'] == 'PRODUCTION_PREVIEW';
    if (duration <= 0 ||
        duration > 420 ||
        (j['status'] != 'APPLIED_ON_OWNER_REQUEST' &&
            !(allowPreview && draft)) ||
        j['automatedReviewPassed'] != true) {
      throw const FormatException('Unpublished story');
    }
    return StoryEpisode(
      id: j['id'] as String,
      title: j['title'] as String,
      series: j['series'] as String,
      theme: j['theme'] as String,
      parentPrompt: j['parentPrompt'] as String,
      minAgeMonths: j['minAgeMonths'] as int,
      maxAgeMonths: j['maxAgeMonths'] as int,
      durationSeconds: duration,
      videoAsset: asset('videoAsset', '.mp4'),
      posterAsset: asset('posterAsset', '.jpg'),
      titleAudioAsset: asset('titleAudioAsset', '.m4a'),
      musicAsset: j['musicAsset'] == '' ? '' : asset('musicAsset', '.m4a'),
      productionPreview: draft,
    );
  }
}
