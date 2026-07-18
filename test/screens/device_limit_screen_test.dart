import 'package:exam_trainer/screens/device_limit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'device registration failure leaves a terminal error, not spinner',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DeviceLimitScreen(
            registerDevice: () async => throw StateError('private failure'),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('device-limit-error')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('private failure'), findsNothing);
    },
  );

  testWidgets(
    'sign-out failure is localized and does not leave loading active',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DeviceLimitScreen(
            signOut: () async => throw StateError('private sign-out failure'),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('device-limit-signout')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('device-limit-error')), findsOneWidget);
      expect(find.textContaining('private sign-out failure'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}
