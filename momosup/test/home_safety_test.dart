import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/catalog_repository.dart';
import 'package:momosup/models/child_profile.dart';
import 'package:momosup/screens/home_screen.dart';
import 'package:momosup/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('보호자 미승인 놀이가 아이 홈에 노출되지 않는다', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final appState = AppState();
    await appState.load();
    await appState.setParentPin('123456');
    await appState.addProfile(
      const ChildProfile(
        id: 'test',
        nickname: '아이',
        ageMonths: 48,
        avatar: 'momo',
        level: '기본',
        answers: [3, 3, 3, 3, 3],
      ),
    );
    final catalog = await const CatalogRepository().load();
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(appState: appState, catalog: catalog),
      ),
    );
    expect(find.text('누구의 발자국일까?'), findsNothing);
    expect(find.textContaining('보호자 검수가 끝나면'), findsOneWidget);
    expect(find.byTooltip('보호자 영역'), findsOneWidget);
  });
}
