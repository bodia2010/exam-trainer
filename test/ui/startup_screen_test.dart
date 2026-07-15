import 'package:exam_trainer/ui/core/theme/exam_theme.dart';
import 'package:exam_trainer/ui/features/startup/startup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('startup screen renders branded loader', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: ExamTheme.light(), home: const StartupScreen()),
    );

    expect(find.text('Exam Trainer'), findsOneWidget);
    expect(find.text('Prüfungstrainer wird vorbereitet …'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('startup error offers retry action', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ExamTheme.light(),
        home: StartupScreen(error: true, onRetry: () => retried = true),
      ),
    );

    await tester.tap(find.text('Erneut versuchen'));
    expect(retried, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
