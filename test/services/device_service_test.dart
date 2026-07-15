// Tests the CR-10 product decision: the device-gate check
// (DeviceService.registerDevice) must only ever block on a genuine
// `200 {allowed: false}` from the backend. Auth failures (401/403), server
// errors (5xx), a malformed body, and network/timeout failures must all
// fail open (DeviceCheckResult.allowed) — never silently treated as a
// confirmed limit, and never left to a raw exception.
//
// forceRegisterCurrentDevice (the "use this device" action) is the
// opposite case: a real cost if it silently claims success it can't back
// up, so it must report confirmed success/failure instead of swallowing
// errors.
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exam_trainer/services/device_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DeviceService.debugIdTokenOverride = () async => 'test-token';
  });

  tearDown(() {
    DeviceService.debugHttpClient = null;
    DeviceService.debugIdTokenOverride = null;
  });

  group('registerDevice', () {
    test('200 allowed:true returns allowed', () async {
      DeviceService.debugHttpClient = MockClient(
        (_) async => http.Response('{"allowed": true}', 200),
      );
      expect(
        await DeviceService.instance.registerDevice(),
        DeviceCheckResult.allowed,
      );
    });

    test(
      '200 allowed:false is the only case that returns limitReached',
      () async {
        DeviceService.debugHttpClient = MockClient(
          (_) async => http.Response('{"allowed": false}', 200),
        );
        expect(
          await DeviceService.instance.registerDevice(),
          DeviceCheckResult.limitReached,
        );
      },
    );

    test('401 fails open', () async {
      DeviceService.debugHttpClient = MockClient(
        (_) async => http.Response('{"error": "Unauthorized"}', 401),
      );
      expect(
        await DeviceService.instance.registerDevice(),
        DeviceCheckResult.allowed,
      );
    });

    test('403 fails open', () async {
      DeviceService.debugHttpClient = MockClient(
        (_) async => http.Response('{"error": "Forbidden"}', 403),
      );
      expect(
        await DeviceService.instance.registerDevice(),
        DeviceCheckResult.allowed,
      );
    });

    test('5xx server error fails open', () async {
      DeviceService.debugHttpClient = MockClient(
        (_) async => http.Response('Internal Server Error', 500),
      );
      expect(
        await DeviceService.instance.registerDevice(),
        DeviceCheckResult.allowed,
      );
    });

    test('malformed JSON body fails open', () async {
      DeviceService.debugHttpClient = MockClient(
        (_) async => http.Response('not json', 200),
      );
      expect(
        await DeviceService.instance.registerDevice(),
        DeviceCheckResult.allowed,
      );
    });

    for (final body in ['{}', '{"allowed": null}', '{"allowed": "false"}']) {
      test('200 with non-boolean/missing allowed fails open: $body', () async {
        DeviceService.debugHttpClient = MockClient(
          (_) async => http.Response(body, 200),
        );
        expect(
          await DeviceService.instance.registerDevice(),
          DeviceCheckResult.allowed,
        );
      });
    }

    test('network exception fails open', () async {
      DeviceService.debugHttpClient = MockClient(
        (_) async => throw const SocketExceptionStub(),
      );
      expect(
        await DeviceService.instance.registerDevice(),
        DeviceCheckResult.allowed,
      );
    });
  });

  group('forceRegisterCurrentDevice', () {
    test('200 reports confirmed success', () async {
      DeviceService.debugHttpClient = MockClient(
        (_) async => http.Response('{"ok": true}', 200),
      );
      expect(await DeviceService.instance.forceRegisterCurrentDevice(), isTrue);
    });

    test('non-200 reports failure instead of assuming success', () async {
      DeviceService.debugHttpClient = MockClient(
        (_) async => http.Response('Internal Server Error', 500),
      );
      expect(
        await DeviceService.instance.forceRegisterCurrentDevice(),
        isFalse,
      );
    });

    for (final body in ['{}', '{"ok": false}', 'not json']) {
      test('200 without ok:true reports failure: $body', () async {
        DeviceService.debugHttpClient = MockClient(
          (_) async => http.Response(body, 200),
        );
        expect(
          await DeviceService.instance.forceRegisterCurrentDevice(),
          isFalse,
        );
      });
    }

    test('a thrown network error reports failure, not success', () async {
      DeviceService.debugHttpClient = MockClient(
        (_) async => throw const SocketExceptionStub(),
      );
      expect(
        await DeviceService.instance.forceRegisterCurrentDevice(),
        isFalse,
      );
    });
  });
}

/// A minimal stand-in for dart:io's SocketException so this test doesn't
/// need to import dart:io just to synthesize a network failure.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
  @override
  String toString() => 'SocketExceptionStub';
}
