import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/utils/audio_output.dart';
import 'package:momosup/utils/audio_policy.dart';
import 'package:momosup/utils/narration_player.dart';
import 'package:momosup/utils/sound_effects.dart';

import 'age_journey_test.dart' as fixtures;

class FakeOutput implements AudioOutput {
  final loaded = <String>[], played = <String>[], volumes = <double>[];
  Completer<void>? loading, playback;
  String path = '';
  bool failLoad = false;
  @override
  Future<void> load(String value) async {
    loaded.add(value);
    if (failLoad) throw StateError('device unavailable');
    await loading?.future;
    path = value;
  }

  @override
  Future<void> volume(double value) async => volumes.add(value);
  @override
  Future<void> play() {
    played.add(path);
    playback = Completer<void>();
    return playback!.future;
  }

  void finish() {
    if (playback != null && !playback!.isCompleted) playback!.complete();
  }

  @override
  Future<void> stop() async => finish();
  @override
  Future<void> dispose() async => finish();
}

Future<void> flush() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    AudioPolicy.instance.configure(
      fixtures.baseProfile.copyWith(
        ageMonths: 48,
        voiceOn: true,
        effectsOn: true,
        lowStimulation: false,
      ),
    );
    AudioPolicy.instance.mute(false);
    AudioPolicy.instance.suspend(false);
  });
  test('연타는 문장을 재시작하지 않고 새 선택은 이전 안내를 대체한다', () async {
    final output = FakeOutput();
    final voice = NarrationPlayer(output: output);
    final first = voice.speak(['intro', 'old-followup']);
    await flush();
    final duplicate = voice.speak(['intro', 'old-followup']);
    await flush();
    expect(output.played, ['intro']);
    final next = voice.speak(['new-choice']);
    await flush();
    expect(output.played, ['intro', 'new-choice']);
    expect(output.loaded, isNot(contains('old-followup')));
    output.finish();
    await Future.wait([first, duplicate, next]);
    expect(AudioPolicy.instance.speaking, isFalse);
    voice.dispose();
    await flush();
  });
  test('로딩 중 음소거했다 풀어도 취소된 목소리가 늦게 나오지 않는다', () async {
    final output = FakeOutput()..loading = Completer<void>();
    final voice = NarrationPlayer(output: output);
    final speech = voice.speak(['intro']);
    await flush();
    AudioPolicy.instance.mute(true);
    AudioPolicy.instance.mute(false);
    output.loading!.complete();
    await speech;
    await flush();
    expect(output.played, isEmpty);
    expect(AudioPolicy.instance.speaking, isFalse);
    voice.dispose();
    await flush();
  });
  test('동시 로딩을 직렬화해 이전 안내가 최신 파일을 덮어쓰지 않는다', () async {
    final output = FakeOutput()..loading = Completer<void>();
    final voice = NarrationPlayer(output: output);
    final first = voice.speak(['old']);
    await flush();
    final next = voice.speak(['new']);
    output.loading!.complete();
    await flush();
    expect(output.loaded, ['old', 'new']);
    expect(output.played, ['new']);
    output.finish();
    await Future.wait([first, next]);
    voice.dispose();
    await flush();
  });
  test('종료 안내도 앱을 나가면 멈추고 복귀만으로 다시 말하지 않는다', () async {
    final output = FakeOutput();
    final voice = NarrationPlayer(output: output);
    final speech = voice.speak(['outro', 'offscreen']);
    await flush();
    voice.didChangeAppLifecycleState(AppLifecycleState.inactive);
    await speech;
    await flush();
    voice.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(output.played, ['outro']);
    expect(AudioPolicy.instance.speaking, isFalse);
    voice.dispose();
    await flush();
  });
  test('음성 오류 뒤 믹싱 상태가 풀리고 다시 듣기로 복구된다', () async {
    final output = FakeOutput()..failLoad = true;
    final voice = NarrationPlayer(output: output);
    await expectLater(voice.speak(['intro']), throwsStateError);
    expect(AudioPolicy.instance.speaking, isFalse);
    output.failLoad = false;
    final retry = voice.speak(['intro']);
    await flush();
    output.finish();
    await retry;
    expect(output.played, ['intro']);
    voice.dispose();
    await flush();
  });
  test('순차 안내와 효과음 덕킹·음성팩별 보정을 적용한다', () async {
    final output = FakeOutput();
    final voice = NarrationPlayer(output: output);
    final normal = AudioPolicy.instance.effectGain('sfx_pop');
    final speech = voice.speak([
      'assets/audio/intro.wav',
      'assets/audio/age_pack/step.m4a',
    ]);
    await flush();
    expect(output.played.length, 1);
    expect(AudioPolicy.instance.effectGain('sfx_pop'), lessThan(normal));
    output.finish();
    await flush();
    expect(output.played.length, 2);
    expect(output.volumes, [.65, 1]);
    output.finish();
    await speech;
    expect(AudioPolicy.instance.effectGain('sfx_pop'), normal);
    AudioPolicy.instance.configure(
      fixtures.baseProfile.copyWith(ageMonths: 48, lowStimulation: true),
    );
    expect(AudioPolicy.instance.effectGain('sfx_pop'), lessThan(normal));
    voice.dispose();
    await flush();
  });
  test('효과음은 100ms 연타를 합치고 동시 재생은 세 개 이하다', () async {
    final outputs = <FakeOutput>[];
    var now = DateTime(2026, 9, 30);
    final effects = SoundEffects.test(
      output: () {
        final out = FakeOutput();
        outputs.add(out);
        return out;
      },
      now: () => now,
    );
    final calls = [effects.pop(), effects.pop(), effects.pop()];
    await flush();
    expect(outputs.single.played.length, 1);
    now = now.add(const Duration(milliseconds: 150));
    calls.addAll([
      effects.playNote(0),
      effects.playNote(1),
      effects.playNote(2),
    ]);
    await flush();
    expect(
      outputs
          .where((o) => o.playback != null && !o.playback!.isCompleted)
          .length,
      3,
    );
    effects.stopAll();
    await Future.wait(calls);
    effects.dispose();
    await flush();
  });
  test('늦게 로드된 효과음은 중단·복귀 후 재생하지 않는다', () async {
    final output = FakeOutput()..loading = Completer<void>();
    final effects = SoundEffects.test(
      output: () => output,
      now: () => DateTime(2026, 9, 30),
    );
    final call = effects.pop();
    await flush();
    effects.didChangeAppLifecycleState(AppLifecycleState.inactive);
    effects.didChangeAppLifecycleState(AppLifecycleState.resumed);
    output.loading!.complete();
    await call;
    expect(output.played, isEmpty);
    effects.dispose();
    await flush();
  });
}
