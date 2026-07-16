import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/voice_gender.dart';
import '../services/auth_service.dart';

class VoicePreferenceRepository {
  VoicePreferenceRepository._();
  static final VoicePreferenceRepository instance =
      VoicePreferenceRepository._();

  @visibleForTesting
  static String? debugUidOverride;

  @visibleForTesting
  static bool debugForceSignedOut = false;

  String? get _uid {
    if (debugForceSignedOut) return null;
    return debugUidOverride ?? AuthService.instance.currentUser?.uid;
  }

  String _keyFor(String uid) => 'voice_preferences_$uid';

  final Map<String, Future<void>> _writeChains = {};

  @visibleForTesting
  void debugResetForTests() {
    _writeChains.clear();
  }

  Future<Map<String, dynamic>> _loadRaw(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(uid));
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveRaw(String uid, Map<String, dynamic> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(uid), jsonEncode(values));
  }

  Future<T> _afterPendingWrites<T>(String uid, Future<T> Function() action) {
    return (_writeChains[uid] ?? Future<void>.value()).then(
      (_) => action(),
      onError: (_) => action(),
    );
  }

  Future<VoiceGender?> getOverride(String recordingId) {
    final uid = _uid;
    if (uid == null) return Future.value();
    return _afterPendingWrites(uid, () async {
      final raw = await _loadRaw(uid);
      if (!raw.containsKey(recordingId)) return null;
      return VoiceGender.fromMetadata(raw[recordingId]);
    });
  }

  Future<Map<String, VoiceGender>> getAllOverrides() {
    final uid = _uid;
    if (uid == null) return Future.value(const {});
    return _afterPendingWrites(uid, () async {
      final raw = await _loadRaw(uid);
      return raw.map(
        (recordingId, value) =>
            MapEntry(recordingId, VoiceGender.fromMetadata(value)),
      );
    });
  }

  Future<void> setOverride(String recordingId, VoiceGender? gender) {
    final uid = _uid;
    if (uid == null) return Future.value();
    final previous = _writeChains[uid] ?? Future<void>.value();
    late final Future<void> current;
    current = previous
        .then((_) {}, onError: (_) {})
        .then((_) async {
          final raw = await _loadRaw(uid);
          if (gender == null || gender == VoiceGender.unknown) {
            raw.remove(recordingId);
          } else {
            raw[recordingId] = gender.storageValue;
          }
          await _saveRaw(uid, raw);
        })
        .whenComplete(() {
          if (identical(_writeChains[uid], current)) {
            _writeChains.remove(uid);
          }
        });
    _writeChains[uid] = current;
    return current;
  }

  Future<void> clearAllForUid(String uid) {
    final previous = _writeChains[uid] ?? Future<void>.value();
    late final Future<void> current;
    current = previous
        .then((_) {}, onError: (_) {})
        .then((_) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_keyFor(uid));
        })
        .whenComplete(() {
          if (identical(_writeChains[uid], current)) {
            _writeChains.remove(uid);
          }
        });
    _writeChains[uid] = current;
    return current;
  }
}
