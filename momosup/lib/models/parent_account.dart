class ParentAccount {
  const ParentAccount({
    required this.id,
    required this.nickname,
    this.email,
    this.profileImageUrl,
    this.provider = 'kakao',
    required this.connectedAt,
  });

  final String id;
  final String nickname;
  final String? email;
  final String? profileImageUrl;
  final String provider;
  final DateTime connectedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nickname': nickname,
    if (email != null) 'email': email,
    if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    'provider': provider,
    'connectedAt': connectedAt.toIso8601String(),
  };

  factory ParentAccount.fromJson(Map<String, dynamic> json) => ParentAccount(
    id: json['id'] as String,
    nickname: json['nickname'] as String,
    email: json['email'] as String?,
    profileImageUrl: json['profileImageUrl'] as String?,
    provider: json['provider'] as String? ?? 'kakao',
    connectedAt: DateTime.parse(json['connectedAt'] as String),
  );

  ParentAccount copyWith({
    String? nickname,
    String? email,
    String? profileImageUrl,
  }) => ParentAccount(
    id: id,
    nickname: nickname ?? this.nickname,
    email: email ?? this.email,
    profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    provider: provider,
    connectedAt: connectedAt,
  );
}
