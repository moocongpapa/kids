import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../models/age_journey.dart';
import '../models/content_review.dart';

class AgeJourneyRepository {
  AgeJourneyRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;

  Future<List<AgeJourney>> load() async {
    final pack = jsonDecode(
      await _bundle.loadString('assets/content/age_journeys.json'),
    ) as Map<String, dynamic>;
    final manifest = jsonDecode(
      await _bundle.loadString('assets/content/age_audio_manifest.json'),
    ) as Map<String, dynamic>;
    final jobs = (manifest['jobs'] as List).cast<Map<String, dynamic>>();
    final music = jsonDecode(
      await _bundle.loadString('assets/content/age_music_manifest.json'),
    ) as Map<String, dynamic>;
    final musicJobs = (music['jobs'] as List).cast<Map<String, dynamic>>();
    final result = <AgeJourney>[];
    for (final raw in pack['activities'] as List) {
      final data = Map<String, dynamic>.from(raw as Map);
      final item = AgeJourney(data);
      final paths = <String, String>{};
      final hashes = <String, String>{};
      final approvedAudio = <String>{};
      for (final song in musicJobs.where((j) => j['activityId'] == item.id)) {
        data['musicLyrics'] = song['lyrics'];
        data['musicPrompt'] = song['prompt'];
      }
      for (final id in item.audioIds) {
        final text = id == 'song'
            ? data['musicPrompt']
            : id == 'guide'
            ? data['narration']
            : item.steps[int.parse(id.split('_').last)];
        final matching = (id == 'song' ? musicJobs : jobs).where(
          (job) =>
              job['id'] == '${item.id}_$id' &&
              job['activityId'] == item.id &&
              (id == 'song' ? job['prompt'] : job['text']) == text,
        );
        if (matching.length != 1) continue;
        final job = matching.single;
        final file = job['file'] as String;
        if (!RegExp(r'^assets/audio/age_pack/[a-z0-9_]+\.(wav|m4a|mp3)$')
            .hasMatch(file)) {
          continue;
        }
        try {
          final bytes = await _bundle.load(file);
          final hash = sha256
              .convert(
                bytes.buffer.asUint8List(
                  bytes.offsetInBytes,
                  bytes.lengthInBytes,
                ),
              )
              .toString();
          if (hash != job['sha256']) continue;
          paths[id] = file;
          hashes[id] = hash;
          if (hasApprovedReview(job)) approvedAudio.add(id);
        } on Exception {
          // A missing or changed recording cannot inherit a prior review.
        }
      }
      data['validatedAudioHashes'] = hashes;
      result.add(
        AgeJourney(
          data,
          audio: paths,
          bundledApproved:
              hasApprovedReview(data, statusField: 'reviewStatus') &&
              item.audioIds.every(approvedAudio.contains),
        ),
      );
    }
    if (result.map((a) => a.id).toSet().length != result.length) {
      throw const FormatException('놀이 ID 중복');
    }
    return result;
  }
}
