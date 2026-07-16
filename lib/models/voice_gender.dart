enum VoiceGender {
  female,
  male,
  unknown;

  static VoiceGender fromMetadata(Object? value) {
    if (value is! String) return VoiceGender.unknown;
    return switch (value.trim().toLowerCase()) {
      'female' => VoiceGender.female,
      'male' => VoiceGender.male,
      'unknown' => VoiceGender.unknown,
      _ => VoiceGender.unknown,
    };
  }

  static VoiceGender? overrideFromMetadata(Object? value) {
    if (value == null) return null;
    return fromMetadata(value);
  }

  static VoiceGender resolve({
    VoiceGender? manualOverride,
    VoiceGender parsedHint = VoiceGender.unknown,
    String speaker = '',
  }) {
    if (manualOverride != null) return manualOverride;
    if (parsedHint != VoiceGender.unknown) return parsedHint;
    return fromExplicitRole(speaker);
  }

  static VoiceGender fromExplicitRole(String speaker) {
    final role = speaker.trim().split(RegExp(r'\s+')).firstOrNull;
    return switch (role?.toLowerCase()) {
      'frau' => VoiceGender.female,
      'herr' => VoiceGender.male,
      _ => VoiceGender.unknown,
    };
  }

  String? get requestValue => switch (this) {
    VoiceGender.female => 'female',
    VoiceGender.male => 'male',
    VoiceGender.unknown => null,
  };

  String get storageValue => switch (this) {
    VoiceGender.female => 'female',
    VoiceGender.male => 'male',
    VoiceGender.unknown => 'unknown',
  };
}

class VoiceGenderMetadata {
  const VoiceGenderMetadata({
    this.voiceGender = VoiceGender.unknown,
    this.speakerVoiceGenders = const {},
  });

  static const empty = VoiceGenderMetadata();

  final VoiceGender voiceGender;
  final Map<String, VoiceGender> speakerVoiceGenders;

  factory VoiceGenderMetadata.fromMetadata(Object? value) {
    if (value is! Map) return empty;
    final monologueGender = VoiceGender.fromMetadata(value['voice_gender']);
    final speakerHints = <String, VoiceGender>{};
    final rawSpeakerHints = value['speaker_voice_genders'];
    if (rawSpeakerHints is List) {
      for (final rawHint in rawSpeakerHints) {
        if (rawHint is! Map) continue;
        final speaker = rawHint['speaker'];
        if (speaker is! String || speaker.trim().isEmpty) continue;
        final gender = VoiceGender.fromMetadata(rawHint['voice_gender']);
        if (gender == VoiceGender.unknown) continue;
        speakerHints[_speakerKey(speaker)] = gender;
      }
    }
    if (monologueGender == VoiceGender.unknown && speakerHints.isEmpty) {
      return empty;
    }
    return VoiceGenderMetadata(
      voiceGender: monologueGender,
      speakerVoiceGenders: Map.unmodifiable(speakerHints),
    );
  }

  static String speakerKey(String speaker) => _speakerKey(speaker);

  VoiceGender genderForSpeaker(String speaker) =>
      speakerVoiceGenders[_speakerKey(speaker)] ?? VoiceGender.unknown;
}

String _speakerKey(String speaker) =>
    speaker.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

String scopedVoiceRecordingId(String courseId, String recordingId) =>
    '${Uri.encodeComponent(courseId)}:$recordingId';
