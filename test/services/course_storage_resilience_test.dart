import 'dart:io';

import 'package:exam_trainer/models/parsed_course.dart';
import 'package:exam_trainer/services/course_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;

  ParsedCourse course(String id, String title) => ParsedCourse(
    id: id,
    title: title,
    sourceFilename: '$id.pdf',
    parsedAt: DateTime(2026),
    sections: const {},
  );

  setUp(() {
    root = Directory.systemTemp.createTempSync('course_storage_resilience_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(root.path);
    SharedPreferences.setMockInitialValues({});
    CourseStorage.debugUidOverride = 'resilience-user';
    CourseStorage.debugIdTokenOverride = () async => 'test-token';
    CourseStorage.debugHttpClient = MockClient((request) async {
      if (request.method == 'GET') return http.Response('{"courses":[]}', 200);
      return http.Response('{"saved":true}', 200);
    });
  });

  tearDown(() async {
    await CourseStorage.instance.debugPendingFlush;
    CourseStorage.instance.debugResetSyncStateForTests();
    CourseStorage.debugUidOverride = null;
    CourseStorage.debugBeforeLocalCommit = null;
    CourseStorage.debugIdTokenOverride = null;
    CourseStorage.debugHttpClient = null;
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  File storedFile(String id) =>
      File('${root.path}/courses/resilience-user/$id.json');

  test('corrupt JSON for one course does not hide valid courses', () async {
    await CourseStorage.instance.save(course('valid', 'Valid course'));
    await CourseStorage.instance.save(course('corrupt', 'Before corruption'));
    const corruptBytes = '{incomplete json';
    await storedFile('corrupt').writeAsString(corruptBytes);

    final loaded = await CourseStorage.instance.loadAll();

    expect(loaded.map((item) => item.id), ['valid']);
    expect(await storedFile('corrupt').readAsString(), corruptBytes);
    expect(
      await File('${storedFile('corrupt').path}.corrupt').readAsString(),
      corruptBytes,
      reason: 'cloud restore must not destroy the diagnostic bytes',
    );
    await CourseStorage.instance.loadAll();
    expect(
      File('${storedFile('corrupt').path}.corrupt.1').existsSync(),
      isFalse,
      reason: 'identical corruption must not create unbounded duplicate files',
    );
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('course_ids_resilience-user'),
      contains('corrupt'),
    );
  });

  test('interrupted replacement preserves the last valid course', () async {
    await CourseStorage.instance.save(course('stable', 'Last valid'));
    CourseStorage.debugBeforeLocalCommit = (_, _) {
      throw const FileSystemException('simulated commit interruption');
    };

    await expectLater(
      CourseStorage.instance.save(course('stable', 'Interrupted update')),
      throwsA(isA<FileSystemException>()),
    );

    CourseStorage.debugBeforeLocalCommit = null;
    final loaded = await CourseStorage.instance.loadAll();
    expect(loaded.single.title, 'Last valid');
  });

  test(
    'missing file listed in preferences is skipped and cleaned up',
    () async {
      SharedPreferences.setMockInitialValues({
        'course_ids_resilience-user': ['missing'],
      });

      expect(await CourseStorage.instance.loadAll(), isEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('course_ids_resilience-user'), isEmpty);
    },
  );
}
