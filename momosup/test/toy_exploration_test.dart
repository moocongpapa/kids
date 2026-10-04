import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/widgets/games/peekaboo_game.dart';
import 'package:momosup/widgets/games/silhouette_puzzle_game.dart';
import 'package:momosup/widgets/games/sorting_game.dart';
import 'package:momosup/widgets/games/xylophone_game.dart';

Finder labelled(String label) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == label,
);

void main() {
  Future<void> show(WidgetTester tester, Widget game) async {
    tester.view.physicalSize = const Size(390, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.fromLTRB(42, 30, 16, 16),
            child: game,
          ),
        ),
      ),
    );
  }

  testWidgets('한 친구 찾기도 완성 후 아이가 다시 숨길 때만 새 놀이가 열린다', (tester) async {
    var completed = 0;
    await show(
      tester,
      PeekabooGame(
        stage: 0,
        lowStimulation: true,
        onComplete: () => completed++,
      ),
    );
    expect(labelled('전체 1개 중 0개'), findsOneWidget);
    await tester.tap(labelled('풀숲 속 모모 찾기'));
    await tester.pump();
    expect(completed, 1);
    expect(labelled('전체 1개 중 1개'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('까꿍!'), findsOneWidget);
    await tester.tap(find.byTooltip('친구들 다시 숨기기'));
    await tester.pump();
    expect(labelled('전체 1개 중 0개'), findsOneWidget);
    expect(find.text('까꿍!'), findsNothing);
    await tester.tap(labelled('풀숲 속 모모 찾기'));
    await tester.pump();
    expect(completed, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('두 단계 까꿍은 살짝 보기 후 찾고 친구를 다시 눌러도 중복 집계하지 않는다', (tester) async {
    await show(tester, const PeekabooGame(stage: 2, lowStimulation: true));
    await tester.tap(labelled('풀숲 속 모모 찾기'));
    await tester.pump();
    expect(labelled('전체 3개 중 0개'), findsOneWidget);
    await tester.tap(labelled('풀숲 속 모모 찾기'));
    await tester.pump();
    await tester.tap(labelled('풀숲 속 모모 찾기'));
    await tester.pump();
    expect(labelled('전체 3개 중 1개'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('탭으로 고른 도토리는 화면 여백에 관계없이 도토리 자리에서 날아간다', (tester) async {
    await show(tester, const SortingGame(lowStimulation: false));
    final acorn = labelled('큰 도토리 1');
    // The tray can be horizontally scrolled on a narrow phone.
    await tester.ensureVisible(acorn);
    final expectedStart =
        tester.getCenter(acorn) - tester.getTopLeft(find.byType(SortingGame));
    await tester.tap(acorn);
    await tester.pump();
    await tester.tap(labelled('큰 바구니'));
    await tester.pump();
    final flight = tester.widget<FlyingAcornWidget>(
      find.byType(FlyingAcornWidget),
    );
    expect((flight.start - expectedStart).distance, lessThan(1));
    expect(labelled('전체 6개 중 1개'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('작은 건반도 손가락을 떼지 않고 훑어 연주하며 건반 밖에서는 소리가 나지 않는다', (tester) async {
    var notes = 0;
    await show(
      tester,
      XylophoneGame(lowStimulation: true, onNote: () => notes++),
    );
    final first = tester.getCenter(labelled('도 음 연주'));
    final second = tester.getCenter(labelled('레 음 연주'));
    final gesture = await tester.startGesture(first);
    await tester.pump();
    expect(notes, 1);
    await gesture.moveTo(second);
    await tester.pump();
    expect(notes, 2);
    await gesture.moveTo(const Offset(5, 5));
    await tester.pump();
    expect(notes, 2);
    await gesture.up();
    expect(tester.takeException(), isNull);
  });

  testWidgets('따라 연주 완성 후 다음 노래를 직접 고르고 다시 완성할 수 있다', (tester) async {
    var completed = 0;
    await show(
      tester,
      XylophoneGame(
        stage: 0,
        lowStimulation: true,
        onComplete: () => completed++,
      ),
    );
    for (final note in ['도', '레']) {
      await tester.tap(labelled('$note 음 연주'));
      await tester.pump();
    }
    await tester.tap(find.byTooltip('따라하기'));
    await tester.pump();
    for (final note in ['도', '레']) {
      await tester.tap(labelled('$note 음 연주'));
      await tester.pump();
    }
    expect(completed, 1);
    await tester.tap(find.byTooltip('다른 노래 불러보기'));
    await tester.pump();
    for (final note in ['도', '미']) {
      await tester.tap(labelled('$note 음 연주'));
      await tester.pump();
    }
    expect(completed, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('저자극 그림자 조각은 완성 뒤 계속 흔들리지 않는다', (tester) async {
    await show(
      tester,
      const SilhouettePuzzleGame(lowStimulation: true, stage: 0),
    );
    await tester.tap(labelled('모모 퍼즐 조각'));
    await tester.pump();
    await tester.tap(labelled('모모 그림자'));
    await tester.pumpAndSettle();
    expect(labelled('전체 2개 중 1개'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}
