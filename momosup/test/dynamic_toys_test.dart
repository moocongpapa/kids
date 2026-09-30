import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/models/child_profile.dart';
import 'package:momosup/screens/dynamic_toy_screen.dart';
import 'package:momosup/state/app_state.dart';
import 'package:momosup/widgets/games/feeding_game.dart';
import 'package:momosup/widgets/games/sorting_game.dart';
import 'package:momosup/widgets/games/peekaboo_game.dart';
import 'package:momosup/widgets/games/xylophone_game.dart';
import 'package:momosup/widgets/games/silhouette_puzzle_game.dart';

Finder labelled(String label) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == label,
);
void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  Future<void> show(WidgetTester tester, Widget game) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: game),
        ),
      ),
    );
  }

  testWidgets('열매는 탭으로도 먹일 수 있고 같은 열매를 중복 집계하지 않는다', (tester) async {
    await show(tester, const FeedingGame(lowStimulation: true));
    await tester.tap(labelled('딸기 먹이기'));
    await tester.pump();
    expect(find.text('냠냠!'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750));
    await tester.tap(labelled('딸기 먹이기'));
    await tester.pump();
    expect(labelled('전체 4개 중 1개'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('도토리 탭 선택과 바구니 탭으로 크기를 맞춘다', (tester) async {
    await show(tester, const SortingGame(lowStimulation: true));
    await tester.tap(labelled('큰 도토리 1'));
    await tester.pump();
    await tester.tap(labelled('작은 바구니'));
    await tester.pump();
    expect(labelled('전체 6개 중 0개'), findsOneWidget);
    await tester.tap(labelled('큰 바구니'));
    await tester.pump();
    expect(labelled('전체 6개 중 1개'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('풀숲을 누르면 친구가 나타나고 세 친구를 찾는다', (tester) async {
    var completed = false;
    await show(
      tester,
      PeekabooGame(lowStimulation: true, onComplete: () => completed = true),
    );
    for (final label in ['풀숲 속 모모 찾기', '나무 뒤 두리 찾기', '꽃밭 속 누리 찾기']) {
      await tester.tap(labelled(label));
      await tester.pump();
    }
    expect(find.text('까꿍!'), findsNWidgets(3));
    expect(completed, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('작은 휴대폰에서도 여덟 악기 버튼이 최소 60 크기로 배치된다', (tester) async {
    await show(tester, const XylophoneGame(lowStimulation: true));
    for (final note in ['도', '레', '미', '파', '솔', '라', '시', '높은 도']) {
      final control = labelled('$note 음 연주');
      expect(tester.getSize(control).width, greaterThanOrEqualTo(60));
      await tester.tap(control);
      await tester.pump();
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets('그림자 퍼즐은 다른 친구를 거부하고 맞는 친구를 받는다', (tester) async {
    await show(tester, const SilhouettePuzzleGame(lowStimulation: true));
    await tester.tap(labelled('모모 퍼즐 조각'));
    await tester.pump();
    await tester.tap(labelled('두리 그림자'));
    await tester.pump();
    expect(labelled('전체 3개 중 0개'), findsOneWidget);
    await tester.tap(labelled('모모 그림자'));
    await tester.pump();
    expect(labelled('전체 3개 중 1개'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('마치기는 쉼 화면으로 이동하고 다음 게임을 시작하지 않는다', (tester) async {
    const profile = ChildProfile(
      id: 'test',
      nickname: '아이',
      ageMonths: 48,
      avatar: 'momo',
      level: '기본',
      answers: [3, 3, 3, 3, 3],
      lowStimulation: true,
    );
    final state = AppState();
    await show(
      tester,
      DynamicToyScreen(
        playAsset: (_) async {},
        toyType: DynamicToyType.feeding,
        appState: state,
        profile: profile,
      ),
    );
    await tester.tap(find.byTooltip('놀이 마치기').first);
    await tester.pumpAndSettle();
    expect(find.text('즐거웠어!'), findsOneWidget);
    expect(find.byTooltip('숲으로 돌아가기'), findsOneWidget);
    expect(find.byType(FeedingGame), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
