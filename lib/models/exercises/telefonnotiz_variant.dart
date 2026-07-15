// Typed view over one telefonnotiz variant — nests multiple "editions"
// under `versions`, each with its own dictation answer.

import 'exercise_common.dart';

/// The five structured fields Hören + Schreiben expects to extract from
/// the dictated call. Each defaults to `''` — the same fallback every
/// current read site already applies — and [kNoAnswerSentinel] (see
/// exercise_common.dart) is a valid, real value for any of them when the
/// source genuinely had nothing to extract.
class TelefonnotizAnswer {
  const TelefonnotizAnswer({
    required this.callType,
    required this.name,
    required this.telefonnummer,
    required this.zuErledigen,
    required this.weitereInformationen,
  });

  final String callType;
  final String name;
  final String telefonnummer;
  final String zuErledigen;
  final List<String> weitereInformationen;

  factory TelefonnotizAnswer.fromJson(Map<String, dynamic> json) =>
      TelefonnotizAnswer(
        callType: json['call_type']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        telefonnummer: json['telefonnummer']?.toString() ?? '',
        zuErledigen: json['zu_erledigen']?.toString() ?? '',
        // Each element is coerced with toString() rather than the
        // screen's previous `.cast<String>()`, which threw on a single
        // non-String bullet instead of degrading just that one entry.
        weitereInformationen: asList(
          json['weitere_informationen'],
        ).map((e) => e.toString()).toList(),
      );

  static const empty = TelefonnotizAnswer(
    callType: '',
    name: '',
    telefonnummer: '',
    zuErledigen: '',
    weitereInformationen: [],
  );
}

class TelefonnotizEdition {
  const TelefonnotizEdition({
    required this.audioUrl,
    required this.monologue,
    required this.label,
    required this.answer,
  });

  final String? audioUrl;
  final String monologue;
  final String? label;
  final TelefonnotizAnswer answer;

  factory TelefonnotizEdition.fromJson(Map<String, dynamic> json) {
    final answerJson = asMapOrNull(json['answer']);
    return TelefonnotizEdition(
      audioUrl: asStringOrNull(json['audio_url']),
      monologue: asString(json['monologue']),
      label: asStringOrNull(json['label']),
      answer: answerJson != null
          ? TelefonnotizAnswer.fromJson(answerJson)
          : TelefonnotizAnswer.empty,
    );
  }

  static List<TelefonnotizEdition> listFromJson(Object? raw) => asList(raw)
      .whereType<Map>()
      .map((e) => TelefonnotizEdition.fromJson(e.cast<String, dynamic>()))
      .toList();
}

class TelefonnotizVariant {
  const TelefonnotizVariant({
    required this.variantNumber,
    required this.topic,
    required this.versions,
  });

  final num? variantNumber;
  final String topic;
  final List<TelefonnotizEdition> versions;

  num displayNumber(int index) => variantNumber ?? (index + 1);

  factory TelefonnotizVariant.fromJson(Map<String, dynamic> json) =>
      TelefonnotizVariant(
        variantNumber: asNumOrNull(json['variant_number']),
        topic: asString(json['topic']),
        versions: TelefonnotizEdition.listFromJson(json['versions']),
      );

  static List<TelefonnotizVariant> listFromJson(Object? raw) => asList(raw)
      .whereType<Map>()
      .map((e) => TelefonnotizVariant.fromJson(e.cast<String, dynamic>()))
      .toList();
}
