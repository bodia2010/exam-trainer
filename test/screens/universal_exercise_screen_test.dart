// Tests for buildContentSpan — renders "**heading**" markers (see
// prompts.py's HEADINGS rule) as bold TextSpans instead of showing the
// literal asterisks, so a passage's internal sub-headings (e.g. a
// Protokoll's "TOP 1 ..." agenda items) read as visually distinct from
// body prose, matching how they're set apart in the source PDF.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_trainer/screens/universal_exercise_screen.dart';

void main() {
  group('buildContentSpan', () {
    test('plain text with no headings becomes a single span', () {
      final span = buildContentSpan('Ein ganz normaler Absatz ohne Titel.');
      expect(span.children, hasLength(1));
      expect(span.children!.single, isA<TextSpan>());
      expect(
        (span.children!.single as TextSpan).text,
        'Ein ganz normaler Absatz ohne Titel.',
      );
      expect(
        (span.children!.single as TextSpan).style!.fontWeight,
        isNot(FontWeight.w700),
      );
    });

    test(
      'a single heading in the middle produces three spans: body, bold, body',
      () {
        final span = buildContentSpan('Vorher. **TOP 1 Begrüßung** Nachher.');
        final children = span.children!.cast<TextSpan>();
        expect(children, hasLength(3));
        expect(children[0].text, 'Vorher. ');
        expect(children[0].style!.fontWeight, isNot(FontWeight.w700));
        expect(children[1].text, 'TOP 1 Begrüßung');
        expect(children[1].style!.fontWeight, FontWeight.w700);
        expect(children[2].text, ' Nachher.');
        expect(children[2].style!.fontWeight, isNot(FontWeight.w700));
      },
    );

    test('a heading at the very start has no leading body span', () {
      final span = buildContentSpan(
        '**Zugangskontrolle und Zeiterfassung**\nRest des Textes.',
      );
      final children = span.children!.cast<TextSpan>();
      expect(children, hasLength(2));
      expect(children[0].text, 'Zugangskontrolle und Zeiterfassung');
      expect(children[0].style!.fontWeight, FontWeight.w700);
      expect(children[1].text, '\nRest des Textes.');
    });

    test(
      'multiple headings (a Protokoll with several TOP items) all render bold',
      () {
        final span = buildContentSpan(
          '**TOP 1 Begrüßung**\nErster Absatz.\n**TOP 2 Probleme**\nZweiter Absatz.',
        );
        final children = span.children!.cast<TextSpan>();
        final headings = children.where(
          (c) => c.style!.fontWeight == FontWeight.w700,
        );
        expect(headings.map((c) => c.text).toList(), [
          'TOP 1 Begrüßung',
          'TOP 2 Probleme',
        ]);
      },
    );

    test(
      'does not strip the asterisks from the plain-text output — they are only in the source markup',
      () {
        final span = buildContentSpan('**Titel**');
        final text = span.children!.cast<TextSpan>().map((s) => s.text).join();
        expect(text, 'Titel');
        expect(text, isNot(contains('*')));
      },
    );
  });
}
