import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/data/catalog_repository.dart';
import 'package:momosup/models/activity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('초기 카탈로그는 다섯 주제와 세 놀이 형식을 갖는다', () async {
    final activities = await const CatalogRepository().load();
    expect(activities.length, 10);
    expect(activities.map((item) => item.id).toSet().length, 10);
    expect(activities.map((item) => item.theme).toSet(), {
      '동물',
      '감정',
      '신체',
      '탈것',
      '자연',
    });
    expect(activities.map((item) => item.mode).toSet(), {
      PlayMode.touch,
      PlayMode.color,
      PlayMode.move,
    });
    expect(activities.every((item) => item.offscreen.isNotEmpty), isTrue);
    expect(activities.every((item) => item.safety.isNotEmpty), isTrue);
  });

  test('사람 승인과 음성이 없으면 아이 모드에 공개하지 않는다', () async {
    final activities = await const CatalogRepository().load();
    final unapproved = activities.where((item) => !item.isFullyApproved);
    expect(unapproved, isNotEmpty);
    for (final item in unapproved) {
      expect(item.isFullyApproved, isFalse);
    }
    expect(
      activities.fold<int>(
        0,
        (count, item) => count + item.requiredAudioIds.length,
      ),
      66,
    );
  });

  test('누락된 안전 정보와 형식 불일치를 거부한다', () {
    const incomplete = Activity(
      id: 'bad',
      title: '검사용',
      theme: '동물',
      mode: PlayMode.touch,
      minAgeMonths: 36,
      maxAgeMonths: 60,
      minutes: 3,
      avatar: 'momo',
      intro: '시작',
      prompt: '선택',
      outro: '끝',
      offscreen: '',
      safety: [],
      choices: ['하나', '둘'],
      reactions: ['반응'],
      verses: [],
    );
    expect(incomplete.validate, throwsFormatException);
  });
}
