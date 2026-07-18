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
    this.expectedRevision = 0,
    this.attempts = 0,
    DateTime? nextAttemptAt,
  }) : operationId = operationId ?? const Uuid().v4(),
       nextAttemptAt = nextAttemptAt ?? DateTime.now();

  final String operationId;
  final String courseId;
  final bool isDelete;
  // Added after the original durable outbox shipped. Missing values in an
  // old queue mean "this client has never observed a server revision".
  int expectedRevision;
  int attempts;
  DateTime nextAttemptAt;

  Map<String, dynamic> toJson() => {
    'operationId': operationId,
    'courseId': courseId,
    'isDelete': isDelete,
    'expectedRevision': expectedRevision,
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
      expectedRevision: (json['expectedRevision'] as num?)?.toInt() ?? 0,
      attempts: attempts is int ? attempts : 0,
      nextAttemptAt: nextRaw is String
          ? (DateTime.tryParse(nextRaw) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Per-course sync data deliberately lives outside [ParsedCourse]. Keeping
/// revisions and tombstones in a per-UID preference map preserves the course
/// JSON format used by existing local files, caches and the production API.
class _CourseSyncMetadata {
  const _CourseSyncMetadata({required this.revision, required this.tombstone});

  final int revision;
  final bool tombstone;

  Map<String, dynamic> toJson() => {
    'revision': revision,
    'tombstone': tombstone,
  };

  static _CourseSyncMetadata? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final revision = value['revision'];
    if (revision is! num) return null;
    return _CourseSyncMetadata(
      revision: revision.toInt(),
      tombstone: value['tombstone'] == true,
    );
  }
}

class _RemoteSnapshot {
  const _RemoteSnapshot({required this.courses, required this.sync});

  final List<ParsedCourse> courses;
  final Map<String, _CourseSyncMetadata> sync;
}

enum _DeliveryKind { delivered, conflict, failed }

class _DeliveryResult {
  const _DeliveryResult(this.kind, {this.revision, this.remoteDeleted = false});

  const _DeliveryResult.failed() : this(_DeliveryKind.failed);

  final _DeliveryKind kind;
  final int? revision;
  final bool remoteDeleted;
}

class CourseStorage {
  CourseStorage._();
  static final instance = CourseStorage._();
  static const _cloudTimeout = Duration(seconds: 15);
  static final _safeCourseId = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  bool _isSafeCourseId(String id) => _safeCourseId.hasMatch(id);

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
  final Map<String, Future<void>> _metadataMutationChains = {};
  final Map<String, Future<void>> _flushFutures = {};
  final Map<String, Timer> _retryTimers = {};
  final Set<String> _syncSuspended = {};

  static const _baseBackoff = Duration(seconds: 5);
  static const _maxBackoff = Duration(minutes: 30);

  CourseSyncState syncStateFor(String courseId) =>
      syncStates.value[courseId] ?? CourseSyncState.synced;

  Future<void> _writeLocal(ParsedCourse course, {String? forUid}) async {
    if (!_isSafeCourseId(course.id)) {
      throw ArgumentError.value(course.id, 'course.id', 'Unsafe course id');
    }
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
  String _metadataKeyFor(String uid) => 'course_sync_metadata_$uid';

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

  Future<Map<String, _CourseSyncMetadata>> _loadMetadata(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_metadataKeyFor(uid));
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return {};
      final metadata = <String, _CourseSyncMetadata>{};
      for (final entry in decoded.entries) {
        final parsed = _CourseSyncMetadata.fromJson(entry.value);
        if (parsed != null) metadata[entry.key] = parsed;
      }
      return metadata;
    } catch (error) {
      final quarantineKey = '${_metadataKeyFor(uid)}_corrupt';
      if (!prefs.containsKey(quarantineKey)) {
        await prefs.setString(quarantineKey, raw);
      }
      debugPrint('Course sync metadata is unreadable for $uid: $error');
      return {};
    }
  }

  Future<void> _saveMetadata(
    String uid,
    Map<String, _CourseSyncMetadata> metadata,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _metadataKeyFor(uid),
      jsonEncode(metadata.map((id, value) => MapEntry(id, value.toJson()))),
    );
  }

  Future<void> _updateMetadata(
    String uid,
    void Function(Map<String, _CourseSyncMetadata> metadata) update,
  ) {
    // Like the outbox, metadata is per-UID and can be touched by a background
    // flush while Home is merging GET results. Serialize read-modify-write so
    // one finished request cannot erase another request's tombstone/revision.
    final previous = _metadataMutationChains[uid] ?? Future<void>.value();
    late final Future<void> current;
    current = previous
        .catchError((_) {})
        .then((_) async {
          final metadata = await _loadMetadata(uid);
          update(metadata);
          await _saveMetadata(uid, metadata);
        })
        .whenComplete(() {
          if (identical(_metadataMutationChains[uid], current)) {
            _metadataMutationChains.remove(uid);
          }
        });
    _metadataMutationChains[uid] = current;
    return current;
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
  }) async {
    final metadata = await _loadMetadata(uid);
    final expectedRevision = metadata[courseId]?.revision ?? 0;
    await _mutateOutbox(uid, (ops) {
      ops.removeWhere((op) => op.courseId == courseId);
      ops.add(
        _OutboxOp(
          courseId: courseId,
          isDelete: isDelete,
          expectedRevision: expectedRevision,
        ),
      );
    });
  }

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

  /// The server accepts the legacy course JSON unchanged plus an additive
  /// expectedRevision. A 409 tells us whether an old upload met a live
  /// revision (preserve it as a conflict copy) or a delete tombstone (delete
  /// wins and the stale local payload must never resurrect it).
  Future<_DeliveryResult> _uploadRemoteById(String uid, _OutboxOp op) async {
    final courseId = op.courseId;
    final dir = await _dirFor(uid);
    final file = File('${dir.path}/$courseId.json');
    if (!await file.exists()) return const _DeliveryResult.failed();
    final ParsedCourse course;
    try {
      final json = jsonDecode(await file.readAsString());
      course = ParsedCourse.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      // Keep the operation visible as failed. Treating unreadable local data
      // as delivered would silently discard the only recovery signal.
      return const _DeliveryResult.failed();
    }
    try {
      final res = await _httpClient
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/courses'),
            headers: await _authHeadersForUid(uid),
            body: jsonEncode({
              'course': course.toJson(),
              'expectedRevision': op.expectedRevision,
            }),
          )
          .timeout(_cloudTimeout);
      final decoded = _decodeResponseMap(res.body);
      if (res.statusCode == 409) {
        return _DeliveryResult(
          _DeliveryKind.conflict,
          revision: _responseRevision(decoded),
          remoteDeleted: _responseDeleted(decoded),
        );
      }
      if (res.statusCode != 200) return const _DeliveryResult.failed();
      return decoded?['saved'] == true
          ? _DeliveryResult(
              _DeliveryKind.delivered,
              revision: _responseRevision(decoded),
            )
          : const _DeliveryResult.failed();
    } catch (e) {
      debugPrint('Course cloud upload failed: $e');
      return const _DeliveryResult.failed();
    }
  }

  /// DELETE uses the same expectedRevision contract as POST. A delete that
  /// loses a race learns the latest revision and retries once with it; a
  /// response that already represents a tombstone is terminal success.
  Future<_DeliveryResult> _deleteRemoteById(String uid, _OutboxOp op) async {
    try {
      final res = await _httpClient
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/api/courses/${op.courseId}'),
            headers: await _authHeadersForUid(uid),
            body: jsonEncode({'expectedRevision': op.expectedRevision}),
          )
          .timeout(_cloudTimeout);
      final decoded = _decodeResponseMap(res.body);
      if (res.statusCode == 409) {
        return _DeliveryResult(
          _DeliveryKind.conflict,
          revision: _responseRevision(decoded),
          remoteDeleted: _responseDeleted(decoded),
        );
      }
      if (res.statusCode != 200) return const _DeliveryResult.failed();
      return decoded?['ok'] == true
          ? _DeliveryResult(
              _DeliveryKind.delivered,
              revision: _responseRevision(decoded),
              remoteDeleted: true,
            )
          : const _DeliveryResult.failed();
    } catch (e) {
      debugPrint('Course cloud delete failed: $e');
      return const _DeliveryResult.failed();
    }
  }

  Map<String, dynamic>? _decodeResponseMap(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  int? _responseRevision(Map<String, dynamic>? response) {
    final direct = response?['revision'];
    if (direct is num) return direct.toInt();
    final currentRevision = response?['currentRevision'];
    if (currentRevision is num) return currentRevision.toInt();
    final current = response?['current'];
    final nested = current is Map<String, dynamic> ? current['revision'] : null;
    return nested is num ? nested.toInt() : null;
  }

  bool _responseDeleted(Map<String, dynamic>? response) {
    if (response?['deleted'] == true || response?['tombstone'] == true) {
      return true;
    }
    final current = response?['current'];
    return current is Map<String, dynamic> &&
        (current['deleted'] == true || current['tombstone'] == true);
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
      final result = op.isDelete
          ? await _deleteRemoteById(uid, op)
          : await _uploadRemoteById(uid, op);
      _inFlight.remove(inFlightKey);
      if (result.kind == _DeliveryKind.delivered) {
        await _recordDeliveredOperation(uid, op, result.revision);
      } else if (result.kind == _DeliveryKind.conflict) {
        final enriched = await _enrichConflict(uid, op, result);
        if (enriched.kind == _DeliveryKind.conflict) {
          await _resolveConflict(uid, op, enriched);
        } else {
          await _markOperationFailed(uid, op.operationId);
        }
      } else {
        await _markOperationFailed(uid, op.operationId);
      }
    }
    final latest = await _loadOutbox(uid);
    _publishSyncStates(uid, latest);
    _scheduleRetry(uid, latest);
  }

  /// The endpoint's minimal 409 deliberately does not echo course contents.
  /// Resolve its revision/deleted bit from the additive GET `sync` list when
  /// needed, rather than treating an opaque conflict as a live course and
  /// accidentally copying an upload over a tombstone.
  Future<_DeliveryResult> _enrichConflict(
    String uid,
    _OutboxOp op,
    _DeliveryResult conflict,
  ) async {
    if (conflict.revision != null || conflict.remoteDeleted) return conflict;
    try {
      final snapshot = await _fetchRemote(uid);
      final metadata = snapshot.sync[op.courseId];
      // A minimal 409 does not tell us whether the remote record is live or
      // deleted. Without authoritative metadata neither destructive cleanup
      // nor a conflict copy is safe, so leave the original queued for retry.
      if (metadata == null) return const _DeliveryResult.failed();
      return _DeliveryResult(
        _DeliveryKind.conflict,
        revision: metadata.revision,
        remoteDeleted: metadata.tombstone,
      );
    } catch (error) {
      debugPrint('Could not resolve course sync conflict: $error');
      return const _DeliveryResult.failed();
    }
  }

  Future<void> _recordDeliveredOperation(
    String uid,
    _OutboxOp op,
    int? revision,
  ) async {
    await _updateMetadata(uid, (metadata) {
      final existing = metadata[op.courseId];
      metadata[op.courseId] = _CourseSyncMetadata(
        revision: revision ?? existing?.revision ?? op.expectedRevision,
        tombstone: op.isDelete,
      );
    });
    await _removeOutboxOperation(uid, op.operationId);
  }

  Future<void> _resolveConflict(
    String uid,
    _OutboxOp op,
    _DeliveryResult conflict,
  ) async {
    if (!op.isDelete && conflict.remoteDeleted) {
      // Delete wins across devices: never retry or copy a stale upload over a
      // tombstone. The original file and dependent bookmarks disappear in the
      // same way as a local delete, while the tombstone remains diagnosable.
      await _removeLocalCourseOnly(uid, op.courseId, removeFavorites: true);
      await _updateMetadata(uid, (metadata) {
        metadata[op.courseId] = _CourseSyncMetadata(
          revision: conflict.revision ?? metadata[op.courseId]?.revision ?? 0,
          tombstone: true,
        );
      });
      await _removeOutboxOperation(uid, op.operationId);
      return;
    }

    if (op.isDelete && conflict.remoteDeleted) {
      await _updateMetadata(uid, (metadata) {
        metadata[op.courseId] = _CourseSyncMetadata(
          revision: conflict.revision ?? metadata[op.courseId]?.revision ?? 0,
          tombstone: true,
        );
      });
      await _removeOutboxOperation(uid, op.operationId);
      return;
    }

    if (op.isDelete) {
      final revision = conflict.revision;
      if (revision != null && revision != op.expectedRevision) {
        // One immediate retry with the server's authoritative revision. If
        // that value keeps returning 409, _markOperationFailed backs off so a
        // malformed/backend-broken response can never produce a tight loop.
        await _mutateOutbox(uid, (ops) {
          final current = ops
              .where((candidate) => candidate.operationId == op.operationId)
              .firstOrNull;
          if (current == null) return;
          current.expectedRevision = revision;
          current.nextAttemptAt = DateTime.now();
        });
        return;
      }
      await _markOperationFailed(uid, op.operationId);
      return;
    }

    // A live course with the same id has changed elsewhere. Preserve this
    // device's payload under a fresh id, then let the next normal merge bring
    // back the server's original. Neither side is silently overwritten.
    final conflictCopyId = await _createConflictCopy(uid, op.courseId);
    if (conflictCopyId == null) {
      await _markOperationFailed(uid, op.operationId);
      return;
    }
    await _updateMetadata(uid, (metadata) {
      metadata[op.courseId] = _CourseSyncMetadata(
        revision: conflict.revision ?? metadata[op.courseId]?.revision ?? 0,
        tombstone: false,
      );
      metadata[conflictCopyId] = const _CourseSyncMetadata(
        revision: 0,
        tombstone: false,
      );
    });
    await _mutateOutbox(uid, (ops) {
      final index = ops.indexWhere(
        (candidate) => candidate.operationId == op.operationId,
      );
      if (index < 0) return;
      ops.removeAt(index);
      ops.removeWhere((candidate) => candidate.courseId == conflictCopyId);
      ops.add(
        _OutboxOp(
          courseId: conflictCopyId,
          isDelete: false,
          expectedRevision: 0,
        ),
      );
    });
  }

  Future<void> _removeOutboxOperation(String uid, String operationId) {
    return _mutateOutbox(uid, (ops) {
      ops.removeWhere((candidate) => candidate.operationId == operationId);
    });
  }

  Future<void> _markOperationFailed(String uid, String operationId) {
    return _mutateOutbox(uid, (ops) {
      final current = ops
          .where((candidate) => candidate.operationId == operationId)
          .firstOrNull;
      if (current == null) return;
      current.attempts++;
      current.nextAttemptAt = DateTime.now().add(_backoffFor(current.attempts));
    });
  }

  Future<String?> _createConflictCopy(String uid, String courseId) async {
    final dir = await _dirFor(uid);
    final original = File('${dir.path}/$courseId.json');
    try {
      final decoded = jsonDecode(await original.readAsString());
      final course = ParsedCourse.fromJson(decoded as Map<String, dynamic>);
      final copy = ParsedCourse(
        id: const Uuid().v4(),
        title: course.title,
        sourceFilename: course.sourceFilename,
        parsedAt: course.parsedAt,
        sections: course.sections,
        examProvider: course.examProvider,
        examCourseType: course.examCourseType,
        examLevel: course.examLevel,
        schemaVersion: course.schemaVersion,
      );
      await _writeLocal(copy, forUid: uid);
      await _removeLocalCourseOnly(uid, courseId, removeFavorites: false);
      return copy.id;
    } catch (error) {
      debugPrint('Could not preserve conflicting course $courseId: $error');
      return null;
    }
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
    _metadataMutationChains.clear();
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

  Future<_RemoteSnapshot> _fetchRemote(String uid) async {
    final res = await _httpClient
        .get(
          Uri.parse('${ApiConfig.baseUrl}/api/courses'),
          headers: await _authHeadersForUid(uid),
        )
        .timeout(_cloudTimeout);
    if (res.statusCode != 200) {
      throw HttpException('Course sync is temporarily unavailable.');
    }
    final decoded = _decodeResponseMap(res.body);
    if (decoded == null || decoded['courses'] is! List<dynamic>) {
      throw const FormatException('Invalid course sync response.');
    }
    final list = decoded['courses'];
    final result = <ParsedCourse>[];
    if (list is List<dynamic>) {
      for (final j in list) {
        try {
          final course = ParsedCourse.fromJson(j as Map<String, dynamic>);
          if (_isSafeCourseId(course.id)) result.add(course);
        } catch (_) {
          // Skip anything that doesn't match the current schema.
        }
      }
    }
    final sync = <String, _CourseSyncMetadata>{};
    // `sync` is the current endpoint contract. The aliases make a rolling
    // client/backend deploy harmless and let old cached proxy responses keep
    // their existing additive-merge behaviour.
    final rawSync =
        decoded['sync'] ?? decoded['metadata'] ?? decoded['courseMetadata'];
    if (rawSync is List<dynamic>) {
      for (final item in rawSync) {
        if (item is! Map<String, dynamic> || item['id'] is! String) continue;
        final id = item['id'] as String;
        if (!_isSafeCourseId(id)) continue;
        final revision = item['revision'];
        if (revision is! num || revision < 0) continue;
        sync[id] = _CourseSyncMetadata(
          revision: revision.toInt(),
          tombstone: item['deleted'] == true || item['tombstone'] == true,
        );
      }
    }
    return _RemoteSnapshot(courses: result, sync: sync);
  }

  Future<void> save(ParsedCourse course) async {
    final uid = _uid;
    await _writeLocal(course, forUid: uid);
    await _updateMetadata(uid, (metadata) {
      final existing = metadata[course.id];
      // A save issued from a stale screen after a delete must still meet the
      // tombstone's revision at the server. Do not clear it locally merely
      // because the old screen happened to finish later.
      metadata[course.id] = _CourseSyncMetadata(
        revision: existing?.revision ?? 0,
        tombstone: existing?.tombstone ?? false,
      );
    });
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
      if (!_isSafeCourseId(id)) {
        debugPrint('Skipping unsafe course id in local index.');
        continue;
      }
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
      var visibleLocal = List<ParsedCourse>.from(local);
      final metadata = await _loadMetadata(uid);
      final remote = await _fetchRemote(uid);
      if (_uid != uid) return const [];
      final remoteTombstones = remote.sync.entries
          .where((entry) => entry.value.tombstone)
          .toList();
      for (final entry in remoteTombstones) {
        if (_uid != uid) return const [];
        // A remote tombstone is authoritative even if this device still has
        // an offline upload queued. It removes the local file, dependent
        // favourites and queued operation before a future sync can revive it.
        await _removeLocalCourseOnly(uid, entry.key, removeFavorites: true);
        await _updateMetadata(uid, (current) {
          current[entry.key] = entry.value;
        });
        await _mutateOutbox(uid, (ops) {
          ops.removeWhere((op) => op.courseId == entry.key);
        });
        visibleLocal.removeWhere((course) => course.id == entry.key);
        metadata[entry.key] = entry.value;
      }
      final localIds = visibleLocal.map((c) => c.id).toSet();
      final pendingDeleteIds = (await _loadOutbox(
        uid,
      )).where((op) => op.isDelete).map((op) => op.courseId).toSet();
      final newOnes = remote.courses
          .where((c) => !localIds.contains(c.id))
          .where((c) => metadata[c.id]?.tombstone != true)
          .where((c) => !pendingDeleteIds.contains(c.id))
          .where((c) => !localLoad.unreadableWithoutBackup.contains(c.id))
          .toList();
      if (newOnes.isEmpty) return _uid == uid ? visibleLocal : const [];
      for (final course in newOnes) {
        if (_uid != uid) return const [];
        await _writeLocal(course, forUid: uid);
        final remoteMetadata = remote.sync[course.id];
        if (remoteMetadata != null) {
          await _updateMetadata(uid, (current) {
            if (current[course.id]?.tombstone != true) {
              current[course.id] = remoteMetadata;
            }
          });
        }
        if (_uid != uid) return const [];
      }
      return _uid == uid ? [...visibleLocal, ...newOnes] : const [];
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
    await (_outboxMutationChains[uid] ?? Future<void>.value());
    await (_metadataMutationChains[uid] ?? Future<void>.value());
    final dir = await _dirFor(uid);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyFor(uid));
    await prefs.remove(_outboxKeyFor(uid));
    await prefs.remove(_metadataKeyFor(uid));
    await prefs.remove('${_outboxKeyFor(uid)}_corrupt');
    await prefs.remove('${_metadataKeyFor(uid)}_corrupt');
    _retryTimers.remove(uid)?.cancel();
    if (_uid == uid) {
      syncStates.value = const {};
      revision.value++;
    }
  }

  /// Removes only local course material. This intentionally does not enqueue
  /// a cloud operation or alter sync metadata: it is also used when a remote
  /// tombstone has already made deletion authoritative.
  Future<void> _removeLocalCourseOnly(
    String uid,
    String id, {
    required bool removeFavorites,
  }) async {
    if (!_isSafeCourseId(id)) return;
    final dir = await _dirFor(uid);
    final file = File('${dir.path}/$id.json');
    if (await file.exists()) await file.delete();
    final prefs = await SharedPreferences.getInstance();
    final prefsKey = _prefsKeyFor(uid);
    final ids = (prefs.getStringList(prefsKey) ?? [])..remove(id);
    await prefs.setStringList(prefsKey, ids);
    if (removeFavorites) {
      await FavoritesService.instance.removeByCourseForUid(id, uid);
    }
  }

  Future<void> delete(String id) async {
    final uid = _uid;
    await _removeLocalCourseOnly(uid, id, removeFavorites: true);
    await _updateMetadata(uid, (metadata) {
      final existing = metadata[id];
      metadata[id] = _CourseSyncMetadata(
        revision: existing?.revision ?? 0,
        tombstone: true,
      );
    });
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
