import '../models/play_observation.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../models/child_profile.dart';
import '../models/parent_account.dart';
import '../models/family_share.dart';
import '../models/age_journey.dart';
import '../data/age_journey_repository.dart';

class PlayRecord {
  const PlayRecord({
    required this.profileId,
    required this.activityId,
    required this.at,
    required this.seconds,
    this.sessionId,
    this.metrics = const {},
  });

  final String profileId;
  final String activityId;
  final DateTime at;
  final int seconds;
  final String? sessionId;
  final Map<String, int> metrics;

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'activityId': activityId,
    'at': at.toIso8601String(),
    'seconds': seconds,
    'sessionId': sessionId,
    'metrics': metrics,
  };

  factory PlayRecord.fromJson(Map<String, dynamic> json) => PlayRecord(
    profileId: json['profileId'] as String,
    activityId: json['activityId'] as String,
    at: DateTime.parse(json['at'] as String),
    seconds: json['seconds'] as int,
    sessionId: json['sessionId'] as String?,
    metrics: Map<String, int>.from(json['metrics'] as Map? ?? {}),
  );
}

class AppState extends ChangeNotifier {
  AppState({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _profilesKey = 'prototype_profiles_v1';
  static const _selectedKey = 'prototype_selected_v1';
  static const _pinKey = 'prototype_parent_pin_v1';
  static const _pinFailCountKey = 'prototype_pin_fail_count_v1';
  static const _pinLockedUntilKey = 'prototype_pin_locked_until_v1';
  static const _recordsKey = 'prototype_records_v1';
  static const _parentAccountKey = 'parent_account_v1';

  final FlutterSecureStorage _storage;
  Future<void> _profileWrites = Future.value();
  final List<ChildProfile> _profiles = [];
  final List<PlayRecord> _records = [];
  final List<PlayObservation> _observations = [];
  ParentAccount? _parentAccount;
  ParentAccount? get parentAccount => _parentAccount;
  bool get hasParentAccount => _parentAccount != null;

  Future<void> setParentAccount(ParentAccount account) async {
    _parentAccount = account;
    await _storage.write(
      key: _parentAccountKey,
      value: jsonEncode(account.toJson()),
    );
    notifyListeners();
  }

  Future<void> logoutParentAccount() async {
    _parentAccount = null;
    await _storage.delete(key: _parentAccountKey);
    notifyListeners();
  }

  List<PlayObservation> get observations => List.unmodifiable(_observations);
  Future<void> _storeObservations(List<PlayObservation> next) async {
    await _storage.write(
      key: 'observations_v1',
      value: jsonEncode(next.map((o) => o.toJson()).toList()),
    );
    _observations
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  Future<void> saveObservation(PlayObservation item) async {
    if (!_profiles.any((p) => p.id == item.profileId)) {
      throw StateError('프로필이 없습니다.');
    }
    await _storeObservations([
      ..._observations.where((o) => o.id != item.id),
      item,
    ]);
  }

  Future<void> deleteObservation(String id) =>
      _storeObservations(_observations.where((o) => o.id != id).toList());

  final Map<String, Map<String, dynamic>> _works = {};
  final Map<String, Map<String, dynamic>> _storyProgress = {};
  Future<void> _storyWrites = Future.value();
  Map<String, dynamic> storyProgress(String profileId, String storyId) =>
      Map.unmodifiable(_storyProgress['$profileId:$storyId'] ?? {});
  Future<void> saveStoryProgress(
    String profileId,
    String storyId, {
    int? positionMs,
    bool? complete,
    bool? favorite,
  }) {
    final task = _storyWrites.catchError((Object _) {}).then((_) async {
      if (!_profiles.any((p) => p.id == profileId)) return;
      final key = '$profileId:$storyId';
      final next = {
        ..._storyProgress,
        key: {
          ...?_storyProgress[key],
          'profileId': profileId,
          if (positionMs != null) 'positionMs': positionMs.clamp(0, 420000),
          'complete': ?complete,
          'favorite': ?favorite,
        },
      };
      await _storage.write(key: 'story_progress_v1', value: jsonEncode(next));
      _storyProgress
        ..clear()
        ..addAll(next);
      notifyListeners();
    });
    _storyWrites = task;
    return task;
  }

  Future<void> _writeQueue = Future.value();
  Map<String, dynamic>? workFor(String profileId, String activityId) =>
      _works['$profileId:$activityId'];
  List<Map<String, dynamic>> worksFor(String profileId) =>
      _works.values.where((w) => w['profileId'] == profileId).toList();
  Future<void> saveWork(
    String profileId,
    String activityId,
    Map<String, dynamic> data,
  ) {
    if (!_profiles.any((p) => p.id == profileId)) return Future.value();
    final snapshot = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    final task = _writeQueue.catchError((Object _) {}).then((_) async {
      final updated = {
        ..._works,
        '$profileId:$activityId': {
          ...snapshot,
          'profileId': profileId,
          'activityId': activityId,
          'savedAt': DateTime.now().toIso8601String(),
        },
      };
      await _storage.write(key: 'play_works_v1', value: jsonEncode(updated));
      _works
        ..clear()
        ..addAll(updated);
      notifyListeners();
    });
    _writeQueue = task;
    return task;
  }

  int secondsRemaining(String id, int limitMinutes) {
    final now = DateTime.now();
    final used = _records
        .where(
          (r) =>
              r.profileId == id &&
              r.at.year == now.year &&
              r.at.month == now.month &&
              r.at.day == now.day,
        )
        .fold<int>(0, (sum, r) => sum + r.seconds);
    return max(0, limitMinutes * 60 - used);
  }

  String? _selectedId;
  bool _hasPin = false;
  bool _loaded = false;
  int _failedPinAttempts = 0;
  DateTime? _pinLockedUntil;

  List<AgeJourney> journeys = [];
  final Set<String> _journeyReviews = {};
  final Map<String, bool> _journeyVisibility = {};
  bool journeyApproved(AgeJourney item) =>
      item.audioReady &&
      _journeyVisibility[item.reviewKey] != false &&
      (item.bundledApproved ||
          _journeyReviews.contains(item.reviewKey) ||
          _journeyVisibility[item.reviewKey] == true);
  Future<void> loadJourneys() async {
    journeys = await AgeJourneyRepository().load();
    notifyListeners();
  }

  Future<void> reviewJourney(AgeJourney item, {required bool approved}) async {
    if (approved && !item.audioReady) throw StateError('음성 준비가 끝나지 않았어요.');
    final updated = {..._journeyVisibility};
    if (approved && item.bundledApproved) {
      // Showing publisher-approved content is not a new local review receipt.
      updated.remove(item.reviewKey);
    } else {
      updated[item.reviewKey] = approved;
    }
    await _storage.write(
      key: 'journey_visibility_v1',
      value: jsonEncode(updated),
    );
    _journeyVisibility
      ..clear()
      ..addAll(updated);
    notifyListeners();
  }

  bool get loaded => _loaded;
  bool get hasPin => _hasPin;
  List<ChildProfile> get profiles => List.unmodifiable(_profiles);
  List<PlayRecord> get records => List.unmodifiable(_records);
  ChildProfile? get activeProfile {
    for (final profile in _profiles) {
      if (profile.id == _selectedId) return profile;
    }
    return _profiles.isEmpty ? null : _profiles.first;
  }

  Future<void> load() async {
    try {
      final observations = await _storage.read(key: 'observations_v1');
      if (observations != null) {
        _observations.addAll(
          (jsonDecode(observations) as List).map(
            (o) => PlayObservation.fromJson(Map<String, dynamic>.from(o)),
          ),
        );
      }
      final works = await _storage.read(key: 'play_works_v1');
      final stories = await _storage.read(key: 'story_progress_v1');
      if (stories != null) {
        final decoded = jsonDecode(stories) as Map<String, dynamic>;
        _storyProgress.addAll(
          decoded.map(
            (key, value) =>
                MapEntry(key, Map<String, dynamic>.from(value as Map)),
          ),
        );
      }
      if (works != null) {
        final decoded = jsonDecode(works) as Map<String, dynamic>;
        _works.addAll(
          decoded.map(
            (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
          ),
        );
      }
      final rawVisibility = await _storage.read(key: 'journey_visibility_v1');
      if (rawVisibility != null) {
        _journeyVisibility.addAll(
          Map<String, bool>.from(jsonDecode(rawVisibility) as Map),
        );
      }
      final rawReviews = await _storage.read(key: 'journey_reviews_v1');
      if (rawReviews != null) {
        _journeyReviews.addAll(
          List<String>.from(jsonDecode(rawReviews) as List),
        );
      }
      final rawAccount = await _storage.read(key: _parentAccountKey);
      if (rawAccount != null) {
        _parentAccount = ParentAccount.fromJson(
          jsonDecode(rawAccount) as Map<String, dynamic>,
        );
      }
      final rawProfiles = await _storage.read(key: _profilesKey);
      final rawRecords = await _storage.read(key: _recordsKey);
      _selectedId = await _storage.read(key: _selectedKey);
      _hasPin = (await _storage.read(key: _pinKey)) != null;
      final rawFailCount = await _storage.read(key: _pinFailCountKey);
      if (rawFailCount != null) {
        _failedPinAttempts = int.tryParse(rawFailCount) ?? 0;
      }
      final rawLockedUntil = await _storage.read(key: _pinLockedUntilKey);
      if (rawLockedUntil != null) {
        final parsed = DateTime.tryParse(rawLockedUntil);
        if (parsed != null && parsed.isAfter(DateTime.now())) {
          _pinLockedUntil = parsed;
        } else {
          await _storage.delete(key: _pinLockedUntilKey);
        }
      }
      if (rawProfiles != null) {
        _profiles.addAll(
          (jsonDecode(rawProfiles) as List<dynamic>).map(
            (row) => ChildProfile.fromJson(row as Map<String, dynamic>),
          ),
        );
      }
      if (rawRecords != null) {
        final cutoff = DateTime.now().subtract(const Duration(days: 90));
        _records.addAll(
          (jsonDecode(rawRecords) as List<dynamic>)
              .map((row) => PlayRecord.fromJson(row as Map<String, dynamic>))
              .where((record) => record.at.isAfter(cutoff)),
        );
      }
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> setParentPin(String pin) async {
    if (!RegExp(r'^\d{4,8}$').hasMatch(pin)) {
      throw const FormatException('PIN은 숫자 4~8자리여야 합니다.');
    }
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final saltText = base64UrlEncode(salt);
    final digest = sha256.convert(utf8.encode('$saltText:$pin'));
    await _storage.write(key: _pinKey, value: 'v2:$saltText:$digest');
    _hasPin = true;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    if (_pinLockedUntil?.isAfter(DateTime.now()) ?? false) return false;
    final stored = await _storage.read(key: _pinKey);
    final parts = stored?.split(':');
    if (parts == null || parts.length != 3 || parts.first != 'v2') {
      return false;
    }
    final calculated = sha256
        .convert(utf8.encode('${parts[1]}:$pin'))
        .toString();
    var difference = calculated.length ^ parts[2].length;
    for (var i = 0; i < min(calculated.length, parts[2].length); i++) {
      difference |= calculated.codeUnitAt(i) ^ parts[2].codeUnitAt(i);
    }
    final ok = difference == 0;
    if (ok) {
      _failedPinAttempts = 0;
      _pinLockedUntil = null;
      await _storage.delete(key: _pinFailCountKey);
      await _storage.delete(key: _pinLockedUntilKey);
    } else {
      _failedPinAttempts++;
      if (_failedPinAttempts >= 5) {
        _pinLockedUntil = DateTime.now().add(const Duration(minutes: 5));
        _failedPinAttempts = 0;
        await _storage.write(
          key: _pinLockedUntilKey,
          value: _pinLockedUntil!.toIso8601String(),
        );
        await _storage.delete(key: _pinFailCountKey);
      } else {
        await _storage.write(
          key: _pinFailCountKey,
          value: '$_failedPinAttempts',
        );
      }
    }
    return ok;
  }

  Future<void> addProfile(ChildProfile profile) async {
    if (_profiles.any((item) => item.id == profile.id)) {
      throw StateError('프로필 ID 중복');
    }
    _profiles.add(profile);
    _selectedId ??= profile.id;
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> updateProfile(ChildProfile profile) async {
    final index = _profiles.indexWhere((item) => item.id == profile.id);
    if (index < 0) throw StateError('존재하지 않는 프로필');
    _profiles[index] = profile;
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> selectProfile(String id) async {
    if (!_profiles.any((item) => item.id == id)) {
      throw StateError('존재하지 않는 프로필');
    }
    _selectedId = id;
    await _storage.write(key: _selectedKey, value: id);
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    if (!_profiles.any((profile) => profile.id == id)) return;
    final directory = await getApplicationDocumentsDirectory();
    final drawings = Directory('${directory.path}/momosup_drawings');
    if (await drawings.exists()) {
      await for (final entry in drawings.list(followLinks: false)) {
        if (entry is File && entry.uri.pathSegments.last.startsWith('${id}_')) {
          await entry.delete();
        }
      }
    }
    await _writeQueue.catchError((Object _) {});
    final remainingWorks = {..._works}
      ..removeWhere((_, w) => w['profileId'] == id);
    await _storage.write(
      key: 'play_works_v1',
      value: jsonEncode(remainingWorks),
    );
    _works
      ..clear()
      ..addAll(remainingWorks);
    await _storeObservations(
      _observations.where((o) => o.profileId != id).toList(),
    );
    _profiles.removeWhere((profile) => profile.id == id);
    await _storyWrites.catchError((Object _) {});
    final remainingStories = {..._storyProgress}
      ..removeWhere((_, value) => value['profileId'] == id);
    await _storage.write(
      key: 'story_progress_v1',
      value: jsonEncode(remainingStories),
    );
    _storyProgress
      ..clear()
      ..addAll(remainingStories);
    _records.removeWhere((record) => record.profileId == id);
    if (_selectedId == id) {
      _selectedId = _profiles.isEmpty ? null : _profiles.first.id;
    }
    await _saveProfiles();
    await _saveRecords();
    notifyListeners();
  }

  Future<FamilyInvitePayload> createFamilyInvite(
    ChildProfile profile, {
    required String inviterRole,
  }) async {
    final familyId = profile.familyId ?? 'fam_${profile.id}';
    final code =
        profile.inviteCode ?? 'MOMO-${(Random().nextInt(8999) + 1000)}-KIDS';
    final inviter = _parentAccount?.nickname ?? '모모보호자';

    final payload = FamilyInvitePayload(
      code: code,
      familyId: familyId,
      childId: profile.id,
      childName: profile.nickname,
      birthDate: profile.birthDate ?? '',
      gender: profile.gender,
      avatar: profile.avatar,
      inviterName: inviter,
      inviterRole: inviterRole,
      ageMonths: profile.ageMonths,
      createdAt: DateTime.now(),
    );

    var updatedMembers = List<FamilyMember>.from(profile.sharedMembers);
    if (!updatedMembers.any((m) => m.isOwner)) {
      updatedMembers.add(
        FamilyMember(
          id: _parentAccount?.id ?? 'owner_${profile.id}',
          name: inviter,
          role: inviterRole,
          isOwner: true,
          joinedAt: DateTime.now(),
        ),
      );
    }

    final updated = profile.copyWith(
      familyId: familyId,
      inviteCode: code,
      ownerParentId: profile.ownerParentId ?? _parentAccount?.id,
      ownerName: profile.ownerName ?? inviter,
      sharedMembers: updatedMembers,
      isShared: true,
    );

    await updateProfile(updated);
    return payload;
  }

  Future<ChildProfile> acceptFamilyInvite(
    String rawCodeOrUrl, {
    required String myName,
    required String myRole,
  }) async {
    final payload = FamilyInvitePayload.fromRaw(rawCodeOrUrl);
    if (payload == null) {
      throw const FormatException('유효하지 않은 초대 코드 또는 링크입니다.');
    }

    final existingIndex = _profiles.indexWhere((p) => p.id == payload.childId);
    if (existingIndex >= 0) {
      final existing = _profiles[existingIndex];
      var members = List<FamilyMember>.from(existing.sharedMembers);
      if (!members.any((m) => m.name == myName && m.role == myRole)) {
        members.add(
          FamilyMember(
            id:
                _parentAccount?.id ??
                'member_${DateTime.now().millisecondsSinceEpoch}',
            name: myName,
            role: myRole,
            isOwner: false,
            joinedAt: DateTime.now(),
          ),
        );
      }
      final updated = existing.copyWith(isShared: true, sharedMembers: members);
      await updateProfile(updated);
      await selectProfile(updated.id);
      return updated;
    }

    final memberList = [
      FamilyMember(
        id: 'owner_${payload.familyId}',
        name: payload.inviterName,
        role: payload.inviterRole,
        isOwner: true,
        joinedAt: payload.createdAt,
      ),
      FamilyMember(
        id:
            _parentAccount?.id ??
            'member_${DateTime.now().millisecondsSinceEpoch}',
        name: myName,
        role: myRole,
        isOwner: false,
        joinedAt: DateTime.now(),
      ),
    ];

    final newProfile = ChildProfile(
      id: payload.childId,
      nickname: payload.childName,
      birthDate: payload.birthDate.isNotEmpty ? payload.birthDate : null,
      gender: payload.gender,
      avatar: payload.avatar,
      ageMonths: payload.ageMonths,
      level: '기본',
      answers: const [3, 3, 3, 3, 3],
      isShared: true,
      familyId: payload.familyId,
      ownerName: payload.inviterName,
      inviteCode: payload.code,
      sharedMembers: memberList,
    );

    await addProfile(newProfile);
    await selectProfile(newProfile.id);
    return newProfile;
  }

  Future<void> leaveFamilyShare(String profileId) async {
    final index = _profiles.indexWhere((p) => p.id == profileId);
    if (index < 0) return;
    await deleteProfile(profileId);
  }

  Future<void> recordPlay({
    required String profileId,
    required String activityId,
    required int seconds,
    String? sessionId,
    Map<String, int> metrics = const {},
  }) async {
    if (!_profiles.any((profile) => profile.id == profileId)) return;
    if (sessionId != null) {
      _records.removeWhere(
        (r) => r.sessionId == sessionId && r.profileId == profileId,
      );
    }
    _records.add(
      PlayRecord(
        profileId: profileId,
        activityId: activityId,
        at: DateTime.now(),
        seconds: seconds.clamp(0, 7 * 60),
        sessionId: sessionId,
        metrics: Map.of(metrics),
      ),
    );
    await _saveRecords();
    notifyListeners();
  }

  int minutesToday(String profileId) {
    final now = DateTime.now();
    final seconds = _records
        .where(
          (record) =>
              record.profileId == profileId &&
              record.at.year == now.year &&
              record.at.month == now.month &&
              record.at.day == now.day,
        )
        .fold<int>(0, (sum, record) => sum + record.seconds);
    return (seconds / 60).ceil();
  }

  Future<void> _saveProfiles() {
    final next = _profileWrites.catchError((Object _) {}).then((_) async {
      await _storage.write(
        key: _profilesKey,
        value: jsonEncode(_profiles.map((profile) => profile.toJson()).toList()),
      );
      if (_selectedId == null) {
        await _storage.delete(key: _selectedKey);
      } else {
        await _storage.write(key: _selectedKey, value: _selectedId);
      }
    });
    _profileWrites = next;
    return next;
  }

  Future<void> _saveRecords() async {
    await _storage.write(
      key: _recordsKey,
      value: jsonEncode(_records.map((record) => record.toJson()).toList()),
    );
  }
}
