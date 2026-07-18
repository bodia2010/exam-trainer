import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/parsed_course.dart';
import 'api_config.dart';
import 'auth_service.dart';
import 'favorites_service.dart';

/// Visible cloud-sync outcome for one course, derived from the persistent
/// outbox in [CourseStorage.syncStates]. `synced` also covers courses that
/// never needed sync (e.g. freshly downloaded from the cloud).
enum CourseSyncState { synced, pending, syncing, error }

/// One durable outbox entry: "this course still needs an upsert/delete sent
/// to the backend". Persisted so an app kill or offline period doesn't lose
/// the operation the way the old in-memory fire-and-forget calls did.
class _OutboxOp {
  _OutboxOp({
    String? operationId,
    required this.courseId,
    required this.isDelete,
    this.attempts = 0,
    DateTime? nextAttemptAt,
  }) : operationId = operationId ?? const Uuid().v4(),
       nextAttemptAt = nextAttemptAt ?? DateTime.now();

  final String operationId;
  final String courseId;
  final bool isDelete;
  int attempts;
  DateTime nextAttemptAt;

  Map<String, dynamic> toJson() => {
    'operationId': operationId,
    'courseId': courseId,
    'isDelete': isDelete,
    'attempts': attempts,
    'nextAttemptAt': nextAttemptAt.toIso8601String(),
  };

  static _OutboxOp? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final courseId = json['courseId'];
    final isDelete = json['isDelete'];
    if (courseId is! String || isDelete is! bool) return null;
    final attempts = json['attempts'];
    final nextRaw = json['nextAttemptAt'];
    return _OutboxOp(
      operationId: json['operationId'] is String
          ? json['operationId'] as String
          : 'legacy:$courseId:$isDelete',
      courseId: courseId,
      isDelete: isDelete,
      attempts: attempts is int ? attempts : 0,
      nextAttemptAt: nextRaw is String
          ? (DateTime.tryParse(nextRaw) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

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

  /// Test seam for stubbing the cloud sync HTTP calls (upload/delete/fetch).
  /// `null` (the default, untouched in production) means "use the shared
  /// production client".
  @visibleForTesting
  static http.Client? debugHttpClient;

  /// Lets tests exercise the production retry timer without waiting seconds.
  @visibleForTesting
  static Duration? debugBaseBackoffOverride;

  final http.Client _productionHttpClient = http.Client();
  http.Client get _httpClient => debugHttpClient ?? _productionHttpClient;

  /// Test seam standing in for [AuthService.requireIdToken] — a plain unit
  /// test has no real signed-in Firebase user/app, so without this every
  /// cloud sync call would fail before [debugHttpClient] is ever reached.
  /// `null` (the default, untouched in production) means "use the real
  /// Firebase ID token" exactly as before this existed.
  @visibleForTesting
  static Future<String> Function()? debugIdTokenOverride;

  String get _uid =>
      debugUidOverride ?? AuthService.instance.currentUser?.uid ?? 'anonymous';
  String _prefsKeyFor(String uid) => 'course_ids_$uid';

  /// Visible, per-course cloud sync outcome computed from the persistent
  /// outbox (see [_OutboxOp]). Absent keys mean `synced`. Callers read
  /// [syncStateFor] rather than this map directly.
  final ValueNotifier<Map<String, CourseSyncState>> syncStates = ValueNotifier(
    const {},
  );

  /// Course ids currently mid-flight in [_flushOutboxForUid], used only to report
  /// [CourseSyncState.syncing] while a request is outstanding.
  final Set<String> _inFlight = {};
  final Map<String, Future<void>> _outboxMutationChains = {};
  final Map<String, Future<void>> _flushFutures = {};
  final Map<String, Timer> _retryTimers = {};
  final Set<String> _syncSuspended = {};

  static const _baseBackoff = Duration(seconds: 5);
  static const _maxBackoff = Duration(minutes: 30);

  CourseSyncState syncStateFor(String courseId) =>
      syncStates.value[courseId] ?? CourseSyncState.synced;

  Future<void> _writeLocal(ParsedCourse course, {String? forUid}) async {
    final uid = forUid ?? _uid;
    final dir = await _dirFor(uid);
    final destination = File('${dir.path}/${course.id}.json');
    final temporary = File('${destination.path}.tmp');

    // Never write through the last known-good file. A crash can leave the
    // temporary file incomplete, while rename commits a fully flushed file
    // as one filesystem operation.
    await temporary.writeAsString(jsonEncode(course.toJson()), flush: true);
    await debugBeforeLocalCommit?.call(temporary, destination);
    await temporary.rename(destination.path);

    final prefs = await SharedPreferences.getInstance();
    final prefsKey = _prefsKeyFor(uid);
    final ids = prefs.getStringList(prefsKey) ?? [];
    if (!ids.contains(course.id)) {
      await prefs.setStringList(prefsKey, [...ids, course.id]);
    }
  }

  Future<Map<String, String>> _authHeadersForUid(String uid) async {
    if (_uid != uid) {
      throw StateError('Cloud sync account changed before authentication.');
    }
    final token =
        await (debugIdTokenOverride?.call() ??
            AuthService.instance.requireIdToken());
    if (_uid != uid) {
      throw StateError('Cloud sync account changed during authentication.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  String _outboxKeyFor(String uid) => 'course_sync_outbox_$uid';

  /// Every outbox read/write below takes an explicit [uid] captured by the
  /// caller up front, rather than reading the live [_uid] getter — the
  /// flush this feeds runs in the background (see [_flushOutboxForUid]) and must
  /// keep operating on the outbox of the account that queued it even if
  /// the signed-in user changes (or a test overrides [debugUidOverride])
  /// while that flush is still in flight.
  Future<List<_OutboxOp>> _loadOutbox(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_outboxKeyFor(uid));
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map(_OutboxOp.fromJson).whereType<_OutboxOp>().toList();
    } catch (error) {
      // Preserve the raw payload for diagnostics/recovery before a later
      // mutation replaces the active key with a valid queue.
      final quarantineKey = '${_outboxKeyFor(uid)}_corrupt';
      if (!prefs.containsKey(quarantineKey)) {
        await prefs.setString(quarantineKey, raw);
      }
      debugPrint('Course sync outbox is unreadable for $uid: $error');
      return [];
    }
  }

  Future<void> _saveOutbox(String uid, List<_OutboxOp> ops) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _outboxKeyFor(uid),
      jsonEncode(ops.map((op) => op.toJson()).toList()),
    );
  }

  String _inFlightKey(String uid, String courseId) => '$uid\u0000$courseId';

  void _publishSyncStates(String uid, List<_OutboxOp> ops) {
    if (_uid != uid) return;
    final map = <String, CourseSyncState>{};
    for (final op in ops) {
      map[op.courseId] = _inFlight.contains(_inFlightKey(uid, op.courseId))
          ? CourseSyncState.syncing
          : (op.attempts > 0 ? CourseSyncState.error : CourseSyncState.pending);
    }
    syncStates.value = Map.unmodifiable(map);
  }

  Future<void> _mutateOutbox(
    String uid,
    void Function(List<_OutboxOp> ops) mutate,
  ) {
    final previous = _outboxMutationChains[uid] ?? Future<void>.value();
    late final Future<void> current;
    current = previous
        .catchError((_) {})
        .then((_) async {
          final ops = await _loadOutbox(uid);
          mutate(ops);
          await _saveOutbox(uid, ops);
          _publishSyncStates(uid, ops);
          _scheduleRetry(uid, ops);
        })
        .whenComplete(() {
          if (identical(_outboxMutationChains[uid], current)) {
            _outboxMutationChains.remove(uid);
          }
        });
    _outboxMutationChains[uid] = current;
    return current;
  }

  void _scheduleRetry(String uid, List<_OutboxOp> ops) {
    _retryTimers.remove(uid)?.cancel();
    if (_uid != uid || ops.isEmpty || _syncSuspended.contains(uid)) return;
    final next = ops
        .map((op) => op.nextAttemptAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final delay = next.difference(DateTime.now());
    _retryTimers[uid] = Timer(delay.isNegative ? Duration.zero : delay, () {
      _retryTimers.remove(uid);
      if (_uid == uid) unawaited(_flushOutboxForUid(uid));
    });
  }

  /// Durably records that [courseId] still needs an upsert/delete sent to
  /// the backend, replacing any earlier pending op for the same id (e.g. a
  /// delete right after a save supersedes the pending upsert — there is
  /// nothing left locally to upload).
  Future<void> _enqueueOutboxOp(
    String uid,
    String courseId, {
    required bool isDelete,
  }) => _mutateOutbox(uid, (ops) {
    ops.removeWhere((op) => op.courseId == courseId);
    ops.add(_OutboxOp(courseId: courseId, isDelete: isDelete));
  });

  Duration _backoffFor(int attempts) {
    final base = debugBaseBackoffOverride ?? _baseBackoff;
    final factor = 1 << attempts.clamp(0, 8);
    final milliseconds = (base.inMilliseconds * factor).clamp(
      base.inMilliseconds,
      _maxBackoff.inMilliseconds,
    );
    return Duration(milliseconds: milliseconds);
  }

  Future<Directory> _dirFor(String uid) async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/courses/$uid');
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  /// `POST /api/courses` upserts by course id and is safe to resend, but a
  /// 200 response can still carry `saved: false` (oversized course or a
  /// Firestore error) — only a decoded `saved: true` counts as delivered.
  Future<bool> _uploadRemoteById(String uid, String courseId) async {
    final dir = await _dirFor(uid);
    final file = File('${dir.path}/$courseId.json');
    if (!await file.exists()) return false;
    final ParsedCourse course;
    try {
      final json = jsonDecode(await file.readAsString());
      course = ParsedCourse.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      // Keep the operation visible as failed. Treating unreadable local data
      // as delivered would silently discard the only recovery signal.
      return false;
    }
    try {
      final res = await _httpClient
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/courses'),
            headers: await _authHeadersForUid(uid),
            body: jsonEncode({'course': course.toJson()}),
          )
          .timeout(_cloudTimeout);
      if (res.statusCode != 200) return false;
      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic> && decoded['saved'] == true;
    } catch (e) {
      debugPrint('Course cloud upload failed: $e');
      return false;
    }
  }

  /// `DELETE /api/courses/<id>` is idempotent server-side (always 200, even
  /// if the doc was already gone), so any non-200/timeout/network error is
  /// the only signal worth retrying on.
  Future<bool> _deleteRemoteById(String uid, String courseId) async {
    try {
      final res = await _httpClient
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/api/courses/$courseId'),
            headers: await _authHeadersForUid(uid),
          )
          .timeout(_cloudTimeout);
      if (res.statusCode != 200) return false;
      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic> && decoded['ok'] == true;
    } catch (e) {
      debugPrint('Course cloud delete failed: $e');
      return false;
    }
  }

  /// Attempts every due outbox op once. Best-effort and re-entrant safe:
  /// called opportunistically from [save], [delete] and [loadAll], and by a
  /// retry timer after failures. Concurrent calls share the same per-UID
  /// in-flight run rather than racing two flushes over the same ops.
  /// Captures [_uid] synchronously at call time (see [_loadOutbox]'s doc)
  /// so a later sign-out/sign-in can't redirect this run mid-flight.
  Future<void> _flushOutboxForUid(String uid) {
    final existing = _flushFutures[uid];
    if (existing != null) return existing;
    late final Future<void> current;
    current = _runFlush(uid).whenComplete(() {
      if (identical(_flushFutures[uid], current)) _flushFutures.remove(uid);
    });
    _flushFutures[uid] = current;
    return current;
  }

  Future<void> _runFlush(String uid) async {
    if (_syncSuspended.contains(uid)) return;
    await (_outboxMutationChains[uid] ?? Future<void>.value());
    final ops = await _loadOutbox(uid);
    if (ops.isEmpty) {
      _publishSyncStates(uid, ops);
      return;
    }
    final now = DateTime.now();
    for (final op in List<_OutboxOp>.from(ops)) {
      if (_syncSuspended.contains(uid)) return;
      if (op.nextAttemptAt.isAfter(now)) continue;
      if (_uid != uid) return;
      final inFlightKey = _inFlightKey(uid, op.courseId);
      _inFlight.add(inFlightKey);
      _publishSyncStates(uid, ops);
      final delivered = op.isDelete
          ? await _deleteRemoteById(uid, op.courseId)
          : await _uploadRemoteById(uid, op.courseId);
      _inFlight.remove(inFlightKey);
      await _mutateOutbox(uid, (latest) {
        final index = latest.indexWhere(
          (candidate) => candidate.operationId == op.operationId,
        );
        if (index < 0) return;
        if (delivered) {
          latest.removeAt(index);
        } else {
          final current = latest[index];
          current.attempts++;
          current.nextAttemptAt = DateTime.now().add(
            _backoffFor(current.attempts),
          );
        }
      });
    }
    final latest = await _loadOutbox(uid);
    _publishSyncStates(uid, latest);
    _scheduleRetry(uid, latest);
  }

  /// Public retry hook (e.g. a manual "retry sync" action or pull-to-refresh)
  /// beyond the automatic opportunistic flush points.
  Future<void> retrySyncNow() async {
    final uid = _uid;
    if (_syncSuspended.contains(uid)) return;
    await _mutateOutbox(uid, (ops) {
      final now = DateTime.now();
      for (final op in ops) {
        op.nextAttemptAt = now;
      }
    });
    await _flushOutboxForUid(uid);
  }

  /// Test seam so a test can deterministically await the flush that [save]
  /// / [delete] fire in the background instead of guessing how many event
  /// loop turns their fire-and-forget call needs.
  @visibleForTesting
  Future<void>? get debugPendingFlush => _flushFutures[_uid];

  /// Clears singleton-only scheduling state between unit tests. Callers must
  /// await any captured [debugPendingFlush] before invoking this helper.
  @visibleForTesting
  void debugResetSyncStateForTests() {
    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    _retryTimers.clear();
    _outboxMutationChains.clear();
    _flushFutures.clear();
    _inFlight.clear();
    _syncSuspended.clear();
    syncStates.value = const {};
  }

  /// Stops new cloud work for the current UID and waits until any request
  /// already in flight has settled. Account deletion calls this before its
  /// backend DELETE so an older upload cannot finish afterwards and recreate
  /// data that the deletion just removed.
  Future<String> suspendCloudSyncForAccountDeletion() async {
    final uid = _uid;
    _syncSuspended.add(uid);
    _retryTimers.remove(uid)?.cancel();
    await (_outboxMutationChains[uid] ?? Future<void>.value());
    await (_flushFutures[uid] ?? Future<void>.value());
    return uid;
  }

  /// Restores delivery when account deletion failed and the account remains.
  void resumeCloudSyncAfterAccountDeletionFailure(String uid) {
    if (!_syncSuspended.remove(uid)) return;
    if (_uid == uid) unawaited(_flushOutboxForUid(uid));
  }

  Future<List<ParsedCourse>> _fetchRemote(String uid) async {
    final res = await _httpClient
        .get(
          Uri.parse('${ApiConfig.baseUrl}/api/courses'),
          headers: await _authHeadersForUid(uid),
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
    final uid = _uid;
    await _writeLocal(course, forUid: uid);
    revision.value++;
    await _enqueueOutboxOp(uid, course.id, isDelete: false);
    if (_uid == uid && !_syncSuspended.contains(uid)) {
      unawaited(_flushOutboxForUid(uid));
    }
  }

  Future<_LocalLoadResult> _loadLocal(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final prefsKey = _prefsKeyFor(uid);
    final ids = prefs.getStringList(prefsKey) ?? [];
    final dir = await _dirFor(uid);
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
      await prefs.setStringList(prefsKey, retainedIds);
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
    final uid = _uid;
    final localLoad = await _loadLocal(uid);
    // A signed-out/in session can change while the filesystem is being read.
    // Never hand an already-loaded previous account's courses to the caller:
    // every screen is not necessarily protected by HomeViewModel's auth
    // generation guard.
    if (_uid != uid) return const [];
    final local = localLoad.courses;
    if (_syncSuspended.contains(uid)) return local;
    if (_uid == uid) unawaited(_flushOutboxForUid(uid));
    try {
      final localIds = local.map((c) => c.id).toSet();
      final pendingDeleteIds = (await _loadOutbox(
        uid,
      )).where((op) => op.isDelete).map((op) => op.courseId).toSet();
      final remote = await _fetchRemote(uid);
      if (_uid != uid) return const [];
      final newOnes = remote
          .where(
            (c) => !localIds.contains(c.id) && !pendingDeleteIds.contains(c.id),
          )
          .where((c) => !localLoad.unreadableWithoutBackup.contains(c.id))
          .toList();
      if (newOnes.isEmpty) return _uid == uid ? local : const [];
      for (final course in newOnes) {
        if (_uid != uid) return const [];
        await _writeLocal(course, forUid: uid);
        if (_uid != uid) return const [];
      }
      return _uid == uid ? [...local, ...newOnes] : const [];
    } catch (e) {
      if (_uid != uid) return const [];
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
    await deleteAllLocalForUid(_uid);
  }

  /// UID-explicit account-deletion variant. The auth session can change while
  /// the backend request is pending; only the account that initiated deletion
  /// may be cleared locally.
  Future<void> deleteAllLocalForUid(String uid) async {
    final dir = await _dirFor(uid);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyFor(uid));
    await prefs.remove(_outboxKeyFor(uid));
    _retryTimers.remove(uid)?.cancel();
    syncStates.value = const {};
    revision.value++;
  }

  Future<void> delete(String id) async {
    final uid = _uid;
    final dir = await _dirFor(uid);
    final f = File('${dir.path}/$id.json');
    if (f.existsSync()) f.deleteSync();
    final prefs = await SharedPreferences.getInstance();
    final prefsKey = _prefsKeyFor(uid);
    final ids = (prefs.getStringList(prefsKey) ?? [])..remove(id);
    await prefs.setStringList(prefsKey, ids);
    await FavoritesService.instance.removeByCourseForUid(id, uid);
    await _enqueueOutboxOp(uid, id, isDelete: true);
    revision.value++;
    if (_uid == uid && !_syncSuspended.contains(uid)) {
      unawaited(_flushOutboxForUid(uid));
    }
  }
}

class _LocalLoadResult {
  const _LocalLoadResult(this.courses, this.unreadableWithoutBackup);

  final List<ParsedCourse> courses;
  final Set<String> unreadableWithoutBackup;
}
