import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite.dart';
import 'auth_service.dart';

class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  // Namespaced by UID for the same reason CourseStorage is — otherwise
  // switching accounts on one device would show the previous account's
  // bookmarks.
  //
  // [debugUidOverride] is test-only, mirrors CourseStorage's — lets
  // `flutter test` swap the effective UID without a real Firebase user.
  @visibleForTesting
  static String? debugUidOverride;

  String get _uid =>
      debugUidOverride ?? AuthService.instance.currentUser?.uid ?? 'anonymous';
  String get _key => 'favorites_$_uid';

  Map<String, Favorite> _cache = {};
  String? _cacheUid;

  Future<void> _ensureLoaded() async {
    if (_cacheUid == _uid) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _cache = {};
    if (raw != null) {
      final map = json.decode(raw) as Map<String, dynamic>;
      _cache = map.map(
        (k, v) => MapEntry(k, Favorite.fromJson(v as Map<String, dynamic>)),
      );
    }
    _cacheUid = _uid;
  }

  Future<bool> isFavorite(String id) async {
    await _ensureLoaded();
    return _cache.containsKey(id);
  }

  Future<void> toggle(Favorite fav) async {
    await _ensureLoaded();
    if (_cache.containsKey(fav.id)) {
      _cache.remove(fav.id);
    } else {
      _cache[fav.id] = fav;
    }
    await _persist();
  }

  Future<List<Favorite>> getAll() async {
    await _ensureLoaded();
    final list = _cache.values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return list;
  }

  Future<void> remove(String id) async {
    await _ensureLoaded();
    _cache.remove(id);
    await _persist();
  }

  /// Cascade delete: called from CourseStorage.delete() so a removed
  /// course never leaves behind bookmarks pointing at exercises that no
  /// longer exist.
  Future<void> removeByCourse(String courseId) async {
    await removeByCourseForUid(courseId, _uid);
  }

  /// UID-explicit variant used by background/cascading storage work. The
  /// signed-in account can change across an async filesystem operation; a
  /// delete that started for A must never remove B's favorites afterward.
  Future<void> removeByCourseForUid(String courseId, String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'favorites_$uid';
    final raw = prefs.getString(key);
    final favorites = <String, Favorite>{};
    if (raw != null) {
      final map = json.decode(raw) as Map<String, dynamic>;
      favorites.addAll(
        map.map(
          (k, v) => MapEntry(k, Favorite.fromJson(v as Map<String, dynamic>)),
        ),
      );
    }
    favorites.removeWhere((_, favorite) => favorite.courseId == courseId);
    await prefs.setString(
      key,
      json.encode(favorites.map((k, v) => MapEntry(k, v.toJson()))),
    );
    if (_cacheUid == uid) _cache = favorites;
  }

  /// Wipes every locally cached favorite for the current UID — mirrors
  /// CourseStorage.deleteAllLocal(), called from the same account-deletion
  /// flow (favorites just reference course/exercise ids, and the courses
  /// they point at are already gone server-side by the time this runs).
  Future<void> clearAll() async {
    await clearAllForUid(_uid);
  }

  /// UID-explicit account-deletion variant; never clears a newly signed-in
  /// user's favorites if the preceding network request belonged to old UID.
  Future<void> clearAllForUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('favorites_$uid');
    if (_cacheUid == uid) _cache = {};
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      json.encode(_cache.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }
}
