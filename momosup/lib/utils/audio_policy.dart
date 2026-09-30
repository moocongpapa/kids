import 'package:flutter/foundation.dart';

import '../models/child_profile.dart';

/// One policy for all games. Muting never changes the parent's saved settings.
class AudioPolicy extends ChangeNotifier {
  static final instance = AudioPolicy();
  bool music = true,
      voice = true,
      effects = true,
      muted = false,
      suspended = false,
      lowStimulation = false;
  final Set<Object> _speeches = {};
  bool get speaking => _speeches.isNotEmpty;
  void beginSpeech(Object token) {
    if (_speeches.add(token)) notifyListeners();
  }

  void endSpeech(Object token) {
    if (_speeches.remove(token)) notifyListeners();
  }

  double get musicGain => speaking
      ? .08
      : lowStimulation
      ? .18
      : .30;
  double effectGain(String name) {
    final base = switch (name) {
      'sfx_pop' || 'sfx_whoosh' || 'sfx_boing' => .28,
      'sfx_chew' || 'sfx_snap' || 'sfx_tada' => .32,
      _ => .45,
    };
    return base * (lowStimulation ? .65 : 1) * (speaking ? .38 : 1);
  }

  double voiceGain(String path) =>
      path.contains('/age_pack/') || path.contains('/toy_pack/') ? 1 : .65;
  bool get canVoice => voice && !muted && !suspended;
  bool get canEffects => effects && !muted && !suspended;
  bool get canMusic => music && !muted && !suspended;
  void configure(ChildProfile p) {
    lowStimulation = p.lowStimulation;
    music = p.musicOn && !p.caregiverMode;
    voice = p.voiceOn;
    effects = p.effectsOn && !p.caregiverMode;
    notifyListeners();
  }

  void mute(bool value) {
    muted = value;
    notifyListeners();
  }

  void suspend(bool value) {
    suspended = value;
    notifyListeners();
  }
}
