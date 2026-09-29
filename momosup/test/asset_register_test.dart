import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('생성 이미지 10개가 등록된 원본 해시와 일치한다', () async {
    final source = await rootBundle.loadString(
      'assets/content/asset_register.json',
    );
    final register = jsonDecode(source) as Map<String, dynamic>;
    final assets = register['assets'] as List<dynamic>;
    expect(assets.length, 10);
    for (final row in assets) {
      final item = row as Map<String, dynamic>;
      final data = await rootBundle.load(item['path'] as String);
      final actual = sha256.convert(data.buffer.asUint8List()).toString();
      expect(actual, item['sha256'], reason: item['path'] as String);
      expect(item['review'], 'approved');
      expect(item['commercialRightsEvidence'], isNotEmpty);
    }
  });
}
