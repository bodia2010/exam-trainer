import 'package:exam_trainer/models/parsed_course.dart';
import 'package:exam_trainer/screens/universal_exercise_screen.dart';
import 'package:exam_trainer/repositories/voice_preference_repository.dart';
import 'package:exam_trainer/services/favorites_service.dart';
import 'package:exam_trainer/widgets/dialogue_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FavoritesService.debugUidOverride = 'audio-collapse-test-user';
    VoicePreferenceRepository.debugUidOverride = 'audio-collapse-test-user';
  });

  tearDown(() {
    FavoritesService.debugUidOverride = null;
    VoicePreferenceRepository.debugUidOverride = null;
  });

  testWidgets('collapsing a Hoeren transcript keeps its audio player mounted', (
    tester,
  ) async {
    final course = ParsedCourse(
      id: 'course-1',
      title: 'Audio course',
      sourceFilename: 'fixture.pdf',
      parsedAt: DateTime(2026, 7, 16),
      sections: const {
        'hoeren_teil4': [
          {
            'variant_number': 1,
            'texts': [
              {
                'title': 'Nummer 40 Bernhardt',
                'content': 'Bernhardt, Geschäftsleitung. Guten Tag.',
                'metadata': {'voice_gender': 'female'},
              },
            ],
            'questions': [
              {
                'number': 40,
                'text': 'Frau Bernhardt',
                'type': 'choice',
                'answer': 'a',
                'options': [
                  {'letter': 'a', 'text': 'hat Änderungswünsche.'},
                ],
              },
            ],
          },
        ],
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        home: UniversalExerciseScreen(
          courseId: course.id,
          sectionType: 'hoeren_teil4',
          index: 0,
          courseLoader: () async => [course],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = find.text('Nummer 40 Bernhardt');
    expect(title, findsOneWidget);
    expect(find.byType(DialogueAudioPlayer), findsNothing);
    expect(
      find.byType(DialogueAudioPlayer, skipOffstage: false),
      findsOneWidget,
    );

    await tester.tap(title);
    await tester.pumpAndSettle();
    final playerFinder = find.byType(DialogueAudioPlayer);
    expect(playerFinder, findsOneWidget);
    final mountedState = tester.state(playerFinder);

    await tester.tap(title);
    await tester.pumpAndSettle();

    expect(find.byType(DialogueAudioPlayer), findsNothing);
    final hiddenPlayer = find.byType(DialogueAudioPlayer, skipOffstage: false);
    expect(hiddenPlayer, findsOneWidget);
    expect(tester.state(hiddenPlayer), same(mountedState));

    await tester.scrollUntilVisible(
      find.text('a) hat Änderungswünsche.'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('a) hat Änderungswünsche.'), findsOneWidget);
    expect(find.byType(Divider), findsNothing);
  });
}
