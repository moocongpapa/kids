import 'dart:convert';

import 'package:crypto/crypto.dart';

const _reviewFields = {
  'status',
  'reviewStatus',
  'humanReviewedAt',
  'rightsEvidence',
  'approvedContentSha256',
  // Added by the repository after checking the bundled recordings.
  'validatedAudioHashes',
  'musicLyrics',
  'musicPrompt',
};

Object? _canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: _canonical(value[key])};
  }
  if (value is List) return value.map(_canonical).toList();
  return value;
}

/// The receipt covers the actual content, including each media file's digest.
String contentReviewDigest(Map<String, dynamic> data) => sha256
    .convert(
      utf8.encode(
        jsonEncode(
          _canonical({
            for (final entry in data.entries)
              if (!_reviewFields.contains(entry.key)) entry.key: entry.value,
          }),
        ),
      ),
    )
    .toString();

bool hasApprovedReview(
  Map<String, dynamic> data, {
  String statusField = 'status',
}) =>
    data[statusField] == 'APPROVED' &&
    data['humanReviewedAt'] is String &&
    DateTime.tryParse(data['humanReviewedAt'] as String) != null &&
    data['rightsEvidence'] is String &&
    (data['rightsEvidence'] as String).trim().isNotEmpty &&
    data['approvedContentSha256'] == contentReviewDigest(data);
