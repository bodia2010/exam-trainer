import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_trainer/screens/favorites_screen.dart';
import 'package:exam_trainer/ui/features/favorites/favorites_controller.dart';

void main() {
  testWidgets('storage error renders retry instead of an endless spinner', (
    tester,
  ) async {
    final controller = FavoritesController(
      load: () async => throw StateError('do not show this'),
    );
    await tester.pumpWidget(
      MaterialApp(home: FavoritesScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('That didn\'t work. Please try again.'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    controller.dispose();
  });
}
