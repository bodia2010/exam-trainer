import 'dart:ui' show SemanticsAction;

import 'package:exam_trainer/models/parsed_course.dart';
import 'package:exam_trainer/screens/sprachbausteine2_exercise_screen.dart';
import 'package:exam_trainer/screens/sprachbausteine_exercise_screen.dart';
import 'package:exam_trainer/services/favorites_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FavoritesService.debugUidOverride = 'sprachbausteine-a11y-smoke-user';
  });

  tearDown(() {
    FavoritesService.debugUidOverride = null;
  });

  testWidgets(
    'both Sprachbausteine screens remain accessible at 200% text scale',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpScreen(tester, const _Teil1Fixture());
        await _verifyGapSemantics(tester);

        final teil1Dropdown = find.byType(DropdownButton<int>).first;
        await tester.ensureVisible(teil1Dropdown);
        await tester.tap(teil1Dropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('damit').last);
        await tester.pumpAndSettle();

        expect(tester.widget<DropdownButton<int>>(teil1Dropdown).value, 0);
        expect(tester.takeException(), isNull);

        await _pumpScreen(tester, const _Teil2Fixture());
        await _verifyGapSemantics(tester);

        final teil2Dropdown = find.byType(DropdownButton<String>).first;
        await tester.ensureVisible(teil2Dropdown);
        await tester.tap(teil2Dropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('obwohl').last);
        await tester.pumpAndSettle();

        expect(tester.widget<DropdownButton<String>>(teil2Dropdown).value, 'a');
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
}

Future<void> _pumpScreen(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
        child: child!,
      ),
      home: screen,
    ),
  );
  await tester.pumpAndSettle();

  expect(find.byType(SingleChildScrollView), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Future<void> _verifyGapSemantics(WidgetTester tester) async {
  for (final number in const [52, 53]) {
    final gap = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == 'Gap $number, choose answer',
      description: 'Semantics for PDF gap [$number]',
    );
    expect(gap, findsOneWidget);

    final data = tester.getSemantics(gap).getSemanticsData();
    expect(data.label, contains('Gap $number, choose answer'));
    expect(data.hasAction(SemanticsAction.tap), isTrue);
  }
}

class _Teil1Fixture extends StatelessWidget {
  const _Teil1Fixture();

  @override
  Widget build(BuildContext context) => SprachbausteineExerciseScreen(
    courseId: _courseId,
    index: 0,
    courseLoader: _loadCourse,
  );
}

class _Teil2Fixture extends StatelessWidget {
  const _Teil2Fixture();

  @override
  Widget build(BuildContext context) => Sprachbausteine2ExerciseScreen(
    courseId: _courseId,
    index: 0,
    courseLoader: _loadCourse,
  );
}

const _courseId = 'sprachbausteine-a11y-course';

Future<List<ParsedCourse>> _loadCourse() async => [_course];

final _course = ParsedCourse(
  id: _courseId,
  title: 'Sprachbausteine accessibility fixture',
  sourceFilename: 'sprachbausteine_fixture.pdf',
  parsedAt: _fixtureDate,
  sections: {
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

final _fixtureDate = DateTime.utc(2026, 7, 16);
