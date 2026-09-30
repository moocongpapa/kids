import 'family_share.dart';

class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.nickname,
    required this.ageMonths,
    required this.avatar,
    required this.level,
    required this.answers,
    this.gender = '선택하지 않음',
    this.birthDate,
    this.familyId,
    this.ownerParentId,
    this.ownerName,
    this.isShared = false,
    this.sharedMembers = const [],
    this.inviteCode,
    this.dailyLimitMinutes = 15,
    this.musicOn = true,
    this.voiceOn = true,
    this.effectsOn = true,
    this.lowStimulation = false,
    this.preschool = true,
    this.playStage = -1,
    this.favoriteJourneys = const [],
    this.activityStages = const {},
  });

  final String id;
  final String nickname;
  final int ageMonths;
  final String avatar;
  final String level;
  final List<int> answers;
  final String gender;
  final String? birthDate; // YYYY-MM-DD
  final String? familyId;
  final String? ownerParentId;
  final String? ownerName;
  final bool isShared;
  final List<FamilyMember> sharedMembers;
  final String? inviteCode;
  final int dailyLimitMinutes;
  final bool musicOn;
  final bool voiceOn, effectsOn;
  final bool lowStimulation;
  final bool preschool;
  final int playStage;
  final Map<String, int> activityStages;
  int stageFor(String activityId) =>
      (activityStages[activityId] ?? effectivePlayStage).clamp(0, 2);
  final List<String> favoriteJourneys;
  bool get caregiverMode => ageMonths < 24;

  static int calculateAgeMonths(DateTime birth, [DateTime? targetNow]) {
    final today = targetNow ?? DateTime.now();
    var months = (today.year - birth.year) * 12 + today.month - birth.month;
    if (today.day < birth.day) {
      months--;
    }
    return months.clamp(0, 120);
  }

  String get birthDateLabel {
    if (birthDate == null || birthDate!.isEmpty) return '';
    try {
      final parts = birthDate!.split('-');
      if (parts.length == 3) {
        return '${parts[0]}년 ${int.tryParse(parts[1]) ?? parts[1]}월 ${int.tryParse(parts[2]) ?? parts[2]}일생';
      }
    } catch (_) {}
    return birthDate!;
  }

  /// -1 follows age and the parent's stated need for help, never a diagnosis.
  /// Explicit saved stages (including legacy stage 0) remain unchanged.
  int get effectivePlayStage => playStage < 0 ? suggestedPlayStage : playStage;
  int get suggestedPlayStage {
    if (ageMonths < 30) return 0;
    if (answers.length == 5 &&
        (answers[0] == 0 || answers[1] == 0 || answers[2] == 0)) {
      return 0;
    }
    if (ageMonths < 60 || (answers.length == 5 && answers[0] == 1)) return 1;
    return 2;
  }

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
    String? birthDate,
    String? familyId,
    String? ownerParentId,
    String? ownerName,
    bool? isShared,
    List<FamilyMember>? sharedMembers,
    String? inviteCode,
    int? dailyLimitMinutes,
    bool? musicOn,
    bool? voiceOn,
    bool? effectsOn,
    bool? lowStimulation,
    bool? preschool,
    int? playStage,
    List<String>? favoriteJourneys,
    Map<String, int>? activityStages,
  }) => ChildProfile(
    id: id,
    nickname: nickname ?? this.nickname,
    ageMonths: ageMonths ?? this.ageMonths,
    avatar: avatar ?? this.avatar,
    level: level ?? this.level,
    answers: answers ?? this.answers,
    gender: gender ?? this.gender,
    birthDate: birthDate ?? this.birthDate,
    familyId: familyId ?? this.familyId,
    ownerParentId: ownerParentId ?? this.ownerParentId,
    ownerName: ownerName ?? this.ownerName,
    isShared: isShared ?? this.isShared,
    sharedMembers: sharedMembers ?? this.sharedMembers,
    inviteCode: inviteCode ?? this.inviteCode,
    dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
    musicOn: musicOn ?? this.musicOn,
    voiceOn: voiceOn ?? this.voiceOn,
    effectsOn: effectsOn ?? this.effectsOn,
    lowStimulation: lowStimulation ?? this.lowStimulation,
    preschool: preschool ?? this.preschool,
    playStage: playStage ?? this.playStage,
    favoriteJourneys: favoriteJourneys ?? this.favoriteJourneys,
    activityStages: activityStages ?? this.activityStages,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nickname': nickname,
    'ageMonths': ageMonths,
    'avatar': avatar,
    'level': level,
    'answers': answers,
    'gender': gender,
    if (birthDate != null) 'birthDate': birthDate,
    if (familyId != null) 'familyId': familyId,
    if (ownerParentId != null) 'ownerParentId': ownerParentId,
    if (ownerName != null) 'ownerName': ownerName,
    'isShared': isShared,
    'sharedMembers': sharedMembers.map((m) => m.toJson()).toList(),
    if (inviteCode != null) 'inviteCode': inviteCode,
    'dailyLimitMinutes': dailyLimitMinutes,
    'musicOn': musicOn,
    'voiceOn': voiceOn,
    'effectsOn': effectsOn,
    'lowStimulation': lowStimulation,
    'preschool': preschool,
    'playStage': playStage,
    'favoriteJourneys': favoriteJourneys,
    'activityStages': activityStages,
  };

  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
    id: json['id'] as String,
    nickname: json['nickname'] as String,
    ageMonths: json['ageMonths'] as int,
    avatar: json['avatar'] as String,
    level: json['level'] as String? ?? '기본',
    answers: List<int>.from((json['answers'] as List<dynamic>?) ?? const []),
    gender: json['gender'] as String? ?? '선택하지 않음',
    birthDate: json['birthDate'] as String?,
    familyId: json['familyId'] as String?,
    ownerParentId: json['ownerParentId'] as String?,
    ownerName: json['ownerName'] as String?,
    isShared: json['isShared'] as bool? ?? false,
    sharedMembers: (json['sharedMembers'] as List<dynamic>?)
            ?.map((m) => FamilyMember.fromJson(m as Map<String, dynamic>))
            .toList() ??
        const [],
    inviteCode: json['inviteCode'] as String?,
    dailyLimitMinutes: json['dailyLimitMinutes'] as int? ?? 15,
    musicOn: json['musicOn'] as bool? ?? true,
    voiceOn: json['voiceOn'] as bool? ?? true,
    effectsOn: json['effectsOn'] as bool? ?? true,
    lowStimulation: json['lowStimulation'] as bool? ?? false,
    preschool: json['preschool'] as bool? ?? true,
    playStage: (json['playStage'] as int? ?? -1).clamp(-1, 2),
    activityStages: Map<String, int>.from(
      json['activityStages'] as Map? ?? const {},
    ),
    favoriteJourneys: List<String>.from(
      json['favoriteJourneys'] as List? ?? const [],
    ),
  );
}
