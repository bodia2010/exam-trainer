import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/import_screen.dart';
import 'screens/course_screen.dart';
import 'screens/section_list_screen.dart';
import 'screens/hoeren_teil1_exercise_screen.dart';
import 'screens/telefonnotiz_exercise_screen.dart';
import 'screens/sprachbausteine_exercise_screen.dart';
import 'screens/sprachbausteine2_exercise_screen.dart';
import 'screens/beschwerde_exercise_screen.dart';
import 'screens/universal_exercise_screen.dart';
import 'screens/sprechen_screen.dart';
import 'screens/sprechen_teil1_list_screen.dart';
import 'screens/sprechen_exercise_screen.dart';
import 'screens/smalltalk_list_screen.dart';
import 'screens/smalltalk_exercise_screen.dart';
import 'screens/sprechen_teil3_list_screen.dart';
import 'screens/sprechen_teil3_exercise_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/import',
      builder: (_, __) => const ImportScreen(),
    ),
    // Sprechen: a fixed B2 Beruf topic bank, independent of any imported
    // PDF course — lives at the top level, not nested under /course/:id.
    GoRoute(
      path: '/sprechen',
      builder: (_, __) => const SprechenScreen(),
      routes: [
        GoRoute(
          path: 'teil1',
          builder: (_, __) => const SprechenTeil1ListScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => SprechenExerciseScreen(
                  exerciseId: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: 'teil2',
          builder: (_, __) => const SmalltalkListScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => SmalltalkExerciseScreen(
                  exerciseId: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: 'teil3',
          builder: (_, __) => const SprechenTeil3ListScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => SprechenTeil3ExerciseScreen(
                  exerciseId: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/course/:id',
      builder: (_, state) => CourseScreen(id: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: ':section',
          builder: (_, state) => SectionListScreen(
            courseId: state.pathParameters['id']!,
            sectionType: state.pathParameters['section']!,
          ),
          routes: [
            GoRoute(
              path: ':index',
              builder: (_, state) {
                final courseId = state.pathParameters['id']!;
                final section = state.pathParameters['section']!;
                final index = int.parse(state.pathParameters['index']!);
                return switch (section) {
                  'telefonnotiz' => TelefonnotizExerciseScreen(
                      courseId: courseId, index: index),
                  'sprachbausteine_teil1' => SprachbausteineExerciseScreen(
                      courseId: courseId, index: index),
                  'hoeren_teil1' => HoerenTeil1ExerciseScreen(
                      courseId: courseId, index: index),
                  'beschwerde' => BeschwerdeExerciseScreen(
                      courseId: courseId, index: index),
                  'sprachbausteine_teil2' => Sprachbausteine2ExerciseScreen(
                      courseId: courseId, index: index),
                  // All other sections use the universal schema/screen
                  _ => UniversalExerciseScreen(
                      courseId: courseId, sectionType: section, index: index),
                };
              },
            ),
          ],
        ),
      ],
    ),
  ],
);

class ExamTrainerApp extends StatelessWidget {
  const ExamTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Exam Trainer',
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00838F)),
        useMaterial3: true,
      ),
    );
  }
}
