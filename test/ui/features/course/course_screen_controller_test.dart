import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:exam_trainer/models/parsed_course.dart';
import 'package:exam_trainer/ui/features/course/course_screen_controller.dart';

ParsedCourse _course(String id) => ParsedCourse(
  id: id,
  title: 'Course $id',
  sourceFilename: '$id.pdf',
  parsedAt: DateTime(2026),
  sections: const {},
);

void main() {
  test(
    'maps content, not found and storage errors to terminal states',
    () async {
      final controller = CourseScreenController(
        loader: () async => [_course('a')],
      );
      await controller.load('a');
      expect(controller.status, CourseScreenStatus.content);
      expect(controller.course?.id, 'a');
      await controller.load('missing');
      expect(controller.status, CourseScreenStatus.notFound);
      controller.dispose();

      final failed = CourseScreenController(
        loader: () async => throw StateError('raw'),
      );
      await failed.load('a');
      expect(failed.status, CourseScreenStatus.error);
      failed.dispose();
    },
  );

  test('late completion cannot overwrite a newer load', () async {
    final first = Completer<List<ParsedCourse>>();
    final second = Completer<List<ParsedCourse>>();
    var calls = 0;
    final controller = CourseScreenController(
      loader: () => ++calls == 1 ? first.future : second.future,
    );
    final old = controller.load('old');
    final current = controller.load('new');
    second.complete([_course('new')]);
    await current;
    first.complete([_course('old')]);
    await old;
    expect(controller.course?.id, 'new');
    controller.dispose();
  });

  test('completion after dispose is ignored', () async {
    final pending = Completer<List<ParsedCourse>>();
    final controller = CourseScreenController(loader: () => pending.future);
    final load = controller.load('late');
    controller.dispose();
    pending.complete([_course('late')]);
    await load;
  });
}
