import 'dart:convert';
import 'dart:io';

import 'package:exam_trainer/models/exercises/universal_variant.dart';
import 'package:exam_trainer/models/parsed_course.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Web Creator Lesen Teil 2 fixture is mobile-compatible schema v1',
    () async {
      final raw = await File(
        'test/fixtures/web_creator_lesen_teil2_course_v1.json',
      ).readAsString();
      final course = ParsedCourse.fromJson(
        (jsonDecode(raw) as Map).cast<String, dynamic>(),
      );

      final variants = UniversalVariant.listFromJson(
        course.sections['lesen_teil2'],
        sectionType: 'lesen_teil2',
      );

      expect(course.id, 'web_fixture_1');
      expect(course.schemaVersion, 1);
      expect(variants, hasLength(1));
      expect(variants.single.questions, hasLength(2));
      expect(variants.single.questions.first.type, 'true_false');
      expect(variants.single.questions.first.answer, 'falsch');
      expect(variants.single.questions.last.type, 'choice');
      expect(variants.single.questions.last.answer, 'b');
    },
  );
}
