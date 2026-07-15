// Tests for ParseService._correctedStartLine (via correctedStartLineForTest),
// the self-healing check that catches Gemini occasionally dropping a digit
// from a discovered start_line — reproduces the exact live failure
// ("start_line": 515 instead of 9515) on a small synthetic document.
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_trainer/services/parse_service.dart';

void main() {
  final svc = ParseService.instance;

  List<String> buildDocLines() {
    // Line 5: unrelated short content that happens to also start with
    // digits, so a naive "line 515 mod 1000" guess wouldn't accidentally
    // land here either.
    final lines = List<String>.generate(20, (i) => 'filler line $i');
    lines[5] = 'Hören Teil 4 (вариант №5) – 100%';
    lines[15] = 'Nummer 36  Some Caller';
    return lines;
  }

  group('correctedStartLineForTest', () {
    test('correct start_line with matching anchor is returned unchanged', () {
      final docLines = buildDocLines();
      final result = svc.correctedStartLineForTest(
        5,
        'Hören Teil 4 (вариант №5) – 100%',
        docLines,
      );
      expect(result, 5);
    });

    test(
      'reproduces the live bug: a dropped leading digit is corrected via anchor search',
      () {
        final docLines = buildDocLines();
        // The model said "start_line": 15 but the real line is 5 — same
        // shape as the live "515 instead of 9515" digit-drop.
        final wrongStartLine = 15;
        final anchor = 'Hören Teil 4 (вариант №5) – 100%';
        final result = svc.correctedStartLineForTest(
          wrongStartLine,
          anchor,
          docLines,
        );
        expect(result, 5, reason: 'should find the real line via anchor text');
      },
    );

    test('anchor search works forward too, not just backward', () {
      final docLines = buildDocLines();
      final result = svc.correctedStartLineForTest(
        2,
        'Nummer 36  Some Caller',
        docLines,
      );
      expect(result, 15);
    });

    test(
      'no anchor match anywhere nearby falls back to the original number',
      () {
        final docLines = buildDocLines();
        final result = svc.correctedStartLineForTest(
          7,
          'this text appears nowhere in the document',
          docLines,
        );
        expect(result, 7);
      },
    );

    test('null or too-short anchor is not trusted enough to search with', () {
      final docLines = buildDocLines();
      expect(svc.correctedStartLineForTest(7, null, docLines), 7);
      expect(svc.correctedStartLineForTest(7, 'short', docLines), 7);
    });

    test(
      'reproduces the exact live magnitude: a 9000-line gap (a dropped leading digit) is still found',
      () {
        // Mirrors the real production failure precisely: claimed
        // start_line 515, real content at 9515, in a large document — a
        // bounded-radius search (e.g. ±500) would miss this; the fix must
        // scan the whole document.
        final docLines = List<String>.generate(10000, (i) => 'filler line $i');
        docLines[9515] = 'Hören Teil 4 (вариант №5) – 100%';
        final result = svc.correctedStartLineForTest(
          515,
          'Hören Teil 4 (вариант №5) – 100%',
          docLines,
        );
        expect(result, 9515);
      },
    );

    test('nearest match wins when the anchor text coincidentally repeats', () {
      final docLines = List<String>.generate(200, (i) => 'filler line $i');
      docLines[50] = 'Nummer 36  repeated text';
      docLines[150] = 'Nummer 36  repeated text';
      // Claimed 60 is closer to the real line at 50 than to the one at 150.
      final result = svc.correctedStartLineForTest(
        60,
        'Nummer 36  repeated text',
        docLines,
      );
      expect(result, 50);
    });

    test(
      'collapses whitespace noise so a cosmetically-off anchor still matches',
      () {
        final docLines = buildDocLines();
        docLines[5] = '   Hören  Teil 4 (вариант №5)   –   100%  ';
        final result = svc.correctedStartLineForTest(
          5,
          'Hören Teil 4 (вариант №5) – 100%',
          docLines,
        );
        expect(result, 5);
      },
    );
  });

  group(
    'correctedItemsForTest — de-duplication when the ANCHOR is the wrong field',
    () {
      test(
        'reproduces the real fixture conflict: entry A has the correct start_line '
        'but a hallucinated anchor naming entry B\'s variant; A must NOT be dragged '
        'onto B\'s already-correct position',
        () {
          final docLines = List<String>.generate(200, (i) => 'filler line $i');
          docLines[100] =
              'Lesen Teil 3 (вариант №4) – 100%'; // entry A's real home
          docLines[150] =
              'Lesen Teil 3 (вариант №5)   -  100%'; // entry B's real home
          final raw = [
            {
              'section_type': 'lesen_teil3',
              'variant_number': 4,
              'version_label': null,
              'start_line': 100, // correct
              'anchor':
                  'Lesen Teil 3 (вариант №5)   -  100%', // hallucinated — names B
            },
            {
              'section_type': 'lesen_teil3',
              'variant_number': 5,
              'version_label': null,
              'start_line': 150, // correct
              'anchor': 'Lesen Teil 3 (вариант №5)   -  100%', // correct
            },
          ];
          final items = svc.correctedItemsForTest(raw, docLines);
          final byVariant = {
            for (final it in items) it.variantNumber: it.startLine,
          };
          expect(
            byVariant[4],
            100,
            reason: 'entry A must keep its own correct start_line, not B\'s',
          );
          expect(byVariant[5], 150);
        },
      );

      test(
        'a genuine digit-drop still gets corrected when there is no conflict',
        () {
          final docLines = List<String>.generate(
            10000,
            (i) => 'filler line $i',
          );
          docLines[9515] = 'Hören Teil 4 (вариант №5) – 100%';
          final raw = [
            {
              'section_type': 'hoeren_teil4',
              'variant_number': 5,
              'version_label': null,
              'start_line': 515,
              'anchor': 'Hören Teil 4 (вариант №5) – 100%',
            },
          ];
          final items = svc.correctedItemsForTest(raw, docLines);
          expect(items.single.startLine, 9515);
        },
      );
    },
  );
}
