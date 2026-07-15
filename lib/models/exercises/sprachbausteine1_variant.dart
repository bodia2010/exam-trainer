// Typed view over one sprachbausteine_teil1 variant — a distinct schema
// (letter_text + all_options + answers), not the universal shape.

import 'exercise_common.dart';

/// One word bank entry. [letter] is kept as raw `Object?` rather than a
/// `String` — the original screen compares it with untyped `==` against
/// [SprachbausteineAnswer.letter] (also raw), and a `String` vs. `num`
/// mismatch there must fail the same way it does today, not be coerced
/// into silently matching after a `.toString()` normalization.
class SprachbausteineOption {
  const SprachbausteineOption({required this.letter, required this.text});

  final Object? letter;
  final String text;

  /// Matches the screen's own display cast (`letter as String? ?? ''`).
  String get displayLetter => letter is String ? letter as String : '';

  factory SprachbausteineOption.fromJson(Map<String, dynamic> json) =>
      SprachbausteineOption(
        letter: json['letter'],
        text: asString(json['text']),
      );

  static List<SprachbausteineOption> listFromJson(Object? raw) => asList(raw)
      .whereType<Map>()
      .map((e) => SprachbausteineOption.fromJson(e.cast<String, dynamic>()))
      .toList();
}

/// The known-correct word for one gap. [letter] stays raw for the same
/// equality-matching reason as [SprachbausteineOption.letter].
class SprachbausteineAnswer {
  const SprachbausteineAnswer({
    required this.questionNumber,
    required this.word,
    required this.letter,
  });

  final int? questionNumber;
  final String? word;
  final Object? letter;

  factory SprachbausteineAnswer.fromJson(Map<String, dynamic> json) =>
      SprachbausteineAnswer(
        questionNumber: asNumOrNull(json['question_number'])?.toInt(),
        word: asStringOrNull(json['word']),
        letter: json['letter'],
      );

  static List<SprachbausteineAnswer> listFromJson(Object? raw) => asList(raw)
      .whereType<Map>()
      .map((e) => SprachbausteineAnswer.fromJson(e.cast<String, dynamic>()))
      .toList();
}

class SprachbausteineTeil1Variant {
  const SprachbausteineTeil1Variant({
    required this.variantNumber,
    required this.topic,
    required this.version,
    required this.letterText,
    required this.allOptions,
    required this.answers,
  });

  final num? variantNumber;
  final String topic;
  final String version;
  final String letterText;
  final List<SprachbausteineOption> allOptions;
  final List<SprachbausteineAnswer> answers;

  num displayNumber(int index) => variantNumber ?? (index + 1);

  factory SprachbausteineTeil1Variant.fromJson(Map<String, dynamic> json) =>
      SprachbausteineTeil1Variant(
        variantNumber: asNumOrNull(json['variant_number']),
        topic: asString(json['topic']),
        version: asString(json['version']),
        letterText: asString(json['letter_text']),
        allOptions: SprachbausteineOption.listFromJson(json['all_options']),
        answers: SprachbausteineAnswer.listFromJson(json['answers']),
      );

  static List<SprachbausteineTeil1Variant> listFromJson(Object? raw) =>
      asList(raw)
          .whereType<Map>()
          .map(
            (e) =>
                SprachbausteineTeil1Variant.fromJson(e.cast<String, dynamic>()),
          )
          .toList();
}
