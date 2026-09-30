import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/toy_audio_repository.dart';
import 'package:momosup/screens/dynamic_toy_screen.dart';
import 'package:momosup/utils/audio_policy.dart';
import 'package:momosup/utils/toy_music_player.dart';
import 'package:momosup/widgets/games/peekaboo_game.dart';
import 'package:momosup/widgets/games/xylophone_game.dart';

import 'age_journey_test.dart' as fixtures;
import 'audio_placement_test.dart' as audio;

class ChangedBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => rootBundle.load(key);
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final json =
        jsonDecode(await rootBundle.loadString(key)) as Map<String, dynamic>;
    final job = (json['jobs'] as List).firstWhere(
      (j) => j['id'] == 'toy_feeding_intro',
    );
    job['text'] = '바뀐 대사';
    return jsonEncode(json);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    AudioPolicy.instance.mute(false);
    AudioPolicy.instance.suspend(false);
    AudioPolicy.instance.configure(
      fixtures.baseProfile.copyWith(
        ageMonths: 48,
        musicOn: true,
        lowStimulation: false,
      ),
    );
  });
  test('완성된 안내 16개와 음악 2곡은 해시가 맞고 실로폰에는 BGM이 없다', () async {
    final pack = await ToyAudioRepository().load();
    expect(pack.voices.length, 5);
    expect(pack.voices.values.fold<int>(0, (n, v) => n + v.length), 16);
    expect(pack.music.length, 4);
    expect(pack.music.values.toSet().length, 2);
    expect(pack.music['xylophone'], isNull);
    final changed = await ToyAudioRepository(bundle: ChangedBundle()).load();
    expect(changed.cue('feeding', 'intro'), isNull);
    expect(changed.cue('feeding', 'outro'), isNotNull);
  });
  test('음악은 안내 중 낮아지고 반복 후 종료·음소거에서 멈춘다', () async {
    final output = audio.FakeOutput();
    final music = ToyMusicPlayer(output: output);
    music.start('picnic');
    await audio.flush();
    expect(output.played, ['picnic']);
    final speech = Object();
    AudioPolicy.instance.beginSpeech(speech);
    await audio.flush();
    expect(output.volumes.last, .08);
    AudioPolicy.instance.endSpeech(speech);
    await audio.flush();
    expect(output.volumes.last, .30);
    output.finish();
    await audio.flush();
    expect(output.played.length, 2);
    AudioPolicy.instance.mute(true);
    await audio.flush();
    expect(output.playback!.isCompleted, isTrue);
    AudioPolicy.instance.mute(false);
    await audio.flush();
    expect(output.played.length, 3);
    music.stop();
    await audio.flush();
    AudioPolicy.instance.suspend(true);
    AudioPolicy.instance.suspend(false);
    await audio.flush();
    expect(output.played.length, 3);
    music.dispose();
    await audio.flush();
  });
  test('음악 로딩 도중 나가면 늦은 자동 재생이 없다', () async {
    final output = audio.FakeOutput()..loading = Completer<void>();
    final music = ToyMusicPlayer(output: output);
    music.start('picnic');
    await audio.flush();
    music.stop();
    output.loading!.complete();
    await audio.flush();
    expect(output.played, isEmpty);
    music.dispose();
    await audio.flush();
  });

  final fixturePack = ToyAudioPack({
    for (final toy in DynamicToyType.values)
      toy.name: {
        for (final cue in ['intro', 'complete', 'outro', 'follow'])
          cue: '${toy.name}-$cue',
      },
  }, const {});
  for (final toy in DynamicToyType.values) {
    testWidgets('${toy.name}: 입장·다시 듣기·휴식 음성이 연결되고 미리보기는 기록하지 않는다', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final state = await fixtures.prepare(48);
      final played = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: DynamicToyScreen(
            toyType: toy,
            appState: state,
            profile: state.activeProfile!.copyWith(
              musicOn: false,
              effectsOn: false,
              playStage: 0,
            ),
            preview: true,
            audioPack: fixturePack,
            playAsset: (path) async {
              played.add(path);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(played, ['${toy.name}-intro']);
      await tester.tap(find.byTooltip('안내 다시 듣기'));
      await tester.pumpAndSettle();
      expect(played.length, 2);
      if (toy == DynamicToyType.peekaboo) {
        final control = find
            .byWidgetPredicate(
              (w) =>
                  w is Semantics &&
                  (w.properties.label?.contains('찾기') ?? false),
            )
            .first;
        await tester.tap(control);
        await tester.pumpAndSettle();
        expect(played.last, 'peekaboo-complete');
        // An already-found friend cannot repeat the completion voice.
        await tester.tap(control);
        await tester.pumpAndSettle();
        expect(played.where((p) => p == 'peekaboo-complete').length, 1);
        expect(
          state.workFor(state.activeProfile!.id, 'sticker_peekaboo'),
          isNull,
        );
      }
      await tester.tap(find.byTooltip('놀이 마치기').first);
      await tester.pumpAndSettle();
      expect(played.last, '${toy.name}-outro');
      expect(find.byType(PeekabooGame), findsNothing);
      expect(state.records, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('실로폰 따라 하기 안내가 있고 건반은 목소리를 멈추는 신호를 보낸다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var notes = 0;
    final modes = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: XylophoneGame(
            stage: 0,
            lowStimulation: true,
            onNote: () => notes++,
            onModeChanged: modes.add,
          ),
        ),
      ),
    );
    Finder note(String text) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == '$text 음 연주',
    );
    await tester.tap(note('도'));
    await tester.pump();
    await tester.tap(note('레'));
    await tester.pump();
    expect(notes, 2);
    await tester.tap(find.byTooltip('따라하기'));
    await tester.pump();
    expect(modes, [true]);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
