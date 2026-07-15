import 'dart:async';

import 'package:exam_trainer/services/device_service.dart';
import 'package:exam_trainer/ui/features/startup/device_gate_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'ensureChecked is non-blocking and redirects only after confirmed limit',
    () async {
      final response = Completer<DeviceCheckResult>();
      var redirects = 0;
      var uid = 'user-a';
      final controller = DeviceGateController(
        check: () => response.future,
        currentUid: () => uid,
        onLimitReached: () => redirects++,
      );

      controller.ensureChecked(uid);
      expect(redirects, 0);
      expect(controller.isBlockedFor(uid), isFalse);

      response.complete(DeviceCheckResult.limitReached);
      await response.future;
      await Future<void>.delayed(Duration.zero);
      expect(redirects, 1);
      expect(controller.isBlockedFor(uid), isTrue);
    },
  );

  test(
    'stale result from previous UID cannot overwrite the new session',
    () async {
      final a = Completer<DeviceCheckResult>();
      final b = Completer<DeviceCheckResult>();
      var uid = 'user-a';
      var calls = 0;
      var redirects = 0;
      final controller = DeviceGateController(
        check: () => calls++ == 0 ? a.future : b.future,
        currentUid: () => uid,
        onLimitReached: () => redirects++,
      );

      controller.ensureChecked('user-a');
      uid = 'user-b';
      controller.reset();
      controller.ensureChecked('user-b');
      b.complete(DeviceCheckResult.allowed);
      await b.future;
      await Future<void>.delayed(Duration.zero);
      a.complete(DeviceCheckResult.limitReached);
      await a.future;
      await Future<void>.delayed(Duration.zero);

      expect(redirects, 0);
      expect(controller.isBlockedFor('user-a'), isFalse);
      expect(controller.isBlockedFor('user-b'), isFalse);
    },
  );

  test('allow invalidates an in-flight blocking response', () async {
    final response = Completer<DeviceCheckResult>();
    var redirects = 0;
    final controller = DeviceGateController(
      check: () => response.future,
      currentUid: () => 'user-a',
      onLimitReached: () => redirects++,
    );

    controller.ensureChecked('user-a');
    controller.allow('user-a');
    response.complete(DeviceCheckResult.limitReached);
    await response.future;
    await Future<void>.delayed(Duration.zero);

    expect(redirects, 0);
    expect(controller.isBlockedFor('user-a'), isFalse);
  });
}
