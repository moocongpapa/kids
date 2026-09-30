import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momosup/models/child_profile.dart';
import 'package:momosup/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  const first = ChildProfile(
    id: 'a',
    nickname: '첫째',
    ageMonths: 36,
    avatar: 'momo',
    level: '기본',
    answers: [3, 3, 3, 3, 3],
  );
  const second = ChildProfile(
    id: 'b',
    nickname: '둘째',
    ageMonths: 48,
    avatar: 'duri',
    level: '기본',
    answers: [3, 3, 3, 3, 3],
  );

  test('PIN은 평문이 아닌 해시로 저장하고 틀린 PIN을 거부한다', () async {
    final state = AppState();
    await state.load();
    await state.setParentPin('123456');
    final saved = await const FlutterSecureStorage().read(
      key: 'prototype_parent_pin_v1',
    );
    expect(saved, startsWith('v2:'));
    expect(saved, isNot(contains('123456')));
    expect(await state.verifyPin('000000'), isFalse);
    expect(await state.verifyPin('123456'), isTrue);
  });

  test('형제별 놀이 기록은 섞이지 않는다', () async {
    final state = AppState();
    await state.load();
    await state.addProfile(first);
    await state.addProfile(second);
    await state.recordPlay(profileId: first.id, activityId: 'one', seconds: 75);
    expect(state.minutesToday(first.id), 2);
    expect(state.minutesToday(second.id), 0);
    await state.selectProfile(second.id);
    expect(state.activeProfile?.id, second.id);
  });

  test('PIN 5회 연속 실패 시 잠금되고 앱 재시작 후에도 잠금이 유지된다', () async {
    final state = AppState();
    await state.load();
    await state.setParentPin('123456');

    // 4회 실패
    for (var i = 0; i < 4; i++) {
      expect(await state.verifyPin('000000'), isFalse);
    }
    // 4회 실패 상태에서는 올바른 PIN 입력 시 성공
    expect(await state.verifyPin('123456'), isTrue);

    // 다시 5회 연속 실패
    for (var i = 0; i < 5; i++) {
      expect(await state.verifyPin('999999'), isFalse);
    }

    // 5회 실패 후에는 맞는 PIN도 거부됨 (잠금 상태)
    expect(await state.verifyPin('123456'), isFalse);

    // 새 AppState 인스턴스로 앱 재시작 시뮬레이션
    final restartedState = AppState();
    await restartedState.load();

    // 재시작 후에도 잠금이 풀리지 않고 거부되어야 함
    expect(await restartedState.verifyPin('123456'), isFalse);
  });
}
