import 'package:flutter_test/flutter_test.dart';

import 'package:exam_trainer/models/voice_gender.dart';

void main() {
  group('VoiceGender', () {
    test('defensively parses backend/parser metadata', () {
      expect(VoiceGender.fromMetadata('female'), VoiceGender.female);
      expect(VoiceGender.fromMetadata('MALE'), VoiceGender.male);
      expect(VoiceGender.fromMetadata(' unknown '), VoiceGender.unknown);
      expect(VoiceGender.fromMetadata('andrea'), VoiceGender.unknown);
      expect(VoiceGender.fromMetadata(42), VoiceGender.unknown);
      expect(VoiceGender.fromMetadata(null), VoiceGender.unknown);
    });

    test('defensively parses nested parser metadata and speaker hints', () {
      final metadata = VoiceGenderMetadata.fromMetadata({
        'voice_gender': 'female',
        'speaker_voice_genders': [
          {'speaker': ' Herr Becker ', 'voice_gender': 'male'},
          {'speaker': '', 'voice_gender': 'female'},
          {'speaker': 'Frau Keller', 'voice_gender': 'feminine'},
          'bad',
        ],
      });

      expect(metadata.voiceGender, VoiceGender.female);
      expect(metadata.genderForSpeaker('Herr Becker'), VoiceGender.male);
      expect(metadata.genderForSpeaker('herr   becker'), VoiceGender.male);
      expect(metadata.genderForSpeaker('Frau Keller'), VoiceGender.unknown);
      expect(
        VoiceGenderMetadata.fromMetadata({'voice_gender': 'other'}).voiceGender,
        VoiceGender.unknown,
      );
      expect(
        VoiceGenderMetadata.fromMetadata('bad'),
        VoiceGenderMetadata.empty,
      );
    });

    test('recording preference IDs are isolated by course', () {
      expect(
        scopedVoiceRecordingId('course/a', 'hoeren_teil4:v1:text-1'),
        'course%2Fa:hoeren_teil4:v1:text-1',
      );
      expect(
        scopedVoiceRecordingId('course-a', 'same-recording'),
        isNot(scopedVoiceRecordingId('course-b', 'same-recording')),
      );
    });

    test(
      'resolution precedence is manual override, parsed hint, role, unknown',
      () {
        expect(
          VoiceGender.resolve(
            manualOverride: VoiceGender.male,
            parsedHint: VoiceGender.female,
            speaker: 'Frau Meier',
          ),
          VoiceGender.male,
        );
        expect(
          VoiceGender.resolve(
            parsedHint: VoiceGender.female,
            speaker: 'Herr Meier',
          ),
          VoiceGender.female,
        );
        expect(VoiceGender.resolve(speaker: 'Frau Meier'), VoiceGender.female);
        expect(VoiceGender.resolve(speaker: 'Herr Meier'), VoiceGender.male);
        expect(
          VoiceGender.resolve(speaker: 'Andrea Faber'),
          VoiceGender.unknown,
        );
      },
    );
  });
}
