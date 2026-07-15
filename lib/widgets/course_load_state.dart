import 'package:flutter/material.dart';

import '../models/parsed_course.dart';
import '../ui/core/theme/exam_theme.dart';

typedef CourseLoader = Future<List<ParsedCourse>> Function();

enum CourseLoadFailure { notFound, error }

/// A terminal course-loading state shared by course and exercise screens.
///
/// The message is intentionally user-facing and never includes the caught
/// exception or a backend response body.
class CourseLoadFailureView extends StatelessWidget {
  const CourseLoadFailureView({
    super.key,
    required this.failure,
    required this.onRetry,
    this.accent = ExamColors.teal,
  });

  final CourseLoadFailure failure;
  final VoidCallback onRetry;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final notFound = failure == CourseLoadFailure.notFound;
    final message = switch (language) {
      'de' =>
        notFound
            ? 'Dieser Kurs oder diese Übung wurde nicht gefunden.'
            : 'Der Kurs konnte nicht geladen werden. Bitte versuche es erneut.',
      'ru' =>
        notFound
            ? 'Курс или упражнение не найдено.'
            : 'Не удалось загрузить курс. Попробуйте ещё раз.',
      'uk' =>
        notFound
            ? 'Курс або вправу не знайдено.'
            : 'Не вдалося завантажити курс. Спробуйте ще раз.',
      _ =>
        notFound
            ? 'This course or exercise could not be found.'
            : 'The course could not be loaded. Please try again.',
    };
    final retry = switch (language) {
      'de' => 'Erneut versuchen',
      'ru' => 'Повторить',
      'uk' => 'Повторити',
      _ => 'Retry',
    };
    final back = switch (language) {
      'de' => 'Zurück',
      'ru' => 'Назад',
      'uk' => 'Назад',
      _ => 'Back',
    };

    return Center(
      key: ValueKey(notFound ? 'course-load-not-found' : 'course-load-error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              notFound ? Icons.search_off_rounded : Icons.error_outline_rounded,
              size: 48,
              color: accent,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: ExamColors.ink),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const ValueKey('course-load-retry'),
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: accent),
              icon: const Icon(Icons.refresh),
              label: Text(retry),
            ),
            TextButton.icon(
              key: const ValueKey('course-load-back'),
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back),
              label: Text(back),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseLoadScaffold extends StatelessWidget {
  const CourseLoadScaffold({
    super.key,
    required this.loading,
    required this.failure,
    required this.onRetry,
    this.accent = ExamColors.teal,
  });

  final bool loading;
  final CourseLoadFailure? failure;
  final VoidCallback onRetry;
  final Color accent;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ExamColors.canvas,
    body: loading
        ? Center(
            key: const ValueKey('course-load-loading'),
            child: CircularProgressIndicator(color: accent),
          )
        : CourseLoadFailureView(
            failure: failure!,
            onRetry: onRetry,
            accent: accent,
          ),
  );
}
