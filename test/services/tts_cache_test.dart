// CR-14: TtsService's on-disk audio cache used to grow forever in the
// app's persistent Documents directory with no size cap and a non-atomic
// write straight to the final path. These tests cover the cache directory
// location, size-bounded LRU eviction, corrupted/truncated-clip recovery,
// and that a crash mid-write never leaves a servable half-written file.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:exam_trainer/services/tts_service.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this._cachePath, this._docsPath);
  final String _cachePath;
  final String _docsPath;

  @override
  Future<String?> getApplicationCachePath() async => _cachePath;

  @override
  Future<String?> getApplicationDocumentsPath() async => _docsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory cacheRoot;
  late Directory docsRoot;
  late TtsService svc;

  // 600 real-ish bytes so every fake clip clears `_minValidBytes` (512) and
  // is only distinguished from a genuinely corrupt clip by its own length.
  List<int> fakeClipBytes([int size = 600]) => List.filled(size, 65);

  setUp(() {
    cacheRoot = Directory.systemTemp.createTempSync('tts_cache_root_');
    docsRoot = Directory.systemTemp.createTempSync('tts_docs_root_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      cacheRoot.path,
      docsRoot.path,
    );
    // TtsService.instance is only ever created inside a test zone — its
    // constructor eagerly builds an http.Client(), which Flutter's test
    // HttpOverrides mock requires to happen inside a running test/setUp,
    // not at main()'s top level.
    svc = TtsService.instance;
    svc.debugResetCacheDirForTests();
    TtsService.debugIdTokenOverride = () async => 'test-token';
  });

  tearDown(() {
    TtsService.debugHttpClient = null;
    TtsService.debugIdTokenOverride = null;
    TtsService.debugMaxCacheBytesOverride = null;
    TtsService.debugForceLegacyCleanupFailure = false;
    svc.debugResetCacheDirForTests();
    if (cacheRoot.existsSync()) cacheRoot.deleteSync(recursive: true);
    if (docsRoot.existsSync()) docsRoot.deleteSync(recursive: true);
  });

  test(
    'cached audio is written under the OS cache directory, not Documents',
    () async {
      TtsService.debugHttpClient = MockClient(
        (_) async => http.Response.bytes(fakeClipBytes(), 200),
      );
      final path = await svc.ensureAudio(const DialogueLine('Chef', 'Hallo.'));
      expect(path, startsWith('${cacheRoot.path}/tts_cache'));
      expect(path, isNot(contains(docsRoot.path)));
    },
  );

  test(
    'a clip is synthesized once and served from cache on the second call',
    () async {
      var requests = 0;
      TtsService.debugHttpClient = MockClient((_) async {
        requests++;
        return http.Response.bytes(fakeClipBytes(), 200);
      });
      const line = DialogueLine('Chef', 'Guten Tag.');
      final first = await svc.ensureAudio(line);
      final second = await svc.ensureAudio(line);
      expect(first, second);
      expect(requests, 1);
    },
  );

  test(
    'a truncated/corrupt cached clip is regenerated instead of served',
    () async {
      const line = DialogueLine('Chef', 'Guten Tag.');
      var requests = 0;
      TtsService.debugHttpClient = MockClient((_) async {
        requests++;
        return http.Response.bytes(fakeClipBytes(), 200);
      });
      final path = await svc.ensureAudio(line);
      // Simulate a previous run that got cut off mid-write, leaving a
      // too-small file at the committed path.
      await File(path).writeAsBytes(List.filled(10, 0));

      final regenerated = await svc.ensureAudio(line);
      expect(regenerated, path);
      expect(await File(path).length(), greaterThanOrEqualTo(512));
      expect(requests, 2);
    },
  );

  test(
    'a stale leftover .tmp file does not get served as valid audio',
    () async {
      TtsService.debugHttpClient = MockClient(
        (_) async => http.Response.bytes(fakeClipBytes(), 200),
      );
      const line = DialogueLine('Chef', 'Guten Tag.');
      final path = await svc.ensureAudio(line);

      // A crash between the temp write and the rename would leave exactly
      // this on disk: a valid `.tmp` sibling, no trace in the real path.
      await File(path).delete();
      await File('$path.tmp').writeAsBytes(fakeClipBytes());
      expect(await File(path).exists(), isFalse);

      // ensureAudio must not mistake the .tmp file for the committed clip —
      // it re-synthesizes and commits atomically again.
      final result = await svc.ensureAudio(line);
      expect(result, path);
      expect(await File(path).exists(), isTrue);
    },
  );

  test('eviction removes the least-recently-used, already-released clip '
      'first once the cache budget is exceeded', () async {
    TtsService.debugMaxCacheBytesOverride = 1500; // ~2.5 clips at 600B
    TtsService.debugHttpClient = MockClient(
      (_) async => http.Response.bytes(fakeClipBytes(), 200),
    );

    final oldest = await svc.ensureAudio(const DialogueLine('A', 'eins'));
    // Distinct mtimes are required for the LRU ordering to be
    // deterministic — real writes are microseconds apart on a fast
    // test machine, which some filesystems round to the same second.
    await File(
      oldest,
    ).setLastModified(DateTime.now().subtract(const Duration(minutes: 3)));
    // A caller must release its lease once it's done using a clip (see
    // TtsService.releasePaths) before that clip becomes eligible for
    // eviction again — a clip nobody has released yet is protected no
    // matter how old its mtime is.
    await svc.releasePaths([oldest]);
    final middle = await svc.ensureAudio(const DialogueLine('B', 'zwei'));
    await File(
      middle,
    ).setLastModified(DateTime.now().subtract(const Duration(minutes: 2)));
    await svc.releasePaths([middle]);

    // Pushes total size over budget; the trim pass this triggers must
    // remove `oldest` (least-recently modified, released) and keep
    // `middle` (released but more recently touched).
    await svc.ensureAudio(const DialogueLine('C', 'drei'));

    expect(await File(oldest).exists(), isFalse);
    expect(await File(middle).exists(), isTrue);
  });

  test('replaying a cached clip touches its mtime so it outlives an unused '
      'older one, once both are released', () async {
    TtsService.debugMaxCacheBytesOverride = 1500;
    TtsService.debugHttpClient = MockClient(
      (_) async => http.Response.bytes(fakeClipBytes(), 200),
    );

    const oldLine = DialogueLine('A', 'eins');
    final oldPath = await svc.ensureAudio(oldLine);
    await File(
      oldPath,
    ).setLastModified(DateTime.now().subtract(const Duration(minutes: 5)));
    await svc.releasePaths([oldPath]);
    final unusedPath = await svc.ensureAudio(const DialogueLine('B', 'zwei'));
    await File(
      unusedPath,
    ).setLastModified(DateTime.now().subtract(const Duration(minutes: 4)));
    await svc.releasePaths([unusedPath]);

    // Replay the old clip — a cache hit — right before the third write
    // pushes the directory over budget. Re-pinned by the replay, so it
    // must be released again once this "use" is done, same as any
    // other ensureAudio result.
    final replayed = await svc.ensureAudio(oldLine);
    await svc.releasePaths([replayed]);
    await svc.ensureAudio(const DialogueLine('C', 'drei'));

    expect(
      await File(oldPath).exists(),
      isTrue,
      reason: 'replayed clip must survive eviction',
    );
    expect(await File(unusedPath).exists(), isFalse);
  });

  group('concurrent ensureAudio calls', () {
    test(
      'two parallel requests for the same DialogueLine do not race the '
      'shared temp file and both resolve to a valid committed clip',
      () async {
        var requests = 0;
        TtsService.debugHttpClient = MockClient((_) async {
          requests++;
          // Hold the "network" response open long enough that, before the
          // fix, the second concurrent call would start its own synthesis
          // and race the first call's `<key>.mp3.tmp`.
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response.bytes(fakeClipBytes(), 200);
        });
        const line = DialogueLine('Chef', 'Guten Tag, wie geht es Ihnen?');

        final results = await Future.wait([
          svc.ensureAudio(line),
          svc.ensureAudio(line),
        ]);

        expect(results[0], results[1]);
        final file = File(results[0]);
        expect(await file.exists(), isTrue);
        expect(await file.length(), greaterThanOrEqualTo(512));
        expect(await File('${results[0]}.tmp').exists(), isFalse);
        // Serialized, not duplicated: the second caller joins the first
        // rather than triggering its own synthesis.
        expect(requests, 1);
      },
    );

    test('a forceRegenerate call arriving while a plain call for the same key '
        'is in flight is serialized, not raced', () async {
      var requests = 0;
      TtsService.debugHttpClient = MockClient((_) async {
        requests++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response.bytes(fakeClipBytes(), 200);
      });
      const line = DialogueLine('Chef', 'Auf Wiedersehen.');

      final results = await Future.wait([
        svc.ensureAudio(line),
        svc.ensureAudio(line, forceRegenerate: true),
      ]);

      expect(results[0], results[1]);
      expect(await File(results[0]).exists(), isTrue);
      expect(await File('${results[0]}.tmp').exists(), isFalse);
      // The plain call fills the cache; the forced call still runs its
      // own synthesis afterwards rather than being silently skipped.
      expect(requests, 2);
    });

    test('concurrent requests for different DialogueLines do not interfere '
        'with each other', () async {
      var requests = 0;
      TtsService.debugHttpClient = MockClient((_) async {
        requests++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return http.Response.bytes(fakeClipBytes(), 200);
      });

      final results = await Future.wait([
        svc.ensureAudio(const DialogueLine('A', 'eins')),
        svc.ensureAudio(const DialogueLine('B', 'zwei')),
        svc.ensureAudio(const DialogueLine('C', 'drei')),
      ]);

      expect(results.toSet().length, 3, reason: 'distinct cache keys');
      for (final path in results) {
        expect(await File(path).exists(), isTrue);
      }
      expect(requests, 3);
    });

    test('a failed synthesis for one caller does not corrupt the file the '
        'other concurrent caller for the same key is waiting on', () async {
      var requests = 0;
      TtsService.debugHttpClient = MockClient((_) async {
        requests++;
        if (requests == 1) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return http.Response('server error', 500);
        }
        return http.Response.bytes(fakeClipBytes(), 200);
      });
      const line = DialogueLine('Chef', 'Ein Moment bitte.');

      final first = svc.ensureAudio(line);
      final second = svc.ensureAudio(line);

      await expectLater(first, throwsA(anything));
      final path = await second;
      expect(await File(path).exists(), isTrue);
      expect(await File(path).length(), greaterThanOrEqualTo(512));
      expect(await File('$path.tmp').exists(), isFalse);
    });
  });

  group('concurrent LRU eviction across different keys', () {
    // Regression for the third independent review: an earlier fix already
    // serialized commit+evict across keys (`_evictionChain`) and excluded
    // each pass's OWN just-committed file from its OWN eviction pass, but
    // that per-pass `exclude` only protected a path from the pass its own
    // commit triggered. An EARLIER pass — triggered by a DIFFERENT key
    // that happened to enter the queue first — could still see this
    // path's file (already written to disk) and delete it while this
    // operation was still waiting for its own turn in the queue, so
    // `ensureAudio` could resolve to a path a concurrent operation had
    // already deleted. The fix pins every path `ensureAudio` returns
    // (see TtsService._pinnedPaths) the instant it's committed, and every
    // eviction pass — whichever key triggered it — now skips ANY pinned
    // path, not just its own.
    test('two concurrent commits for different keys under a tight budget: '
        'BOTH futures resolve to a still-existing file (no over-eviction) '
        'while both leases are held, with no leftover .tmp', () async {
      // Two 600B clips (1200B total) against a 1000B budget. Both
      // callers are still holding their lease at this point (neither
      // has released yet), so the directory is allowed to sit
      // temporarily over budget — see TtsService.releasePaths's doc.
      // What must NEVER happen is either returned path having already
      // been deleted by the other key's eviction pass.
      TtsService.debugMaxCacheBytesOverride = 1000;
      TtsService.debugHttpClient = MockClient((_) async {
        // Small delay so both commits are genuinely in flight together
        // — this is the actual race window the bug lived in.
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return http.Response.bytes(fakeClipBytes(), 200);
      });

      Future<bool> valid(Future<String> operation) async {
        final path = await operation;
        return File(path).exists();
      }

      final validAtReturn = await Future.wait([
        valid(svc.ensureAudio(const DialogueLine('A', 'eins'))),
        valid(svc.ensureAudio(const DialogueLine('B', 'zwei'))),
      ]);

      expect(
        validAtReturn,
        everyElement(isTrue),
        reason:
            'every ensureAudio() call must resolve to a path that still '
            'exists at the moment it resolves, even while a sibling '
            'key\'s eviction pass is racing it',
      );

      final cacheDir = Directory('${cacheRoot.path}/tts_cache');
      final entries = await cacheDir.list().toList();
      final clips = entries.where((e) => e.path.endsWith('.mp3')).toList();
      final tmps = entries.where((e) => e.path.endsWith('.tmp')).toList();
      expect(
        clips,
        hasLength(2),
        reason: 'both leases are still held — neither may be evicted yet',
      );
      expect(tmps, isEmpty);
    });

    test(
      'after both leases from the previous scenario are released, a '
      'deferred eviction pass brings the cache back under budget without '
      'over-evicting, and the evicted key resynthesizes on request',
      () async {
        TtsService.debugMaxCacheBytesOverride = 1000;
        TtsService.debugHttpClient = MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return http.Response.bytes(fakeClipBytes(), 200);
        });

        final results = await Future.wait([
          svc.ensureAudio(const DialogueLine('A', 'eins')),
          svc.ensureAudio(const DialogueLine('B', 'zwei')),
        ]);
        final pathA = results[0];
        final pathB = results[1];
        expect(pathA, isNot(pathB));
        // Both still exist right after resolving (see previous test) —
        // now simulate both callers finishing their use and releasing.
        await svc.releasePaths([pathA, pathB]);

        final existsA = await File(pathA).exists();
        final existsB = await File(pathB).exists();
        expect(
          existsA != existsB,
          isTrue,
          reason:
              'once released, exactly one of the two 600B clips must '
              'survive a 1000B budget — not both (over budget) and not '
              'neither (over-eviction); existsA=$existsA existsB=$existsB',
        );

        final cacheDir = Directory('${cacheRoot.path}/tts_cache');
        final entries = await cacheDir.list().toList();
        final clips = entries.where((e) => e.path.endsWith('.mp3')).toList();
        final tmps = entries.where((e) => e.path.endsWith('.tmp')).toList();
        expect(clips, hasLength(1));
        expect(tmps, isEmpty);
        var totalBytes = 0;
        for (final clip in clips) {
          totalBytes += await File(clip.path).length();
        }
        expect(totalBytes, lessThanOrEqualTo(1000));

        // Whichever key got evicted must synthesize fresh on the next
        // call, not silently reuse/serve a path that no longer exists —
        // and the cache must not stay over budget forever with no
        // further synthesis to trigger a fix-up pass.
        final evictedLine = existsA
            ? const DialogueLine('B', 'zwei')
            : const DialogueLine('A', 'eins');
        var resynthRequests = 0;
        TtsService.debugHttpClient = MockClient((_) async {
          resynthRequests++;
          return http.Response.bytes(fakeClipBytes(), 200);
        });
        final resynthesized = await svc.ensureAudio(evictedLine);
        expect(await File(resynthesized).exists(), isTrue);
        expect(resynthRequests, 1);
      },
    );

    test(
      'three concurrent commits for different keys under a tight budget: '
      'all three remain accessible until released, and after release '
      'exactly the mathematically correct number of LRU survivors remain',
      () async {
        // 3 x 600B = 1800B against a 1400B budget (90% target = 1260B):
        // removing exactly one 600B clip brings the total to 1200B, which
        // already clears the target, so exactly one clip must be evicted
        // once released — not two (over-eviction) and not zero (broken
        // budget).
        TtsService.debugMaxCacheBytesOverride = 1400;
        TtsService.debugHttpClient = MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return http.Response.bytes(fakeClipBytes(), 200);
        });

        final results = await Future.wait([
          svc.ensureAudio(const DialogueLine('A', 'eins')),
          svc.ensureAudio(const DialogueLine('B', 'zwei')),
          svc.ensureAudio(const DialogueLine('C', 'drei')),
        ]);

        for (final path in results) {
          expect(
            await File(path).exists(),
            isTrue,
            reason:
                'all three leases are still held — none may be '
                'evicted before release',
          );
        }

        await svc.releasePaths(results);

        var survivors = 0;
        for (final path in results) {
          if (await File(path).exists()) survivors++;
        }
        expect(
          survivors,
          2,
          reason:
              'evicting exactly one 600B clip clears the 1400B budget\'s '
              '90% target; over-eviction would leave fewer, and a broken '
              'budget would leave all three',
        );

        final cacheDir = Directory('${cacheRoot.path}/tts_cache');
        final tmps = await cacheDir
            .list()
            .where((e) => e.path.endsWith('.tmp'))
            .toList();
        expect(tmps, isEmpty);
      },
    );
  });

  group('legacy Documents/tts_cache cleanup', () {
    test(
      'a legacy cache directory left over from before CR-14 is removed',
      () async {
        final legacy = Directory('${docsRoot.path}/tts_cache')
          ..createSync(recursive: true);
        File('${legacy.path}/old_clip.mp3').writeAsBytesSync(fakeClipBytes());
        // An unrelated sibling under Documents must survive the cleanup —
        // only the exact former cache subdirectory is in scope.
        final unrelated = File('${docsRoot.path}/courses.json')
          ..createSync(recursive: true);
        unrelated.writeAsStringSync('{}');

        TtsService.debugHttpClient = MockClient(
          (_) async => http.Response.bytes(fakeClipBytes(), 200),
        );
        await svc.ensureAudio(const DialogueLine('Chef', 'Hallo.'));

        expect(await legacy.exists(), isFalse);
        expect(await unrelated.exists(), isTrue);
      },
    );

    test('a missing legacy directory is handled without error', () async {
      final legacy = Directory('${docsRoot.path}/tts_cache');
      expect(await legacy.exists(), isFalse);

      TtsService.debugHttpClient = MockClient(
        (_) async => http.Response.bytes(fakeClipBytes(), 200),
      );
      final path = await svc.ensureAudio(const DialogueLine('Chef', 'Hallo.'));
      expect(await File(path).exists(), isTrue);
    });

    test('a storage exception during legacy cleanup does not break the main '
        'TTS scenario', () async {
      Directory('${docsRoot.path}/tts_cache').createSync(recursive: true);
      TtsService.debugForceLegacyCleanupFailure = true;
      TtsService.debugHttpClient = MockClient(
        (_) async => http.Response.bytes(fakeClipBytes(), 200),
      );

      final path = await svc.ensureAudio(const DialogueLine('Chef', 'Hallo.'));
      expect(await File(path).exists(), isTrue);
    });

    test('running cleanup again on an already-clean state is safe', () async {
      final legacy = Directory('${docsRoot.path}/tts_cache')
        ..createSync(recursive: true);
      TtsService.debugHttpClient = MockClient(
        (_) async => http.Response.bytes(fakeClipBytes(), 200),
      );

      await svc.ensureAudio(const DialogueLine('Chef', 'Hallo.'));
      expect(await legacy.exists(), isFalse);

      // Simulate a fresh process (new memoized state) running cleanup
      // again against the now-already-clean legacy location.
      svc.debugResetCacheDirForTests();
      final second = await svc.ensureAudio(
        const DialogueLine('Chef', 'Hallo.'),
      );
      expect(await File(second).exists(), isTrue);
    });
  });
}
