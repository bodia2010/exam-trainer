// Tests for buildContentSpan — renders "**heading**" markers (see
// prompts.py's HEADINGS rule) as bold TextSpans instead of showing the
// literal asterisks, so a passage's internal sub-headings (e.g. a
// Protokoll's "TOP 1 ..." agenda items) read as visually distinct from
// body prose, matching how they're set apart in the source PDF.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_trainer/models/parsed_course.dart';
import 'package:exam_trainer/repositories/voice_preference_repository.dart';
import 'package:exam_trainer/screens/universal_exercise_screen.dart';
import 'package:exam_trainer/services/favorites_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('buildContentSpan', () {
    test('plain text with no headings becomes a single span', () {
      final span = buildContentSpan('Ein ganz normaler Absatz ohne Titel.');
      expect(span.children, hasLength(1));
      expect(span.children!.single, isA<TextSpan>());
      expect(
        (span.children!.single as TextSpan).text,
        'Ein ganz normaler Absatz ohne Titel.',
      );
      expect(
        (span.children!.single as TextSpan).style!.fontWeight,
        isNot(FontWeight.w700),
      );
    });

    test(
      'a single heading in the middle produces three spans: body, bold, body',
      () {
        final span = buildContentSpan(
          'Vorher. **TOP 1 Begrüßung** Nachher.',
          sectionType: 'lesen_teil4',
        );
        final children = span.children!.cast<TextSpan>();
        expect(children, hasLength(3));
        expect(children[0].text, 'Vorher.\n\n');
        expect(children[0].style!.fontWeight, isNot(FontWeight.w700));
        expect(children[1].text, 'TOP 1 Begrüßung');
        expect(children[1].style!.fontWeight, FontWeight.w700);
        expect(children[2].text, '\n\nNachher.');
        expect(children[2].style!.fontWeight, isNot(FontWeight.w700));
      },
    );

    test('a heading at the very start has no leading body span', () {
      final span = buildContentSpan(
        '**Zugangskontrolle und Zeiterfassung**\nRest des Textes.',
        sectionType: 'lesen_teil4',
      );
      final children = span.children!.cast<TextSpan>();
      expect(children, hasLength(2));
      expect(children[0].text, 'Zugangskontrolle und Zeiterfassung');
      expect(children[0].style!.fontWeight, FontWeight.w700);
      expect(children[1].text, '\n\nRest des Textes.');
    });

    test('flat Protokoll metadata is restored as labelled lines', () {
      final span = buildContentSpan(
        'Protokoll 20.06.20XX, 10.00-12.00 '
        'Besprechungsraum: 032, Ort: Hannover '
        'Teilnehmende: Veronika Emmerich, Marita Hinze '
        'Sitzungsleitung: Veronika Emmerich '
        'Protokollantin: Sibylle Marquardt '
        'Nicht Anwesende: Martin Stahl '
        'Tagesordnungspunkte: 1. Begrüßung 2. Probleme mit einem Zulieferer',
        sectionType: 'lesen_teil4',
      );
      final children = span.children!.cast<TextSpan>();
      final boldLabels = children
          .where((child) => child.style?.fontWeight == FontWeight.w700)
          .map((child) => child.text)
          .toList();

      expect(boldLabels, contains('Protokoll'));
      expect(boldLabels, contains('Besprechungsraum:'));
      expect(boldLabels, contains('Ort:'));
      expect(boldLabels, contains('Teilnehmende:'));
      expect(boldLabels, contains('Sitzungsleitung:'));
      expect(boldLabels, contains('Protokollantin:'));
      expect(boldLabels, contains('Nicht Anwesende:'));
      expect(boldLabels, contains('Tagesordnungspunkte:'));

      final plainText = span.toPlainText();
      expect(plainText, startsWith('Protokoll 20.06.20XX, 10.00-12.00\n'));
      expect(plainText, contains('20.06.20XX, 10.00-12.00'));
      expect(plainText, contains('\nBesprechungsraum: 032, Ort: Hannover'));
      expect(plainText, contains('\nTeilnehmende: Veronika Emmerich'));
      expect(plainText, contains('\nSitzungsleitung: Veronika Emmerich'));
      expect(plainText, contains('\nProtokollantin: Sibylle Marquardt'));
      expect(plainText, contains('\nNicht Anwesende: Martin Stahl'));
      expect(plainText, contains('\n\nTagesordnungspunkte:\n'));
      expect(plainText, contains('1. Begrüßung'));
      expect(plainText, contains('2. Probleme mit einem Zulieferer'));
    });

    test('protocol-like prose outside Lesen Teil 4 remains unchanged', () {
      const content =
          'Protokoll 20.06.20XX, 10.00-12.00 Tagesordnungspunkte: '
          'TOP 1 Diese Wörter gehören zum normalen Hörtext.';
      final span = buildContentSpan(content, sectionType: 'hoeren_teil4');

      expect(span.toPlainText(), content);
      expect(
        span.children!.cast<TextSpan>(),
        everyElement(
          predicate<TextSpan>(
            (child) => child.style?.fontWeight != FontWeight.w700,
          ),
        ),
      );
    });

    test('TOP 1, TOP 2 and TOP 3 are bold and start separate paragraphs', () {
      final span = buildContentSpan(
        'Tagesordnungspunkte: 1. Begrüßung. '
        '**TOP 1 Begrüßung und Genehmigung** VE begrüßt alle. '
        'Der nächste Termin ist der 24.09.20XX. '
        '**TOP 2 Probleme mit einem Zulieferer** MH berichtet weiter. '
        '**TOP 3 Zwischenstand Qualitätssicherung** Die Abteilung prüft.',
        sectionType: 'lesen_teil4',
      );
      final children = span.children!.cast<TextSpan>();
      final headings = children.where(
        (child) =>
            child.style!.fontWeight == FontWeight.w700 &&
            (child.text?.startsWith('TOP ') ?? false),
      );
      expect(headings.map((c) => c.text).toList(), [
        'TOP 1 Begrüßung und Genehmigung',
        'TOP 2 Probleme mit einem Zulieferer',
        'TOP 3 Zwischenstand Qualitätssicherung',
      ]);

      final plainText = span.toPlainText();
      expect(plainText, contains('\n\nTOP 1 Begrüßung und Genehmigung\n\n'));
      expect(
        plainText,
        contains('\n\nTOP 2 Probleme mit einem Zulieferer\n\n'),
      );
      expect(
        plainText,
        contains('\n\nTOP 3 Zwischenstand Qualitätssicherung\n\n'),
      );
      expect(plainText, contains('Tagesordnungspunkte: 1. Begrüßung.'));
      expect(plainText, contains('VE begrüßt alle.'));
      expect(plainText, contains('24.09.20XX'));
      expect(plainText, contains('MH berichtet weiter.'));
      expect(plainText, contains('Die Abteilung prüft.'));
    });

    test(
      'does not strip the asterisks from the plain-text output — they are only in the source markup',
      () {
        final span = buildContentSpan('**Titel**', sectionType: 'lesen_teil4');
        final text = span.children!.cast<TextSpan>().map((s) => s.text).join();
        expect(text, 'Titel');
        expect(text, isNot(contains('*')));
      },
    );
  });

  group('TOP heading rendering in UniversalExerciseScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FavoritesService.debugUidOverride = 'top-heading-test-user';
      VoicePreferenceRepository.debugUidOverride = 'top-heading-test-user';
    });

    tearDown(() {
      FavoritesService.debugUidOverride = null;
      VoicePreferenceRepository.debugUidOverride = null;
    });

    testWidgets(
      'keeps headings and body accessible without overflow at 200% text scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final semanticsHandle = tester.ensureSemantics();

        final course = ParsedCourse(
          id: 'top-heading-course',
          title: 'Lesen fixture',
          sourceFilename: 'fixture.pdf',
          parsedAt: DateTime(2026, 7, 17),
          sections: const {
            'lesen_teil4': [
              {
                'variant_number': 1,
                'topic': 'Zulieferer, Fahrtenbuch',
                'texts': [
                  {
                    'title': 'Zulieferer, Fahrtenbuch',
                    'content':
                        'Protokoll 20.06.20XX, 10.00-12.00 '
                        'Besprechungsraum: 032, Ort: Hannover '
                        'Teilnehmende: Veronika Emmerich, Marita Hinze '
                        'Tagesordnungspunkte: 1. Begrüßung 2. Probleme '
                        'TOP 1 Begrüßung und Genehmigung VE begrüßt alle Anwesenden. '
                        'TOP 2 Probleme mit einem Zulieferer MH berichtet über den Zulieferer. '
                        'TOP 3 Zwischenstand Qualitätssicherung Die Abteilung prüft weiter.',
                  },
                ],
                'questions': [],
              },
            ],
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('de'),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: UniversalExerciseScreen(
              courseId: course.id,
              sectionType: 'lesen_teil4',
              index: 0,
              courseLoader: () async => [course],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final passage = find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('TOP 1 Begrüßung'),
        );
        expect(passage, findsOneWidget);

        final richText = tester.widget<RichText>(passage);
        final accessibleText = richText.text.toPlainText();
        expect(
          accessibleText,
          contains('\n\nTOP 1 Begrüßung und Genehmigung\n\n'),
        );
        expect(
          accessibleText,
          contains('\n\nTOP 2 Probleme mit einem Zulieferer\n\n'),
        );
        expect(
          accessibleText,
          contains('\n\nTOP 3 Zwischenstand Qualitätssicherung\n\n'),
        );
        expect(accessibleText, contains('VE begrüßt alle Anwesenden.'));
        expect(accessibleText, isNot(contains('**')));

        final semantics = tester.getSemantics(passage);
        expect(semantics.label, contains('TOP 1 Begrüßung'));
        expect(semantics.label, contains('TOP 2 Probleme'));
        expect(semantics.label, contains('TOP 3 Zwischenstand'));
        expect(semantics.label, contains('VE begrüßt alle Anwesenden.'));
        expect(tester.takeException(), isNull);

        await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
        await tester.pump();
        expect(tester.takeException(), isNull);
        semanticsHandle.dispose();
      },
    );
  });
}
