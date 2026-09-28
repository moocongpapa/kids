import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../models/activity.dart';

class CatalogRepository {
  const CatalogRepository();

  Future<List<Activity>> load() async {
    final source = await rootBundle.loadString('assets/content/catalog.json');
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    final manifestSource = await rootBundle.loadString(
      'assets/content/audio_manifest.json',
    );
    final manifest = jsonDecode(manifestSource) as Map<String, dynamic>;
    final jobs = <String, Map<String, dynamic>>{};
    for (final value in manifest['jobs'] as List<dynamic>) {
      final job = value as Map<String, dynamic>;
      final key = '${job['activityId']}::${job['lineId']}';
      if (jobs.containsKey(key)) throw FormatException('음성 작업 ID 중복: $key');
      jobs[key] = job;
    }
    final rows = decoded['activities'] as List<dynamic>;
    final activities = <Activity>[];
    for (final row in rows) {
      final raw = row as Map<String, dynamic>;
      final draft = Activity.fromJson(raw);
      final approved = await _allAudioApproved(draft, jobs);
      activities.add(Activity.fromJson(raw, audioReviewApproved: approved));
    }
    if (activities.map((activity) => activity.id).toSet().length !=
        activities.length) {
      throw const FormatException('콘텐츠 ID 중복');
    }
    return activities;
  }

  Future<bool> _allAudioApproved(
    Activity activity,
    Map<String, Map<String, dynamic>> jobs,
  ) async {
    if (activity.humanApprovedAt?.isEmpty ?? true) return false;
    if (activity.rightsVerifiedAt?.isEmpty ?? true) return false;
    for (final id in activity.requiredAudioIds) {
      final job = jobs['${activity.id}::$id'];
      final filePath = activity.audioFiles[id];
      if (job == null || job['status'] != 'APPROVED' ||
          !_hasValue(job['humanReviewedAt']) ||
          !_hasValue(job['commercialRightsEvidence']) ||
          !_hasValue(job['sha256']) || filePath == null ||
          filePath != job['suggestedFile'] ||
          !filePath.startsWith('assets/audio/') || filePath.contains('..') ||
          job['text'] != _scriptFor(activity, id)) {
        return false;
      }
      try {
        final bytes = await rootBundle.load(filePath);
        final hash = sha256.convert(bytes.buffer.asUint8List(
          bytes.offsetInBytes,
          bytes.lengthInBytes,
        )).toString();
        if (hash != job['sha256']) return false;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  bool _hasValue(Object? value) => value is String && value.trim().isNotEmpty;

  String? _scriptFor(Activity activity, String id) {
    switch (id) {
      case 'intro': return activity.intro;
      case 'prompt': return activity.prompt;
      case 'outro': return activity.outro;
      case 'offscreen': return activity.offscreen;
      case 'song': return activity.verses.join('\n');
    }
    final parts = id.split('_');
    if (parts.length != 2) return null;
    final index = int.tryParse(parts[1]);
    if (index == null) return null;
    if (parts[0] == 'choice' && index < activity.choices.length) {
      return activity.choices[index];
    }
    if (parts[0] == 'reaction' && index < activity.reactions.length) {
      return activity.reactions[index];
    }
    return null;
  }
}
