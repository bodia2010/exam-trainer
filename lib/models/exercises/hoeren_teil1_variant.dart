import 'exercise_common.dart';

/// Typed view over one hoeren_teil1 variant — three dialogue "pairs", each
/// optionally holding a richtig/falsch question and a multiple-choice
/// question (parse_service requires exactly 3 pairs and always a present
/// multiple_choice, but the screen already treats both as defensively
/// optional — this DTO keeps that same tolerance rather than tightening
/// it, since malformed local/cached data must still degrade, not crash).
class RichtigFalschQuestion {
  const RichtigFalschQuestion({
    required this.number,
    required this.statement,
    required this.answer,
  });

  final int number;
  final String statement;
  final bool? answer;

  factory RichtigFalschQuestion.fromJson(Map<String, dynamic> json) =>
      RichtigFalschQuestion(
        // Structural: the screen keys `_rfAnswers` by this number (see
        // exercise_common.dart's [asRequiredInt]).
        number: asRequiredInt(json['number'], field: 'number'),
        statement: asString(json['statement']),
        answer: asBoolOrNull(json['answer']),
      );
}

class MultipleChoiceQuestion {
  const MultipleChoiceQuestion({
    required this.number,
    required this.stem,
    required this.options,
    required this.correctLetter,
  });

  final int number;
  final String stem;
  final List<ExerciseOption> options;
  final String? correctLetter;

  factory MultipleChoiceQuestion.fromJson(Map<String, dynamic> json) =>
      MultipleChoiceQuestion(
        // Structural: the screen keys `_mcAnswers` by this number (see
        // exercise_common.dart's [asRequiredInt]).
        number: asRequiredInt(json['number'], field: 'number'),
        stem: asString(json['stem']),
        options: ExerciseOption.listFromJson(json['options']),
        correctLetter: asStringOrNull(json['correct_letter']),
      );
}

class QuestionPair {
  const QuestionPair({
    required this.dialogue,
    required this.richtigFalsch,
    required this.multipleChoice,
  });

  final String dialogue;
  final RichtigFalschQuestion? richtigFalsch;
  final MultipleChoiceQuestion? multipleChoice;

  factory QuestionPair.fromJson(Map<String, dynamic> json) {
    final rf = asMapOrNull(json['richtig_falsch']);
    final mc = asMapOrNull(json['multiple_choice']);
    return QuestionPair(
      dialogue: asString(json['dialogue']),
      richtigFalsch: rf != null ? RichtigFalschQuestion.fromJson(rf) : null,
      multipleChoice: mc != null ? MultipleChoiceQuestion.fromJson(mc) : null,
    );
  }

  static List<QuestionPair> listFromJson(Object? raw) => asList(raw)
      .whereType<Map>()
      .map((e) => QuestionPair.fromJson(e.cast<String, dynamic>()))
      .toList();
}

class HoerenTeil1Variant {
  const HoerenTeil1Variant({
    required this.variantNumber,
    required this.version,
    required this.questionPairs,
  });

  final num? variantNumber;
  final String version;
  final List<QuestionPair> questionPairs;

  num displayNumber(int index) => variantNumber ?? (index + 1);

  factory HoerenTeil1Variant.fromJson(Map<String, dynamic> json) {
    final pairs = QuestionPair.listFromJson(json['question_pairs']);
    // Each kind is keyed into its own answer map by number (`_rfAnswers`,
    // `_mcAnswers` in the screen) independently of the other kind, so
    // uniqueness is checked within each kind across all pairs, not across
    // both combined.
    assertUniqueNumbers(
      pairs.map((p) => p.richtigFalsch?.number).whereType<int>(),
      context: 'richtig_falsch question',
    );
    assertUniqueNumbers(
      pairs.map((p) => p.multipleChoice?.number).whereType<int>(),
      context: 'multiple_choice question',
    );
    return HoerenTeil1Variant(
      variantNumber: asNumOrNull(json['variant_number']),
      version: asString(json['version']),
      questionPairs: pairs,
    );
  }

  static List<HoerenTeil1Variant> listFromJson(Object? raw) => asList(raw)
      .whereType<Map>()
      .map((e) => HoerenTeil1Variant.fromJson(e.cast<String, dynamic>()))
      .toList();
}
