// CR-15: DialogueAudioPlayer used to show hardcoded German/Russian text
// regardless of the app's locale, and stored the raw caught exception
// (which can carry a backend response body, see CR-11) as user-facing
// error text. These tests pin: the idle label follows the app locale, the
// transcript toggle exposes a real accessibility label, and a synthesis
// failure never surfaces the exception's own message.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exam_trainer/models/exercises/telefonnotiz_variant.dart';
import 'package:exam_trainer/models/voice_gender.dart';
import 'package:exam_trainer/repositories/voice_preference_repository.dart';
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

  /// When set, gates the VERY NEXT call to [play] (whichever call count
  /// that is), then clears itself — lets a test hold open a specific,
  /// later `play()` call (not necessarily the first) so an OLDER
  /// `_playFrom` can be made to resolve strictly after a NEWER one,
  /// deterministically reproducing the ordering a real race only
  /// sometimes produces.
  Completer<void>? gateNextPlay;

  /// When true, the FIRST call to [play] throws after any [gateFirstPlay]
  /// is released. Calls after the first always succeed, so a test can
  /// simulate "the doomed attempt is superseded by a fresh, successful
  /// one" without needing two separate fakes.
  bool failFirstPlay = false;

  bool failSetPlaybackRate = false;
  bool failPause = false;
  bool failResume = false;
  bool failDispose = false;
  int disposeCallCount = 0;
  int stopCallCount = 0;

  /// How many times production code has attached a completion listener
  /// (i.e. called `.listen()` on [onPlayerComplete]) — the direct signal
  /// for whether a stale, superseded `_playFrom` call attached a SECOND,
  /// redundant listener alongside the current one's. Counting attachments
  /// is a more reliable test signal than trying to observe both listeners
  /// actually firing: `flutter_test`'s `runAsync` briefly leaves the
  /// test's controlled zone for real async execution and back, and a
  /// broadcast StreamController's event delivery to a subscription
  /// created in an earlier `runAsync` excursion is not reliably observed
  /// once the test has returned to a later one — a test-harness quirk,
  /// not a statement about the real `audioplayers` platform behavior.
  int completeListenCount = 0;

  /// Lets a test simulate the underlying player firing its completion
  /// event, without needing a real platform channel.
  void fireComplete() => _completeController.add(null);

  @override
  Stream<Duration> get onPositionChanged => _positionController.stream;
  @override
  Stream<Duration> get onDurationChanged => _durationController.stream;
  @override
  Stream<void> get onPlayerComplete {
    completeListenCount++;
    return _completeController.stream;
  }

  @override
  Future<void> play(Source source) async {
    playCallCount++;
    if (playCallCount == 1) {
      if (gateFirstPlay != null) await gateFirstPlay!.future;
      if (failFirstPlay) {
        throw Exception('simulated play failure: missing/invalid file');
      }
    }
    final gate = gateNextPlay;
    if (gate != null) {
      gateNextPlay = null;
      await gate.future;
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
  Future<void> pause() async {
    if (failPause) throw Exception('simulated pause failure');
  }

  @override
  Future<void> resume() async {
    if (failResume) throw Exception('simulated resume failure');
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
  }

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> dispose() async {
    disposeCallCount++;
    await _positionController.close();
    await _durationController.close();
    await _completeController.close();
    if (failDispose) throw Exception('simulated dispose failure');
  }
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('dialogue_audio_player_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    SharedPreferences.setMockInitialValues({});
    VoicePreferenceRepository.debugUidOverride = 'dialogue-player-test-user';
    VoicePreferenceRepository.debugForceSignedOut = false;
    VoicePreferenceRepository.instance.debugResetForTests();
    // TtsService.instance is a singleton shared across tests in this file —
    // reset its memoized cache dir so it re-resolves against this test's
    // fake PathProviderPlatform instead of a previous test's temp dir.
    TtsService.instance.debugResetCacheDirForTests();
  });

  tearDown(() {
    TtsService.debugHttpClient = null;
    TtsService.debugIdTokenOverride = null;
    VoicePreferenceRepository.debugUidOverride = null;
    VoicePreferenceRepository.debugForceSignedOut = false;
    VoicePreferenceRepository.instance.debugResetForTests();
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

  Future<void> waitForPlayCalls(
    WidgetTester tester,
    _FakeAudioPlayerAdapter player,
    int expected,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (player.playCallCount < expected &&
        DateTime.now().isBefore(deadline)) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(
      player.playCallCount,
      greaterThanOrEqualTo(expected),
      reason: 'audio preparation did not reach play() before the test timeout',
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

  group('voice gender controls', () {
    testWidgets('single-recording controls are localized and accessible', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        wrap(
          const DialogueAudioPlayer(
            text: 'Eine neutrale Aufnahme ohne Sprecher.',
            accent: Colors.blue,
            recordingId: 'recording-single',
            parsedVoiceGender: VoiceGender.female,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.bySemanticsLabel('Recording voice'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('manual single-recording override beats parsed voice hint', (
      tester,
    ) async {
      TtsService.debugIdTokenOverride = () async => 'test-token';
      final requestBodies = <Map<String, dynamic>>[];
      TtsService.debugHttpClient = MockClient((request) async {
        requestBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response.bytes(List.filled(600, 65), 200);
      });
      final fakePlayer = _FakeAudioPlayerAdapter();

      await tester.pumpWidget(
        wrap(
          DialogueAudioPlayer(
            text: 'Hallo, hier ist Andrea Faber.',
            accent: Colors.blue,
            recordingId: 'telefonnotiz:v1:original',
            parsedVoiceGender: VoiceGender.female,
            debugPlayerFactory: () => fakePlayer,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Male'));
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.play_circle_filled));
        await Future<void>.delayed(const Duration(milliseconds: 120));
      });
      await tester.pump();

      expect(requestBodies, hasLength(1));
      expect(requestBodies.single['voice_gender'], 'male');
      expect(
        await VoicePreferenceRepository.instance.getOverride(
          'telefonnotiz:v1:original',
        ),
        VoiceGender.male,
      );
    });

    testWidgets('per-speaker overrides are scoped by speaker and recording', (
      tester,
    ) async {
      TtsService.debugIdTokenOverride = () async => 'test-token';
      final requestBodies = <Map<String, dynamic>>[];
      TtsService.debugHttpClient = MockClient((request) async {
        requestBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response.bytes(List.filled(600, 65), 200);
      });
      final fakePlayer = _FakeAudioPlayerAdapter();

      await tester.pumpWidget(
        wrap(
          DialogueAudioPlayer(
            text: 'Chef: Hallo. Frau Kunde: Guten Tag.',
            accent: Colors.blue,
            recordingId: 'hoeren_teil1:v1:original:pair-1',
            parsedSpeakerVoiceGenders: const {
              'chef': VoiceGender.male,
              'frau kunde': VoiceGender.female,
            },
            debugPlayerFactory: () => fakePlayer,
          ),
        ),
      );
      await tester.pump();

      expect(find.bySemanticsLabel('Voice for Chef'), findsOneWidget);
      expect(find.bySemanticsLabel('Voice for Frau Kunde'), findsOneWidget);

      await tester.tap(find.text('Female').first);
      await tester.pump();
      await tester.tap(find.text('Male').last);
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.play_circle_filled));
        await Future<void>.delayed(const Duration(milliseconds: 180));
      });
      await tester.pump();

      expect(requestBodies, hasLength(2));
      expect(requestBodies[0]['speaker'], 'Chef');
      expect(requestBodies[0]['voice_gender'], 'female');
      expect(requestBodies[1]['speaker'], 'Frau Kunde');
      expect(requestBodies[1]['voice_gender'], 'male');

      expect(
        await VoicePreferenceRepository.instance.getOverride(
          'hoeren_teil1:v1:original:pair-1#speaker:chef',
        ),
        VoiceGender.female,
      );
      expect(
        await VoicePreferenceRepository.instance.getOverride(
          'hoeren_teil1:v1:original:pair-2#speaker:chef',
        ),
        isNull,
      );
    });

    testWidgets(
      'changing recording configuration stops, releases leases, reparses, '
      'and does not autoplay',
      (tester) async {
        TtsService.debugIdTokenOverride = () async => 'test-token';
        TtsService.debugHttpClient = MockClient(
          (_) async => http.Response.bytes(List.filled(600, 65), 200),
        );
        final fakePlayer = _FakeAudioPlayerAdapter();

        Widget player(String text, String recordingId) => wrap(
          DialogueAudioPlayer(
            text: text,
            accent: Colors.blue,
            recordingId: recordingId,
            initiallyShowText: true,
            showTextToggle: false,
            debugPlayerFactory: () => fakePlayer,
          ),
        );

        await tester.pumpWidget(player('Chef: Erste Aufnahme.', 'rec-1'));
        await tester.pump();
        await tester.runAsync(() async {
          await tester.tap(find.byIcon(Icons.play_circle_filled));
          await Future<void>.delayed(const Duration(milliseconds: 120));
        });
        await tester.pump();

        expect(fakePlayer.playCallCount, 1);
        expect(TtsService.instance.debugPinCountsForTests, isNotEmpty);

        await tester.pumpWidget(player('Chef: Zweite Aufnahme.', 'rec-2'));
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 80));
        });
        await tester.pump();

        expect(fakePlayer.stopCallCount, greaterThanOrEqualTo(1));
        expect(TtsService.instance.debugPinCountsForTests, isEmpty);
        expect(fakePlayer.playCallCount, 1, reason: 'must not autoplay');
        expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is RichText &&
                w.text.toPlainText().contains('Zweite Aufnahme.'),
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is RichText &&
                w.text.toPlainText().contains('Erste Aufnahme.'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('Telefonnotiz-style version switch shows new recording text', (
      tester,
    ) async {
      final variant = TelefonnotizVariant.fromJson({
        'variant_number': 1,
        'versions': [
          {
            'label': 'Original',
            'monologue': 'Hallo, hier ist die erste Aufnahme.',
            'answer': {},
          },
          {
            'label': 'Neue Version',
            'monologue': 'Hallo, hier ist die zweite Aufnahme.',
            'answer': {},
            'metadata': {'voice_gender': 'female'},
          },
        ],
      });
      final versionIndex = ValueNotifier<int>(0);
      addTearDown(versionIndex.dispose);

      await tester.pumpWidget(
        wrap(
          ValueListenableBuilder<int>(
            valueListenable: versionIndex,
            builder: (context, index, _) {
              final version = variant.versions[index];
              return Column(
                children: [
                  for (var i = 0; i < variant.versions.length; i++)
                    ChoiceChip(
                      label: Text(variant.versions[i].label!),
                      selected: index == i,
                      onSelected: (_) => versionIndex.value = i,
                    ),
                  DialogueAudioPlayer(
                    text: version.monologue,
                    accent: Colors.blue,
                    recordingId: version.recordingId,
                    parsedVoiceGender: version.voiceGender,
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Recording text'));
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText && w.text.toPlainText().contains('erste Aufnahme'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Neue Version'));
      await tester.pump();
      await tester.tap(find.text('Recording text'));
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText && w.text.toPlainText().contains('zweite Aufnahme'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText && w.text.toPlainText().contains('erste Aufnahme'),
        ),
        findsNothing,
      );
      expect(find.text('Female'), findsOneWidget);
    });
  });

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
        expect(
          TtsService.instance.debugPinCountsForTests,
          isEmpty,
          reason:
              'the stale continuation must release the lease it just '
              'acquired instead of leaving it pinned forever now that '
              'nothing will ever use it',
        );
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
        expect(
          TtsService.instance.debugPinCountsForTests,
          isEmpty,
          reason:
              'the disposed first instance\'s stale continuation must '
              'release its lease; the second instance never started, so '
              'it never acquired one',
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

        await tester.tap(find.byIcon(Icons.play_circle_filled));
        await waitForPlayCalls(tester, fakePlayer, 1);

        expect(find.text('Error while generating'), findsOneWidget);
        expect(find.textContaining('Exception'), findsNothing);
        expect(find.textContaining('simulated'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          find.byIcon(Icons.pause_circle_filled),
          findsNothing,
          reason: 'must not be stuck showing a live "playing" bar',
        );
        expect(
          fakePlayer.stopCallCount,
          greaterThanOrEqualTo(1),
          reason:
              'a best-effort stop() must run so nothing keeps playing in '
              'the background under the error UI',
        );
        expect(
          TtsService.instance.debugPinCountsForTests,
          isEmpty,
          reason:
              'the lease on the failed line must be released, not '
              'pinned forever',
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

        await tester.tap(find.byIcon(Icons.play_circle_filled));
        await waitForPlayCalls(tester, fakePlayer, 1);

        expect(find.text('Error while generating'), findsOneWidget);
        expect(
          fakePlayer.playedPaths,
          hasLength(1),
          reason:
              'play() itself must have succeeded before rate-setting '
              'failed',
        );
        expect(
          fakePlayer.stopCallCount,
          greaterThanOrEqualTo(1),
          reason:
              'play() genuinely started — a best-effort stop() must run '
              'so it does not keep playing unsupervised under the error '
              'UI',
        );
        expect(TtsService.instance.debugPinCountsForTests, isEmpty);
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

        await tester.tap(find.byIcon(Icons.play_circle_filled));
        await waitForPlayCalls(tester, fakePlayer, 1);
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
        await tester.tap(find.byIcon(Icons.play_circle_filled));
        await waitForPlayCalls(tester, fakePlayer, 1);

        // Regenerate supersedes it with a fresh attempt, whose own play()
        // call (the fake's second) succeeds.
        await tester.tap(find.byTooltip('Regenerate audio'));
        await waitForPlayCalls(tester, fakePlayer, 2);
        expect(
          find.byIcon(Icons.pause_circle_filled),
          findsOneWidget,
          reason: 'the newer operation should have reached playing',
        );
        // forceRegenerate re-synthesizes the SAME cache key (the line's
        // content didn't change) — the refcount being exactly 1, not 2,
        // proves the first operation's lease was actually released before
        // the new one was acquired, not merely accumulated on top of it.
        expect(
          TtsService.instance.debugPinCountsForTests.values,
          [1],
          reason:
              'regenerate must release the previous lease before the new '
              'attempt re-pins the same path',
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

        await tester.tap(find.byIcon(Icons.play_circle_filled));
        await waitForPlayCalls(tester, fakePlayer, 1);
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

  // Third independent review: TtsService's cache pin/lease is only useful
  // if this widget actually releases it at every point it stops using a
  // path — otherwise a lease-leak silently defeats the cache's own size
  // limit (CR-14) one dialogue at a time. These tests pin every release
  // point required: normal completion, synthesis error, playback error
  // (covered above), stop, regenerate (covered above), dispose (covered
  // above and below), and a stale operation (covered above).
  group('lease release', () {
    testWidgets(
      'normal end-of-dialogue playback releases the lease, freeing the '
      'clip for eviction afterwards',
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

        await tester.tap(find.byIcon(Icons.play_circle_filled));
        await waitForPlayCalls(tester, fakePlayer, 1);
        expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
        expect(TtsService.instance.debugPinCountsForTests, isNotEmpty);

        // The only line just finished — firing completion advances past
        // the end of the dialogue (there's no next line), which must
        // release the lease and go idle.
        fakePlayer.fireComplete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
        expect(TtsService.instance.debugPinCountsForTests, isEmpty);
      },
    );

    testWidgets('stop() releases the lease on the in-progress dialogue', (
      tester,
    ) async {
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

      await tester.tap(find.byIcon(Icons.play_circle_filled));
      await waitForPlayCalls(tester, fakePlayer, 1);
      expect(TtsService.instance.debugPinCountsForTests, isNotEmpty);

      await tester.tap(find.byIcon(Icons.stop_circle_outlined));
      await tester.pump();

      expect(TtsService.instance.debugPinCountsForTests, isEmpty);
    });

    testWidgets(
      'a synthesis failure part-way through a multi-line dialogue releases '
      'the leases already acquired for the earlier, successful lines',
      (tester) async {
        TtsService.debugIdTokenOverride = () async => 'test-token';
        var requests = 0;
        TtsService.debugHttpClient = MockClient((_) async {
          requests++;
          if (requests == 1) {
            return http.Response.bytes(List.filled(600, 65), 200);
          }
          return http.Response('boom', 500);
        });

        await tester.pumpWidget(
          wrap(
            const DialogueAudioPlayer(
              text: 'Chef: Hallo. Frau Kunde: Guten Tag.',
              accent: Colors.blue,
            ),
          ),
        );
        await tester.pump();

        await tester.runAsync(() async {
          await tester.tap(find.byIcon(Icons.play_circle_filled));
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pump();

        expect(find.text('Error while generating'), findsOneWidget);
        expect(
          TtsService.instance.debugPinCountsForTests,
          isEmpty,
          reason:
              'the first line\'s clip was successfully synthesized and '
              'pinned before the second line failed — that lease must be '
              'released, not left dangling, when the whole prepare '
              'aborts',
        );
      },
    );

    testWidgets('AudioPlayerAdapter.dispose() failing does not throw and still '
        'releases the lease on whatever was already synthesized', (
      tester,
    ) async {
      TtsService.debugIdTokenOverride = () async => 'test-token';
      TtsService.debugHttpClient = MockClient(
        (_) async => http.Response.bytes(List.filled(600, 65), 200),
      );
      final fakePlayer = _FakeAudioPlayerAdapter()..failDispose = true;

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

      await tester.tap(find.byIcon(Icons.play_circle_filled));
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump();
        if (find.byIcon(Icons.pause_circle_filled).evaluate().isNotEmpty) {
          break;
        }
      }
      expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
      expect(TtsService.instance.debugPinCountsForTests, isNotEmpty);

      await tester.pumpWidget(wrap(const SizedBox.shrink()));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason:
            'a failing AudioPlayerAdapter.dispose() must not become an '
            'unhandled async exception (no setState-after-dispose '
            'either, which would also surface here)',
      );
      expect(fakePlayer.disposeCallCount, 1);
      expect(TtsService.instance.debugPinCountsForTests, isEmpty);
    });

    testWidgets('rapid successive jumps only let the newest attempt register a '
        'completion listener, so a stale one can\'t silently advance '
        'playback again', (tester) async {
      TtsService.debugIdTokenOverride = () async => 'test-token';
      TtsService.debugHttpClient = MockClient(
        (_) async => http.Response.bytes(List.filled(600, 65), 200),
      );
      final fakePlayer = _FakeAudioPlayerAdapter();

      // Three turns so the newer jump lands on a MIDDLE line: if a stale
      // listener from the older jump also fired, it would replay the
      // newer jump's own line a second time — a wrong, extra play()
      // call that's observable no matter which of the two same-duration
      // (`_gap`) delayed continuations happens to run first. (A jump to
      // the LAST line doesn't discriminate: its natural-end branch nulls
      // `_paths` early enough that a second, later-firing stale listener
      // finds nothing left to play regardless of the fix — a two-turn
      // version of this test would pass even with the bug reintroduced.)
      await tester.pumpWidget(
        wrap(
          DialogueAudioPlayer(
            text: 'Chef: Hallo. Frau Kunde: Guten Tag. Chef: Tschuss.',
            accent: Colors.blue,
            debugPlayerFactory: () => fakePlayer,
            initiallyShowText: true,
            showTextToggle: false,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.play_circle_filled));
      await waitForPlayCalls(tester, fakePlayer, 1);
      expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
      expect(fakePlayer.playedPaths, hasLength(1));

      // Turn tiles render their speaker/text via RichText (not Text),
      // so find.textContaining can't see them directly — locate each
      // tile's RichText by its plain text content instead, then walk up
      // to its own (nearest) GestureDetector ancestor, which is exactly
      // _turnTile's onTap wrapper.
      Finder turnFinder(String contains) => find
          .ancestor(
            of: find.byWidgetPredicate(
              (w) => w is RichText && w.text.toPlainText().contains(contains),
            ),
            matching: find.byType(GestureDetector),
          )
          .first;
      final turnOne = turnFinder('Hallo.');
      final turnTwo = turnFinder('Guten Tag.');

      // Gate the OLDER jump's own play() call open so it can be made to
      // resolve strictly AFTER the newer jump's — a real race only
      // sometimes lands in this order, so this reproduces it
      // deterministically instead of relying on timing luck.
      final olderGate = Completer<void>();
      fakePlayer.gateNextPlay = olderGate;
      await tester.runAsync(() async {
        await tester.tap(turnOne); // older jump: index 0, hangs in play()
        await tester.tap(turnTwo); // newer jump: index 1, resolves at once
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(
        find.byIcon(Icons.pause_circle_filled),
        findsOneWidget,
        reason: 'the newer jump must already be showing as active',
      );
      expect(fakePlayer.playedPaths, hasLength(2));

      // The newer jump (index 1) has attached its completion listener
      // by now (2 attachments total so far: the initial _start's index
      // 0, cancelled by the older jump's own top-of-function cancel;
      // and the newer jump's index 1). This is the key assertion: the
      // OLDER jump's play() call hasn't resolved yet (still gated), so
      // it has not — and, with the fix, never will — attach its own
      // listener alongside the newer one's.
      expect(fakePlayer.completeListenCount, 2);

      // Now let the OLDER jump's play() finally resolve, after the
      // newer one has already taken over and attached its own
      // completion listener. The older call's own play() DID happen
      // (the fake unconditionally records it once its gate releases,
      // regardless of what _playFrom does with the result afterwards)
      // — that third playedPaths entry is an unavoidable, expected side
      // effect of this test's setup, not what's under test here.
      await tester.runAsync(() async {
        olderGate.complete();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason:
            'the stale older _playFrom resuming after being superseded '
            'must not throw or corrupt state',
      );
      expect(fakePlayer.playedPaths, hasLength(3));

      // The load-bearing assertion: with the fix, the older jump's
      // resumed continuation must bail out (seq guard) BEFORE reaching
      // `.listen()` — the count must stay at 2. Without the fix (only
      // guarded by `token`, which the older jump still matches since
      // `_jumpTo` doesn't bump `_opToken`), it would attach a SECOND,
      // redundant listener for index 0 here, silently overwriting
      // `_onCompleteSub`'s reference to the newer jump's subscription
      // without cancelling it — both would remain live, so completing
      // the dialogue would incorrectly replay index 1 a second time
      // once the older, stale listener also fires.
      expect(
        fakePlayer.completeListenCount,
        2,
        reason:
            'the older, superseded _playFrom must never attach its own '
            'completion listener once a newer one has already taken '
            'over — that is exactly what would let a stale listener '
            'silently re-advance playback later',
      );
    });
  });
}
