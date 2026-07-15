import 'package:exam_trainer/models/parsed_course.dart';
import 'package:exam_trainer/screens/beschwerde_exercise_screen.dart';
import 'package:exam_trainer/screens/course_screen.dart';
import 'package:exam_trainer/screens/hoeren_teil1_exercise_screen.dart';
import 'package:exam_trainer/screens/section_list_screen.dart';
import 'package:exam_trainer/screens/sprachbausteine2_exercise_screen.dart';
import 'package:exam_trainer/screens/sprachbausteine_exercise_screen.dart';
import 'package:exam_trainer/screens/telefonnotiz_exercise_screen.dart';
import 'package:exam_trainer/screens/universal_exercise_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

typedef ScreenFactory = Widget Function(Future<List<ParsedCourse>> Function());

void main() {
  final storageErrorScreens = <String, ScreenFactory>{
    'course': (load) => CourseScreen(id: 'course-1', courseLoader: load),
    'section list': (load) => SectionListScreen(
      courseId: 'course-1',
      sectionType: 'lesen_teil1',
      courseLoader: load,
    ),
    'universal exercise': (load) => UniversalExerciseScreen(
      courseId: 'course-1',
      sectionType: 'lesen_teil1',
      index: 0,
      courseLoader: load,
    ),
    'Sprachbausteine 1': (load) => SprachbausteineExerciseScreen(
      courseId: 'course-1',
      index: 0,
      courseLoader: load,
    ),
    'Sprachbausteine 2': (load) => Sprachbausteine2ExerciseScreen(
      courseId: 'course-1',
      index: 0,
      courseLoader: load,
    ),
    'Beschwerde': (load) => BeschwerdeExerciseScreen(
      courseId: 'course-1',
      index: 0,
      courseLoader: load,
    ),
    'Telefonnotiz': (load) => TelefonnotizExerciseScreen(
      courseId: 'course-1',
      index: 0,
      courseLoader: load,
    ),
    'Hören Teil 1': (load) => HoerenTeil1ExerciseScreen(
      courseId: 'course-1',
      index: 0,
      courseLoader: load,
    ),
  };

  for (final entry in storageErrorScreens.entries) {
    testWidgets('${entry.key} ends in error when storage throws', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: entry.value(() async => throw StateError('private details')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('course-load-error')), findsOneWidget);
      expect(find.byKey(const Key('course-load-retry')), findsOneWidget);
      expect(find.byKey(const Key('course-load-back')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('private details'), findsNothing);
    });
  }

  testWidgets('missing course ends in not-found state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CourseScreen(id: 'missing', courseLoader: () async => []),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('course-load-not-found')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('negative and out-of-range exercise indexes are not found', (
    tester,
  ) async {
    final course = _course();

    for (final index in [-1, 1]) {
      await tester.pumpWidget(
        MaterialApp(
          home: UniversalExerciseScreen(
            courseId: course.id,
            sectionType: 'lesen_teil1',
            index: index,
            courseLoader: () async => [course],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('course-load-not-found')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    }
  });

  // CR-08: a section variant whose shape drifted from what the screen
  // expects (e.g. a list entry that isn't a Map, because of a parse-side
  // schema change or corrupted cache) must not crash the widget tree —
  // each screen now forces its own field casts inside the same try/catch
  // that already guards the top-level `variants[index] as Map` cast.
  final schemaDriftScreens = <String, ScreenFactory>{
    'universal exercise (malformed questions)': (_) => UniversalExerciseScreen(
      courseId: 'c1',
      sectionType: 'lesen_teil1',
      index: 0,
      courseLoader: () async => [
        _courseWithSection('lesen_teil1', [
          {
            'questions': ['not-a-map'],
          },
        ]),
      ],
    ),
    'Beschwerde (malformed texts)': (_) => BeschwerdeExerciseScreen(
      courseId: 'c1',
      index: 0,
      courseLoader: () async => [
        _courseWithSection('beschwerde', [
          {
            'questions': <Map<String, dynamic>>[],
            'texts': ['not-a-map'],
          },
        ]),
      ],
    ),
    'Hören Teil 1 (malformed question_pairs)': (_) => HoerenTeil1ExerciseScreen(
      courseId: 'c1',
      index: 0,
      courseLoader: () async => [
        _courseWithSection('hoeren_teil1', [
          {
            'question_pairs': ['not-a-map'],
          },
        ]),
      ],
    ),
    'Telefonnotiz (malformed versions)': (_) => TelefonnotizExerciseScreen(
      courseId: 'c1',
      index: 0,
      courseLoader: () async => [
        _courseWithSection('telefonnotiz', [
          {
            'versions': ['not-a-map'],
          },
        ]),
      ],
    ),
    'section list (malformed variant)': (_) => SectionListScreen(
      courseId: 'c1',
      sectionType: 'lesen_teil1',
      courseLoader: () async => [
        _courseWithSection('lesen_teil1', ['not-a-map']),
      ],
    ),
  };

  for (final entry in schemaDriftScreens.entries) {
    testWidgets('${entry.key} ends in error instead of crashing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: entry.value(() async => []),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('course-load-error')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  }

  testWidgets('retry replaces an error with loaded course content', (
    tester,
  ) async {
    var attempts = 0;
    Future<List<ParsedCourse>> load() async {
      attempts++;
      if (attempts == 1) throw Exception('offline');
      return [_course()];
    }

    await tester.pumpWidget(
      MaterialApp(
        home: CourseScreen(id: 'course-1', courseLoader: load),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('course-load-error')), findsOneWidget);

    await tester.tap(find.byKey(const Key('course-load-retry')));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Smoke course'), findsOneWidget);
    expect(find.byKey(const Key('course-load-error')), findsNothing);
  });
}

ParsedCourse _course() => ParsedCourse(
  id: 'course-1',
  title: 'Smoke course',
  sourceFilename: 'fixture.pdf',
  parsedAt: DateTime(2026, 7, 15),
  sections: const {
    'lesen_teil1': [
      {'variant_number': 1, 'questions': <Map<String, dynamic>>[]},
    ],
  },
);

ParsedCourse _courseWithSection(String sectionType, List<dynamic> variants) =>
    ParsedCourse(
      id: 'c1',
      title: 'Drift course',
      sourceFilename: 'fixture.pdf',
      parsedAt: DateTime(2026, 7, 15),
      sections: {sectionType: variants},
    );
