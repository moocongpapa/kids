/// Deliberately simple pretend-world rules, not a physics learning assessment.
class BuildTrial {
  const BuildTrial({
    required this.attempt,
    required this.id,
    required this.step,
    required this.stage,
    required this.count,
    required this.pieces,
  });
  final int attempt, step, stage, count;
  final String id;
  final Map<int, int> pieces;
  bool get wind => id == 'age_60_03';
  bool get bridge => id == 'age_72_05';
  bool get bus => id == 'age_60_02';
  bool get garden => id == 'age_60_06' || id == 'age_84_02';
  int get demand => stage == 0
      ? 1
      : stage == 2 && step == 2
      ? 3
      : 2;
  BuildResult evaluate() {
    for (var i = 0; i < count; i++) {
      if (!pieces.containsKey(i)) {
        return BuildResult(false, i, '빈 자리를 이어 주세요.', 0);
      }
    }
    if (wind || bridge) {
      for (var i = 0; i < count; i++) {
        final strength = wind ? [3, 2, 1][pieces[i]!] : [2, 3, 1][pieces[i]!];
        if (strength < demand) {
          return BuildResult(
            false,
            i,
            wind
                ? '가벼운 조각이 움직였어요. 다른 재료로 바꿔 볼까요?'
                : '얇은 조각이 휘었어요. 두꺼운 조각을 놓아 볼까요?',
            wind ? 0 : 1,
          );
        }
      }
    }
    if (bus) {
      final friends = stage == 0 ? 2 : 3;
      for (var friend = 0; friend < friends; friend++) {
        if (!pieces.values.contains(friend)) {
          final replace = pieces.keys.firstWhere(
            (k) => pieces.values.where((v) => v == pieces[k]).length > 1,
            orElse: () => 0,
          );
          return BuildResult(false, replace, '기다리는 친구에게도 자리를 주세요.', friend);
        }
      }
    }
    if (garden && stage > 0) {
      final rest = id == 'age_84_02' ? 1 : 2;
      if (!pieces.values.contains(rest)) {
        return BuildResult(false, count - 1, '꽃 옆에 쉴 자리도 놓아 주세요.', rest);
      }
    }
    return const BuildResult(true, null, '친구가 편하게 지났어요.', null);
  }

  Map<String, dynamic> toJson() => {
    'step': step,
    'pieces': pieces.map((k, v) => MapEntry('$k', v)),
    'success': evaluate().success,
    'reason': evaluate().reason,
  };
}

class BuildResult {
  const BuildResult(
    this.success,
    this.problemSlot,
    this.reason,
    this.repairValue,
  );
  final bool success;
  final int? problemSlot, repairValue;
  final String reason;
}

String buildPieceLabel(String id, int value) {
  if (id == 'age_60_02') return ['모모', '두리', '누리'][value];
  if (id == 'age_60_06') return ['첫 꽃', '다른 꽃', '쉼터'][value];
  if (id == 'age_84_02') return ['길가 꽃', '쉼터', '작은 꽃'][value];
  return ['넓은 나무', '두꺼운 나무', '가벼운 잎 지붕'][value];
}
