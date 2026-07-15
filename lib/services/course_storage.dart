import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/parsed_course.dart';
import 'api_config.dart';
import 'auth_service.dart';
import 'favorites_service.dart';

class CourseStorage {
  CourseStorage._();
  static final instance = CourseStorage._();
  static const _cloudTimeout = Duration(seconds: 15);

  /// Bumped after every save/delete. GoRouter's `go('/')` can land back on
  /// an already-existing Home page instance instead of a fresh one (same
  /// route key), so Home can't rely on initState alone to pick up a course
  /// saved while it was off-screen — it listens to this instead.
  final ValueNotifier<int> revision = ValueNotifier(0);

  /// Every file/pref is namespaced by the signed-in user's UID. Without
  /// this, signing out of a premium account and into a free one on the
  /// same device would show the premium account's fully-parsed courses —
  /// the free-tier server-side limit (1 variant/section) is pointless if
  /// the previously-parsed full course is just sitting in shared local
  /// storage for whoever logs in next.
  /// Test-only override for [_uid]. `null` (the default, untouched in
  /// production) means "use the real signed-in Firebase user" exactly as
  /// before — this only exists so `flutter test` can exercise per-UID
  /// isolation without a real Firebase app/user, which a plain unit test
  /// environment doesn't have.
  @visibleForTesting
  static String? debugUidOverride;

  /// Test seam for simulating a process/filesystem failure after the
  /// replacement file has been fully flushed, but before it is committed.
  /// Production never assigns this callback.
  @visibleForTesting
  static FutureOr<void> Function(File temporary, File destination)?
  debugBeforeLocalCommit;

  String get _uid =>
      debugUidOverride ?? AuthService.instance.currentUser?.uid ?? 'anonymous';
  String get _prefsKey => 'course_ids_$_uid';

  /// Course ids deleted locally this session, whose cloud DELETE may still
  /// be in flight (it's fire-and-forget — see [delete]). Live bug: [_load]
  /// in HomeScreen runs [loadAll] right after a delete, and [loadAll]'s
  /// cross-device merge treats anything still on the server as "new" and
  /// re-downloads it — resurrecting the course locally before the cloud
  /// delete had a chance to land, so it reappeared after the first tap and
  /// only actually deleted on a second attempt (once the first DELETE had
  /// finished server-side). Never pruned: a genuinely new course always
  /// gets a fresh uuid, so a once-deleted id has no legitimate reason to
  /// come back for this account.
  final Set<String> _pendingDeletes = {};

  Future<Directory> get _dir async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/courses/$_uid');
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  Future<void> _writeLocal(ParsedCourse course) async {
    final dir = await _dir;
    final destination = File('${dir.path}/${course.id}.json');
    final temporary = File('${destination.path}.tmp');

    // Never write through the last known-good file. A crash can leave the
    // temporary file incomplete, while rename commits a fully flushed file
    // as one filesystem operation.
    await temporary.writeAsString(jsonEncode(course.toJson()), flush: true);
    await debugBeforeLocalCommit?.call(temporary, destination);
    await temporary.rename(destination.path);

    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_prefsKey) ?? [];
    if (!ids.contains(course.id)) {
      await prefs.setStringList(_prefsKey, [...ids, course.id]);
    }
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.instance.requireIdToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Best-effort — a save must succeed locally regardless of network
  /// state, so this is fire-and-forget from [save] rather than awaited.
  Future<void> _uploadRemote(ParsedCourse course) async {
    try {
      await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/courses'),
            headers: await _authHeaders(),
            body: jsonEncode({'course': course.toJson()}),
          )
          .timeout(_cloudTimeout);
    } catch (e) {
      debugPrint('Course cloud upload failed: $e');
    }
  }

  Future<List<ParsedCourse>> _fetchRemote() async {
    final res = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/api/courses'),
          headers: await _authHeaders(),
        )
        .timeout(_cloudTimeout);
    if (res.statusCode != 200) return [];
    final list =
        (jsonDecode(res.body) as Map<String, dynamic>)['courses']
            as List<dynamic>;
    final result = <ParsedCourse>[];
    for (final j in list) {
      try {
        result.add(ParsedCourse.fromJson(j as Map<String, dynamic>));
      } catch (_) {
        // Skip anything that doesn't match the current schema.
      }
    }
    return result;
  }

  Future<void> save(ParsedCourse course) async {
    await _writeLocal(course);
    revision.value++;
    unawaited(_uploadRemote(course));
  }

  Future<_LocalLoadResult> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_prefsKey) ?? [];
    final dir = await _dir;
    final result = <ParsedCourse>[];
    final unreadableWithoutBackup = <String>{};
    final retainedIds = <String>[];
    for (final id in ids.toSet()) {
      final file = File('${dir.path}/$id.json');
      final temporary = File('${file.path}.tmp');

      if (!await file.exists()) {
        // A crash between flush and rename can leave a complete temporary
        // file. Recover it only when no committed version exists.
        final recovered = await _recoverTemporary(temporary, file);
        if (!recovered) {
          debugPrint('Course file is missing for id $id');
          continue;
        }
      }

      retainedIds.add(id);
      try {
        final json = jsonDecode(await file.readAsString());
        result.add(ParsedCourse.fromJson(json as Map<String, dynamic>));
      } catch (error) {
        // Preserve the exact bytes before a cloud merge can restore this id
        // over the unreadable destination. Keep the preference entry too so
        // an offline load remains diagnosable and recoverable.
        final preserved = await _preserveCorruptFile(file);
        if (!preserved) unreadableWithoutBackup.add(id);
        debugPrint('Skipping unreadable course $id: $error');
      }
    }

    // Missing files cannot be loaded and keeping their stale ids causes the
    // same failed lookup forever. Corrupt files remain listed above so no
    // potentially recoverable user data is deleted.
    if (!listEquals(ids, retainedIds)) {
      await prefs.setStringList(_prefsKey, retainedIds);
    }
    return _LocalLoadResult(result, unreadableWithoutBackup);
  }

  Future<bool> _preserveCorruptFile(File source) async {
    try {
      var quarantine = File('${source.path}.corrupt');
      var suffix = 1;
      while (await quarantine.exists()) {
        if (await source.length() == await quarantine.length() &&
            listEquals(
              await source.readAsBytes(),
              await quarantine.readAsBytes(),
            )) {
          return true;
        }
        quarantine = File('${source.path}.corrupt.$suffix');
        suffix++;
      }
      await source.copy(quarantine.path);
      return true;
    } catch (error) {
      // The original remains untouched. The caller prevents cloud merge from
      // overwriting this id when no diagnostic copy could be secured.
      debugPrint('Could not preserve unreadable course ${source.path}: $error');
      return false;
    }
  }

  Future<bool> _recoverTemporary(File temporary, File destination) async {
    if (!await temporary.exists()) return false;
    try {
      final json = jsonDecode(await temporary.readAsString());
      ParsedCourse.fromJson(json as Map<String, dynamic>);
      await temporary.rename(destination.path);
      return true;
    } catch (error) {
      debugPrint(
        'Course temporary file is not recoverable at ${temporary.path}: '
        '$error',
      );
      return false;
    }
  }

  /// Merges in any course imported from a different device under the same
  /// account — without this, "import on phone, open on tablet" would
  /// silently show nothing until re-importing the same PDF a second time.
  /// Purely additive and best-effort: a cloud fetch failure (offline, cold
  /// start, ...) just falls back to whatever's already on this device.
  Future<List<ParsedCourse>> loadAll() async {
    final localLoad = await _loadLocal();
    final local = localLoad.courses;
    try {
      final localIds = local.map((c) => c.id).toSet();
      final remote = await _fetchRemote();
      final newOnes = remote
          .where(
            (c) => !localIds.contains(c.id) && !_pendingDeletes.contains(c.id),
          )
          .where((c) => !localLoad.unreadableWithoutBackup.contains(c.id))
          .toList();
      if (newOnes.isEmpty) return local;
      for (final course in newOnes) {
        await _writeLocal(course);
      }
      return [...local, ...newOnes];
    } catch (e) {
      debugPrint('Course cloud sync failed: $e');
      return local;
    }
  }

  /// Wipes every locally cached course for the current UID — the whole
  /// per-UID directory plus the id-list pref, not a per-course loop, since
  /// this is only ever called right after the backend confirms the
  /// account's Firestore data is gone (account deletion) and nothing
  /// local should survive that. Does NOT touch favorites — the caller
  /// (account-deletion flow) clears those separately.
  Future<void> deleteAllLocal() async {
    final dir = await _dir;
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    revision.value++;
  }

  Future<void> delete(String id) async {
    _pendingDeletes.add(id);
    final dir = await _dir;
    final f = File('${dir.path}/$id.json');
    if (f.existsSync()) f.deleteSync();
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_prefsKey) ?? [])..remove(id);
    await prefs.setStringList(_prefsKey, ids);
    await FavoritesService.instance.removeByCourse(id);
    revision.value++;
    unawaited(
      http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/api/courses/$id'),
            headers: await _authHeaders(),
          )
          .timeout(_cloudTimeout)
          .catchError((e) {
            debugPrint('Course cloud delete failed: $e');
            return http.Response('', 0);
          }),
    );
  }
}

class _LocalLoadResult {
  const _LocalLoadResult(this.courses, this.unreadableWithoutBackup);

  final List<ParsedCourse> courses;
  final Set<String> unreadableWithoutBackup;
}
