// Tests the persistent cloud-sync outbox added for CR-07: upload/delete used
// to be fire-and-forget with no retry and an in-memory-only pending-delete
// set, so a transient failure or an app restart silently lost the operation
// (see the historical CR-07 notes in CODE_REVIEW_2026-07-15.md). This file
// verifies the replacement — a persistent per-UID outbox with backoff retry,
// idempotent-success detection, and visible per-course sync state.
import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exam_trainer/models/parsed_course.dart';
import 'package:exam_trainer/services/course_storage.dart';
import 'package:exam_trainer/services/favorites_service.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this._root);
  final String _root;

  @override
  Future<String?> getApplicationDocumentsPath() async => _root;
}

class _DelayedPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _DelayedPathProviderPlatform(this._root);

  final String _root;
  final pathRequested = Completer<void>();
  final releasePath = Completer<void>();

  @override
  Future<String?> getApplicationDocumentsPath() async {
    if (!pathRequested.isCompleted) pathRequested.complete();
    await releasePath.future;
    return _root;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;

  ParsedCourse course(String id, String title) => ParsedCourse(
    id: id,
    title: title,
    sourceFilename: '$id.pdf',
    parsedAt: DateTime(2026, 1, 1),
    sections: const {},
  );

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('course_storage_outbox_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempRoot.path);
    SharedPreferences.setMockInitialValues({});
    CourseStorage.debugUidOverride = 'outbox-user';
    CourseStorage.debugIdTokenOverride = () async => 'test-token';
    CourseStorage.debugBaseBackoffOverride = null;
    FavoritesService.debugUidOverride = 'outbox-user';
  });

  tearDown(() async {
    await CourseStorage.instance.debugPendingFlush;
    CourseStorage.instance.debugResetSyncStateForTests();
    CourseStorage.debugUidOverride = null;
    CourseStorage.debugIdTokenOverride = null;
    CourseStorage.debugHttpClient = null;
    CourseStorage.debugBaseBackoffOverride = null;
    FavoritesService.debugUidOverride = null;
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  test('a save that fails to reach the backend is retried and eventually '
      'marked synced, without ever being dropped', () async {
    var uploadCalls = 0;
    CourseStorage.debugHttpClient = MockClient((request) async {
      uploadCalls++;
      if (uploadCalls == 1) return http.Response('', 503);
      return http.Response(jsonEncode({'saved': true}), 200);
    });

    await CourseStorage.instance.save(course('c1', 'Course 1'));
    await CourseStorage.instance.debugPendingFlush;

    expect(
      CourseStorage.instance.syncStateFor('c1'),
      CourseSyncState.error,
      reason: 'first attempt failed (503) and must not be silently lost',
    );
    expect(uploadCalls, 1);

    await CourseStorage.instance.retrySyncNow();
    expect(uploadCalls, 2);
    expect(CourseStorage.instance.syncStateFor('c1'), CourseSyncState.synced);
  });

  test(
    'a 200 response with saved:false is treated as a failure, not success',
    () async {
      CourseStorage.debugHttpClient = MockClient((request) async {
        return http.Response(jsonEncode({'saved': false}), 200);
      });

      await CourseStorage.instance.save(course('c2', 'Course 2'));
      await CourseStorage.instance.debugPendingFlush;

      expect(CourseStorage.instance.syncStateFor('c2'), CourseSyncState.error);
    },
  );

  test('a pending delete survives an app restart and is not resurrected by '
      'cross-device merge', () async {
    // Simulate the delete never reaching the backend before "restart".
    CourseStorage.debugHttpClient = MockClient((request) async {
      return http.Response('', 0);
    });

    await CourseStorage.instance.save(course('c3', 'Course 3'));
    await CourseStorage.instance.debugPendingFlush;
    await CourseStorage.instance.delete('c3');
    await CourseStorage.instance.debugPendingFlush;

    // The old implementation kept pending deletes in an in-process Set,
    // so a fresh CourseStorage/process would lose them; the outbox lives
    // in SharedPreferences instead, so it survives.
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('course_sync_outbox_outbox-user'),
      contains('"isDelete":true'),
      reason: 'the delete tombstone must be persisted, not just in memory',
    );

    CourseStorage.debugHttpClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode({
            'courses': [course('c3', 'Course 3').toJson()],
          }),
          200,
        );
      }
      return http.Response('', 503);
    });

    final loaded = await CourseStorage.instance.loadAll();
    expect(
      loaded.map((c) => c.id),
      isNot(contains('c3')),
      reason:
          'a course whose delete is still pending in the outbox must not '
          'be re-downloaded by the cross-device merge',
    );
  });

  test('a successful delete is removed from the outbox', () async {
    CourseStorage.debugHttpClient = MockClient((request) async {
      if (request.method == 'DELETE') {
        return http.Response(jsonEncode({'ok': true}), 200);
      }
      return http.Response(jsonEncode({'saved': true}), 200);
    });

    await CourseStorage.instance.save(course('c4', 'Course 4'));
    await CourseStorage.instance.debugPendingFlush;
    await CourseStorage.instance.delete('c4');
    await CourseStorage.instance.debugPendingFlush;

    expect(CourseStorage.instance.syncStateFor('c4'), CourseSyncState.synced);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('course_sync_outbox_outbox-user'), '[]');
  });

  test(
    'a remote tombstone removes stale local course and pending upload',
    () async {
      CourseStorage.debugHttpClient = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'courses': [
                course('deleted-remotely', 'Old local copy').toJson(),
              ],
              'sync': [
                {
                  'id': 'deleted-remotely',
                  'revision': 7,
                  'deleted': true,
                  'updatedAt': '2026-07-18T10:00:00Z',
                },
              ],
            }),
            200,
          );
        }
        return http.Response('', 503);
      });

      await CourseStorage.instance.save(
        course('deleted-remotely', 'Old local copy'),
      );
      await CourseStorage.instance.debugPendingFlush;

      final loaded = await CourseStorage.instance.loadAll();
      final prefs = await SharedPreferences.getInstance();
      final metadata =
          jsonDecode(prefs.getString('course_sync_metadata_outbox-user')!)
              as Map<String, dynamic>;

      expect(loaded, isEmpty);
      expect(
        File(
          '${tempRoot.path}/courses/outbox-user/deleted-remotely.json',
        ).existsSync(),
        isFalse,
      );
      expect(prefs.getStringList('course_ids_outbox-user'), isEmpty);
      expect(prefs.getString('course_sync_outbox_outbox-user'), '[]');
      expect(metadata['deleted-remotely'], {'revision': 7, 'tombstone': true});
    },
  );

  test(
    'a stale delete learns server revision then reaches its tombstone',
    () async {
      var deleteCalls = 0;
      CourseStorage.debugHttpClient = MockClient((request) async {
        if (request.method == 'DELETE') {
          deleteCalls++;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (deleteCalls == 1) {
            expect(body['expectedRevision'], 1);
            return http.Response(
              jsonEncode({'ok': false, 'conflict': true}),
              409,
            );
          }
          expect(body['expectedRevision'], 2);
          return http.Response(jsonEncode({'ok': true, 'revision': 3}), 200);
        }
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'courses': [],
              'sync': [
                {'id': 'stale-delete', 'revision': 2, 'deleted': false},
              ],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'saved': true, 'revision': 1}), 200);
      });

      await CourseStorage.instance.save(course('stale-delete', 'Delete me'));
      await CourseStorage.instance.debugPendingFlush;
      await CourseStorage.instance.delete('stale-delete');
      await CourseStorage.instance.debugPendingFlush;
      // The refreshed revision is scheduled immediately. Yield to that retry
      // instead of relying on a clock/backoff in this deterministic regression.
      await Future<void>.delayed(Duration.zero);
      await CourseStorage.instance.debugPendingFlush;

      final prefs = await SharedPreferences.getInstance();
      expect(deleteCalls, 2);
      expect(prefs.getString('course_sync_outbox_outbox-user'), '[]');
      expect(
        prefs.getString('course_sync_metadata_outbox-user'),
        contains('"revision":3'),
      );
    },
  );

  test(
    'opaque upload 409 consults sync metadata and cannot revive tombstone',
    () async {
      var getCalls = 0;
      CourseStorage.debugHttpClient = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({'saved': false, 'conflict': true}),
            409,
          );
        }
        if (request.method == 'GET') {
          getCalls++;
          return http.Response(
            jsonEncode({
              'courses': [],
              'sync': [
                {'id': 'stale-upload', 'revision': 8, 'deleted': true},
              ],
            }),
            200,
          );
        }
        return http.Response('', 500);
      });

      await CourseStorage.instance.save(course('stale-upload', 'Offline copy'));
      await CourseStorage.instance.debugPendingFlush;

      final prefs = await SharedPreferences.getInstance();
      expect(getCalls, 1);
      expect(
        File(
          '${tempRoot.path}/courses/outbox-user/stale-upload.json',
        ).existsSync(),
        isFalse,
      );
      expect(prefs.getString('course_sync_outbox_outbox-user'), '[]');
      expect(
        prefs.getString('course_sync_metadata_outbox-user'),
        contains('"tombstone":true'),
      );
    },
  );

  test(
    'opaque upload 409 with unavailable metadata preserves original for retry',
    () async {
      CourseStorage.debugHttpClient = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({'saved': false, 'conflict': true}),
            409,
          );
        }
        return http.Response('', 503);
      });

      await CourseStorage.instance.save(
        course('unknown-conflict', 'Keep this exact local copy'),
      );
      await CourseStorage.instance.debugPendingFlush;

      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('course_ids_outbox-user');
      final outbox =
          jsonDecode(prefs.getString('course_sync_outbox_outbox-user')!)
              as List<dynamic>;
      expect(ids, ['unknown-conflict']);
      expect(outbox, hasLength(1));
      expect(outbox.single['courseId'], 'unknown-conflict');
      expect(outbox.single['attempts'], 1);
      expect(
        File(
          '${tempRoot.path}/courses/outbox-user/unknown-conflict.json',
        ).existsSync(),
        isTrue,
      );
    },
  );

  test(
    'legacy GET without sync metadata still downloads a valid course',
    () async {
      CourseStorage.debugHttpClient = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'courses': [
                course('legacy-cloud', 'Legacy cloud course').toJson(),
              ],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'saved': true}), 200);
      });

      final loaded = await CourseStorage.instance.loadAll();

      expect(loaded.single.id, 'legacy-cloud');
      expect(loaded.single.title, 'Legacy cloud course');
    },
  );

  test('unsafe remote course and sync ids are ignored defensively', () async {
    CourseStorage.debugHttpClient = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'courses': [
            course('../escape', 'Unsafe').toJson(),
            course('safe-cloud', 'Safe').toJson(),
          ],
          'sync': [
            {'id': '../escape', 'revision': 9, 'deleted': true},
            {'id': 'safe-cloud', 'revision': 1, 'deleted': false},
          ],
        }),
        200,
      );
    });

    final loaded = await CourseStorage.instance.loadAll();

    expect(loaded.map((item) => item.id), ['safe-cloud']);
    expect(File('${tempRoot.path}/courses/escape.json').existsSync(), isFalse);
  });

  test(
    'corrupt sync metadata is quarantined without hiding legacy course',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('course_sync_metadata_outbox-user', '{broken');
      CourseStorage.debugHttpClient = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'courses': [course('metadata-safe', 'Still visible').toJson()],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'saved': true}), 200);
      });

      final loaded = await CourseStorage.instance.loadAll();

      expect(loaded.single.id, 'metadata-safe');
      expect(
        prefs.getString('course_sync_metadata_outbox-user_corrupt'),
        '{broken',
      );
    },
  );

  test('sync metadata survives restart and remains isolated by UID', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'course_sync_metadata_outbox-user',
      jsonEncode({
        'deleted-on-a': {'revision': 4, 'tombstone': true},
      }),
    );
    CourseStorage.debugHttpClient = MockClient((request) async {
      if (request.method != 'GET') {
        return http.Response(jsonEncode({'saved': true}), 200);
      }
      return http.Response(
        jsonEncode({
          'courses': [course('deleted-on-a', 'Must stay deleted').toJson()],
          'sync': [
            {'id': 'deleted-on-a', 'revision': 4, 'deleted': false},
          ],
        }),
        200,
      );
    });

    // The singleton reset is the part of state a real process restart loses;
    // SharedPreferences is deliberately retained.
    CourseStorage.instance.debugResetSyncStateForTests();
    expect(await CourseStorage.instance.loadAll(), isEmpty);
    expect(
      prefs.getString('course_sync_metadata_outbox-user'),
      contains('"tombstone":true'),
    );

    CourseStorage.debugUidOverride = 'other-user';
    FavoritesService.debugUidOverride = 'other-user';
    final otherUser = await CourseStorage.instance.loadAll();
    expect(otherUser.map((item) => item.id), ['deleted-on-a']);
    expect(
      prefs.getString('course_sync_metadata_other-user'),
      contains('"tombstone":false'),
    );
  });

  test('a live 409 keeps local content as a new conflict copy', () async {
    var uploads = 0;
    String? copyId;
    CourseStorage.debugHttpClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(jsonEncode({'courses': [], 'sync': []}), 200);
      }
      uploads++;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final uploaded = body['course'] as Map<String, dynamic>;
      if (uploads == 1) {
        return http.Response(jsonEncode({'saved': true, 'revision': 1}), 200);
      }
      if (uploads == 2) {
        expect(uploaded['id'], 'live-conflict');
        return http.Response(
          jsonEncode({'revision': 2, 'deleted': false}),
          409,
        );
      }
      copyId = uploaded['id'] as String;
      return http.Response(jsonEncode({'saved': true, 'revision': 1}), 200);
    });

    await CourseStorage.instance.save(course('live-conflict', 'Original'));
    await CourseStorage.instance.debugPendingFlush;
    await CourseStorage.instance.save(course('live-conflict', 'Local edit'));
    await CourseStorage.instance.debugPendingFlush;
    await Future<void>.delayed(Duration.zero);
    await CourseStorage.instance.debugPendingFlush;

    final saved = await CourseStorage.instance.loadAll();
    expect(copyId, isNotNull);
    expect(copyId, isNot('live-conflict'));
    expect(saved.where((item) => item.id == copyId).single.title, 'Local edit');
    expect(
      File(
        '${tempRoot.path}/courses/outbox-user/live-conflict.json',
      ).existsSync(),
      isFalse,
    );
  });

  test(
    'an operation enqueued during an active flush is not overwritten',
    () async {
      final firstStarted = Completer<void>();
      final releaseFirst = Completer<http.Response>();
      var secondUploads = 0;
      CourseStorage.debugHttpClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final uploaded = body['course'] as Map<String, dynamic>;
        if (uploaded['id'] == 'race-1') {
          if (!firstStarted.isCompleted) firstStarted.complete();
          return releaseFirst.future;
        }
        secondUploads++;
        return http.Response(jsonEncode({'saved': true}), 200);
      });

      await CourseStorage.instance.save(course('race-1', 'First'));
      await firstStarted.future;
      await CourseStorage.instance.save(course('race-2', 'Second'));
      final activeFlush = CourseStorage.instance.debugPendingFlush;
      releaseFirst.complete(http.Response(jsonEncode({'saved': true}), 200));
      await activeFlush;

      final prefs = await SharedPreferences.getInstance();
      final persisted =
          prefs.getString('course_sync_outbox_outbox-user') ?? '[]';
      expect(
        persisted.contains('race-2') || secondUploads == 1,
        isTrue,
        reason:
            'the concurrent operation must be persisted or already delivered',
      );
      await CourseStorage.instance.retrySyncNow();
      expect(secondUploads, 1);
      expect(
        CourseStorage.instance.syncStateFor('race-2'),
        CourseSyncState.synced,
      );
    },
  );

  test(
    'account switch while token is loading sends no cross-UID request',
    () async {
      final tokenRequested = Completer<void>();
      final releaseToken = Completer<void>();
      var requests = 0;
      CourseStorage.debugIdTokenOverride = () async {
        tokenRequested.complete();
        await releaseToken.future;
        return 'token-for-live-user';
      };
      CourseStorage.debugHttpClient = MockClient((request) async {
        requests++;
        return http.Response(jsonEncode({'saved': true}), 200);
      });

      await CourseStorage.instance.save(course('account-a-course', 'A'));
      await tokenRequested.future;
      final userAFlush = CourseStorage.instance.debugPendingFlush;
      CourseStorage.debugUidOverride = 'user-b';
      FavoritesService.debugUidOverride = 'user-b';
      releaseToken.complete();
      await userAFlush;

      expect(requests, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('course_sync_outbox_outbox-user'),
        contains('account-a-course'),
      );
    },
  );

  test(
    'account switch during local loading never returns prior UID courses',
    () async {
      CourseStorage.debugHttpClient = MockClient(
        (_) async => http.Response(jsonEncode({'saved': true}), 200),
      );
      await CourseStorage.instance.save(course('local-a', 'Only A'));
      await CourseStorage.instance.debugPendingFlush;

      final delayedPath = _DelayedPathProviderPlatform(tempRoot.path);
      PathProviderPlatform.instance = delayedPath;
      final loading = CourseStorage.instance.loadAll();
      await delayedPath.pathRequested.future;
      CourseStorage.debugUidOverride = 'user-b';
      FavoritesService.debugUidOverride = 'user-b';
      delayedPath.releasePath.complete();

      expect(await loading, isEmpty);
    },
  );

  test('account switch during successful remote fetch returns no prior UID '
      'courses', () async {
    CourseStorage.debugHttpClient = MockClient(
      (_) async => http.Response(jsonEncode({'saved': true}), 200),
    );
    await CourseStorage.instance.save(course('remote-a', 'Only A'));
    await CourseStorage.instance.debugPendingFlush;

    final requestStarted = Completer<void>();
    final releaseResponse = Completer<http.Response>();
    CourseStorage.debugHttpClient = MockClient((request) async {
      if (request.method == 'GET') {
        requestStarted.complete();
        return releaseResponse.future;
      }
      return http.Response(jsonEncode({'saved': true}), 200);
    });
    final loading = CourseStorage.instance.loadAll();
    await requestStarted.future;
    CourseStorage.debugUidOverride = 'user-b';
    FavoritesService.debugUidOverride = 'user-b';
    releaseResponse.complete(http.Response(jsonEncode({'courses': []}), 200));

    expect(await loading, isEmpty);
  });

  test('account switch during failed remote fetch does not fall back to '
      'prior UID courses', () async {
    CourseStorage.debugHttpClient = MockClient(
      (_) async => http.Response(jsonEncode({'saved': true}), 200),
    );
    await CourseStorage.instance.save(course('failed-remote-a', 'Only A'));
    await CourseStorage.instance.debugPendingFlush;

    final requestStarted = Completer<void>();
    final releaseFailure = Completer<http.Response>();
    CourseStorage.debugHttpClient = MockClient((request) async {
      if (request.method == 'GET') {
        requestStarted.complete();
        return releaseFailure.future;
      }
      return http.Response(jsonEncode({'saved': true}), 200);
    });
    final loading = CourseStorage.instance.loadAll();
    await requestStarted.future;
    CourseStorage.debugUidOverride = 'user-b';
    FavoritesService.debugUidOverride = 'user-b';
    releaseFailure.completeError(StateError('offline'));

    expect(await loading, isEmpty);
  });

  test('failed upload is retried automatically after backoff', () async {
    CourseStorage.debugBaseBackoffOverride = const Duration(milliseconds: 15);
    final retried = Completer<void>();
    var calls = 0;
    CourseStorage.debugHttpClient = MockClient((request) async {
      calls++;
      if (calls == 1) return http.Response('', 503);
      if (!retried.isCompleted) retried.complete();
      return http.Response(jsonEncode({'saved': true}), 200);
    });

    await CourseStorage.instance.save(course('auto-retry', 'Retry'));
    await CourseStorage.instance.debugPendingFlush;
    await retried.future.timeout(const Duration(seconds: 1));
    await CourseStorage.instance.debugPendingFlush;

    expect(calls, 2);
    expect(
      CourseStorage.instance.syncStateFor('auto-retry'),
      CourseSyncState.synced,
    );
  });

  test(
    'corrupt outbox is quarantined before a new operation replaces it',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('course_sync_outbox_outbox-user', '{broken outbox');
      CourseStorage.debugHttpClient = MockClient(
        (_) async => http.Response(jsonEncode({'saved': true}), 200),
      );

      await CourseStorage.instance.save(course('after-corruption', 'Safe'));
      await CourseStorage.instance.debugPendingFlush;

      expect(
        prefs.getString('course_sync_outbox_outbox-user_corrupt'),
        '{broken outbox',
      );
    },
  );

  test(
    'missing local upload is retained as an error, not false synced',
    () async {
      CourseStorage.debugHttpClient = MockClient(
        (_) async => http.Response(jsonEncode({'saved': true}), 200),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'course_sync_outbox_outbox-user',
        jsonEncode([
          {
            'operationId': 'missing-op',
            'courseId': 'missing-upload',
            'isDelete': false,
            'attempts': 0,
            'nextAttemptAt': DateTime.now().toIso8601String(),
          },
        ]),
      );
      await CourseStorage.instance.retrySyncNow();

      expect(
        CourseStorage.instance.syncStateFor('missing-upload'),
        CourseSyncState.error,
      );
    },
  );

  test(
    'account deletion waits for active sync and suspends later uploads',
    () async {
      final firstStarted = Completer<void>();
      final releaseFirst = Completer<http.Response>();
      var calls = 0;
      CourseStorage.debugHttpClient = MockClient((request) async {
        calls++;
        if (calls == 1) {
          firstStarted.complete();
          return releaseFirst.future;
        }
        return http.Response(jsonEncode({'saved': true}), 200);
      });

      await CourseStorage.instance.save(course('before-delete', 'Before'));
      await firstStarted.future;
      var suspended = false;
      final suspension = CourseStorage.instance
          .suspendCloudSyncForAccountDeletion()
          .then((_) => suspended = true);
      await Future<void>.delayed(Duration.zero);
      expect(suspended, isFalse);

      releaseFirst.complete(http.Response(jsonEncode({'saved': true}), 200));
      await suspension;
      await CourseStorage.instance.save(course('during-delete', 'During'));
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);

      CourseStorage.instance.resumeCloudSyncAfterAccountDeletionFailure(
        'outbox-user',
      );
      await CourseStorage.instance.debugPendingFlush;
      expect(calls, 2);
    },
  );

  test(
    'account deletion clears quarantine without resetting another UID UI',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'course_sync_outbox_outbox-user_corrupt',
        'broken-a',
      );
      await prefs.setString(
        'course_sync_metadata_outbox-user_corrupt',
        'broken-b',
      );
      CourseStorage.debugUidOverride = 'other-user';
      FavoritesService.debugUidOverride = 'other-user';
      CourseStorage.instance.syncStates.value = const {
        'other-course': CourseSyncState.pending,
      };
      final revisionBefore = CourseStorage.instance.revision.value;

      await CourseStorage.instance.deleteAllLocalForUid('outbox-user');

      expect(
        prefs.containsKey('course_sync_outbox_outbox-user_corrupt'),
        isFalse,
      );
      expect(
        prefs.containsKey('course_sync_metadata_outbox-user_corrupt'),
        isFalse,
      );
      expect(
        CourseStorage.instance.syncStateFor('other-course'),
        CourseSyncState.pending,
      );
      expect(CourseStorage.instance.revision.value, revisionBefore);
    },
  );
}
