import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/models/child_profile.dart';
import 'package:momosup/screens/dynamic_toy_screen.dart';
import 'package:momosup/state/app_state.dart';
import 'package:momosup/widgets/games/feeding_game.dart';
import 'package:momosup/widgets/games/sorting_game.dart';
import 'package:momosup/widgets/games/peekaboo_game.dart';
import 'package:momosup/widgets/games/xylophone_game.dart';
import 'package:momosup/widgets/games/silhouette_puzzle_game.dart';

void main() {
  const profile = ChildProfile(
    id: 'test_child',
    nickname: '모모친구',
    ageMonths: 48,
    avatar: 'momo',
    level: '기본',
    answers: [3, 3, 3, 3, 3],
  );

  testWidgets('1번 냠냠 열매 먹이기 놀이가 정상 렌더링되고 작동한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FeedingGame(),
        ),
      ),
    );

    expect(find.textContaining('모모에게 맛있는 열매'), findsOneWidget);
    expect(find.text('🍓'), findsOneWidget);
    expect(find.text('🍌'), findsOneWidget);
  });

  testWidgets('2번 도토리 쏙쏙 분류 놀이가 정상 렌더링되고 바구니가 표시된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SortingGame(),
        ),
      ),
    );

    expect(find.textContaining('큰 바구니'), findsOneWidget);
    expect(find.textContaining('아기 바구니'), findsOneWidget);
    expect(find.text('🌰'), findsWidgets);
  });

  testWidgets('3번 살랑살랑 풀숲 까꿍 놀이에서 덤불을 터치하면 모모가 나타난다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PeekabooGame(),
        ),
      ),
    );

    expect(find.text('누구게? 톡!'), findsWidgets);

    // Tap first bush
    await tester.tap(find.text('초록 풀숲'));
    await tester.pump();

    expect(find.textContaining('까꿍! 덤불 뒤에서 아기 곰 모모가 나타났어'), findsOneWidget);
  });

  testWidgets('4번 통통 튀는 물방울 실로폰 음계가 렌더링된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: XylophoneGame(),
        ),
      ),
    );

    expect(find.text('도'), findsOneWidget);
    expect(find.text('솔'), findsOneWidget);
    expect(find.text('높은도'), findsOneWidget);

    await tester.tap(find.text('도'));
    await tester.pump();
  });

  testWidgets('5번 숲속 친구들 실루엣 퍼즐이 렌더링된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SilhouettePuzzleGame(),
        ),
      ),
    );

    expect(find.textContaining('깜장 그림자가 있어요'), findsOneWidget);
    expect(find.text('모모'), findsOneWidget);
    expect(find.text('두리'), findsOneWidget);
    expect(find.text('누리'), findsOneWidget);
  });

  testWidgets('DynamicToyScreen 래퍼가 정상적으로 도장 쾅 마무리를 제공한다', (tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      MaterialApp(
        home: DynamicToyScreen(
          toyType: DynamicToyType.feeding,
          appState: appState,
          profile: profile,
        ),
      ),
    );

    expect(find.text('🥕 냠냠 열매 먹이기'), findsOneWidget);
    expect(find.textContaining('놀이 마치기'), findsOneWidget);

    // Tap finish
    await tester.tap(find.textContaining('놀이 마치기').last);
    await tester.pumpAndSettle();

    expect(find.text('숲 탐험 도장 쾅! 참 잘했어요'), findsOneWidget);
    expect(find.text('숲으로 돌아가기'), findsOneWidget);
  });
}
