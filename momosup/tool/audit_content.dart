import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Local release audit. This cannot replace listening, looking, or legal review.
void main(List<String> args) {
  final release = args.contains('--release');
  final catalog = jsonDecode(
    File('assets/content/catalog.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final manifest = jsonDecode(
    File('assets/content/audio_manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final register = jsonDecode(
    File('assets/content/asset_register.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final activities = catalog['activities'] as List<dynamic>;
  final jobs = manifest['jobs'] as List<dynamic>;
  final assets = register['assets'] as List<dynamic>;
  final issues = <String>[];

  if (activities.length != 10) {
    issues.add('초기 목표 놀이 10개가 아닙니다: ${activities.length}개');
  }
  if (jobs.length != 66) {
    issues.add('음성 작업 목록이 66개가 아닙니다: ${jobs.length}개');
  }
  for (final row in activities) {
    final item = row as Map<String, dynamic>;
    final id = item['id'] as String;
    final lines = jobs.where(
      (job) => (job as Map<String, dynamic>)['activityId'] == id,
    );
    final audio = item['audioFiles'] as Map<String, dynamic>;
    if (item['humanApprovedAt'] == null) issues.add('$id: 사람 최종 승인 없음');
    if (item['rightsVerifiedAt'] == null) issues.add('$id: 상업 이용권 확인 없음');
    for (final job in lines) {
      final line = job as Map<String, dynamic>;
      final key = line['lineId'] as String;
      final path = audio[key] as String?;
      if (line['status'] != 'APPROVED' ||
          line['humanReviewedAt'] == null ||
          line['commercialRightsEvidence'] == null) {
        issues.add('$id/$key: 음성·노래 사람 검수 또는 사용권 승인 없음');
      }
      if (path == null || !path.startsWith('assets/audio/')) {
        issues.add('$id/$key: 승인 음성 경로 없음');
      } else if (!File(path).existsSync()) {
        issues.add('$id/$key: 음성 파일 없음 ($path)');
      } else {
        if (line['suggestedFile'] != path) {
          issues.add('$id/$key: 작업 목록과 배포 경로 불일치');
        }
        final expectedHash = line['sha256'];
        final actualHash = sha256.convert(File(path).readAsBytesSync()).toString();
        if (expectedHash == null || expectedHash != actualHash) {
          issues.add('$id/$key: 음성 파일 해시 누락 또는 불일치');
        }
      }
    }
  }
  for (final row in assets) {
    final asset = row as Map<String, dynamic>;
    final path = asset['path'] as String;
    final file = File(path);
    if (!file.existsSync()) {
      issues.add('$path: 이미지 파일 없음');
      continue;
    }
    final hash = sha256.convert(file.readAsBytesSync()).toString();
    if (hash != asset['sha256']) issues.add('$path: 파일 해시 불일치');
    if (asset['review'] != 'approved') issues.add('$path: 창업자 시각 검수 미승인');
    if (asset['commercialRightsEvidence'] == null) {
      issues.add('$path: 상업 이용권 증빙 없음');
    }
  }

  stdout.writeln(
    '콘텐츠 ${activities.length}개, 음성 작업 ${jobs.length}개, 이미지 ${assets.length}개',
  );
  stdout.writeln('출시 전 미완료 ${issues.length}건');
  for (final issue in issues.take(20)) {
    stdout.writeln('- $issue');
  }
  if (issues.length > 20) stdout.writeln('... 외 ${issues.length - 20}건');
  if (release && issues.isNotEmpty) exitCode = 1;
}
