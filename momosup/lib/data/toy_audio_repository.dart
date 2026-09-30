import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

class ToyAudioPack {
  const ToyAudioPack(this.voices, this.music);
  final Map<String, Map<String, String>> voices;
  final Map<String, String> music;
  String? cue(String toy, String cue) => voices[toy]?[cue];
}

/// Bundled offline media. Authorization and automated checks are recorded
/// separately from human listening review; no approval is invented here.
class ToyAudioRepository {
  ToyAudioRepository({AssetBundle? bundle}) : bundle = bundle ?? rootBundle;
  final AssetBundle bundle;
  Future<ToyAudioPack> load() async {
    final manifest = jsonDecode(
      await bundle.loadString('assets/content/toy_audio_manifest.json'),
    ) as Map<String, dynamic>;
    final voices = <String, Map<String, String>>{};
    final music = <String, String>{};
    if (manifest['applicationAuthorization'] is! String) {
      return ToyAudioPack(voices, music);
    }
    for (final raw in manifest['jobs'] as List) {
      final job = Map<String, dynamic>.from(raw);
      final review = job['automatedReview'] as Map?;
      if (job['status'] != 'APPLIED_ON_OWNER_REQUEST' ||
          review?['passed'] != true) {
        continue;
      }
      final speech = job['kind'] == 'speech';
      final spec = {
        for (final key
            in speech
                ? ['id', 'toy', 'cue', 'kind', 'text']
                : ['id', 'kind', 'toys', 'prompt'])
          key: job[key],
      };
      if (sha256.convert(utf8.encode(jsonEncode(spec))).toString() !=
          job['specSha256']) {
        continue;
      }
      final file = job['file'] as String;
      if (!RegExp(r'^assets/audio/toy_pack/toy_[a-z_]+\.m4a$').hasMatch(file)) {
        continue;
      }
      try {
        final bytes = await bundle.load(file);
        if (sha256
                .convert(
                  bytes.buffer.asUint8List(
                    bytes.offsetInBytes,
                    bytes.lengthInBytes,
                  ),
                )
                .toString() !=
            job['sha256']) {
          continue;
        }
        if (speech) {
          voices.putIfAbsent(
            job['toy'] as String,
            () => {},
          )[job['cue'] as String] = file;
        } else {
          for (final toy in job['toys'] as List) {
            music[toy as String] = file;
          }
        }
      } on Exception {
        // Missing or changed media never inherits a generation check.
      }
    }
    return ToyAudioPack(voices, music);
  }
}
