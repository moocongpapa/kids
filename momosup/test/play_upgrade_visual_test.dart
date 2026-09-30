import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/age_journey_repository.dart';
import 'package:momosup/data/catalog_repository.dart';
import 'package:momosup/screens/play_library_screen.dart';
import 'package:momosup/screens/observation_screen.dart';
import 'package:momosup/screens/journey_screen.dart';
import 'age_journey_test.dart' as fixtures;

void main() {
  setUpAll(() async {
    fixtures.fixture = await fixtures.readDrafts(); fixtures.approvedPack = await AgeJourneyRepository().load();
    for(final (family,path) in [('NotoSansKR','assets/fonts/NotoSansKR-wght.ttf'),('MaterialIcons','fonts/MaterialIcons-Regular.otf')]) {
      await (FontLoader(family)..addFont(rootBundle.load(path))).load();
    }
  });
  for(final page in ['library','observation','bridge_repair','detective']) {
    testWidgets('개선 화면 $page', (tester) async {
      tester.view.physicalSize = const Size(390,844); tester.view.devicePixelRatio = 1;
      addTearDown(() {tester.view.resetPhysicalSize();tester.view.resetDevicePixelRatio();});
      final state=await fixtures.prepare(page == 'bridge_repair' ? 72 : 48); state.journeys=fixtures.approvedPack;
      final catalog=await const CatalogRepository().load(); final p=state.activeProfile!.copyWith(playStage:2,effectsOn:false);
      await tester.pumpWidget(MaterialApp(theme:ThemeData(fontFamily:'NotoSansKR'), home:
        page == 'library' ? PlayLibraryScreen(appState:state,catalog:catalog,profile:p)
        : page == 'observation' ? ObservationScreen(state:state,profile:p,catalog:catalog)
        : JourneyPlayScreen(journey:state.journeys.firstWhere((a)=>a.id==(page=='bridge_repair'?'age_72_05':'age_48_02')),
          appState:state,profile:p,preview:true,playAsset:(_) async {})));
      await tester.pumpAndSettle();
      if(page=='bridge_repair' || page=='detective') {
        await tester.tap(find.byTooltip('놀이 시작')); await tester.pumpAndSettle();
        if(page=='bridge_repair') {
          await tester.runAsync(()=>tester.state<GameWidgetState>(find.byWidgetPredicate((w)=>w is GameWidget)).loaderFuture);
          Future<void> tap(String s) async { await tester.ensureVisible(find.byTooltip(s));await tester.pumpAndSettle();await tester.tap(find.byTooltip(s));await tester.pumpAndSettle(); }
          await tap('가벼운 잎 지붕');
          for(var i=1;i<=4;i++) {await tap('$i번째 빈 자리');}
          await tap('만든 길 시험하기');
          tester.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0); await tester.pumpAndSettle();
        }
      }
      await tester.runAsync(() async { for(final name in ['momo','duri','nuri']) { await precacheImage(AssetImage('assets/images/$name.png'),tester.element(find.byType(Scaffold).first)); }});
      await tester.pumpAndSettle(); expect(tester.takeException(),isNull);
      await expectLater(find.byType(Scaffold).first,matchesGoldenFile('goldens/quality_$page.png'));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
