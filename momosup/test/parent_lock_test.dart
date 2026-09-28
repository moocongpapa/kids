import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/screens/parent_screen.dart';

void main() {
  testWidgets('보호자 화면은 5분 뒤 아이 화면으로 돌아간다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ParentSessionGuard(
                    child: Scaffold(body: Text('보호자 민감 화면')),
                  ),
                ),
              ),
              child: const Text('아이 화면'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('아이 화면'));
    await tester.pumpAndSettle();
    expect(find.text('보호자 민감 화면'), findsOneWidget);
    await tester.pump(const Duration(minutes: 5));
    await tester.pumpAndSettle();
    expect(find.text('보호자 민감 화면'), findsNothing);
    expect(find.text('아이 화면'), findsOneWidget);
  });
}
