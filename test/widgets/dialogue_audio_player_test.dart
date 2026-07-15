// CR-15: DialogueAudioPlayer used to show hardcoded German/Russian text
// regardless of the app's locale, and stored the raw caught exception
// (which can carry a backend response body, see CR-11) as user-facing
// error text. These tests pin: the idle label follows the app locale, the
// transcript toggle exposes a real accessibility label, and a synthesis
// failure never surfaces the exception's own message.
import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:exam_trainer/services/tts_service.dart';
import 'package:exam_trainer/widgets/dialogue_audio_player.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this._path);
  final String _path;

  @override
  Future<String?> getApplicationCachePath() async => _path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _path;
}

/// Fake [AudioPlayerAdapter] that never touches a real platform channel —
/// `package:audioplayers`' method/event channels aren't mocked in plain
/// `flutter test` (confirmed: even a bare `AudioPlayer().stop()` throws
/// `MissingPluginException`), which previously made it impossible to
/// drive this widget past the "preparing" state in a widget test. This
/// lets tests deterministically simulate a play()/setPlaybackRate()
/// failure and reach real playing/paused states.
class _FakeAudioPlayerAdapter implements AudioPlayerAdapter {
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _completeController = StreamController<void>.broadcast();

  int playCallCount = 0;
  final List<String> playedPaths = [];

  /// When set, the FIRST call to [play] awaits this before resolving —
  /// lets a test hold a play() call open to dispose or supersede the
  /// widget mid-flight.
  Completer<void>? gateFirstPlay;

  /// When true, the FIRST call to [play] throws after any [gateFirstPlay]
  /// is released. Calls after the first always succeed, so a test can
  /// simulate "the doomed attempt is superseded by a fresh, successful
  /// one" without needing two separate fakes.
  bool failFirstPlay = false;

  bool failSetPlaybackRate = false;
  int disposeCallCount = 0;

  @override
  Stream<Duration> get onPositionChanged => _positionController.stream;
  @override
  Stream<Duration> get onDurationChanged => _durationController.stream;
  @override
  Stream<void> get onPlayerComplete => _completeController.stream;

  @override
  Future<void> play(Source source) async {
    playCallCount++;
    if (playCallCount == 1) {
      if (gateFirstPlay != null) await gateFirstPlay!.future;
      if (failFirstPlay) {
        throw Exception('simulated play failure: missing/invalid file');
      }
    }
    playedPaths.add(source is DeviceFileSource ? source.path : '<unknown>');
  }

  @override
  Future<void> setPlaybackRate(double rate) async {
    if (failSetPlaybackRate) {
      throw Exception('simulated setPlaybackRate failure');
    }
  }

  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> dispose() async {
    disposeCallCount++;
    await _positionController.close();
    await _durationController.close();
    await _completeController.close();
  }
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('dialogue_audio_player_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    // TtsService.instance is a singleton shared across tests in this file —
    // reset its memoized cache dir so it re-resolves against this test's
    // fake PathProviderPlatform instead of a previous test's temp dir.
    TtsService.instance.debugResetCacheDirForTests();
  });

  tearDown(() {
    TtsService.debugHttpClient = null;
    TtsService.debugIdTokenOverride = null;
    TtsService.instance.debugResetCacheDirForTests();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Widget wrap(Widget child, {Locale locale = const Locale('en')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de'),
        Locale('en'),
        Locale('ru'),
        Locale('uk'),
      ],
      home: Scaffold(body: child),
    );
  }

  testWidgets('the idle play label follows the app locale, not a hardcoded '
      'German/Russian string', (tester) async {
    await tester.pumpWidget(
      wrap(
        const DialogueAudioPlayer(text: 'Chef: Hallo.', accent: Colors.blue),
        locale: const Locale('en'),
      ),
    );
    await tester.pump();

    expect(find.text('Listen to dialogue'), findsOneWidget);
    expect(find.text('Dialog anhören'), findsNothing);
    expect(find.text('Текст диалога'), findsNothing);
  });

  testWidgets('the transcript toggle exposes an accessibility label', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const DialogueAudioPlayer(text: 'Chef: Hallo.', accent: Colors.blue),
      ),
    );
    await tester.pump();

    final semantics = tester.getSemantics(
      find.text('Dialogue text').hitTestable(),
    );
    expect(semantics.label, 'Dialogue text');
  });

  testWidgets(
    'a synthesis failure never shows the raw exception text to the user',
    (tester) async {
      TtsService.debugIdTokenOverride = () async => 'test-token';
      TtsService.debugHttpClient = MockClient(
        (_) async =>
            http.Response('super secret internal stack trace detail', 500),
      );

      await tester.pumpWidget(
        wrap(
          const DialogueAudioPlayer(text: 'Chef: Hallo.', accent: Colors.blue),
        ),
      );
      await tester.pump();
      // testWidgets runs inside a FakeAsync zone, where genuine dart:io
      // async calls (TtsService.ensureAudio checks real file
      // existence/length before it ever reaches the mocked HTTP call)
      // never complete without stepping outside that zone via runAsync.
      // Not pumpAndSettle either: `audioplayers`' position/duration stream
      // subscriptions keep scheduling activity for the player's lifetime,
      // so pumpAndSettle never observes quiescence.
      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.play_circle_filled));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      expect(find.textContaining('secret internal stack trace'), findsNothing);
      expect(find.textContaining('500'), findsNothing);
      expect(find.text('Error while generating'), findsOneWidget);
    },
  );

  // CR: lifecycle hardening — a stale prepare/play async chain used to be
  // able to setState (or worse, start playback) after the widget was gone,
  // and two overlapping operations (e.g. tap play then hit regenerate
  // mid-preparing) could race each other's state. These tests pin the
  // generation-token guard added to fix that.
  group('lifecycle', () {
    testWidgets(
      'disposing while audio is still preparing does not throw and applies '
      'no stale state once the network response finally arrives',
      (tester) async {
        final release = Completer<http.Response>();
        TtsService.debugIdTokenOverride = () async => 'test-token';
        TtsService.debugHttpClient = MockClient((_) async => release.future);

        await tester.pumpWidget(
          wrap(
            const DialogueAudioPlayer(
              text: 'Chef: Hallo.',
              accent: Colors.blue,
            ),
          ),
        );
        await tester.pump();

        // File I/O inside TtsService.ensureAudio is real dart:io, which
        // needs runAsync to make progress even though the HTTP response
        // itself is gated behind `release` (see the module-level comment
        // on the earlier error test for why plain pump() can't do this).
        await tester.runAsync(() async {
          await tester.tap(find.byIcon(Icons.play_circle_filled));
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();
        expect(
          find.byType(CircularProgressIndicator),
          findsOneWidget,
          reason: 'must be mid-prepare, awaiting the gated HTTP response',
        );

        // Unmount the player while its prepare loop is still awaiting
        // `release` — this disposes _DialogueAudioPlayerState mid-await.
        await tester.pumpWidget(wrap(const SizedBox.shrink()));

        // Now let the pending "network" call resolve. Before the fix, the
        // resumed continuation would call setState on a disposed State and
        // could go on to call _player.play() on an already-disposed player.
        await tester.runAsync(() async {
          release.complete(http.Response.bytes(List.filled(600, 65), 200));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'the regenerate button is disabled while a prepare is already running',
      (tester) async {
        final release = Completer<http.Response>();
        TtsService.debugIdTokenOverride = () async => 'test-token';
        TtsService.debugHttpClient = MockClient((_) async => release.future);

        await tester.pumpWidget(
          wrap(
            const DialogueAudioPlayer(
              text: 'Chef: Hallo.',
              accent: Colors.blue,
            ),
          ),
        );
        await tester.pump();

        await tester.runAsync(() async {
          await tester.tap(find.byIcon(Icons.play_circle_filled));
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();

        final regenerateButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.refresh_rounded),
        );
        expect(
          regenerateButton.onPressed,
          isNull,
          reason:
              'tapping regenerate mid-prepare must not start a second, '
              'overlapping prepare operation against the same cache key',
        );
        // Deliberately leave `release` uncompleted — this test only cares
        // about the button's disabled state while preparing.
      },
    );

    testWidgets(
      'mounting a fresh player after a previous instance was disposed '
      'mid-prepare starts a clean, independent prepare operation '
      '(repeated-launch path, e.g. leaving and reopening the exercise)',
      (tester) async {
        final firstRelease = Completer<http.Response>();
        var requests = 0;
        TtsService.debugIdTokenOverride = () async => 'test-token';
        TtsService.debugHttpClient = MockClient((_) async {
          requests++;
          // Only the very first (later-disposed) instance's request is
          // gated; nothing in this test ever lets a second attempt reach
          // this far, so any later call would just get the same shape.
          if (requests == 1) return firstRelease.future;
          return http.Response.bytes(List.filled(600, 65), 200);
        });

        const player = DialogueAudioPlayer(
          text: 'Chef: Hallo.',
          accent: Colors.blue,
        );

        await tester.pumpWidget(wrap(player));
        await tester.pump();
        await tester.runAsync(() async {
          await tester.tap(find.byIcon(Icons.play_circle_filled));
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Leave the screen (dispose) before the first attempt ever
        // resolves — mirrors navigating away mid-import/mid-prepare.
        await tester.pumpWidget(wrap(const SizedBox.shrink()));

        // Come back and mount a brand-new instance for the same line.
        await tester.pumpWidget(wrap(player));
        await tester.pump();
        expect(
          find.byIcon(Icons.play_circle_filled),
          findsOneWidget,
          reason:
              'fresh instance must start idle, unaffected by the '
              'disposed one\'s in-flight operation',
        );

        // Now let the FIRST (disposed) instance's gated request resolve.
        // Its stale continuation must not touch the new, second instance.
        await tester.runAsync(() async {
          firstRelease.complete(http.Response.bytes(List.filled(600, 65), 200));
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(
          find.byIcon(Icons.play_circle_filled),
          findsOneWidget,
          reason:
              'the new instance must remain idle until its own tap '
              'starts it',
        );
      },
    );
  });

  // Independent-review follow-up: _player.play() failing used to be
  // silently swallowed after `_state` was already set to `playing`,
  // leaving the widget stuck showing a live playback bar with no audio
  // and no way out. These tests use _FakeAudioPlayerAdapter (see above)
  // to reach real playing/paused states and simulate platform failures —
  // both impossible with the real audioplayers platform channels in this
  // test harness.
  group('AudioPlayer failure handling', () {
    testWidgets(
      'a play() failure (missing/invalid file) shows the generic error UI, '
      'never a raw exception, and never leaves the widget stuck showing '
      '"playing"',
      (tester) async {
        TtsService.debugIdTokenOverride = () async => 'test-token';
        TtsService.debugHttpClient = MockClient(
          (_) async => http.Response.bytes(List.filled(600, 65), 200),
        );
        final fakePlayer = _FakeAudioPlayerAdapter()..failFirstPlay = true;

        await tester.pumpWidget(
          wrap(
            DialogueAudioPlayer(
              text: 'Chef: Hallo.',
              accent: Colors.blue,
              debugPlayerFactory: () => fakePlayer,
            ),
          ),
        );
        await tester.pump();

        await tester.runAsync(() async {
          await tester.tap(find.byIcon(Icons.play_circle_filled));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        expect(find.text('Error while generating'), findsOneWidget);
        expect(find.textContaining('Exception'), findsNothing);
        expect(find.textContaining('simulated'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          find.byIcon(Icons.pause_circle_filled),
          findsNothing,
          reason: 'must not be stuck showing a live "playing" bar',
        );
      },
    );

    testWidgets(
      'a setPlaybackRate() failure after a successful play() also shows '
      'the generic error UI instead of leaving "playing" with no audio',
      (tester) async {
        TtsService.debugIdTokenOverride = () async => 'test-token';
        TtsService.debugHttpClient = MockClient(
          (_) async => http.Response.bytes(List.filled(600, 65), 200),
        );
        final fakePlayer = _FakeAudioPlayerAdapter()
          ..failSetPlaybackRate = true;

        await tester.pumpWidget(
          wrap(
            DialogueAudioPlayer(
              text: 'Chef: Hallo.',
              accent: Colors.blue,
              debugPlayerFactory: () => fakePlayer,
            ),
          ),
        );
        await tester.pump();

        await tester.runAsync(() async {
          await tester.tap(find.byIcon(Icons.play_circle_filled));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        expect(find.text('Error while generating'), findsOneWidget);
        expect(
          fakePlayer.playedPaths,
          hasLength(1),
          reason:
              'play() itself must have succeeded before rate-setting '
              'failed',
        );
      },
    );

    testWidgets(
      'a play() error that resolves after the widget is disposed does not '
      'setState or throw',
      (tester) async {
        TtsService.debugIdTokenOverride = () async => 'test-token';
        TtsService.debugHttpClient = MockClient(
          (_) async => http.Response.bytes(List.filled(600, 65), 200),
        );
        final gate = Completer<void>();
        final fakePlayer = _FakeAudioPlayerAdapter()
          ..failFirstPlay = true
          ..gateFirstPlay = gate;

        await tester.pumpWidget(
          wrap(
            DialogueAudioPlayer(
              text: 'Chef: Hallo.',
              accent: Colors.blue,
              debugPlayerFactory: () => fakePlayer,
            ),
          ),
        );
        await tester.pump();

        await tester.runAsync(() async {
          await tester.tap(find.byIcon(Icons.play_circle_filled));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();
        // State is optimistically "playing" already (set before awaiting
        // play()); the gated play() call itself hasn't resolved yet.

        // Unmount the player while play() is still pending.
        await tester.pumpWidget(wrap(const SizedBox.shrink()));

        // Now let the gated play() finally reject.
        await tester.runAsync(() async {
          gate.complete();
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'a stale play() failure does not overwrite the state of a newer, '
      'already-succeeded operation',
      (tester) async {
        TtsService.debugIdTokenOverride = () async => 'test-token';
        TtsService.debugHttpClient = MockClient(
          (_) async => http.Response.bytes(List.filled(600, 65), 200),
        );
        final gate = Completer<void>();
        final fakePlayer = _FakeAudioPlayerAdapter()
          ..failFirstPlay = true
          ..gateFirstPlay = gate;

        await tester.pumpWidget(
          wrap(
            DialogueAudioPlayer(
              text: 'Chef: Hallo.',
              accent: Colors.blue,
              debugPlayerFactory: () => fakePlayer,
            ),
          ),
        );
        await tester.pump();

        // Start the first (doomed) attempt — it gets stuck inside the
        // gated, eventually-failing first play() call.
        await tester.runAsync(() async {
          await tester.tap(find.byIcon(Icons.play_circle_filled));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        // Regenerate supersedes it with a fresh attempt, whose own play()
        // call (the fake's second) succeeds.
        await tester.runAsync(() async {
          await tester.tap(find.byTooltip('Regenerate audio'));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();
        expect(
          find.byIcon(Icons.pause_circle_filled),
          findsOneWidget,
          reason: 'the newer operation should have reached playing',
        );

        // Now let the stale first play() finally reject.
        await tester.runAsync(() async {
          gate.complete();
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();

        expect(
          find.byIcon(Icons.pause_circle_filled),
          findsOneWidget,
          reason:
              'the stale rejection must not flip a newer, successful '
              'operation into error state',
        );
        expect(find.text('Error while generating'), findsNothing);
      },
    );

    testWidgets(
      'paused state exposes weiterhoeren ("Resume") as its label, not the '
      'idle "listen to dialogue" label',
      (tester) async {
        TtsService.debugIdTokenOverride = () async => 'test-token';
        TtsService.debugHttpClient = MockClient(
          (_) async => http.Response.bytes(List.filled(600, 65), 200),
        );
        final fakePlayer = _FakeAudioPlayerAdapter();

        await tester.pumpWidget(
          wrap(
            DialogueAudioPlayer(
              text: 'Chef: Hallo.',
              accent: Colors.blue,
              debugPlayerFactory: () => fakePlayer,
            ),
          ),
        );
        await tester.pump();

        await tester.runAsync(() async {
          await tester.tap(find.byIcon(Icons.play_circle_filled));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();
        expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);

        // Tap the now-showing pause icon to pause playback.
        await tester.tap(find.byIcon(Icons.pause_circle_filled));
        await tester.pump();

        expect(find.text('Resume'), findsOneWidget);
        expect(find.text('Listen to dialogue'), findsNothing);
        final semantics = tester.getSemantics(
          find.byIcon(Icons.play_circle_filled).hitTestable(),
        );
        expect(semantics.label, 'Resume');
      },
    );
  });
}
