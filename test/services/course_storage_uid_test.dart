// Tests per-UID isolation in CourseStorage: courses saved while signed in
// as one user must not be visible to a different signed-in user on the
// same device/install (see CourseStorage._uid doc comment).
//
// No real Firebase user is available in a plain `flutter test` run, so the
// UID is swapped via CourseStorage.debugUidOverride (a
// @visibleForTesting-only hook — production code always uses the real
// signed-in Firebase user). path_provider and shared_preferences are faked
// so the test never touches a real device path or persists across runs;
// the cloud-sync half of loadAll() fails fast (no Firebase app configured)
// and is swallowed by CourseStorage's own try/catch, so no network call is
// ever attempted either.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exam_trainer/models/parsed_course.dart';
import 'package:exam_trainer/services/course_storage.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this._root);
  final String _root;

  @override
  Future<String?> getApplicationDocumentsPath() async => _root;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('course_storage_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempRoot.path);
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    CourseStorage.debugUidOverride = null;
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  ParsedCourse course(String id, String title) => ParsedCourse(
        id: id,
        title: title,
        sourceFilename: '$id.pdf',
        parsedAt: DateTime(2026, 1, 1),
        sections: const {},
      );

  test('a course saved under one UID is invisible to a different UID', () async {
    CourseStorage.debugUidOverride = 'uidA';
    await CourseStorage.instance.save(course('course-a', 'Course A'));

    CourseStorage.debugUidOverride = 'uidB';
    await CourseStorage.instance.save(course('course-b', 'Course B'));

    CourseStorage.debugUidOverride = 'uidA';
    final coursesA = await CourseStorage.instance.loadAll();
    expect(coursesA.map((c) => c.id), equals(['course-a']));

    CourseStorage.debugUidOverride = 'uidB';
    final coursesB = await CourseStorage.instance.loadAll();
    expect(coursesB.map((c) => c.id), equals(['course-b']));
  });

  test('a UID that never saved anything sees an empty course list', () async {
    CourseStorage.debugUidOverride = 'uidA';
    await CourseStorage.instance.save(course('course-a', 'Course A'));

    CourseStorage.debugUidOverride = 'brand-new-uid';
    final courses = await CourseStorage.instance.loadAll();
    expect(courses, isEmpty);
  });
}
