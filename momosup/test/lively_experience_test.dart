import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/utils/sound_effects.dart';
import 'package:momosup/widgets/avatar_image.dart';
import 'package:momosup/widgets/woodland_art.dart';
import 'package:momosup/widgets/bouncy_tap.dart';
import 'package:momosup/widgets/forest_background.dart';
import 'package:momosup/widgets/forest_coloring_studio.dart';
import 'package:momosup/widgets/forest_game_ui.dart';
import 'package:momosup/widgets/living_creation_overlay.dart';
import 'package:momosup/widgets/touch_trail.dart';

void main() {
  group('1. Magic Touch Trail Tests', () {
    testWidgets('화면 터치 및 드래그 시 마법 파티클이 정상 생성되고 렌더링된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ForestTouchTrail(
              child: SizedBox.expand(
                child: Center(child: Text('숲속 놀이터')),
              ),
            ),
          ),
        ),
      );

      expect(find.text('숲속 놀이터'), findsOneWidget);

      // Trigger pointer down and move gestures
      final gesture = await tester.startGesture(const Offset(100, 100));
      await tester.pump(const Duration(milliseconds: 30));
      await gesture.moveTo(const Offset(150, 150));
      await tester.pump(const Duration(milliseconds: 30));
      await gesture.moveTo(const Offset(200, 180));
      await tester.pump(const Duration(milliseconds: 30));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));

      // CustomPaint for trail should be active in the tree
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ForestBackground에 ForestTouchTrail이 포함되어 전체 화면에 터치 효과가 동작한다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ForestBackground(
              lowStimulation: false,
              child: Text('홈 화면'),
            ),
          ),
        ),
      );

      expect(find.byType(ForestTouchTrail), findsOneWidget);
    });
  });

  group('2. Living Creations Animation Tests', () {
    testWidgets('도안 카테고리별(탈것, 동물, 사물)로 살아난 스케치북 연출이 올바른 자막과 모션을 표시한다', (tester) async {
      final busTemplate = ColoringCatalog.vehicles.first;
      final segments = busTemplate.createSegments();
      // Color first segment
      segments[0].color = Colors.amber;

      var closed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LivingCreationOverlay(
              template: busTemplate,
              segments: segments,
              quiet: true,
              onClose: () => closed = true,
            ),
          ),
        ),
      );

      expect(find.text('내가 칠한 붕붕 버스!'), findsOneWidget);
      expect(find.text('부릉부릉~ 살아서 신나게 달려요! 🚗'), findsOneWidget);

      // Tap on the living artwork
      await tester.tap(find.text('내가 칠한 붕붕 버스!'));
      await tester.pump(const Duration(milliseconds: 100));

      // Close the overlay
      await tester.tap(find.text('숲으로 쏙!'));
      expect(closed, isTrue);
    });

    testWidgets('ForestColoringStudio에서 "살아나기" 버튼을 누르면 LivingCreationOverlay가 열린다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ForestColoringStudio(quiet: true),
            ),
          ),
        ),
      );

      // Verify "살아나기" button exists
      expect(find.text('살아나기'), findsOneWidget);

      await tester.tap(find.text('살아나기'));
      await tester.pump();

      // Living overlay appears with artwork title
      expect(find.byType(LivingCreationOverlay), findsOneWidget);
      expect(find.text('내가 칠한 포근 토끼!'), findsOneWidget);
      expect(find.text('깡충깡충~ 살아서 춤을 춰요! 🐾'), findsOneWidget);

      // Tap close button in overlay
      await tester.tap(find.text('다시 칠하기'));
      await tester.pump();

      expect(find.byType(LivingCreationOverlay), findsNothing);
    });
  });

  group('3. Living Characters & AvatarImage Tests', () {
    testWidgets('캐릭터가 터치한 아이를 바라보고 인사한 뒤 쉬는 표정으로 돌아온다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AvatarImage(
                avatar: 'momo',
                size: 120,
                interactive: true,
                lowStimulation: false,
              ),
            ),
          ),
        ),
      );

      // Initially character image is rendered
      expect(find.byType(AvatarImage), findsOneWidget);

      // Tap character
      await tester.tap(find.byType(AvatarImage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.widget<WoodlandCharacter>(find.byType(WoodlandCharacter)).mood, WoodlandMood.lookRight);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.widget<WoodlandCharacter>(find.byType(WoodlandCharacter)).mood, WoodlandMood.wave);

      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.widget<WoodlandCharacter>(find.byType(WoodlandCharacter)).mood, WoodlandMood.idle);
    });
  });

  group('4. Bouncy Spring Physics & Musical Sound Tests', () {
    testWidgets('BouncyTap 위젯이 누르고 뗄 때 탄성 변형(scale)과 탭 콜백을 실행한다', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BouncyTap(
                musicalSound: true,
                onTap: () => tapped = true,
                child: const Text('젤리 버튼'),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('젤리 버튼')));
      await tester.pump(const Duration(milliseconds: 100));

      // Up gesture triggers tap
      await gesture.up();
      await tester.pump();

      expect(tapped, isTrue);
    });

    test('SoundEffects.instance.musicalTap()이 에러 없이 순환 음계를 재생한다', () async {
      // Calling musicalTap multiple times rotates pentatonic steps smoothly
      await SoundEffects.instance.musicalTap();
      await SoundEffects.instance.musicalTap();
      await SoundEffects.instance.musicalTap();
      await SoundEffects.instance.musicalTap();
      await SoundEffects.instance.musicalTap();
    });
  });
}
