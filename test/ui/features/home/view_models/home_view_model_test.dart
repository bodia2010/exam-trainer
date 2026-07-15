import 'dart:async';
import 'dart:io';

import 'package:exam_trainer/models/parsed_course.dart';
import 'package:exam_trainer/ui/features/home/view_models/home_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'refresh failure preserves courses that are already displayed',
    () async {
      final existing = ParsedCourse(
        id: 'existing',
        title: 'Existing course',
        sourceFilename: 'existing.pdf',
        parsedAt: DateTime(2026),
        sections: const {},
      );
      var shouldFail = false;
      final viewModel = HomeViewModel(
        loadCourses: () async {
          if (shouldFail) {
            throw const FileSystemException('storage unavailable');
          }
          return [existing];
        },
        loadPremium: () async => false,
        deleteCourse: (_) async {},
        courseRevision: ValueNotifier(0),
        authChanges: const Stream.empty(),
      );

      await viewModel.refreshCourses();
      shouldFail = true;
      await viewModel.refreshCourses();

      expect(viewModel.loading, isFalse);
      expect(viewModel.courses, [same(existing)]);
      viewModel.dispose();
    },
  );
}
