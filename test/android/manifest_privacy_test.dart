// CR-12: guards the Android manifest privacy decisions against silent
// regressions — no storage/media permission this app doesn't actually use
// (the PDF picker goes through the Storage Access Framework, which needs
// none), automatic backup/device-transfer disabled (locally-cached course
// data is UID-scoped and only ever a Firestore mirror — see
// CourseStorage.loadAll's cross-device merge — and must not survive an
// account deletion in a stale Google backup snapshot), and a real display
// name instead of the raw package-ish "exam_trainer".
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'manifest requests no storage/media permission the app does not need',
    () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      // Checked as actual <uses-permission> declarations, not a bare
      // substring match — this file's own explanatory comment mentions
      // these permission names by name to document why they were removed.
      expect(
        manifest,
        isNot(contains('android.permission.READ_EXTERNAL_STORAGE"')),
      );
      expect(
        manifest,
        isNot(contains('android.permission.READ_MEDIA_IMAGES"')),
      );
      expect(
        manifest,
        isNot(contains('android.permission.WRITE_EXTERNAL_STORAGE"')),
      );
      // INTERNET is the one permission this app genuinely needs (every
      // backend call, TTS, Firebase Auth).
      expect(manifest, contains('android.permission.INTERNET"'));
    },
  );

  test('automatic backup/device-transfer of local app data is disabled', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:allowBackup="false"'));
  });

  test('app has a real display name, not the raw package identifier', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, isNot(contains('android:label="exam_trainer"')));
    expect(manifest, contains('android:label="Exam Trainer"'));
  });
}
