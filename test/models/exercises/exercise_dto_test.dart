// CR-08: typed DTOs at the exercise data boundary. These tests pin the
// exact defaulting/graceful-degradation behavior each screen relied on
// when it read raw Map<String, dynamic> JSON directly (see the field
// inventory in course_load_state_test.dart's schema-drift cases) — a
// missing/wrong-typed field must degrade to a safe default, never throw,
// and a handful of fields (kNoAnswerSentinel, raw `letter` equality) must
// survive completely unchanged since screens branch on their exact value.
import 'package:flutter_test/flutter_test.dart';

import 'package:exam_trainer/models/exercises/exercise_common.dart';
import 'package:exam_trainer/models/exercises/hoeren_teil1_variant.dart';
import 'package:exam_trainer/models/exercises/sprachbausteine1_variant.dart';
import 'package:exam_trainer/models/exercises/telefonnotiz_variant.dart';
import 'package:exam_trainer/models/exercises/universal_variant.dart';
import 'package:exam_trainer/models/voice_gender.dart';

void main() {
  group('ExerciseText', () {
    test('non-ASCII version labels cannot collapse to one recording ID', () {
      final first = stableVariantRecordingId(
        sectionType: 'hoeren_teil4',
        variantNumber: 1,
        variantIndex: 0,
        version: 'Новая версия',
      );
      final second = stableVariantRecordingId(
        sectionType: 'hoeren_teil4',
        variantNumber: 1,
        variantIndex: 0,
        version: 'Старая версия',
      );

      expect(first, isNot(second));
      expect(first, startsWith('hoeren_teil4:v1:original-'));
      expect(
        first,
        stableVariantRecordingId(
          sectionType: 'hoeren_teil4',
          variantNumber: 1,
          variantIndex: 0,
          version: 'Новая версия',
        ),
      );
    });

    test('title is null (not "") when missing — distinct from explicit ""', () {
      final missing = ExerciseText.fromJson({'content': 'body'});
      final explicit = ExerciseText.fromJson({'title': '', 'content': 'body'});
      expect(missing.title, isNull);
      expect(explicit.title, '');
    });

    test('content defaults to "" when missing or wrong type', () {
      expect(ExerciseText.fromJson({}).content, '');
      expect(ExerciseText.fromJson({'content': 42}).content, '');
    });

    test('listFromJson drops non-Map entries instead of throwing', () {
      final list = ExerciseText.listFromJson([
        {'title': 'a', 'content': '1'},
        'not-a-map',
        {'title': 'b', 'content': '2'},
      ]);
      expect(list.map((t) => t.content), ['1', '2']);
    });

    test('listFromJson on a non-List value returns empty, not throw', () {
      expect(ExerciseText.listFromJson('not-a-list'), isEmpty);
      expect(ExerciseText.listFromJson(null), isEmpty);
    });

    test('voice metadata and recordingId are parsed per text', () {
      final texts = ExerciseText.listFromJson(
        [
          {
            'title': 'Nummer 36',
            'content': 'Andrea spricht.',
            'metadata': {'voice_gender': 'female'},
          },
          {
            'title': 'Dialog',
            'content': 'Herr Becker: Hallo.',
            'metadata': {
              'speaker_voice_genders': [
                {'speaker': 'Herr Becker', 'voice_gender': 'male'},
              ],
            },
          },
        ],
        sectionType: 'hoeren_teil4',
        variantNumber: 4,
        version: 'Neue Version',
      );

      expect(texts[0].voiceGender, VoiceGender.female);
      expect(texts[0].recordingId, 'hoeren_teil4:v4:neue-version:text-1');
      expect(
        texts[1].voiceMetadata.genderForSpeaker('Herr Becker'),
        VoiceGender.male,
      );
      expect(texts[1].recordingId, 'hoeren_teil4:v4:neue-version:text-2');
    });
  });

  group('ExerciseQuestion', () {
    test('kNoAnswerSentinel survives verbatim as the answer value', () {
      final q = ExerciseQuestion.fromJson({
        'number': 3,
        'answer': kNoAnswerSentinel,
      });
      expect(q.answer, kNoAnswerSentinel);
    });

    test('answer coerces a non-String value via toString(), matching the '
        'old _normalized() tolerance', () {
      final q = ExerciseQuestion.fromJson({'number': 1, 'answer': 42});
      expect(q.answer, '42');
    });

    test('answer stays null when absent (distinct from any real value)', () {
      expect(ExerciseQuestion.fromJson({'number': 1}).answer, isNull);
    });

    test('text/type/options default safely when missing', () {
      final q = ExerciseQuestion.fromJson({'number': 7});
      expect(q.text, '');
      expect(q.type, 'choice');
      expect(q.options, isEmpty);
    });

    test('a missing or non-numeric "number" throws instead of defaulting '
        'to 0 — a structural field, not a presentational one (see '
        'ExerciseSchemaException)', () {
      expect(() => ExerciseQuestion.fromJson({}), throwsA(isException));
      expect(
        () => ExerciseQuestion.fromJson({'number': 'not-a-number'}),
        throwsA(isException),
      );
    });

    test('listFromJson throws on a duplicate question number instead of '
        'letting two distinct questions collide in every screen\'s '
        '`Map<int, ...>` answer table', () {
      expect(
        () => ExerciseQuestion.listFromJson([
          {'number': 1, 'text': 'Frage 1'},
          {'number': 1, 'text': 'Frage 2'},
        ]),
        throwsA(isException),
      );
    });

    test('listFromJson throws when a required "number" is missing on one '
        'of several otherwise-valid questions (the "two questions become '
        '#0" regression)', () {
      expect(
        () => ExerciseQuestion.listFromJson([
          {'number': 1, 'text': 'Frage 1'},
          {'text': 'Frage ohne Nummer'},
          {'number': 3, 'text': 'Frage 3'},
        ]),
        throwsA(isException),
      );
    });
  });

  group('UniversalVariant', () {
    test('a fully-populated variant round-trips every field', () {
      final v = UniversalVariant.fromJson({
        'variant_number': 3,
        'topic': 'Arbeit',
        'version': 'Neue Version',
        'audio_url': 'https://example.com/a.mp3',
        'texts': [
          {'title': 'a) Text', 'content': 'Inhalt'},
        ],
        'option_pool': [
          {'letter': 'a', 'text': 'Option A'},
        ],
        'questions': [
          {
            'number': 1,
            'text': 'Frage',
            'type': 'match',
            'answer': 'a',
            'options': [],
          },
        ],
      });
      expect(v.variantNumber, 3);
      expect(v.topic, 'Arbeit');
      expect(v.version, 'Neue Version');
      expect(v.audioUrl, 'https://example.com/a.mp3');
      expect(v.texts.single.content, 'Inhalt');
      expect(v.optionPool.single.letter, 'a');
      expect(v.questions.single.type, 'match');
    });

    test('displayNumber falls back to index+1 exactly like the old '
        "`v['variant_number'] ?? (index + 1)`", () {
      final v = UniversalVariant.fromJson({});
      expect(v.displayNumber(4), 5);
    });

    test('a missing/empty variant has no questions/texts/options and does '
        'not throw', () {
      final v = UniversalVariant.fromJson({});
      expect(v.questions, isEmpty);
      expect(v.texts, isEmpty);
      expect(v.optionPool, isEmpty);
      expect(v.audioUrl, isNull);
    });
  });

  group('SprachbausteineTeil1Variant', () {
    test('letter equality is preserved across types (raw, not toString)', () {
      final v = SprachbausteineTeil1Variant.fromJson({
        'all_options': [
          {'letter': 1, 'text': 'eins'},
        ],
        'answers': [
          {'question_number': 5, 'word': 'eins', 'letter': 1},
        ],
      });
      // Both letters came from JSON numbers, so they must compare equal —
      // a screen that stringified one side (e.g. via toString()) would
      // wrongly treat 1 and "1" as different keys once mixed input types
      // are involved, which is exactly the equality-matching bug this
      // preserves against.
      expect(v.allOptions.single.letter, v.answers.single.letter);
      expect(v.allOptions.single.displayLetter, ''); // not a String
    });

    test('displayLetter returns the raw String when letter is a String', () {
      final option = SprachbausteineOption.fromJson({
        'letter': 'b',
        'text': 'zwei',
      });
      expect(option.displayLetter, 'b');
    });

    test('letterText/topic/version default to "" and lists default empty', () {
      final v = SprachbausteineTeil1Variant.fromJson({});
      expect(v.letterText, '');
      expect(v.topic, '');
      expect(v.allOptions, isEmpty);
      expect(v.answers, isEmpty);
    });
  });

  group('TelefonnotizVariant', () {
    test('answer defaults to TelefonnotizAnswer.empty when missing/wrong '
        'type', () {
      final withoutAnswer = TelefonnotizEdition.fromJson({});
      final withWrongType = TelefonnotizEdition.fromJson({'answer': 'oops'});
      expect(withoutAnswer.answer, TelefonnotizAnswer.empty);
      expect(withWrongType.answer, TelefonnotizAnswer.empty);
    });

    test('weitereInformationen coerces each element via toString() instead '
        'of throwing on one non-String bullet', () {
      final answer = TelefonnotizAnswer.fromJson({
        'weitere_informationen': ['a real bullet', 42, null],
      });
      expect(answer.weitereInformationen, ['a real bullet', '42', 'null']);
    });

    test('kNoAnswerSentinel survives as a real field value', () {
      final answer = TelefonnotizAnswer.fromJson({
        'call_type': kNoAnswerSentinel,
      });
      expect(answer.callType, kNoAnswerSentinel);
    });

    test('label stays null (not "") when absent, matching the tab-title '
        'fallback the screen applies only when it is missing', () {
      expect(TelefonnotizEdition.fromJson({}).label, isNull);
    });

    test('voice_gender is read from the actual version metadata contract', () {
      final variant = TelefonnotizVariant.fromJson({
        'variant_number': 3,
        'versions': [
          {
            'monologue': 'A',
            'answer': {},
            'label': 'Original',
            'metadata': {'voice_gender': 'female'},
          },
          {
            'monologue': 'B',
            'answer': {},
            'label': 'Neu',
            'metadata': {'voice_gender': 'male'},
          },
        ],
      });
      expect(variant.versions[0].voiceGender, VoiceGender.female);
      expect(variant.versions[1].voiceGender, VoiceGender.male);
    });

    test('duplicate and empty edition labels still get distinct IDs', () {
      final variant = TelefonnotizVariant.fromJson({
        'variant_number': 3,
        'versions': [
          {'monologue': 'A', 'answer': {}, 'label': ''},
          {'monologue': 'B', 'answer': {}, 'label': ''},
          {'monologue': 'C', 'answer': {}, 'label': 'Повтор'},
          {'monologue': 'D', 'answer': {}, 'label': 'Повтор'},
        ],
      });

      expect(variant.versions.map((e) => e.recordingId).toSet(), hasLength(4));
    });

    test('recordingId changes when a Telefonnotiz version label changes', () {
      final variant = TelefonnotizVariant.fromJson({
        'variant_number': 5,
        'versions': [
          {'label': 'Original', 'monologue': 'A', 'answer': {}},
          {'label': 'Neue Version', 'monologue': 'B', 'answer': {}},
        ],
      });
      expect(
        variant.versions[0].recordingId,
        'telefonnotiz:v5:original:edition-1',
      );
      expect(
        variant.versions[1].recordingId,
        'telefonnotiz:v5:neue-version:edition-2',
      );
      expect(
        variant.versions[0].recordingId,
        isNot(variant.versions[1].recordingId),
      );
    });
  });

  group('HoerenTeil1Variant', () {
    test('richtig_falsch and multiple_choice are null when absent, not '
        'thrown on', () {
      final pair = QuestionPair.fromJson({'dialogue': 'Hallo'});
      expect(pair.richtigFalsch, isNull);
      expect(pair.multipleChoice, isNull);
      expect(pair.dialogue, 'Hallo');
    });

    test('richtig_falsch.number/multiple_choice.number are structural: a '
        'missing value throws instead of both silently becoming 0 and '
        'colliding in the screen\'s _rfAnswers/_mcAnswers maps', () {
      expect(
        () => QuestionPair.fromJson({'richtig_falsch': <String, dynamic>{}}),
        throwsA(isException),
      );
      expect(
        () => QuestionPair.fromJson({'multiple_choice': <String, dynamic>{}}),
        throwsA(isException),
      );
    });

    test('HoerenTeil1Variant.fromJson throws on a duplicate richtig_falsch '
        'number across pairs (each kind is keyed independently, see '
        'assertUniqueNumbers)', () {
      expect(
        () => HoerenTeil1Variant.fromJson({
          'question_pairs': [
            {
              'richtig_falsch': {'number': 1, 'statement': 'a'},
            },
            {
              'richtig_falsch': {'number': 1, 'statement': 'b'},
            },
          ],
        }),
        throwsA(isException),
      );
    });

    test('multiple_choice.options[].letter defaults to "" instead of '
        'throwing (the old code used a non-nullable `as String` here)', () {
      final pair = QuestionPair.fromJson({
        'multiple_choice': {
          'number': 1,
          'options': [<String, dynamic>{}],
        },
      });
      expect(pair.multipleChoice!.options.single.letter, '');
    });

    test(
      'question-pair voice_gender and recordingId are parsed defensively',
      () {
        final variant = HoerenTeil1Variant.fromJson({
          'variant_number': 2,
          'version': 'Neue Version',
          'question_pairs': [
            {
              'dialogue': 'A',
              'metadata': {
                'speaker_voice_genders': [
                  {'speaker': 'Herr Becker', 'voice_gender': 'male'},
                ],
              },
              'richtig_falsch': {'number': 1, 'answer': true},
              'multiple_choice': {
                'number': 2,
                'correct_letter': 'a',
                'options': [
                  {'letter': 'a'},
                ],
              },
            },
            {
              'dialogue': 'B',
              'metadata': {'voice_gender': 'female'},
              'richtig_falsch': {'number': 3, 'answer': true},
              'multiple_choice': {
                'number': 4,
                'correct_letter': 'a',
                'options': [
                  {'letter': 'a'},
                ],
              },
            },
          ],
        });
        expect(variant.questionPairs[0].voiceGender, VoiceGender.unknown);
        expect(
          variant.questionPairs[0].voiceMetadata.genderForSpeaker(
            'Herr Becker',
          ),
          VoiceGender.male,
        );
        expect(variant.questionPairs[1].voiceGender, VoiceGender.female);
        expect(
          variant.questionPairs[0].recordingId,
          'hoeren_teil1:v2:neue-version:pair-1',
        );
        expect(
          variant.questionPairs[1].recordingId,
          'hoeren_teil1:v2:neue-version:pair-2',
        );
      },
    );
  });
}
