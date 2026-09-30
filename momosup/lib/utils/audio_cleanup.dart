import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Drain pending stop events before closing the player's stream subscriptions.
Future<void> disposeAudioPlayer(AudioPlayer player) async {
  try { await player.stop(); } catch (_) { /* A failed device still needs cleanup. */ }
  try { await player.dispose(); }
  catch (error) { if (kDebugMode) debugPrint('Audio cleanup: $error'); }
}
