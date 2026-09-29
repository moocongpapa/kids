import 'dart:convert';
import 'dart:io';

/// Generates a production checklist from the canonical content catalog.
/// No child audio is synthesized or published by this script.
void main(List<String> args) {
  final catalog = jsonDecode(
    File('assets/content/catalog.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final activities = catalog['activities'] as List<dynamic>;
  final jobs = <Map<String, dynamic>>[];
  final existingFile = File('assets/content/audio_manifest.json');
  final existingJobs = <String, Map<String, dynamic>>{};
  Map<String, dynamic>? existingManifest;
  var allJobsUnchanged = true;
  if (existingFile.existsSync()) {
    existingManifest = jsonDecode(existingFile.readAsStringSync()) as Map<String, dynamic>;
    for (final value in existingManifest['jobs'] as List<dynamic>? ?? <dynamic>[]) {
      final old = Map<String, dynamic>.from(value as Map);
      final key = '${old['activityId']}::${old['lineId']}';
      existingJobs[key] = old;
    }
  }

  for (final row in activities) {
    final activity = row as Map<String, dynamic>;
    final id = activity['id'] as String;
    void add(String key, String text, {String kind = 'speech'}) {
      final existing = existingJobs['$id::$key'];
      // Keep generated files and review evidence only while the canonical text
      // and job type remain unchanged. Revised scripts must be regenerated.
      final unchanged = existing?['text'] == text && existing?['kind'] == kind;
      if (!unchanged) allJobsUnchanged = false;
      jobs.add({
        if (unchanged) ...existing!,
        'activityId': id,
        'lineId': key,
        'kind': kind,
        'text': text,
        'suggestedFile': unchanged
            ? existing!['suggestedFile'] ?? 'assets/audio/${id}__$key.m4a'
            : 'assets/audio/${id}__$key.m4a',
        if (!unchanged) ...{
          'generationModel': null,
          'generationDate': null,
          'commercialRightsEvidence': null,
          'humanReviewedAt': null,
          'status': 'NOT_CREATED',
        },
      });
    }

    add('intro', activity['intro'] as String);
    add('prompt', activity['prompt'] as String);
    if (activity['mode'] == 'touch') {
      final choices = activity['choices'] as List<dynamic>;
      final reactions = activity['reactions'] as List<dynamic>;
      for (var index = 0; index < choices.length; index++) {
        add('choice_$index', choices[index] as String);
        add('reaction_$index', reactions[index] as String);
      }
    }
    if (activity['mode'] == 'move') {
      add(
        'song',
        (activity['verses'] as List<dynamic>).join('\n'),
        kind: 'original_song',
      );
    }
    add('outro', activity['outro'] as String);
    add('offscreen', activity['offscreen'] as String);
  }

  final preserveOwnerReview = allJobsUnchanged &&
      existingJobs.length == jobs.length &&
      existingManifest?['status'] == 'owner_reviewed_for_staging';
  final manifest = {
    'sourceCatalogVersion': catalog['version'],
    'status': preserveOwnerReview
        ? 'owner_reviewed_for_staging'
        : 'production_brief_only',
    'notice': preserveOwnerReview
        ? existingManifest!['notice']
        : '변경된 음성 작업은 생성·사람 검수·사용권 확인이 필요합니다. 아이 모드 배포 금지.',
    'jobCount': jobs.length,
    'jobs': jobs,
  };
  final output = '${const JsonEncoder.withIndent('  ').convert(manifest)}\n';
  if (args.contains('--write')) {
    File('assets/content/audio_manifest.json').writeAsStringSync(output);
    stdout.writeln('음성·노래 제작 작업 ${jobs.length}개를 내보냈습니다.');
  } else {
    stdout.write(output);
  }
}
