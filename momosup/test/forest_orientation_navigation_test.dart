import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/utils/forest_orientation.dart';

const landscape = [
  'DeviceOrientation.landscapeLeft',
  'DeviceOrientation.landscapeRight',
];
const portrait = ['DeviceOrientation.portraitUp'];

Widget childPage(String name) =>
    ForestOrientationScope(child: Scaffold(body: Text(name)));

List<List<String>> recordOrientations(WidgetTester tester) {
  final calls = <List<String>>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        calls.add(List<String>.from(call.arguments as List));
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

void main() {
  testWidgets('아이 화면의 push·pop·교체·홈 복귀에는 세로 요청이 끼어들지 않는다', (tester) async {
    final calls = recordOrientations(tester);

    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        navigatorObservers: [forestOrientationObserver],
        home: childPage('아이 홈'),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls.last, landscape);
    calls.clear();

    for (final name in ['놀이 목록', '놀이', '이야기숲', '영상']) {
      nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => childPage(name)),
      );
      await tester.pumpAndSettle();
      expect(calls, isEmpty, reason: '$name으로 이동하면서 방향을 다시 요청하지 않아야 한다');
    }

    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(calls, isEmpty, reason: '뒤로 갈 때도 가로를 유지해야 한다');

    nav.currentState!.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => childPage('새 이야기')),
    );
    await tester.pumpAndSettle();
    expect(calls, isEmpty, reason: '화면 교체도 가로를 유지해야 한다');

    nav.currentState!.popUntil((route) => route.isFirst);
    await tester.pumpAndSettle();
    expect(calls, isEmpty, reason: '여러 화면을 한 번에 닫아도 가로를 유지해야 한다');

    tester.binding.addPostFrameCallback((_) {
      nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => childPage('자동으로 열린 놀이')),
      );
    });
    tester.binding.scheduleFrame();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(calls, isEmpty, reason: '프레임 종료 뒤의 화면 이동에도 가로를 유지해야 한다');

    // Navigation after the new home builds must wait for the following page's
    // scope instead of resolving from this frame's now-inactive pages.
    tester.binding.addPostFrameCallback((_) {
      nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => childPage('자동으로 열린 이야기')),
      );
    });
    nav.currentState!.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => childPage('새 아이 홈')),
      (_) => false,
    );
    await tester.pumpAndSettle();
    expect(calls, isEmpty, reason: '경로 제거와 프레임 종료 후 이동이 겹쳐도 가로를 유지해야 한다');

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('보호자 전환·미리보기·앱 복귀·홈 모드 변경은 필요한 방향만 요청한다', (tester) async {
    final calls = recordOrientations(tester);
    final nav = GlobalKey<NavigatorState>();
    final mode = ValueNotifier(ForestOrientation.landscape);
    addTearDown(mode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        navigatorObservers: [forestOrientationObserver],
        home: ValueListenableBuilder<ForestOrientation>(
          valueListenable: mode,
          builder: (_, value, _) => ForestOrientationScope(
            mode: value,
            child: const Scaffold(body: Text('홈')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls.last, landscape);
    calls.clear();

    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('보호자')),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, [portrait]);
    calls.clear();

    nav.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => childPage('놀이 미리보기')),
    );
    await tester.pumpAndSettle();
    expect(calls, [landscape]);
    calls.clear();

    showModalBottomSheet<void>(
      context: nav.currentContext!,
      builder: (_) => const SizedBox(height: 100, child: Text('팝업')),
    );
    await tester.pumpAndSettle();
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(calls, isEmpty);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(calls, [landscape]);
    calls.clear();

    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(calls, [portrait]);
    calls.clear();

    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(calls, [landscape]);
    calls.clear();

    mode.value = ForestOrientation.portrait;
    await tester.pumpAndSettle();
    expect(calls, [portrait]);
    calls.clear();
    mode.value = ForestOrientation.landscape;
    await tester.pumpAndSettle();
    expect(calls, [landscape]);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
