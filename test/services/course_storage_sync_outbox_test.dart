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
}
