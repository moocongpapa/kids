import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/widgets/woodland_art.dart';

Future<void> precacheWoodlandArt(WidgetTester tester) async {
  await tester.runAsync(() async {
    final context = tester.element(find.byType(Scaffold).first);
    for (final asset in woodlandArtAssets) {
      await precacheImage(AssetImage(asset), context);
    }
  });
}
