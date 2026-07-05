import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/import_screen.dart';
import 'screens/course_screen.dart';
import 'screens/section_list_screen.dart';
import 'screens/hoeren_teil1_exercise_screen.dart';
import 'screens/telefonnotiz_exercise_screen.dart';
import 'screens/sprachbausteine_exercise_screen.dart';

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
                  _ => HoerenTeil1ExerciseScreen(
                      courseId: courseId, index: index),
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
