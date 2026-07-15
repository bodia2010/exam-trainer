// Tests for ParseService's private, pure-function validation helpers
// (`_validateGroup` / `_validateShape`), reached through the
// `@visibleForTesting` wrappers `validateGroupForTest` /
// `validateShapeForTest` declared right next to them in parse_service.dart.
//
// Covers all 12 section types: the 3 with bespoke shapes (hoeren_teil1,
// telefonnotiz, sprachbausteine_teil1) plus the 9 sharing the universal
// schema (lesen_teil1-4, beschwerde, sprachbausteine_teil2, hoeren_teil2-4).
// No network/Firebase involved — these functions are pure JSON-in,
// problem-list-out.
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_trainer/services/parse_service.dart';

void main() {
  final svc = ParseService.instance;

  // Every universal-schema type and its official telc question count (see
  // ParseService._expectedQuestionCount).
  const universalCounts = <String, int>{
    'lesen_teil1': 5,
    'lesen_teil2': 2,
    'lesen_teil3': 4,
    'lesen_teil4': 5,
    'beschwerde': 2,
    'sprachbausteine_teil2': 6,
    'hoeren_teil2': 4,
    'hoeren_teil3': 4,
    'hoeren_teil4': 5,
  };

  Map<String, dynamic> universalItem(
    String type,
    int count, {
    int variant = 1,
    String qType = 'true_false',
  }) => {
    'variant_number': variant,
    'texts': ['Ein Beispieltext.'],
    'questions': List.generate(
      count,
      (i) => {
        'number': i + 1,
        'type': qType,
        'answer': qType == 'true_false' ? 'richtig' : 'A',
      },
    ),
  };

  group('_validateGroup — structural checks shared by every type', () {
    test(
      'an empty result list is rejected (would silently drop a variant)',
      () {
        expect(
          svc.validateGroupForTest(const [], 'lesen_teil1'),
          contains(contains('empty result')),
        );
      },
    );

    test('a non-object entry is reported', () {
      final problems = svc.validateGroupForTest([
        'not an object',
      ], 'lesen_teil1');
      expect(problems, contains(contains('non-object entry')));
    });

    test('missing variant_number is reported', () {
      final item = universalItem('lesen_teil1', 5)..remove('variant_number');
      final problems = svc.validateGroupForTest([item], 'lesen_teil1');
      expect(problems, contains('missing variant_number'));
    });

    test('a leaked <<SAME_AS_ORIGINAL>> sentinel is reported', () {
      final item = universalItem('lesen_teil1', 5);
      item['texts'] = '<<SAME_AS_ORIGINAL>>';
      final problems = svc.validateGroupForTest([item], 'lesen_teil1');
      expect(problems.any((p) => p.contains('SAME_AS_ORIGINAL')), isTrue);
    });

    test('a leaked item delimiter is reported', () {
      final item = universalItem('lesen_teil1', 5);
      (item['texts'] as List)[0] = 'oops ${ParseService.itemDelimiter} leaked';
      final problems = svc.validateGroupForTest([item], 'lesen_teil1');
      expect(problems.any((p) => p.contains('leaked')), isTrue);
    });
  });

  group('_validateShape — universal schema (9 types)', () {
    for (final entry in universalCounts.entries) {
      final type = entry.key;
      final count = entry.value;

      test('$type: valid item with exactly $count questions passes', () {
        final problems = svc.validateShapeForTest(
          type,
          universalItem(type, count),
        );
        expect(problems, isEmpty);
      });

      test('$type: wrong question count is rejected', () {
        final problems = svc.validateShapeForTest(
          type,
          universalItem(type, count - 1),
        );
        expect(
          problems.any((p) => p.contains('expected $count questions')),
          isTrue,
        );
      });

      test('$type: missing texts is rejected', () {
        final item = universalItem(type, count)..remove('texts');
        final problems = svc.validateShapeForTest(type, item);
        expect(problems, contains(contains('texts is empty')));
      });

      test('$type: unknown question type is rejected', () {
        final item = universalItem(type, count, qType: 'mystery');
        final problems = svc.validateShapeForTest(type, item);
        expect(problems.any((p) => p.contains('unknown type')), isTrue);
      });
    }

    test('choice question: answer not among its own options is rejected', () {
      final item = {
        'variant_number': 1,
        'texts': ['t'],
        'questions': [
          {
            'number': 1,
            'type': 'choice',
            'answer': 'Z',
            'options': [
              {'letter': 'A'},
              {'letter': 'B'},
            ],
          },
        ],
      };
      final problems = svc.validateShapeForTest('lesen_teil1', item);
      expect(
        problems.any((p) => p.contains('not among its own options')),
        isTrue,
      );
    });

    test('match question: answer not in option_pool is rejected', () {
      final item = {
        'variant_number': 1,
        'texts': ['t'],
        'option_pool': [
          {'letter': 'A'},
        ],
        'questions': [
          {'number': 1, 'type': 'match', 'answer': 'Z'},
        ],
      };
      final problems = svc.validateShapeForTest('lesen_teil1', item);
      expect(problems.any((p) => p.contains('not in option_pool')), isTrue);
    });

    test('"(nicht angegeben)" answer passes validation for choice/match/'
        'true_false alike — the source genuinely had no question here, '
        'not a parsing failure', () {
      // Live case: beschwerde variant 6's second edition ends before
      // reaching questions 19/20 at all — prompts.py tells the model to
      // say so honestly with this sentinel instead of inventing a
      // plausible-looking answer, and it can never match any real
      // option/pool/richtig-falsch value by design. lesen_teil1 expects
      // exactly 5 questions (universalCounts), so each case below pads
      // with 4 ordinary valid true_false fillers to isolate the sentinel
      // question's own validation from the unrelated question-count check.
      Map<String, dynamic> filler(int number) => {
        'number': number,
        'type': 'true_false',
        'answer': 'richtig',
      };

      for (final q in [
        {
          'number': 5,
          'type': 'choice',
          'answer': '(nicht angegeben)',
          'options': [
            {'letter': 'a', 'text': '(nicht angegeben)'},
          ],
        },
        {'number': 5, 'type': 'match', 'answer': '(nicht angegeben)'},
        {'number': 5, 'type': 'true_false', 'answer': '(nicht angegeben)'},
      ]) {
        final item = {
          'variant_number': 1,
          'texts': ['t'],
          'option_pool': [
            {'letter': 'A'},
          ],
          'questions': [filler(1), filler(2), filler(3), filler(4), q],
        };
        final problems = svc.validateShapeForTest('lesen_teil1', item);
        expect(
          problems,
          isEmpty,
          reason: 'type=${q['type']} should not be flagged: $problems',
        );
      }
    });
  });

  group('_validateShape — hoeren_teil1', () {
    Map<String, dynamic> pair({
      String dialogue = 'Ein kurzer Dialogtext.',
      bool richtig = true,
      String correct = 'A',
      List<String> letters = const ['A', 'B'],
    }) => {
      'dialogue': dialogue,
      'richtig_falsch': {'answer': richtig},
      'multiple_choice': {
        'options': letters.map((l) => {'letter': l}).toList(),
        'correct_letter': correct,
      },
    };

    test('valid item with exactly 3 question_pairs passes', () {
      final item = {
        'variant_number': 1,
        'question_pairs': [pair(), pair(), pair()],
      };
      expect(svc.validateShapeForTest('hoeren_teil1', item), isEmpty);
    });

    test('fewer than 3 question_pairs is rejected', () {
      final item = {
        'variant_number': 1,
        'question_pairs': [pair(), pair()],
      };
      final problems = svc.validateShapeForTest('hoeren_teil1', item);
      expect(problems.any((p) => p.contains('exactly 3 entries')), isTrue);
    });

    test('empty dialogue in a pair is rejected', () {
      final item = {
        'variant_number': 1,
        'question_pairs': [pair(dialogue: '   '), pair(), pair()],
      };
      final problems = svc.validateShapeForTest('hoeren_teil1', item);
      expect(problems.any((p) => p.contains('dialogue is empty')), isTrue);
    });

    test('correct_letter not among its own options is rejected', () {
      final item = {
        'variant_number': 1,
        'question_pairs': [pair(correct: 'Z'), pair(), pair()],
      };
      final problems = svc.validateShapeForTest('hoeren_teil1', item);
      expect(
        problems.any((p) => p.contains('not among its own options')),
        isTrue,
      );
    });
  });

  group('_validateShape — telefonnotiz', () {
    Map<String, dynamic> completeAnswer() => {
      'call_type': 'Anfrage',
      'name': 'Herr Schmidt',
      'telefonnummer': '030 1234567',
      'weitere_informationen': ['Bestellung Nr. 4711'],
      'zu_erledigen': 'Rückruf bis Freitag',
    };

    test('valid item with monologue and all five answer fields passes', () {
      final item = {
        'variant_number': 1,
        'versions': [
          {
            'monologue': 'Hallo, hier ist eine Nachricht für Sie.',
            'answer': completeAnswer(),
          },
        ],
      };
      expect(svc.validateShapeForTest('telefonnotiz', item), isEmpty);
    });

    test('empty versions list is rejected', () {
      final item = {'variant_number': 1, 'versions': <dynamic>[]};
      final problems = svc.validateShapeForTest('telefonnotiz', item);
      expect(problems, contains('versions is empty'));
    });

    test('empty monologue is rejected', () {
      final item = {
        'variant_number': 1,
        'versions': [
          {'monologue': '', 'answer': completeAnswer()},
        ],
      };
      final problems = svc.validateShapeForTest('telefonnotiz', item);
      expect(problems.any((p) => p.contains('monologue is empty')), isTrue);
    });

    test('missing answer object is rejected', () {
      final item = {
        'variant_number': 1,
        'versions': [
          {'monologue': 'Text.'},
        ],
      };
      final problems = svc.validateShapeForTest('telefonnotiz', item);
      expect(problems.any((p) => p.contains('answer is missing')), isTrue);
    });

    test('missing answer.name is rejected', () {
      final item = {
        'variant_number': 1,
        'versions': [
          {'monologue': 'Text.', 'answer': completeAnswer()..remove('name')},
        ],
      };
      final problems = svc.validateShapeForTest('telefonnotiz', item);
      expect(problems.any((p) => p.contains('answer.name is empty')), isTrue);
    });

    test('empty answer.zu_erledigen is rejected', () {
      // Live bug: this field renders as an invisible blank in the UI
      // (the SizedBox.shrink fallback for an empty value) instead of an
      // obvious error, so it needs its own explicit check.
      final item = {
        'variant_number': 1,
        'versions': [
          {
            'monologue': 'Text.',
            'answer': completeAnswer()..['zu_erledigen'] = '',
          },
        ],
      };
      final problems = svc.validateShapeForTest('telefonnotiz', item);
      expect(
        problems.any((p) => p.contains('answer.zu_erledigen is empty')),
        isTrue,
      );
    });

    test('empty answer.call_type is rejected', () {
      final item = {
        'variant_number': 1,
        'versions': [
          {
            'monologue': 'Text.',
            'answer': completeAnswer()..['call_type'] = '',
          },
        ],
      };
      final problems = svc.validateShapeForTest('telefonnotiz', item);
      expect(
        problems.any((p) => p.contains('answer.call_type is empty')),
        isTrue,
      );
    });

    test('empty answer.telefonnummer is rejected', () {
      final item = {
        'variant_number': 1,
        'versions': [
          {
            'monologue': 'Text.',
            'answer': completeAnswer()..['telefonnummer'] = '',
          },
        ],
      };
      final problems = svc.validateShapeForTest('telefonnotiz', item);
      expect(
        problems.any((p) => p.contains('answer.telefonnummer is empty')),
        isTrue,
      );
    });

    test(
      '"(nicht angegeben)" passes validation — a confirmed source gap is not '
      'a parsing failure',
      () {
        // Live case: variant 9's source literally has "Telefonnummer:"
        // with nothing after it (the monologue even has dots in place of
        // a number — "rufen Sie mich unter der Nummer ................."),
        // and one edition of another variant had no printed monologue at
        // all. Retrying either does nothing since there's nothing more to
        // extract, so the prompt asks Gemini to write this sentinel
        // instead of an empty string, and this non-empty value must sail
        // through validation rather than trigger an endless retry loop.
        final item = {
          'variant_number': 9,
          'versions': [
            {
              'monologue': '(nicht angegeben)',
              'answer': completeAnswer()
                ..['telefonnummer'] = '(nicht angegeben)'
                ..['weitere_informationen'] = ['(nicht angegeben)'],
            },
          ],
        };
        expect(svc.validateShapeForTest('telefonnotiz', item), isEmpty);
      },
    );

    test('empty answer.weitere_informationen list is rejected', () {
      final item = {
        'variant_number': 1,
        'versions': [
          {
            'monologue': 'Text.',
            'answer': completeAnswer()..['weitere_informationen'] = <String>[],
          },
        ],
      };
      final problems = svc.validateShapeForTest('telefonnotiz', item);
      expect(
        problems.any(
          (p) => p.contains('answer.weitere_informationen is empty'),
        ),
        isTrue,
      );
    });
  });

  group('_validateShape — sprachbausteine_teil1', () {
    test('valid item passes', () {
      final item = {
        'variant_number': 1,
        'letter_text': 'Sehr geehrte Damen und Herren, [1] und [2] fehlen.',
        'all_options': [
          {'letter': 'A'},
          {'letter': 'B'},
        ],
        'answers': [
          {'letter': 'A', 'question_number': 1},
          {'letter': 'B', 'question_number': 2},
        ],
      };
      expect(svc.validateShapeForTest('sprachbausteine_teil1', item), isEmpty);
    });

    test('empty letter_text is rejected', () {
      final item = {
        'variant_number': 1,
        'letter_text': '',
        'all_options': [
          {'letter': 'A'},
        ],
        'answers': [
          {'letter': 'A', 'question_number': 1},
        ],
      };
      final problems = svc.validateShapeForTest('sprachbausteine_teil1', item);
      expect(problems, contains('letter_text is empty'));
    });

    test('an answer letter not among all_options is rejected', () {
      final item = {
        'variant_number': 1,
        'letter_text': 'Text mit [1] Lücke.',
        'all_options': [
          {'letter': 'A'},
        ],
        'answers': [
          {'letter': 'Z', 'question_number': 1},
        ],
      };
      final problems = svc.validateShapeForTest('sprachbausteine_teil1', item);
      expect(problems.any((p) => p.contains('not among all_options')), isTrue);
    });

    test('letter_text missing the [n] marker for an answer is rejected', () {
      final item = {
        'variant_number': 1,
        'letter_text': 'Text ohne Marker.',
        'all_options': [
          {'letter': 'A'},
        ],
        'answers': [
          {'letter': 'A', 'question_number': 1},
        ],
      };
      final problems = svc.validateShapeForTest('sprachbausteine_teil1', item);
      expect(problems.any((p) => p.contains('missing [1] marker')), isTrue);
    });
  });
}
