import 'dart:convert';

class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.name,
    required this.role,
    this.isOwner = false,
    required this.joinedAt,
  });

  final String id;
  final String name;
  final String role; // e.g. 엄마, 아빠, 할머니, 할아버지, 삼촌/이모, 돌봄선생님
  final bool isOwner;
  final DateTime joinedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'isOwner': isOwner,
    'joinedAt': joinedAt.toIso8601String(),
  };

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['id'] as String,
    name: json['name'] as String,
    role: json['role'] as String,
    isOwner: json['isOwner'] as bool? ?? false,
    joinedAt: DateTime.parse(json['joinedAt'] as String),
  );
}

class FamilyInvitePayload {
  const FamilyInvitePayload({
    required this.code,
    required this.familyId,
    required this.childId,
    required this.childName,
    required this.birthDate,
    required this.gender,
    required this.avatar,
    required this.inviterName,
    required this.inviterRole,
    required this.ageMonths,
    required this.createdAt,
  });

  final String code;
  final String familyId;
  final String childId;
  final String childName;
  final String birthDate;
  final String gender;
  final String avatar;
  final String inviterName;
  final String inviterRole;
  final int ageMonths;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'code': code,
    'familyId': familyId,
    'childId': childId,
    'childName': childName,
    'birthDate': birthDate,
    'gender': gender,
    'avatar': avatar,
    'inviterName': inviterName,
    'inviterRole': inviterRole,
    'ageMonths': ageMonths,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FamilyInvitePayload.fromJson(Map<String, dynamic> json) =>
      FamilyInvitePayload(
        code: json['code'] as String,
        familyId: json['familyId'] as String,
        childId: json['childId'] as String,
        childName: json['childName'] as String,
        birthDate: json['birthDate'] as String,
        gender: json['gender'] as String? ?? '선택하지 않음',
        avatar: json['avatar'] as String? ?? 'momo',
        inviterName: json['inviterName'] as String? ?? '보호자',
        inviterRole: json['inviterRole'] as String? ?? '가족',
        ageMonths: json['ageMonths'] as int? ?? 36,
        createdAt: DateTime.parse(
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        ),
      );

  String toToken() => base64UrlEncode(utf8.encode(jsonEncode(toJson())));

  String toShareUrl() => 'https://momosup.app/share?invite=${toToken()}';

  static FamilyInvitePayload? fromRaw(String raw) {
    var trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.contains('invite=')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.queryParameters.containsKey('invite')) {
        trimmed = uri.queryParameters['invite']!;
      }
    }

    try {
      final decodedJson = utf8.decode(base64Url.decode(base64Url.normalize(trimmed)));
      final map = jsonDecode(decodedJson) as Map<String, dynamic>;
      return FamilyInvitePayload.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
