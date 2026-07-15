/// Shared typed building blocks for the exercise section DTOs (CR-08).
///
/// These mirror the exact field vocabulary the exercise screens already
/// read off raw `Map<String, dynamic>` JSON (see parse_service.dart's
/// `_validateShape` for the parse-time invariants) — this is a read-time
/// typed *view* over that same JSON, not a new wire/storage format. Every
/// field here defaults defensively (matching or improving on the screens'
/// existing `as T? ?? fallback` casts) so a schema-drifted or hand-edited
/// course degrades to a safe default field-by-field instead of throwing
/// during parsing or later during build().
library;

/// The source PDF sometimes has no real question/answer for a slot in a
/// given edition; the parse prompt is told to say so honestly with this
/// exact sentinel rather than invent plausible content (see prompts.py's
/// Common rules). Screens compare an answer field against this literal
/// value, so it must survive as a real string here — never normalized
/// away or treated as equivalent to "answer is null".
const kNoAnswerSentinel = '(nicht angegeben)';

/// Safe field extractors shared by every DTO in this directory. A bare
/// `json['x'] as String?` throws when `json['x']` is present but the
/// WRONG type (e.g. a number where a string was expected) — a nullable
/// cast only tolerates null, not a type mismatch. These check the runtime
/// type explicitly first, so a schema-drifted field degrades to the
/// fallback exactly like a missing one, instead of throwing.
String? asStringOrNull(Object? value) => value is String ? value : null;

String asString(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;

int asInt(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : fallback;

num? asNumOrNull(Object? value) => value is num ? value : null;

bool? asBoolOrNull(Object? value) => value is bool ? value : null;

List<Object?> asList(Object? value) => value is List ? value : const [];

Map<String, dynamic>? asMapOrNull(Object? value) =>
    value is Map ? value.cast<String, dynamic>() : null;

/// Thrown by a DTO's `fromJson`/`listFromJson` when a field this
/// exercise's identification, counting, or completion logic depends on is
/// missing or the wrong type. Unlike the `asX` helpers above — which
/// degrade presentation fields to a safe default — these fields must not
/// be silently defaulted: two questions that both fall back to
/// `number: 0` collide in every screen's `Map<int, ...>` answer/lookup
/// table (`_selected[q.number]`, `_questionsByNumber`, `_rfAnswers`, ...),
/// silently merging two distinct questions into one instead of surfacing
/// as a schema error. `loadVariant` (see variant_loader.dart) already
/// catches any exception thrown during `fromJson` and turns it into the
/// existing not-found/error UI — throwing here routes a real schema
/// defect to that existing path instead of letting it corrupt state.
class ExerciseSchemaException implements Exception {
  const ExerciseSchemaException(this.message);
  final String message;

  @override
  String toString() => 'ExerciseSchemaException: $message';
}

/// Required-field counterpart to [asInt]: throws [ExerciseSchemaException]
/// instead of defaulting when [value] is missing or not a number. Reserved
/// for structural fields that identify/count/complete an exercise.
int asRequiredInt(Object? value, {required String field}) {
  if (value is num) return value.toInt();
  throw ExerciseSchemaException(
    'required field "$field" is missing or not a number: $value',
  );
}

/// Throws [ExerciseSchemaException] if [numbers] contains a duplicate.
/// Two structurally distinct entries that resolve to the same identifying
/// number would otherwise silently collide wherever a screen keys a
/// lookup/answer map by that number (see [ExerciseSchemaException]).
void assertUniqueNumbers(Iterable<int> numbers, {required String context}) {
  final seen = <int>{};
  for (final n in numbers) {
    if (!seen.add(n)) {
      throw ExerciseSchemaException('duplicate $context number: $n');
    }
  }
}

/// One display text/passage — `lesen`/`hoeren` reading or listening
/// material, and beschwerde's letters (matched positionally/by title in
/// the beschwerde screen, not by any field this DTO adds).
class ExerciseText {
  const ExerciseText({required this.title, required this.content});

  // `title` is deliberately nullable rather than defaulted to '' — a
  // missing title and an explicitly-empty title are two different states
  // consuming screens fall back on differently (the universal exercise
  // screen shows a localized "Text" placeholder only when it's missing;
  // beschwerde falls back to '' either way). Collapsing both to '' here
  // would make that distinction impossible to recover at the call site.
  final String? title;
  final String content;

  factory ExerciseText.fromJson(Map<String, dynamic> json) => ExerciseText(
    title: asStringOrNull(json['title']),
    content: asString(json['content']),
  );

  static List<ExerciseText> listFromJson(Object? raw) => asList(raw)
      .whereType<Map>()
      .map((e) => ExerciseText.fromJson(e.cast<String, dynamic>()))
      .toList();
}

/// One selectable answer option (a matching-pool entry, a multiple-choice
/// option, or a sprachbausteine option).
class ExerciseOption {
  const ExerciseOption({required this.letter, required this.text});

  final String letter;
  final String text;

  factory ExerciseOption.fromJson(Map<String, dynamic> json) => ExerciseOption(
    letter: asString(json['letter']),
    text: asString(json['text']),
  );

  static List<ExerciseOption> listFromJson(Object? raw) => asList(raw)
      .whereType<Map>()
      .map((e) => ExerciseOption.fromJson(e.cast<String, dynamic>()))
      .toList();
}

/// One question in the universal schema (lesen_teil1-4, hoeren_teil2-4,
/// beschwerde, sprachbausteine_teil2 — see parse_service's `_validateUniversal`
/// dispatch, which treats all of these the same way).
///
/// [answer] is intentionally `String?` rather than a closed enum/non-null
/// value: it can legitimately be null (no answer recorded), a letter, a
/// `'richtig'`/`'falsch'` literal, or [kNoAnswerSentinel] — all four are
/// real, distinguishable states the screens branch on.
class ExerciseQuestion {
  const ExerciseQuestion({
    required this.number,
    required this.text,
    required this.type,
    required this.answer,
    required this.options,
  });

  final int number;
  final String text;
  final String type;
  final String? answer;
  final List<ExerciseOption> options;

  factory ExerciseQuestion.fromJson(Map<String, dynamic> json) =>
      ExerciseQuestion(
        // Structural, not presentational: see [asRequiredInt] — every
        // screen keys an answer/lookup map by this number, so a missing
        // or malformed value must surface as a schema error, not silently
        // collide with another question that also defaulted to 0.
        number: asRequiredInt(json['number'], field: 'number'),
        text: asString(json['text']),
        type: asString(json['type'], fallback: 'choice'),
        // toString() rather than a bare cast — mirrors the screens'
        // existing `_normalized()` helper, which already accepts any
        // non-null Object for `answer` (a defensive coercion, not a new
        // behavior). Only actual null stays null.
        answer: json['answer']?.toString(),
        options: ExerciseOption.listFromJson(json['options']),
      );

  static List<ExerciseQuestion> listFromJson(Object? raw) {
    final list = asList(raw)
        .whereType<Map>()
        .map((e) => ExerciseQuestion.fromJson(e.cast<String, dynamic>()))
        .toList();
    assertUniqueNumbers(list.map((q) => q.number), context: 'question');
    return list;
  }
}
