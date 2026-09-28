import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../models/child_profile.dart';

class PlayRecord {
  const PlayRecord({
    required this.profileId,
    required this.activityId,
    required this.at,
    required this.seconds,
  });

  final String profileId;
  final String activityId;
  final DateTime at;
  final int seconds;

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'activityId': activityId,
    'at': at.toIso8601String(),
    'seconds': seconds,
  };

  factory PlayRecord.fromJson(Map<String, dynamic> json) => PlayRecord(
    profileId: json['profileId'] as String,
    activityId: json['activityId'] as String,
    at: DateTime.parse(json['at'] as String),
    seconds: json['seconds'] as int,
  );
}

class AppState extends ChangeNotifier {
  AppState({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _profilesKey = 'prototype_profiles_v1';
  static const _selectedKey = 'prototype_selected_v1';
  static const _pinKey = 'prototype_parent_pin_v1';
  static const _recordsKey = 'prototype_records_v1';

  final FlutterSecureStorage _storage;
  final List<ChildProfile> _profiles = [];
  final List<PlayRecord> _records = [];
  String? _selectedId;
  bool _hasPin = false;
  bool _loaded = false;
  int _failedPinAttempts = 0;
  DateTime? _pinLockedUntil;

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
      final rawProfiles = await _storage.read(key: _profilesKey);
      final rawRecords = await _storage.read(key: _recordsKey);
      _selectedId = await _storage.read(key: _selectedKey);
      _hasPin = (await _storage.read(key: _pinKey)) != null;
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
    } else {
      _failedPinAttempts++;
      if (_failedPinAttempts >= 5) {
        _pinLockedUntil = DateTime.now().add(const Duration(minutes: 5));
        _failedPinAttempts = 0;
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
    _profiles.removeWhere((profile) => profile.id == id);
    _records.removeWhere((record) => record.profileId == id);
    if (_selectedId == id) {
      _selectedId = _profiles.isEmpty ? null : _profiles.first.id;
    }
    await _saveProfiles();
    await _saveRecords();
    notifyListeners();
  }

  Future<void> recordPlay({
    required String profileId,
    required String activityId,
    required int seconds,
  }) async {
    if (!_profiles.any((profile) => profile.id == profileId)) return;
    _records.add(
      PlayRecord(
        profileId: profileId,
        activityId: activityId,
        at: DateTime.now(),
        seconds: seconds.clamp(0, 7 * 60),
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

  Future<void> _saveProfiles() async {
    await _storage.write(
      key: _profilesKey,
      value: jsonEncode(_profiles.map((profile) => profile.toJson()).toList()),
    );
    if (_selectedId == null) {
      await _storage.delete(key: _selectedKey);
    } else {
      await _storage.write(key: _selectedKey, value: _selectedId);
    }
  }

  Future<void> _saveRecords() async {
    await _storage.write(
      key: _recordsKey,
      value: jsonEncode(_records.map((record) => record.toJson()).toList()),
    );
  }
}
