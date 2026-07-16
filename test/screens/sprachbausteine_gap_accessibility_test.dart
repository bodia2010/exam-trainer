import 'dart:ui' show SemanticsAction;

import 'package:exam_trainer/models/parsed_course.dart';
import 'package:exam_trainer/screens/sprachbausteine2_exercise_screen.dart';
import 'package:exam_trainer/screens/sprachbausteine_exercise_screen.dart';
import 'package:exam_trainer/services/favorites_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FavoritesService.debugUidOverride = 'gap-accessibility-test-user';
  });

  tearDown(() {
    FavoritesService.debugUidOverride = null;
  });

  group('Sprachbausteine gap accessibility', () {
    const localizedLabels = <String, List<String>>{
      'de': ['Lücke 52, Antwort auswählen', 'Lücke 53, Antwort auswählen'],
      'ru': ['Пропуск 52, выбрать ответ', 'Пропуск 53, выбрать ответ'],
      'uk': ['Пропуск 52, вибрати відповідь', 'Пропуск 53, вибрати відповідь'],
      'en': ['Gap 52, choose answer', 'Gap 53, choose answer'],
    };

    for (final screen in <String, Widget Function(Locale)>{
      'Teil 1': (locale) => _teil1Screen(),
      'Teil 2': (locale) => _teil2Screen(),
    }.entries) {
      testWidgets('${screen.key} exposes a localized label for every gap', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();

        for (final labels in localizedLabels.entries) {
          await _pumpScreen(
            tester,
            locale: Locale(labels.key),
            home: screen.value(Locale(labels.key)),
          );

          for (final label in labels.value) {
            final gap = _semanticsWithLabel(label);
            expect(gap, findsOneWidget);
            final data = tester.getSemantics(gap).getSemanticsData();
            expect(data.label, contains(label));
            expect(
              data.hasAction(SemanticsAction.tap),
              isTrue,
              reason:
                  '${screen.key} must identify the actual PDF gap number in '
                  'locale ${labels.key} without losing the dropdown action',
            );
          }
        }
        semantics.dispose();
      });
    }

    testWidgets('Teil 1 labelled dropdown remains interactive', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpScreen(
        tester,
        locale: const Locale('en'),
        home: _teil1Screen(),
      );

      await tester.tap(find.byType(DropdownButton<int>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('damit').last);
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>).first,
      );
      expect(dropdown.value, 0);
      final data = tester
          .getSemantics(_semanticsWithLabel('Gap 52, choose answer'))
          .getSemanticsData();
      expect(data.label, contains('Gap 52, choose answer'));
      expect('${data.label} ${data.value}', contains('damit'));
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets(
      'Teil 1 keeps a long selected word accessible on a narrow phone',
      (tester) async {
        final semantics = tester.ensureSemantics();
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await _pumpScreen(
          tester,
          locale: const Locale('en'),
          home: _longTeil1Screen(),
          textScale: 2,
        );

        expect(tester.takeException(), isNull);
        final gap = _semanticsWithLabel('Gap 52, choose answer');
        expect(gap, findsOneWidget);
        await tester.tap(find.byType(DropdownButton<int>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('very long replacement instruction').last);
        await tester.pumpAndSettle();

        final data = tester.getSemantics(gap).getSemanticsData();
        expect(
          '${data.label} ${data.value}',
          contains('very long replacement instruction'),
        );
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        semantics.dispose();
      },
    );

    testWidgets('Teil 2 labelled dropdown remains interactive', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpScreen(
        tester,
        locale: const Locale('en'),
        home: _teil2Screen(),
      );

      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('obwohl').last);
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>).first,
      );
      expect(dropdown.value, 'a');
      final data = tester
          .getSemantics(_semanticsWithLabel('Gap 52, choose answer'))
          .getSemanticsData();
      expect(data.label, contains('Gap 52, choose answer'));
      expect('${data.label} ${data.value}', contains('obwohl'));
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    for (final screen in <String, Widget>{
      'Teil 1': _teil1Screen(),
      'Teil 2': _teil2Screen(),
    }.entries) {
      testWidgets(
        '${screen.key} renders at 200% text scale on a phone viewport',
        (tester) async {
          tester.view.physicalSize = const Size(412, 915);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await _pumpScreen(
            tester,
            // Russian is the widest supported UI locale here and catches
            // action-bar/layout regressions that a short English label may
            // hide at the same 200% scale.
            locale: const Locale('ru'),
            home: screen.value,
            textScale: 2,
          );

          expect(find.byType(SingleChildScrollView), findsOneWidget);
          final dropdowns = find.byWidgetPredicate(
            (widget) => widget is DropdownButton,
          );
          expect(dropdowns, findsNWidgets(2));
          for (var i = 0; i < 2; i++) {
            expect(
              tester.getRect(dropdowns.at(i)).height,
              greaterThanOrEqualTo(48),
              reason: 'every gap must remain a 48dp touch target',
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}

Finder _semanticsWithLabel(String label) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == label,
  description: 'Semantics(label: $label)',
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required Locale locale,
  required Widget home,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [
        Locale('de'),
        Locale('ru'),
        Locale('uk'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

Widget _teil1Screen() => SprachbausteineExerciseScreen(
  courseId: 'course-1',
  index: 0,
  courseLoader: () async => [_course()],
);

Widget _teil2Screen() => Sprachbausteine2ExerciseScreen(
  courseId: 'course-1',
  index: 0,
  courseLoader: () async => [_course()],
);

Widget _longTeil1Screen() => SprachbausteineExerciseScreen(
  courseId: 'course-long',
  index: 0,
  courseLoader: () async => [_longCourse()],
);

ParsedCourse _longCourse() => ParsedCourse(
  id: 'course-long',
  title: 'Long option fixture',
  sourceFilename: 'fixture.pdf',
  parsedAt: DateTime(2026, 7, 17),
  sections: const {
    'sprachbausteine_teil1': [
      {
        'variant_number': 1,
        'letter_text': 'Heute [52] wir lernen und [53] wir üben.',
        'all_options': [
          {'letter': 'a', 'text': 'very long replacement instruction'},
          {'letter': 'b', 'text': 'deshalb'},
        ],
        'answers': [
          {
            'question_number': 52,
            'letter': 'a',
            'word': 'very long replacement instruction',
          },
          {'question_number': 53, 'letter': 'b', 'word': 'deshalb'},
        ],
      },
    ],
  },
);

ParsedCourse _course() => ParsedCourse(
  id: 'course-1',
  title: 'Accessibility fixture',
  sourceFilename: 'fixture.pdf',
  parsedAt: DateTime(2026, 7, 16),
  sections: const {
    'sprachbausteine_teil1': [
      {
        'variant_number': 1,
        'letter_text': 'Heute [52] wir lernen und [53] wir üben.',
        'all_options': [
          {'letter': 'a', 'text': 'damit'},
          {'letter': 'b', 'text': 'deshalb'},
        ],
        'answers': [
          {'question_number': 52, 'letter': 'a', 'word': 'damit'},
          {'question_number': 53, 'letter': 'b', 'word': 'deshalb'},
        ],
      },
    ],
    'sprachbausteine_teil2': [
      {
        'variant_number': 1,
        'texts': [
          {'content': 'Heute [52] wir lernen und [53] wir üben.'},
        ],
        'questions': [
          {
            'number': 52,
            'answer': 'a',
            'options': [
              {'letter': 'a', 'text': 'obwohl'},
              {'letter': 'b', 'text': 'darum'},
            ],
          },
          {
            'number': 53,
            'answer': 'b',
            'options': [
              {'letter': 'a', 'text': 'wenn'},
              {'letter': 'b', 'text': 'weil'},
            ],
          },
        ],
      },
    ],
  },
);
