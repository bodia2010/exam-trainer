// CR-15: DialogueAudioPlayer used to show hardcoded German/Russian text
// regardless of the app's locale, and stored the raw caught exception
// (which can carry a backend response body, see CR-11) as user-facing
// error text. These tests pin: the idle label follows the app locale, the
// transcript toggle exposes a real accessibility label, and a synthesis
// failure never surfaces the exception's own message.
import 'dart:async';
import 'dart:io';

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
}
