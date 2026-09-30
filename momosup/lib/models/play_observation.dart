class PlayObservation {
  const PlayObservation({
    required this.id,
    required this.profileId,
    required this.activityId,
    required this.at,
    required this.ageMonths,
    required this.stage,
    required this.start,
    required this.help,
    required this.enjoyment,
    required this.ending,
    required this.offscreen,
    required this.device,
    required this.issues,
    this.sessionId,
  });
  final String id, profileId, activityId, device;
  final String? sessionId;
  final DateTime at;
  final int ageMonths, stage, start, help, enjoyment, ending, offscreen;
  final List<String> issues;
  Map<String, dynamic> toJson() => {
    'id': id,
    'profileId': profileId,
    'activityId': activityId,
    'at': at.toIso8601String(),
    'ageMonths': ageMonths,
    'stage': stage,
    'start': start,
    'help': help,
    'enjoyment': enjoyment,
    'ending': ending,
    'offscreen': offscreen,
    'device': device,
    'issues': issues,
    'sessionId': sessionId,
  };
  factory PlayObservation.fromJson(Map<String, dynamic> j) => PlayObservation(
    id: j['id'] as String? ?? '',
    profileId: j['profileId'] as String? ?? '',
    activityId: j['activityId'] as String? ?? '',
    at: j['at'] != null ? DateTime.parse(j['at'] as String) : DateTime.now(),
    ageMonths: (j['ageMonths'] as num?)?.toInt() ?? 0,
    stage: (j['stage'] as num?)?.toInt() ?? 1,
    start: (j['start'] as num?)?.toInt() ?? 0,
    help: (j['help'] as num?)?.toInt() ?? 0,
    enjoyment: (j['enjoyment'] as num?)?.toInt() ?? 0,
    ending: (j['ending'] as num?)?.toInt() ?? 0,
    offscreen: (j['offscreen'] as num?)?.toInt() ?? 0,
    device: j['device'] as String? ?? '',
    issues: (j['issues'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    sessionId: j['sessionId'] as String? ?? '',
  );
  String get ageBand => ageMonths < 24
      ? '${(ageMonths ~/ 6) * 6}~${(ageMonths ~/ 6) * 6 + 5}개월'
      : '${ageMonths ~/ 12}세';

  /// No profile IDs, aliases, exact ages, timestamps or free text leave this screen.
  Map<String, dynamic> anonymousSummaryRow() => {
    'activityId': activityId,
    'ageBand': ageBand,
    'stage': stage,
    'start': start,
    'help': help,
    'enjoyment': enjoyment,
    'ending': ending,
    'offscreen': offscreen,
    'device': device,
    'issues': issues,
  };
}

const startLabels = ['혼자 시작', '그림·말 안내 후 시작', '함께 손을 움직임', '시작하지 않음'];
const helpLabels = ['없음', '1번', '2~3번', '4번 이상'];
const enjoymentLabels = ['다시 하고 싶어 함', '편안히 참여', '관심 적음', '불편해함'];
const endingLabels = ['편안히 마침', '한 번 안내 후 마침', '마치기 어려움', '중간에 중단'];
const offscreenLabels = ['시도함', '제안만 함', '하지 않음'];
const observationIssues = [
  '소리가 안 나옴',
  '소리가 큼',
  '첫 조작 혼란',
  '터치·드래그 어려움',
  '규칙 이해 어려움',
  '흥미 부족',
  '종료 어려움',
  '저장·이어하기 오류',
  '무서움·불편함',
];

String observationSuggestion(Iterable<PlayObservation> rows) {
  final list = rows.toList();
  if (list.isEmpty) return '아직 실제 관찰 기록이 없어요. 가족이 준비되면 시작해 주세요.';
  if (list.any((o) => o.issues.contains('무서움·불편함') || o.enjoyment == 3)) {
    return '불편함이 기록됐어요. 해당 놀이를 쉬고 소리·장면을 보호자가 먼저 확인해 주세요.';
  }
  if (list.where((o) => o.start >= 2 || o.help >= 2).length >= 2) {
    return '도움이 여러 번 필요했어요. 해당 놀이를 함께 시작 단계로 조정해 볼 수 있어요.';
  }
  if (list.where((o) => o.ending >= 2).length >= 2) {
    return '마치기 안내와 화면 밖 놀이 연결을 먼저 살펴봐 주세요.';
  }
  return '소수의 관찰 기록입니다. 다른 날에도 같은 반응인지 살펴봐 주세요.';
}
