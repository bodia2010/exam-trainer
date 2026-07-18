import 'dart:async';
import 'dart:math';

import 'package:exam_trainer/models/parsed_course.dart';
import 'package:exam_trainer/ui/features/course/probe_pruefung_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ParsedCourse _course(String id, {Map<String, List<dynamic>>? sections}) =>
    ParsedCourse(
      id: id,
      title: 'Course $id',
      sourceFilename: '$id.pdf',
      parsedAt: DateTime(2026),
      sections: sections ?? const {},
    );

List<ProbeExamPart> _plan(ParsedCourse course, Random _) => [
  ProbeExamPart(
    label: course.title,
    subtitle: 'Variant',
    route: '/${course.id}',
    color: Colors.blue,
    icon: Icons.book,
    minutes: 5,
  ),
];

void main() {
  test(
    'maps content, not found and storage failures to terminal states',
    () async {
      final controller = ProbePruefungController(
        loader: () async => [_course('a')],
        planBuilder: _plan,
      );
      await controller.load('a');
      expect(controller.status, ProbePruefungStatus.content);
      expect(controller.course?.id, 'a');
      expect(controller.parts.single.route, '/a');
      expect(controller.totalMinutes, 5);
      await controller.load('missing');
      expect(controller.status, ProbePruefungStatus.notFound);
      controller.dispose();

      final failed = ProbePruefungController(
        loader: () async => throw StateError('raw storage error'),
        planBuilder: _plan,
      );
      await failed.load('a');
      expect(failed.status, ProbePruefungStatus.error);
      failed.dispose();
    },
  );

  test(
    'malformed variants end in error and regeneration keeps prior plan',
    () async {
      final malformed = ProbePruefungController(
        loader: () async => [
          _course(
            'a',
            sections: {
              'lesen_teil1': ['not a variant'],
            },
          ),
        ],
      );
      await malformed.load('a');
      expect(malformed.status, ProbePruefungStatus.error);
      malformed.dispose();

      var failRegeneration = false;
      final controller = ProbePruefungController(
        loader: () async => [_course('a')],
        planBuilder: (course, random) {
          if (failRegeneration) throw StateError('malformed reroll');
          return _plan(course, random);
        },
      );
      await controller.load('a');
      final original = controller.parts.single.route;
      failRegeneration = true;
      expect(controller.regenerate(), isFalse);
      expect(controller.parts.single.route, original);
      controller.dispose();
    },
  );

  test('late completion cannot overwrite a newer course', () async {
    final first = Completer<List<ParsedCourse>>();
    final second = Completer<List<ParsedCourse>>();
    var calls = 0;
    final controller = ProbePruefungController(
      loader: () => ++calls == 1 ? first.future : second.future,
      planBuilder: _plan,
    );
    final old = controller.load('old');
    final current = controller.load('new');
    second.complete([_course('new')]);
    await current;
    first.complete([_course('old')]);
    await old;
    expect(controller.course?.id, 'new');
    expect(controller.parts.single.route, '/new');
    controller.dispose();
  });

  test('completion after dispose is ignored', () async {
    final pending = Completer<List<ParsedCourse>>();
    final controller = ProbePruefungController(
      loader: () => pending.future,
      planBuilder: _plan,
    );
    final load = controller.load('late');
    controller.dispose();
    pending.complete([_course('late')]);
    await load;
  });
}
