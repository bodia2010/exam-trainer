import 'dart:convert';
import 'dart:io';

import 'package:exam_trainer/models/parsed_course.dart';
import 'package:exam_trainer/screens/course_screen.dart';
import 'package:exam_trainer/screens/home_screen.dart';
import 'package:exam_trainer/screens/section_list_screen.dart';
import 'package:exam_trainer/screens/universal_exercise_screen.dart';
import 'package:exam_trainer/services/favorites_service.dart';
import 'package:exam_trainer/ui/core/theme/exam_theme.dart';
import 'package:exam_trainer/ui/features/home/view_models/home_view_model.dart';
import 'package:exam_trainer/ui/features/startup/startup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'fixtures/pdf_cache_result.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runPdfCourseSmokeTests();
}

void runPdfCourseSmokeTests() {
  testWidgets(
    'authorized fake PDF cache result survives home, exercise and reload',
    (tester) async {
      final tempRoot = Directory.systemTemp.createTempSync('pdf_smoke_');
      addTearDown(() {
        FavoritesService.debugUidOverride = null;
        StartupCoordinator.instance.reset();
        if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
      });

      // The non-empty UID represents an authenticated test account. Both the
      // importer and repository are local fakes and never open an HTTP client.
      const uid = 'authorized-smoke-user';
      FavoritesService.debugUidOverride = uid;
      final repository = _FakeCourseRepository(tempRoot, uid);
      final imported = await _fakeCachedPdfImport();
      await repository.save(imported);

      final firstRevision = ChangeNotifier();
      final firstHome = _homeViewModel(firstRevision, repository);
      final firstRouter = _router(firstHome, repository);
      addTearDown(() {
        firstRouter.dispose();
        firstHome.dispose();
        firstRevision.dispose();
      });

      await tester.pumpWidget(_app(firstRouter));
      await tester.pumpAndSettle();

      expect(find.text('PDF Smoke Course'), findsWidgets);
      await tester.tap(find.byKey(const Key('home_continue_course')));
      await tester.pumpAndSettle();

      expect(find.text('PDF Smoke Course'), findsOneWidget);
      await tester.tap(find.text('Zuordnungsaufgabe').first);
      await tester.pumpAndSettle();

      expect(find.text('Variante 1'), findsOneWidget);
      await tester.tap(find.text('Variante 1'));
      await tester.pumpAndSettle();

      expect(
        find.text('Welche Antwort ist richtig?', findRichText: true),
        findsOneWidget,
      );
      await tester.tap(find.textContaining('a) Die richtige Antwort'));
      await tester.tap(find.text('Prüfen'));
      await tester.pumpAndSettle();
      expect(find.text('1 von 1 richtig'), findsOneWidget);

      // Recreate the app-facing dependencies and read from disk again. The
      // imported course must remain visible after this simulated reload.
      await tester.pumpWidget(const SizedBox.shrink());
      StartupCoordinator.instance.reset();
      final reloadedRepository = _FakeCourseRepository(tempRoot, uid);
      final reloaded = await reloadedRepository.loadAll();
      expect(reloaded.map((course) => course.id), contains('smoke-course'));

      final secondRevision = ChangeNotifier();
      final secondHome = _homeViewModel(secondRevision, reloadedRepository);
      final secondRouter = _router(secondHome, reloadedRepository);
      addTearDown(() {
        secondRouter.dispose();
        secondHome.dispose();
        secondRevision.dispose();
      });

      await tester.pumpWidget(_app(secondRouter));
      await tester.pumpAndSettle();
      expect(find.text('PDF Smoke Course'), findsWidgets);
    },
  );
}

Future<ParsedCourse> _fakeCachedPdfImport() async {
  final json = jsonDecode(pdfCacheResultFixture) as Map<String, dynamic>;
  return ParsedCourse.fromJson(json);
}

HomeViewModel _homeViewModel(
  ChangeNotifier revision,
  _FakeCourseRepository repository,
) => HomeViewModel(
  loadCourses: repository.loadAll,
  loadPremium: () async => true,
  deleteCourse: repository.delete,
  courseRevision: revision,
  authChanges: const Stream.empty(),
);

GoRouter _router(HomeViewModel home, _FakeCourseRepository repository) =>
    GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              HomeScreen(viewModel: home, showAccountControls: false),
        ),
        GoRoute(
          path: '/course/:id',
          builder: (_, state) => CourseScreen(
            id: state.pathParameters['id']!,
            courseLoader: repository.loadAll,
          ),
          routes: [
            GoRoute(
              path: ':section',
              builder: (_, state) => SectionListScreen(
                courseId: state.pathParameters['id']!,
                sectionType: state.pathParameters['section']!,
                courseLoader: repository.loadAll,
              ),
              routes: [
                GoRoute(
                  path: ':index',
                  builder: (_, state) => UniversalExerciseScreen(
                    courseId: state.pathParameters['id']!,
                    sectionType: state.pathParameters['section']!,
                    index: int.parse(state.pathParameters['index']!),
                    courseLoader: repository.loadAll,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

class _FakeCourseRepository {
  _FakeCourseRepository(this.root, this.uid) : assert(uid != '');

  final Directory root;
  final String uid;

  Directory get _directory => Directory('${root.path}/courses/$uid');

  Future<void> save(ParsedCourse course) async {
    _directory.createSync(recursive: true);
    File(
      '${_directory.path}/${course.id}.json',
    ).writeAsStringSync(jsonEncode(course.toJson()), flush: true);
  }

  Future<List<ParsedCourse>> loadAll() async {
    if (!_directory.existsSync()) return [];
    final courses = <ParsedCourse>[];
    for (final entity in _directory.listSync()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      final json =
          jsonDecode(entity.readAsStringSync()) as Map<String, dynamic>;
      courses.add(ParsedCourse.fromJson(json));
    }
    return courses;
  }

  Future<void> delete(String id) async {
    final file = File('${_directory.path}/$id.json');
    if (file.existsSync()) file.deleteSync();
  }
}

Widget _app(GoRouter router) => MaterialApp.router(
  theme: ExamTheme.light(),
  locale: const Locale('de'),
  supportedLocales: const [Locale('de')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  routerConfig: router,
);
