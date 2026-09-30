import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

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

  static const defaultSecret = 'momosup_family_share_secret_v1';

  String toToken({String secret = defaultSecret}) {
    final payloadB64 = base64UrlEncode(utf8.encode(jsonEncode(toJson())));
    final sig = Hmac(sha256, utf8.encode(secret))
        .convert(utf8.encode(payloadB64))
        .toString();
    return '$payloadB64.$sig';
  }

  String toShareUrl({String secret = defaultSecret}) =>
      'https://momosup.app/share?invite=${toToken(secret: secret)}';

  static FamilyInvitePayload? fromRaw(
    String raw, {
    String secret = defaultSecret,
  }) {
    var trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.contains('invite=')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.queryParameters.containsKey('invite')) {
        trimmed = uri.queryParameters['invite']!;
      }
    }

    try {
      String payloadB64;
      if (trimmed.contains('.')) {
        final parts = trimmed.split('.');
        if (parts.length != 2) return null;
        payloadB64 = parts[0];
        final sig = parts[1];
        final expectedSig = Hmac(sha256, utf8.encode(secret))
            .convert(utf8.encode(payloadB64))
            .toString();
        var diff = sig.length ^ expectedSig.length;
        for (var i = 0; i < min(sig.length, expectedSig.length); i++) {
          diff |= sig.codeUnitAt(i) ^ expectedSig.codeUnitAt(i);
        }
        if (diff != 0) return null; // Signature mismatch / tampered token
      } else {
        // Legacy unsigned base64 token compatibility
        payloadB64 = trimmed;
      }

      final decodedJson = utf8.decode(
        base64Url.decode(base64Url.normalize(payloadB64)),
      );
      final map = jsonDecode(decodedJson) as Map<String, dynamic>;
      return FamilyInvitePayload.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
