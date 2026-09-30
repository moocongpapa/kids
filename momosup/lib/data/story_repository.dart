import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/child_profile.dart';
import '../models/story_episode.dart';

class StoryRepository {
  const StoryRepository();
  Future<List<StoryEpisode>> load({bool includePreviews = false}) async {
    final data = jsonDecode(
      await rootBundle.loadString('assets/content/story_catalog.json'),
    ) as Map<String, dynamic>;
    return [
          ...(data['episodes'] as List),
          if (includePreviews) ...(data['previews'] as List? ?? []),
        ]
        .map(
          (j) => StoryEpisode.fromJson(
            Map<String, dynamic>.from(j as Map),
            allowPreview: includePreviews,
          ),
        )
        .toList();
  }

  static List<StoryEpisode> forProfile(
    List<StoryEpisode> episodes,
    ChildProfile profile,
  ) => episodes.where((e) => e.availableFor(profile)).toList()
    ..sort((a, b) {
      final age = (b.recommendedFor(profile) ? 1 : 0).compareTo(
        a.recommendedFor(profile) ? 1 : 0,
      );
      return age != 0 ? age : b.minAgeMonths.compareTo(a.minAgeMonths);
    });
}
