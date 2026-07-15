// CR-08 migration test: a full course JSON shaped exactly like what the
// app persisted BEFORE schemaVersion/typed DTOs existed (no `schema_version`
// key at all, every section as raw dynamic JSON) must still load
// end-to-end — through ParsedCourse.fromJson and then through every typed
// exercise DTO — without throwing and without losing data. This is the
// "old course fixture" the CR-08 migration plan calls for: a real
// representative shape per section type, not just the individual DTO unit
// fixtures in exercise_dto_test.dart.
import 'package:flutter_test/flutter_test.dart';

import 'package:exam_trainer/models/exercises/hoeren_teil1_variant.dart';
import 'package:exam_trainer/models/exercises/sprachbausteine1_variant.dart';
import 'package:exam_trainer/models/exercises/telefonnotiz_variant.dart';
import 'package:exam_trainer/models/exercises/universal_variant.dart';
import 'package:exam_trainer/models/parsed_course.dart';

/// One representative variant per section type, matching the shapes
/// parse_service.dart's `_validateShape` accepts today. Deliberately has
/// NO `schema_version` key anywhere — this is what every course saved
/// before CR-08 actually looks like on disk/Firestore.
Map<String, dynamic> _legacyCourseJson() => {
  'id': 'legacy-course-1',
  'title': 'Altkurs',
  'source_filename': 'altkurs.pdf',
  'parsed_at': DateTime(2025, 1, 1).toIso8601String(),
  'sections': {
    'lesen_teil1': [
      {
        'variant_number': 1,
        'topic': 'Büro',
        'texts': [
          {'title': 'a) Erste Anzeige', 'content': 'Text A'},
          {'title': 'b) Zweite Anzeige', 'content': 'Text B'},
        ],
        'questions': [
          {
            'number': 1,
            'text': 'Person sucht ...',
            'type': 'match',
            'answer': 'a',
          },
        ],
      },
    ],
    'lesen_teil2': [
      {
        'variant_number': 1,
        'texts': [
          {'title': 'Text', 'content': 'Ein langer Lesetext.'},
        ],
        'questions': [
          {
            'number': 1,
            'text': 'Frage 1',
            'type': 'choice',
            'answer': 'b',
            'options': [
              {'letter': 'a', 'text': 'Option A'},
              {'letter': 'b', 'text': 'Option B'},
            ],
          },
        ],
      },
    ],
    'lesen_teil3': [
      {
        'variant_number': 1,
        'texts': [
          {'title': 'a) Anzeige A', 'content': 'Text A'},
          {'title': 'b) Anzeige B', 'content': 'Text B'},
        ],
        'questions': [
          {
            'number': 1,
            'text': 'Welche Anzeige passt?',
            'type': 'match',
            'answer': 'a',
          },
        ],
      },
    ],
    'lesen_teil4': [
      {
        'variant_number': 1,
        'texts': [
          {'title': 'Firmenrichtlinie', 'content': 'Ein Regeltext.'},
        ],
        'questions': [
          {
            'number': 14,
            'text': 'Die Regel gilt für alle Mitarbeiter.',
            'type': 'true_false',
            'answer': 'richtig',
          },
        ],
      },
    ],
    'beschwerde': [
      {
        'variant_number': 1,
        'texts': [
          {'title': 'Interner Hinweis', 'content': 'Memo-Text'},
          {'title': 'Kundenbeschwerde', 'content': 'Beschwerde-Text'},
          {'title': 'Musterantwort', 'content': 'Antwort-Text'},
        ],
        'questions': [
          {
            'number': 19,
            'text': 'Warum beschwert sich der Kunde?',
            'answer': 'c',
            'options': [
              {'letter': 'a', 'text': 'A'},
              {'letter': 'b', 'text': 'B'},
              {'letter': 'c', 'text': 'C'},
            ],
          },
        ],
      },
    ],
    'sprachbausteine_teil1': [
      {
        'variant_number': 1,
        'letter_text': 'Sehr geehrte [52] Damen und Herren [53] ...',
        'all_options': [
          {'letter': 'a', 'text': 'Herr'},
          {'letter': 'b', 'text': 'Frau'},
        ],
        'answers': [
          {'question_number': 52, 'letter': 'a', 'word': 'Herr'},
        ],
      },
    ],
    'sprachbausteine_teil2': [
      {
        'variant_number': 1,
        'texts': [
          {'content': 'Ein Text mit [1] Lücken.'},
        ],
        'questions': [
          {
            'number': 1,
            'answer': 'a',
            'options': [
              {'letter': 'a', 'text': 'mit'},
              {'letter': 'b', 'text': 'ohne'},
            ],
          },
        ],
      },
    ],
    'telefonnotiz': [
      {
        'variant_number': 1,
        'topic': 'Anruf',
        'versions': [
          {
            'audio_url': 'https://example.com/call.mp3',
            'monologue': 'Guten Tag, hier ist ...',
            'answer': {
              'call_type': 'Anfrage',
              'name': 'Herr Müller',
              'telefonnummer': '030 1234567',
              'zu_erledigen': 'Rückruf morgen',
              'weitere_informationen': ['Dringend', 'Vor 10 Uhr'],
            },
          },
        ],
      },
    ],
    'hoeren_teil1': [
      {
        'variant_number': 1,
        'question_pairs': [
          {
            'dialogue': 'Dialog 1',
            'richtig_falsch': {
              'number': 1,
              'statement': 'Aussage 1',
              'answer': true,
            },
            'multiple_choice': {
              'number': 2,
              'stem': 'Frage 2',
              'correct_letter': 'a',
              'options': [
                {'letter': 'a', 'text': 'A'},
                {'letter': 'b', 'text': 'B'},
              ],
            },
          },
        ],
      },
    ],
    'hoeren_teil2': [
      {
        'variant_number': 1,
        'texts': [
          {'title': 'Person 1', 'content': ''},
        ],
        'option_pool': [
          {'letter': 'a', 'text': 'Aussage A'},
        ],
        'questions': [
          {'number': 1, 'type': 'match', 'answer': 'a'},
        ],
      },
    ],
    'hoeren_teil3': [
      {
        'variant_number': 1,
        'questions': [
          {
            'number': 1,
            'text': 'Frage',
            'type': 'choice',
            'answer': 'a',
            'options': [
              {'letter': 'a', 'text': 'A'},
            ],
          },
        ],
      },
    ],
    'hoeren_teil4': [
      {
        'variant_number': 1,
        'questions': [
          {
            'number': 1,
            'text': 'Frage',
            'type': 'true_false',
            'answer': 'richtig',
          },
        ],
      },
    ],
  },
};

void main() {
  test(
    'a legacy course (no schema_version key) loads via ParsedCourse.fromJson '
    'and defaults schemaVersion to 1',
    () {
      final course = ParsedCourse.fromJson(_legacyCourseJson());
      expect(course.schemaVersion, 1);
      expect(course.id, 'legacy-course-1');
      // All 12 exercise types the app currently supports (see
      // PRODUCT_PLAN.md's section table) — not just a subset.
      expect(course.sections.keys, hasLength(12));
    },
  );

  test('every universal-schema section in the legacy fixture parses through '
      'UniversalVariant without throwing', () {
    final course = ParsedCourse.fromJson(_legacyCourseJson());
    for (final type in [
      'lesen_teil1',
      'lesen_teil2',
      'lesen_teil3',
      'lesen_teil4',
      'beschwerde',
      'sprachbausteine_teil2',
      'hoeren_teil2',
      'hoeren_teil3',
      'hoeren_teil4',
    ]) {
      final variants = UniversalVariant.listFromJson(course.sections[type]);
      expect(variants, isNotEmpty, reason: '$type produced no variants');
      expect(variants.first.questions, isNotEmpty);
    }
  });

  test('sprachbausteine_teil1 in the legacy fixture parses through '
      'SprachbausteineTeil1Variant and keeps the gap/answer link intact', () {
    final course = ParsedCourse.fromJson(_legacyCourseJson());
    final variants = SprachbausteineTeil1Variant.listFromJson(
      course.sections['sprachbausteine_teil1'],
    );
    expect(variants.single.letterText, contains('[52]'));
    expect(variants.single.answers.single.questionNumber, 52);
    expect(variants.single.allOptions.first.letter, 'a');
  });

  test('telefonnotiz in the legacy fixture parses through TelefonnotizVariant '
      'and keeps all five answer fields', () {
    final course = ParsedCourse.fromJson(_legacyCourseJson());
    final variants = TelefonnotizVariant.listFromJson(
      course.sections['telefonnotiz'],
    );
    final answer = variants.single.versions.single.answer;
    expect(answer.callType, 'Anfrage');
    expect(answer.name, 'Herr Müller');
    expect(answer.telefonnummer, '030 1234567');
    expect(answer.zuErledigen, 'Rückruf morgen');
    expect(answer.weitereInformationen, ['Dringend', 'Vor 10 Uhr']);
  });

  test('hoeren_teil1 in the legacy fixture parses through HoerenTeil1Variant '
      'and keeps both question kinds per pair', () {
    final course = ParsedCourse.fromJson(_legacyCourseJson());
    final variants = HoerenTeil1Variant.listFromJson(
      course.sections['hoeren_teil1'],
    );
    final pair = variants.single.questionPairs.single;
    expect(pair.richtigFalsch!.answer, isTrue);
    expect(pair.multipleChoice!.correctLetter, 'a');
    expect(pair.multipleChoice!.options, hasLength(2));
  });

  test('a course round-tripped through toJson/fromJson keeps every section '
      'parseable the same way', () {
    final original = ParsedCourse.fromJson(_legacyCourseJson());
    final roundTripped = ParsedCourse.fromJson(original.toJson());
    expect(roundTripped.schemaVersion, 1);
    expect(
      UniversalVariant.listFromJson(
        roundTripped.sections['lesen_teil1'],
      ).single.topic,
      'Büro',
    );
  });
}
