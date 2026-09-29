import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/utils/forest_audio.dart';
import 'package:momosup/widgets/forest_background.dart';
import 'package:momosup/widgets/forest_game_ui.dart';

void main() {
  test('숲 소리 음소거 토글', () {
    final audio = ForestAudio.instance;
    audio.toggleMute();
    expect(audio.isMuted.value, isTrue);
    audio.toggleMute();
    expect(audio.isMuted.value, isFalse);
  });
  testWidgets('차분한 모드로 바꾸면 숲과 사물의 반복 움직임이 멈춘다', (tester) async {
    Widget world(bool quiet) => MaterialApp(
      home: Scaffold(
        body: ForestBackground(
          lowStimulation: quiet,
          child: ForestFloat(still: quiet, child: const Text('숲속 친구')),
        ),
      ),
    );
    await tester.pumpWidget(world(false));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('숲속 친구'), findsOneWidget);
    await tester.pumpWidget(world(true));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(find.byType(CustomPaint), findsWidgets);
  });
  testWidgets('운영체제 움직임 줄이기도 반복 효과를 멈춘다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: ForestBackground(child: ForestFloat(child: Text('고요한 숲'))),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
