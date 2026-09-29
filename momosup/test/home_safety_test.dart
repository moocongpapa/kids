import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/catalog_repository.dart';
import 'package:momosup/models/activity.dart';
import 'package:momosup/models/child_profile.dart';
import 'package:momosup/screens/home_screen.dart';
import 'package:momosup/state/app_state.dart';

const profile = ChildProfile(
  id: 'test',
  nickname: '아이',
  ageMonths: 48,
  avatar: 'momo',
  level: '기본',
  answers: [3, 3, 3, 3, 3],
  lowStimulation: true,
);
Future<AppState> stateForHome() async {
  FlutterSecureStorage.setMockInitialValues({});
  final state = AppState();
  await state.load();
  await state.setParentPin('123456');
  await state.addProfile(profile);
  return state;
}

void main() {
  testWidgets('미승인 놀이를 그림 메뉴에서도 노출하지 않는다', (tester) async {
    final state = await stateForHome();
    final source = jsonDecode(
      await rootBundle.loadString('assets/content/catalog.json'),
    ) as Map<String, dynamic>;
    final drafts = (source['activities'] as List).map((row) {
      final item = Map<String, dynamic>.from(row as Map);
      item['humanApprovedAt'] = null;
      return Activity.fromJson(item);
    }).toList();
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(appState: state, catalog: drafts),
      ),
    );
    await tester.tap(find.byTooltip('이야기숲'));
    await tester.pumpAndSettle();
    expect(find.text('곧 만나요'), findsOneWidget);
    expect(find.byTooltip('보호자 영역'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('모든 승인 놀이가 모드별로 접근 가능하고 시간 종료 시 감각 놀이도 잠긴다', (tester) async {
    final state = await stateForHome();
    final catalog = await const CatalogRepository().load();
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(appState: state, catalog: catalog),
      ),
    );
    for (final entry in [
      ('이야기숲', PlayMode.touch),
      ('그림숲', PlayMode.color),
      ('노래숲', PlayMode.move),
    ]) {
      await tester.tap(find.byTooltip(entry.$1));
      await tester.pumpAndSettle();
      for (final activity in catalog.where((a) => a.mode == entry.$2)) {
        expect(
          find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == activity.title,
          ),
          findsOneWidget,
        );
      }
    }
    for (var i = 0; i < 4; i++) {
      await state.recordPlay(
        profileId: profile.id,
        activityId: 'test',
        seconds: 5 * 60,
      );
    }
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('감각 놀이숲'));
    await tester.pumpAndSettle();
    expect(find.text('숲도 쉬는 시간'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == '열매 먹이기',
      ),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
