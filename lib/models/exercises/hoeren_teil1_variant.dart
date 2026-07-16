import 'exercise_common.dart';
import '../voice_gender.dart';

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
    this.voiceMetadata = VoiceGenderMetadata.empty,
    this.voiceGender = VoiceGender.unknown,
    this.recordingId = 'hoeren_teil1:vindex-1:original:pair-1',
  });

  final String dialogue;
  final RichtigFalschQuestion? richtigFalsch;
  final MultipleChoiceQuestion? multipleChoice;
  final VoiceGenderMetadata voiceMetadata;
  final VoiceGender voiceGender;
  final String recordingId;

  factory QuestionPair.fromJson(
    Map<String, dynamic> json, {
    num? variantNumber,
    int variantIndex = 0,
    String? version,
    int pairIndex = 0,
  }) {
    final rf = asMapOrNull(json['richtig_falsch']);
    final mc = asMapOrNull(json['multiple_choice']);
    final ownMetadata = VoiceGenderMetadata.fromMetadata(json['metadata']);
    return QuestionPair(
      dialogue: asString(json['dialogue']),
      richtigFalsch: rf != null ? RichtigFalschQuestion.fromJson(rf) : null,
      multipleChoice: mc != null ? MultipleChoiceQuestion.fromJson(mc) : null,
      voiceMetadata: ownMetadata,
      voiceGender: ownMetadata.voiceGender,
      recordingId: stableVariantRecordingId(
        sectionType: 'hoeren_teil1',
        variantNumber: variantNumber,
        variantIndex: variantIndex,
        version: version,
        slot: 'pair-${pairIndex + 1}',
      ),
    );
  }

  static List<QuestionPair> listFromJson(
    Object? raw, {
    num? variantNumber,
    int variantIndex = 0,
    String? version,
  }) {
    final maps = asList(raw).whereType<Map>().toList();
    return [
      for (var i = 0; i < maps.length; i++)
        QuestionPair.fromJson(
          maps[i].cast<String, dynamic>(),
          variantNumber: variantNumber,
          variantIndex: variantIndex,
          version: version,
          pairIndex: i,
        ),
    ];
  }
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

  factory HoerenTeil1Variant.fromJson(
    Map<String, dynamic> json, {
    int variantIndex = 0,
  }) {
    final variantNumber = asNumOrNull(json['variant_number']);
    final version = asString(json['version']);
    final pairs = QuestionPair.listFromJson(
      json['question_pairs'],
      variantNumber: variantNumber,
      variantIndex: variantIndex,
      version: version,
    );
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
      variantNumber: variantNumber,
      version: version,
      questionPairs: pairs,
    );
  }

  static List<HoerenTeil1Variant> listFromJson(Object? raw) {
    final maps = asList(raw).whereType<Map>().toList();
    return [
      for (var i = 0; i < maps.length; i++)
        HoerenTeil1Variant.fromJson(
          maps[i].cast<String, dynamic>(),
          variantIndex: i,
        ),
    ];
  }
}
