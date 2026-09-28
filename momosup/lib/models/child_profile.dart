class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.nickname,
    required this.ageMonths,
    required this.avatar,
    required this.level,
    required this.answers,
    this.gender = '선택하지 않음',
    this.dailyLimitMinutes = 15,
    this.musicOn = true,
    this.lowStimulation = false,
  });

  final String id;
  final String nickname;
  final int ageMonths;
  final String avatar;
  final String level;
  final List<int> answers;
  final String gender;
  final int dailyLimitMinutes;
  final bool musicOn;
  final bool lowStimulation;

  String get ageLabel =>
      ageMonths < 36 ? '$ageMonths개월' : '만 ${ageMonths ~/ 12}세';

  String get avatarAsset => 'assets/images/$avatar.png';

  ChildProfile copyWith({
    String? nickname,
    int? ageMonths,
    String? avatar,
    String? level,
    List<int>? answers,
    String? gender,
    int? dailyLimitMinutes,
    bool? musicOn,
    bool? lowStimulation,
  }) => ChildProfile(
    id: id,
    nickname: nickname ?? this.nickname,
    ageMonths: ageMonths ?? this.ageMonths,
    avatar: avatar ?? this.avatar,
    level: level ?? this.level,
    answers: answers ?? this.answers,
    gender: gender ?? this.gender,
    dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
    musicOn: musicOn ?? this.musicOn,
    lowStimulation: lowStimulation ?? this.lowStimulation,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nickname': nickname,
    'ageMonths': ageMonths,
    'avatar': avatar,
    'level': level,
    'answers': answers,
    'gender': gender,
    'dailyLimitMinutes': dailyLimitMinutes,
    'musicOn': musicOn,
    'lowStimulation': lowStimulation,
  };

  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
    id: json['id'] as String,
    nickname: json['nickname'] as String,
    ageMonths: json['ageMonths'] as int,
    avatar: json['avatar'] as String,
    level: json['level'] as String? ?? '기본',
    answers: List<int>.from((json['answers'] as List<dynamic>?) ?? const []),
    gender: json['gender'] as String? ?? '선택하지 않음',
    dailyLimitMinutes: json['dailyLimitMinutes'] as int? ?? 15,
    musicOn: json['musicOn'] as bool? ?? true,
    lowStimulation: json['lowStimulation'] as bool? ?? false,
  );
}
