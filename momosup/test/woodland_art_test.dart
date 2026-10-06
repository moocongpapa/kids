import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/widgets/avatar_image.dart';
import 'package:momosup/widgets/forest_landscape.dart';
import 'package:momosup/widgets/games/feeding_game.dart';
import 'package:momosup/widgets/woodland_art.dart';

import 'woodland_visual_assets.dart';

Finder labelled(String label) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == label,
);

void main() {
  testWidgets('새 먹이주기는 입 벌리기·씹기·만족 순서이며 중복 입력은 한 번만 먹는다', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ForestLandscapeFrame(
          quiet: true,
          onExit: () {},
          onReplay: () {},
          child: FeedingGame(stage: 0, onComplete: () => completed++),
        ),
      ),
    );
    await precacheWoodlandArt(tester);
    await tester.pump();
    WoodlandMood mood() =>
        tester.widget<WoodlandCharacter>(find.byType(WoodlandCharacter)).mood;
    await tester.tap(labelled('딸기 먹이기'));
    await tester.pump();
    expect(mood(), WoodlandMood.open);
    expect(
      tester.widget<Semantics>(labelled('딸기 먹이기')).properties.enabled,
      isFalse,
    );
    await tester.tapAt(tester.getCenter(labelled('딸기 먹이기')));
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pump();
    expect(mood(), anyOf(WoodlandMood.chew, WoodlandMood.blink));
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(mood(), WoodlandMood.happy);
    expect(completed, 0);
    await tester.tap(labelled('산딸기 먹이기'));
    await tester.pump();
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(completed, 1);
    expect(find.byTooltip('한 번 더 먹이기'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('캐릭터 인사 도중 동작 줄이기를 켜면 인사와 프레임 요청이 멈춘다', (tester) async {
    Widget screen(bool quiet) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: quiet),
        child: const Scaffold(
          body: Center(child: AvatarImage(avatar: 'duri')),
        ),
      ),
    );
    await tester.pumpWidget(screen(false));
    await tester.tap(find.byType(AvatarImage));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpWidget(screen(true));
    await tester.pumpAndSettle();
    expect(
      tester.widget<WoodlandCharacter>(find.byType(WoodlandCharacter)).mood,
      WoodlandMood.idle,
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.tap(find.byType(AvatarImage));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('캐릭터와 조립 그림의 셀 경계에 이웃 그림이나 잘린 발이 없다', (tester) async {
    tester.view.physicalSize = const Size(960, 510);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFF7F1DE),
          body: Column(
            children: [
              Row(
                children: [
                  for (final mood in WoodlandMood.values)
                    WoodlandCharacter(avatar: 'momo', size: 120, mood: mood),
                ],
              ),
              Row(
                children: [
                  for (final avatar in ['duri', 'nuri'])
                    for (final mood in [
                      WoodlandMood.idle,
                      WoodlandMood.lookRight,
                      WoodlandMood.blink,
                      WoodlandMood.wave,
                    ])
                      WoodlandCharacter(avatar: avatar, size: 120, mood: mood),
                ],
              ),
              Row(
                children: [
                  for (var f = 0; f < 8; f++)
                    WoodlandSprite(
                      asset: woodlandArtAssets[4],
                      frame: f,
                      columns: 4,
                      rows: 3,
                      size: 120,
                    ),
                ],
              ),
              Row(
                children: [
                  for (var f = 8; f < 12; f++)
                    WoodlandSprite(
                      asset: woodlandArtAssets[4],
                      frame: f,
                      columns: 4,
                      rows: 3,
                      size: 140,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await precacheWoodlandArt(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/woodland_art_contact.png'),
    );
  });
}
