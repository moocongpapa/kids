import 'package:flutter/foundation.dart';

import '../models/child_profile.dart';

/// One policy for all games. Muting never changes the parent's saved settings.
class AudioPolicy extends ChangeNotifier {
  static final instance = AudioPolicy();
  bool music = true,
      voice = true,
      effects = true,
      muted = false,
      suspended = false;
  bool get canVoice => voice && !muted && !suspended;
  bool get canEffects => effects && !muted && !suspended;
  bool get canMusic => music && !muted && !suspended;
  void configure(ChildProfile p) {
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
