import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/game/forest_world_scene.dart';

void main() {
  test('작은 가로 화면과 세로 화면의 숲 입구가 겹치거나 작아지지 않는다', () {
    for (final size in [
      const Size(480, 113),
      const Size(756, 190),
      const Size(320, 360),
    ]) {
      for (var count = 1; count <= 5; count++) {
        final rects = ForestWorldLayout(size, count).portals;
        for (var i = 0; i < rects.length; i++) {
          expect(rects[i].shortestSide, greaterThanOrEqualTo(64));
          expect(rects[i].left, greaterThanOrEqualTo(0));
          expect(rects[i].right, lessThanOrEqualTo(size.width));
          expect(rects[i].top, greaterThanOrEqualTo(0));
          expect(rects[i].bottom, lessThanOrEqualTo(size.height));
          for (final next in rects.skip(i + 1)) {
            expect(rects[i].overlaps(next), isFalse);
          }
        }
      }
    }
  });

  testWidgets('Flame 숲은 숨겨지거나 차분한 모드일 때 멈추고 복귀 때 설정을 따른다', (tester) async {
    Widget world({
      bool quiet = false,
      bool visible = true,
      bool reduced = false,
    }) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: TickerMode(
          enabled: visible,
          child: ForestWorldScene(
            count: 4,
            area: 0,
            quiet: quiet,
            child: const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pumpWidget(world(quiet: true));
    await tester.pumpAndSettle();
    final game = tester
        .widget<GameWidget<ForestWorldGame>>(
          find.byType(GameWidget<ForestWorldGame>),
        )
        .game!;
    expect(game.paused, isTrue);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(world());
    await tester.pump(const Duration(milliseconds: 200));
    expect(game.paused, isFalse);
    await tester.pumpWidget(world(visible: false));
    await tester.pumpAndSettle();
    expect(game.paused, isTrue);

    await tester.pumpWidget(world(reduced: true));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(game.paused, isTrue);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
