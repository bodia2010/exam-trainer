import 'package:exam_trainer/l10n/strings.dart';
import 'package:exam_trainer/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpActions(
    WidgetTester tester, {
    Locale locale = const Locale('de'),
    required VoidCallback onSignOut,
    required VoidCallback onDelete,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        locale: locale,
        home: Scaffold(
          body: Builder(
            builder: (context) => AccountActions(
              s: S.of(context),
              onSignOut: onSignOut,
              onDelete: onDelete,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('account actions expose logout and delete controls', (
    tester,
  ) async {
    var signOutCalls = 0;
    var deleteCalls = 0;
    await pumpActions(
      tester,
      onSignOut: () => signOutCalls++,
      onDelete: () => deleteCalls++,
    );

    expect(find.byKey(const Key('account_sign_out')), findsOneWidget);
    expect(find.byKey(const Key('account_delete')), findsOneWidget);
    expect(signOutCalls, 0);
    expect(deleteCalls, 0);
  });

  testWidgets('logout invokes the supplied callback', (tester) async {
    var signOutCalls = 0;
    await pumpActions(tester, onSignOut: () => signOutCalls++, onDelete: () {});

    await tester.tap(find.byKey(const Key('account_sign_out')));
    expect(signOutCalls, 1);
  });

  testWidgets('delete invokes only after its explicit tile action', (
    tester,
  ) async {
    var deleteCalls = 0;
    await pumpActions(tester, onSignOut: () {}, onDelete: () => deleteCalls++);

    expect(deleteCalls, 0);
    await tester.tap(find.byKey(const Key('account_delete')));
    expect(deleteCalls, 1);
  });

  testWidgets('controls remain available in every supported locale', (
    tester,
  ) async {
    for (final locale in const [
      Locale('de'),
      Locale('ru'),
      Locale('uk'),
      Locale('en'),
    ]) {
      await pumpActions(
        tester,
        locale: locale,
        onSignOut: () {},
        onDelete: () {},
      );
      expect(find.byKey(const Key('account_sign_out')), findsOneWidget);
      expect(find.byKey(const Key('account_delete')), findsOneWidget);
    }
  });
}
