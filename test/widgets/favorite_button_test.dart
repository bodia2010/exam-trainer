import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_trainer/widgets/favorite_button.dart';
import 'package:exam_trainer/ui/features/favorites/favorite_button_controller.dart';

void main() {
  testWidgets('loading button is disabled and storage error is terminal', (
    tester,
  ) async {
    final controller = FavoriteButtonController(
      check: (_) async => throw StateError('do not show'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FavoriteButton(
            favId: 'id',
            title: 'Title',
            subtitle: 'Subtitle',
            route: '/course',
            controller: controller,
          ),
        ),
      ),
    );
    expect(find.byType(IconButton), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(IconButton), findsOneWidget);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });
}
