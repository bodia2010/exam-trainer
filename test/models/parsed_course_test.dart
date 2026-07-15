// CR-08: schemaVersion is a new, additive field on ParsedCourse. These
// tests guard the two properties that make it backward compatible with
// courses already persisted on disk/Firestore before this field existed:
// a JSON blob missing `schema_version` must default to 1 (not throw and
// not silently become 0/null), and a round trip must preserve whatever
// version is actually stored.
import 'package:flutter_test/flutter_test.dart';

import 'package:exam_trainer/models/parsed_course.dart';

void main() {
  Map<String, dynamic> baseJson() => {
    'id': 'c1',
    'title': 'Course',
    'source_filename': 'fixture.pdf',
    'parsed_at': DateTime(2026, 1, 1).toIso8601String(),
    'sections': <String, dynamic>{},
  };

  test('a course JSON saved before schemaVersion existed defaults to 1', () {
    final course = ParsedCourse.fromJson(baseJson());
    expect(course.schemaVersion, 1);
  });

  test('an explicit schema_version round-trips through toJson/fromJson', () {
    final json = {...baseJson(), 'schema_version': 3};
    final course = ParsedCourse.fromJson(json);
    expect(course.schemaVersion, 3);
    expect(ParsedCourse.fromJson(course.toJson()).schemaVersion, 3);
  });

  test('toJson always includes schema_version for a freshly built course', () {
    final course = ParsedCourse(
      id: 'c1',
      title: 'Course',
      sourceFilename: 'fixture.pdf',
      parsedAt: DateTime(2026, 1, 1),
      sections: const {},
    );
    expect(course.toJson()['schema_version'], 1);
  });
}
