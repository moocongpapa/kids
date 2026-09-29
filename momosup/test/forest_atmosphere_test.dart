import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/utils/forest_audio.dart';
import 'package:momosup/widgets/forest_background.dart';
import 'package:momosup/widgets/living_forest_scene.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.just_audio.methods'),
      (MethodCall methodCall) async => {},
    );
  });

  group('ForestAudio tests', () {
    test('음소거 토글 및 시작/정지 동작 검증', () {
      final audio = ForestAudio.instance;
      expect(audio.isMuted.value, isFalse);

      audio.toggleMute();
      expect(audio.isMuted.value, isTrue);

      audio.toggleMute();
      expect(audio.isMuted.value, isFalse);
    });
  });

  group('ForestBackground widget tests', () {
    testWidgets('일반 및 저자극 모드에서 정상 렌더링', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ForestBackground(
              lowStimulation: false,
              child: Text('Forest content'),
            ),
          ),
        ),
      );
      expect(find.text('Forest content'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ForestBackground(
              lowStimulation: true,
              child: Text('Forest content low-stim'),
            ),
          ),
        ),
      );
      expect(find.text('Forest content low-stim'), findsOneWidget);
    });
  });

  group('LivingForestScene widget tests', () {
    testWidgets('살아 움직이는 캐릭터들이 렌더링되고 터치 시 말풍선 반응', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LivingForestScene(lowStimulation: false),
            ),
          ),
        ),
      );

      // Verify Momo, Duri, Nuri labels
      expect(find.text('모모'), findsOneWidget);
      expect(find.text('두리'), findsOneWidget);
      expect(find.text('누리'), findsOneWidget);

      // Tap on Momo
      await tester.tap(find.text('모모'));
      await tester.pump();

      // Verify bubble appeared
      expect(find.textContaining('모모숲에 온 걸 환영해!'), findsOneWidget);

      // Tap on Duri
      await tester.tap(find.text('두리'));
      await tester.pump();

      // Verify Duri's bubble appeared
      expect(find.textContaining('숲으로 신나는 모험을 가자!'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    });
  });
}
