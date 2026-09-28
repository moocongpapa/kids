import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/catalog_repository.dart';
import 'package:momosup/data/recommendation.dart';
import 'package:momosup/models/activity.dart';
import 'package:momosup/models/child_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('선호 놀이와 나이를 반영하되 주제는 다양하게 제안한다', () async {
    final catalog = await const CatalogRepository().load();
    const profile = ChildProfile(
      id: 'demo',
      nickname: '아이',
      ageMonths: 36,
      avatar: 'momo',
      level: '기본',
      answers: [3, 3, 3, 1, 3], // 그림 선호
    );
    final choices = recommendedFor(profile, catalog);
    expect(choices.length, 3);
    expect(choices.first.mode, PlayMode.color);
    expect(choices.map((item) => item.theme).toSet().length, 3);
    expect(choices.any((item) => item.id == 'hand_shapes'), isFalse);
  });

  test('음악을 끄면 노래 놀이를 추천하지 않는다', () async {
    final catalog = await const CatalogRepository().load();
    const profile = ChildProfile(
      id: 'demo',
      nickname: '아이',
      ageMonths: 48,
      avatar: 'momo',
      level: '기본',
      answers: [3, 3, 3, 2, 3],
      musicOn: false,
    );
    expect(
      recommendedFor(
        profile,
        catalog,
      ).every((item) => item.mode != PlayMode.move),
      isTrue,
    );
  });
}
