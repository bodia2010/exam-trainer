import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:exam_trainer/models/parsed_course.dart';
import 'package:exam_trainer/ui/features/course/section_list_controller.dart';

ParsedCourse _course(String id, {Map<String, List<dynamic>>? sections}) =>
    ParsedCourse(
      id: id,
      title: 'Course $id',
      sourceFilename: '$id.pdf',
      parsedAt: DateTime(2026),
      sections: sections ?? const {},
    );

void main() {
  test('maps content and empty sections to terminal content state', () async {
    final controller = SectionListController(
      loader: () async => [
        _course(
          'a',
          sections: {
            'lesen_teil1': [
              {'variant_number': 1, 'topic': 'Topic'},
            ],
            'lesen_teil2': [],
          },
        ),
      ],
    );

    await controller.load('a', 'lesen_teil1');
    expect(controller.status, SectionListStatus.content);
    expect(controller.variants, hasLength(1));
    await controller.load('a', 'lesen_teil2');
    expect(controller.status, SectionListStatus.content);
    expect(controller.variants, isEmpty);
    controller.dispose();
  });

  test('maps missing courses and loader or malformed data errors', () async {
    final missing = SectionListController(loader: () async => [_course('a')]);
    await missing.load('missing', 'lesen_teil1');
    expect(missing.status, SectionListStatus.notFound);
    missing.dispose();

    final failed = SectionListController(
      loader: () async => throw StateError('storage failure'),
    );
    await failed.load('a', 'lesen_teil1');
    expect(failed.status, SectionListStatus.error);
    failed.dispose();

    final malformed = SectionListController(
      loader: () async => [
        _course(
          'a',
          sections: {
            'lesen_teil1': ['not a variant'],
          },
        ),
      ],
    );
    await malformed.load('a', 'lesen_teil1');
    expect(malformed.status, SectionListStatus.error);
    malformed.dispose();
  });

  test('late completion cannot overwrite a newer load', () async {
    final first = Completer<List<ParsedCourse>>();
    final second = Completer<List<ParsedCourse>>();
    var calls = 0;
    final controller = SectionListController(
      loader: () => ++calls == 1 ? first.future : second.future,
    );
    final old = controller.load('old', 'lesen_teil1');
    final current = controller.load('new', 'lesen_teil1');
    second.complete([
      _course(
        'new',
        sections: {
          'lesen_teil1': [
            {'variant_number': 2},
          ],
        },
      ),
    ]);
    await current;
    first.complete([
      _course(
        'old',
        sections: {
          'lesen_teil1': [
            {'variant_number': 1},
          ],
        },
      ),
    ]);
    await old;
    expect(controller.status, SectionListStatus.content);
    expect(
      (controller.variants.single as Map<String, dynamic>)['variant_number'],
      2,
    );
    controller.dispose();
  });

  test('completion after dispose is ignored', () async {
    final pending = Completer<List<ParsedCourse>>();
    final controller = SectionListController(loader: () => pending.future);
    final load = controller.load('late', 'lesen_teil1');
    controller.dispose();
    pending.complete([_course('late')]);
    await load;
  });
}
