import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/utils/audio_policy.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    // Widget tests validate visual/interaction behavior, not device audio output.
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.just_audio.methods'),
      (call) async {
        if (call.method == 'disposeAllPlayers' ||
            call.method == 'disposePlayer') {
          return <String, dynamic>{};
        }
        throw PlatformException(code: 'audio_unavailable_in_widget_test');
      },
    );
  });
  tearDown(() {
    AudioPolicy.instance.resetForTesting();
  });
  await testMain();
}
