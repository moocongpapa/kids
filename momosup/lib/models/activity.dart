enum PlayMode { touch, color, move }

class Activity {
  const Activity({
    required this.id,
    required this.title,
    required this.theme,
    required this.mode,
    required this.minAgeMonths,
    required this.maxAgeMonths,
    required this.minutes,
    required this.avatar,
    required this.intro,
    required this.prompt,
    required this.outro,
    required this.offscreen,
    required this.safety,
    required this.choices,
    required this.reactions,
    required this.verses,
    this.audioFiles = const {},
    this.humanApprovedAt,
    this.rightsVerifiedAt,
    this.audioReviewApproved = false,
  });

  final String id;
  final String title;
  final String theme;
  final PlayMode mode;
  final int minAgeMonths;
  final int maxAgeMonths;
  final int minutes;
  final String avatar;
  final String intro;
  final String prompt;
  final String outro;
  final String offscreen;
  final List<String> safety;
  final List<String> choices;
  final List<String> reactions;
  final List<String> verses;
  final Map<String, String> audioFiles;
  final String? humanApprovedAt;
  final String? rightsVerifiedAt;
  final bool audioReviewApproved;

  bool get isFullyApproved =>
      (humanApprovedAt?.isNotEmpty ?? false) &&
      (rightsVerifiedAt?.isNotEmpty ?? false) &&
      audioReviewApproved &&
      requiredAudioIds.every((id) => audioFiles[id]?.isNotEmpty ?? false);

  List<String> get requiredAudioIds => [
    'intro',
    'prompt',
    'outro',
    'offscreen',
    if (mode == PlayMode.touch)
      for (var i = 0; i < choices.length; i++) ...['choice_$i', 'reaction_$i'],
    if (mode == PlayMode.move) 'song',
  ];

  bool supportsAge(int ageMonths) =>
      ageMonths >= minAgeMonths && ageMonths <= maxAgeMonths;

  String get modeLabel => switch (mode) {
    PlayMode.touch => '만져 보기',
    PlayMode.color => '그림·색칠',
    PlayMode.move => '노래·동작',
  };

  factory Activity.fromJson(
    Map<String, dynamic> json, {
    bool audioReviewApproved = false,
  }) {
    final mode = switch (json['mode']) {
      'touch' => PlayMode.touch,
      'color' => PlayMode.color,
      'move' => PlayMode.move,
      _ => throw FormatException('알 수 없는 놀이 형식: ${json['mode']}'),
    };
    final activity = Activity(
      id: json['id'] as String,
      title: json['title'] as String,
      theme: json['theme'] as String,
      mode: mode,
      minAgeMonths: json['minAgeMonths'] as int,
      maxAgeMonths: json['maxAgeMonths'] as int,
      minutes: json['minutes'] as int,
      avatar: json['avatar'] as String,
      intro: json['intro'] as String,
      prompt: json['prompt'] as String,
      outro: json['outro'] as String,
      offscreen: json['offscreen'] as String,
      safety: List<String>.from(json['safety'] as List<dynamic>),
      choices: List<String>.from(
        (json['choices'] as List<dynamic>?) ?? const [],
      ),
      reactions: List<String>.from(
        (json['reactions'] as List<dynamic>?) ?? const [],
      ),
      verses: List<String>.from((json['verses'] as List<dynamic>?) ?? const []),
      audioFiles: Map<String, String>.from(
        (json['audioFiles'] as Map<String, dynamic>?) ?? const {},
      ),
      humanApprovedAt: json['humanApprovedAt'] as String?,
      rightsVerifiedAt: json['rightsVerifiedAt'] as String?,
      audioReviewApproved: audioReviewApproved,
    );
    activity.validate();
    return activity;
  }

  void validate() {
    if (id.isEmpty || title.isEmpty || intro.isEmpty || outro.isEmpty) {
      throw FormatException('필수 콘텐츠 문구 누락: $id');
    }
    if (minAgeMonths < 0 || maxAgeMonths < minAgeMonths) {
      throw FormatException('연령 범위 오류: $id');
    }
    if (minutes < 2 || minutes > 7) {
      throw FormatException('놀이 길이 오류: $id');
    }
    if (safety.isEmpty || offscreen.isEmpty) {
      throw FormatException('안전 또는 화면 밖 전환 누락: $id');
    }
    if (mode == PlayMode.touch &&
        (choices.length < 2 || choices.length != reactions.length)) {
      throw FormatException('터치 선택·반응 수 불일치: $id');
    }
    if (mode == PlayMode.move && verses.length < 2) {
      throw FormatException('노래·동작 가사 부족: $id');
    }
  }
}
