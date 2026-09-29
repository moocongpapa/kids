import 'dart:convert';

import 'package:crypto/crypto.dart';

const journeyStages = ['함께 해요', '해볼래요', '바꿔볼래요'];
const journeyBands = [
  (6, 8),
  (9, 11),
  (12, 14),
  (15, 17),
  (18, 23),
  (24, 29),
  (30, 35),
  (36, 47),
  (48, 59),
  (60, 71),
  (72, 83),
  (84, 95),
];
String journeyBandLabel(int months) {
  final band = journeyBands.firstWhere((b) => months >= b.$1 && months <= b.$2);
  return band.$1 < 36
      ? '${band.$1}~${band.$2}개월'
      : '만 ${band.$1 ~/ 12}세${band.$1 == 84 ? ' 미취학' : ''}';
}

class AgeJourney {
  AgeJourney(this.data, {this.audio = const {}}) {
    if (steps.length != 3 ||
        variants.length != 3 ||
        id.isEmpty ||
        minAge < 6 ||
        maxAge > 95 ||
        maxAge < minAge) {
      throw FormatException('놀이 구성 오류: $id');
    }
    if (minAge < 24 && !isCaregiver) {
      throw FormatException('영아의 디지털 놀이 금지: $id');
    }
    if (!isCaregiver &&
        (choices.length != 3 ||
            choices.any((c) => c.isEmpty || c.length > 3))) {
      throw FormatException('장면 선택지 오류: $id');
    }
  }
  final Map<String, dynamic> data;
  final Map<String, String> audio;
  String get id => data['id'] as String;
  String get title => data['title'] as String;
  String get summary => data['summary'] as String;
  String get world => data['world'] as String;
  String get avatar => data['avatar'] as String;
  String get mechanic => data['mechanic'] as String;
  String get materials => data['materials'] as String;
  String get offscreen => data['offscreen'] as String;
  int get minAge => data['minAgeMonths'] as int;
  int get maxAge => data['maxAgeMonths'] as int;
  int get minutes => data['minutes'] as int;
  bool get isCaregiver => mechanic == 'caregiver';
  List<String> get steps => List<String>.from(data['steps'] as List);
  List<String> get variants => List<String>.from(data['variants'] as List);
  List<String> get safety => List<String>.from(data['safety'] as List);
  List<String> get symbols => List<String>.from(data['symbols'] as List);
  List<List<String>> get choices => (data['choices'] as List)
      .map((v) => List<String>.from(v as List))
      .toList();
  bool supports(int months, {bool preschool = true}) =>
      months >= minAge && months <= maxAge && (months < 84 || preschool);
  List<String> get audioIds => isCaregiver
      ? ['guide', if (id == 'age_06_06' || id == 'age_15_05') 'song']
      : ['step_0', 'step_1', 'step_2'];
  bool get audioReady => audioIds.every(audio.containsKey);
  // Exact content and validated audio digests are part of a local review receipt.
  String get reviewKey =>
      '$id:${sha256.convert(utf8.encode(jsonEncode(data)))}';
}
