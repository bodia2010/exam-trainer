// CR-13: loadVariant consolidates the lookup/bounds-check/parse logic that
// used to be duplicated in every exercise screen's _load(). These tests
// pin its three outcomes independently of any specific screen.
import 'package:flutter_test/flutter_test.dart';

import 'package:exam_trainer/models/parsed_course.dart';
import 'package:exam_trainer/ui/features/exercise/variant_loader.dart';
import 'package:exam_trainer/widgets/course_load_state.dart';

void main() {
  ParsedCourse course(String id, Map<String, List<dynamic>> sections) =>
      ParsedCourse(
        id: id,
        title: 'Course',
        sourceFilename: 'f.pdf',
        parsedAt: DateTime(2026, 1, 1),
        sections: sections,
      );

  test(
    'a present course/index parses the variant and reports no failure',
    () async {
      final result = await loadVariant<String>(
        courseLoader: () async => [
          course('c1', {
            'lesen_teil1': [
              {'topic': 'x'},
            ],
          }),
        ],
        courseId: 'c1',
        sectionType: 'lesen_teil1',
        index: 0,
        fromJson: (json) => json['topic'] as String,
      );
      expect(result.variant, 'x');
      expect(result.failure, isNull);
    },
  );

  test('a missing course reports notFound, not error', () async {
    final result = await loadVariant<String>(
      courseLoader: () async => [],
      courseId: 'missing',
      sectionType: 'lesen_teil1',
      index: 0,
      fromJson: (json) => json['topic'] as String,
    );
    expect(result.variant, isNull);
    expect(result.failure, CourseLoadFailure.notFound);
  });

  test('an out-of-range index reports notFound, not error', () async {
    final result = await loadVariant<String>(
      courseLoader: () async => [
        course('c1', {
          'lesen_teil1': [
            {'topic': 'x'},
          ],
        }),
      ],
      courseId: 'c1',
      sectionType: 'lesen_teil1',
      index: 5,
      fromJson: (json) => json['topic'] as String,
    );
    expect(result.failure, CourseLoadFailure.notFound);
  });

  test('a courseLoader that throws reports error, not notFound', () async {
    final result = await loadVariant<String>(
      courseLoader: () async => throw Exception('offline'),
      courseId: 'c1',
      sectionType: 'lesen_teil1',
      index: 0,
      fromJson: (json) => json['topic'] as String,
    );
    expect(result.variant, isNull);
    expect(result.failure, CourseLoadFailure.error);
  });

  test('a variant that is not a Map reports error, not notFound', () async {
    final result = await loadVariant<String>(
      courseLoader: () async => [
        course('c1', {
          'lesen_teil1': ['not-a-map'],
        }),
      ],
      courseId: 'c1',
      sectionType: 'lesen_teil1',
      index: 0,
      fromJson: (json) => json['topic'] as String,
    );
    expect(result.failure, CourseLoadFailure.error);
  });

  test('a fromJson that throws reports error, not a crash', () async {
    final result = await loadVariant<String>(
      courseLoader: () async => [
        course('c1', {
          'lesen_teil1': [
            {'topic': 'x'},
          ],
        }),
      ],
      courseId: 'c1',
      sectionType: 'lesen_teil1',
      index: 0,
      fromJson: (json) => throw StateError('bad shape'),
    );
    expect(result.failure, CourseLoadFailure.error);
  });

  test('VariantLoadGuard invalidates older and disposed requests', () {
    final guard = VariantLoadGuard();
    final first = guard.begin();
    final second = guard.begin();

    expect(guard.isCurrent(first), isFalse);
    expect(guard.isCurrent(second), isTrue);

    guard.dispose();
    expect(guard.isCurrent(second), isFalse);
  });
}
