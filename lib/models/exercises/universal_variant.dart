import 'exercise_common.dart';

/// Typed view over one variant of the "universal" schema shared by
/// lesen_teil1-4, hoeren_teil2-4, beschwerde and sprachbausteine_teil2 (see
/// parse_service's `_validateUniversal` dispatch, which validates all of
/// these the same way). `beschwerde`/`sprachbausteine_teil2` only consume a
/// subset of these fields — reusing one DTO here matches the actual shared
/// backend schema rather than inventing eight near-duplicate types.
class UniversalVariant {
  const UniversalVariant({
    required this.variantNumber,
    required this.topic,
    required this.version,
    required this.audioUrl,
    required this.texts,
    required this.optionPool,
    required this.questions,
  });

  /// Raw variant number as sent by parse (almost always an int, but never
  /// cast/enforced by the screens today — kept as `num?` rather than
  /// forcing a non-null `int` so a missing value degrades to the caller's
  /// `displayNumber` fallback instead of crashing during parsing).
  final num? variantNumber;
  final String topic;
  final String version;
  final String? audioUrl;
  final List<ExerciseText> texts;
  final List<ExerciseOption> optionPool;
  final List<ExerciseQuestion> questions;

  /// `variant_number ?? (index + 1)` — the exact fallback every consuming
  /// screen already applies.
  num displayNumber(int index) => variantNumber ?? (index + 1);

  factory UniversalVariant.fromJson(
    Map<String, dynamic> json, {
    String sectionType = 'universal',
    int variantIndex = 0,
  }) {
    final variantNumber = asNumOrNull(json['variant_number']);
    final version = asString(json['version']);
    return UniversalVariant(
      variantNumber: variantNumber,
      topic: asString(json['topic']),
      version: version,
      audioUrl: asStringOrNull(json['audio_url']),
      texts: ExerciseText.listFromJson(
        json['texts'],
        sectionType: sectionType,
        variantNumber: variantNumber,
        variantIndex: variantIndex,
        version: version,
      ),
      optionPool: ExerciseOption.listFromJson(json['option_pool']),
      questions: ExerciseQuestion.listFromJson(json['questions']),
    );
  }

  static List<UniversalVariant> listFromJson(
    Object? raw, {
    String sectionType = 'universal',
  }) {
    final maps = asList(raw).whereType<Map>().toList();
    return [
      for (var i = 0; i < maps.length; i++)
        UniversalVariant.fromJson(
          maps[i].cast<String, dynamic>(),
          sectionType: sectionType,
          variantIndex: i,
        ),
    ];
  }
}
