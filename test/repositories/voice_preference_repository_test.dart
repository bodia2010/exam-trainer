import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exam_trainer/models/voice_gender.dart';
import 'package:exam_trainer/repositories/voice_preference_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    VoicePreferenceRepository.debugUidOverride = null;
    VoicePreferenceRepository.debugForceSignedOut = false;
    VoicePreferenceRepository.instance.debugResetForTests();
  });

  tearDown(() {
    VoicePreferenceRepository.debugUidOverride = null;
    VoicePreferenceRepository.debugForceSignedOut = false;
    VoicePreferenceRepository.instance.debugResetForTests();
  });

  test('overrides are isolated by UID', () async {
    final repo = VoicePreferenceRepository.instance;

    VoicePreferenceRepository.debugUidOverride = 'uid-a';
    await repo.setOverride('telefonnotiz:v1:original', VoiceGender.female);

    VoicePreferenceRepository.debugUidOverride = 'uid-b';
    expect(await repo.getOverride('telefonnotiz:v1:original'), isNull);
    await repo.setOverride('telefonnotiz:v1:original', VoiceGender.male);

    VoicePreferenceRepository.debugUidOverride = 'uid-a';
    expect(
      await repo.getOverride('telefonnotiz:v1:original'),
      VoiceGender.female,
    );
  });

  test(
    'signed-out access never creates shared anonymous preferences',
    () async {
      final repo = VoicePreferenceRepository.instance;
      VoicePreferenceRepository.debugForceSignedOut = true;

      await repo.setOverride('recording', VoiceGender.female);

      expect(await repo.getOverride('recording'), isNull);
      expect(await repo.getAllOverrides(), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isNot(contains('voice_preferences_anonymous')));
    },
  );

  test('rapid writes are serialized latest-wins for one UID', () async {
    final repo = VoicePreferenceRepository.instance;
    VoicePreferenceRepository.debugUidOverride = 'uid-latest';

    final first = repo.setOverride(
      'hoeren_teil1:v2:original:pair-1',
      VoiceGender.female,
    );
    final second = repo.setOverride(
      'hoeren_teil1:v2:original:pair-1',
      VoiceGender.male,
    );
    final third = repo.setOverride(
      'hoeren_teil1:v2:original:pair-1',
      VoiceGender.female,
    );
    await Future.wait([first, second, third]);

    expect(
      await repo.getOverride('hoeren_teil1:v2:original:pair-1'),
      VoiceGender.female,
    );
  });

  test(
    'unknown clears an override and account cleanup is UID-explicit',
    () async {
      final repo = VoicePreferenceRepository.instance;

      VoicePreferenceRepository.debugUidOverride = 'delete-user';
      await repo.setOverride('recording', VoiceGender.female);
      await repo.setOverride('cleared', VoiceGender.male);
      await repo.setOverride('cleared', VoiceGender.unknown);

      VoicePreferenceRepository.debugUidOverride = 'keep-user';
      await repo.setOverride('recording', VoiceGender.male);

      await repo.clearAllForUid('delete-user');

      VoicePreferenceRepository.debugUidOverride = 'delete-user';
      expect(await repo.getOverride('recording'), isNull);
      expect(await repo.getOverride('cleared'), isNull);

      VoicePreferenceRepository.debugUidOverride = 'keep-user';
      expect(await repo.getOverride('recording'), VoiceGender.male);
    },
  );
}
