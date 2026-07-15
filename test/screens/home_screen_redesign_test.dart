import 'dart:async';

import 'package:exam_trainer/models/parsed_course.dart';
import 'package:exam_trainer/screens/home_screen.dart';
import 'package:exam_trainer/ui/core/theme/exam_theme.dart';
import 'package:exam_trainer/ui/features/home/view_models/home_view_model.dart';
import 'package:exam_trainer/ui/features/startup/startup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home keeps branded preloader while courses load', (
    tester,
  ) async {
    final courses = Completer<List<ParsedCourse>>();
    final revision = ChangeNotifier();
    final viewModel = HomeViewModel(
      loadCourses: () => courses.future,
      loadPremium: () async => false,
      deleteCourse: (_) async {},
      courseRevision: revision,
      authChanges: const Stream.empty(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ExamTheme.light(),
        home: HomeScreen(viewModel: viewModel, showAccountControls: false),
      ),
    );
    await tester.pump();

    expect(find.byType(StartupScreen), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    courses.complete(const []);
    await tester.pumpAndSettle();
    expect(find.byType(StartupScreen), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    viewModel.dispose();
    revision.dispose();
  });

  testWidgets('warm home renders real product sections and handles actions', (
    tester,
  ) async {
    final revision = ChangeNotifier();
    final course = ParsedCourse(
      id: 'course-1',
      title: 'B2 Beruf – Prüfungstraining',
      sourceFilename: 'training.pdf',
      parsedAt: DateTime(2026, 7, 15),
      sections: const {
        'lesen_teil1': [
          {'variant_number': 1},
        ],
        'hoeren_teil1': [
          {'variant_number': 1},
        ],
      },
    );
    final viewModel = HomeViewModel(
      loadCourses: () async => [course],
      loadPremium: () async => false,
      deleteCourse: (_) async {},
      courseRevision: revision,
      authChanges: const Stream.empty(),
    );
    var importTapped = false;
    ParsedCourse? openedCourse;

    await tester.pumpWidget(
      MaterialApp(
        theme: ExamTheme.light(),
        locale: const Locale('de'),
        supportedLocales: const [Locale('de')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: HomeScreen(
          viewModel: viewModel,
          showAccountControls: false,
          onImportTap: () => importTapped = true,
          onCourseTap: (value) => openedCourse = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Exam Trainer'), findsOneWidget);
    expect(find.text('PDF importieren'), findsOneWidget);
    expect(find.text('Weiterlernen'), findsWidgets);
    expect(find.text('B2 Beruf'), findsWidgets);
    expect(find.byKey(const Key('home_bottom_navigation')), findsOneWidget);

    await tester.tap(find.byKey(const Key('home_import_pdf')));
    expect(importTapped, isTrue);

    await tester.tap(find.byKey(const Key('home_continue_course')));
    expect(openedCourse?.id, 'course-1');

    await tester.pumpWidget(const SizedBox.shrink());
    viewModel.dispose();
    revision.dispose();
  });
}
