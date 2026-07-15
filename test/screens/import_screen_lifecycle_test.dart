import 'dart:async';

import 'package:exam_trainer/models/parsed_course.dart';
import 'package:exam_trainer/screens/import_screen.dart';
import 'package:exam_trainer/services/parse_service.dart';
import 'package:exam_trainer/ui/features/import/pdf_import_file.dart';
import 'package:exam_trainer/ui/features/import/pdf_import_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'leaving during conversion neither saves nor navigates after completion',
    (tester) async {
      const pdf = PickedPdfFile(path: '/not-read.pdf', name: 'fixture.pdf');
      final conversion = Completer<String>();
      final services = _FakeImportServices(conversion.future);

      await tester.pumpWidget(
        MaterialApp(
          home: ImportScreen(
            filePicker: _FakePicker(pdf),
            fileValidator: const _FakeValidator.valid(),
            services: services,
          ),
        ),
      );
      await tester.tap(find.text('Choose PDF'));
      await tester.pump();
      expect(services.convertCalls, 1);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Previous screen'))),
      );
      expect(find.text('Previous screen'), findsOneWidget);

      conversion.complete('# converted');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(tester.takeException(), isNull);
      expect(services.saveCalls, 0);
      expect(find.text('Previous screen'), findsOneWidget);
    },
  );

  testWidgets('oversized PDF is rejected before conversion is sent', (
    tester,
  ) async {
    final services = _FakeImportServices(Future.value('# converted'));

    await tester.pumpWidget(
      MaterialApp(
        home: ImportScreen(
          filePicker: _FakePicker(
            const PickedPdfFile(path: '/not-read.pdf', name: 'large.pdf'),
          ),
          fileValidator: const _FakeValidator.tooLarge(),
          services: services,
        ),
      ),
    );
    await tester.tap(find.text('Choose PDF'));
    await tester.pumpAndSettle();

    expect(services.convertCalls, 0);
    expect(find.textContaining('maximum size is 25 MB'), findsOneWidget);
  });
}

class _FakePicker implements PdfFilePicker {
  const _FakePicker(this.file);

  final PickedPdfFile file;

  @override
  Future<PickedPdfFile?> pick() async => file;
}

class _FakeValidator extends PdfFileValidator {
  const _FakeValidator.valid() : error = null;

  const _FakeValidator.tooLarge() : error = PdfFileValidationError.tooLarge;

  final PdfFileValidationError? error;

  @override
  Future<ValidatedPdfFile> validate(PickedPdfFile picked) async {
    final validationError = error;
    if (validationError != null) {
      throw PdfFileValidationException(validationError);
    }
    return ValidatedPdfFile(path: picked.path, name: picked.name, size: 12);
  }
}

class _FakeImportServices implements PdfImportServices {
  _FakeImportServices(this.conversion);

  final Future<String> conversion;
  int convertCalls = 0;
  int saveCalls = 0;

  @override
  Future<String> convertPdf(ValidatedPdfFile file) {
    convertCalls++;
    return conversion;
  }

  @override
  Future<bool> isPremium() async => true;

  @override
  Future<Map<String, List<dynamic>>?> getCachedSections(
    String markdown,
  ) async => {
    'lesen_teil1': [
      {'variant_number': 1},
    ],
  };

  @override
  Future<List<DiscoveredItem>> discoverSections(String markdown) async => [];

  @override
  Map<String, List<VariantGroup>> groupChunksBySectionType(
    String markdown,
    List<DiscoveredItem> items,
  ) => const {};

  @override
  Future<({List<dynamic> items, List<String> errors})> parseVariantGroups(
    List<VariantGroup> groups,
    String sectionType, {
    void Function(int done, int total)? onProgress,
  }) async => (items: const <dynamic>[], errors: const <String>[]);

  @override
  Future<void> cacheSections(
    String markdown,
    Map<String, List<dynamic>> sections,
  ) async {}

  @override
  Future<void> saveCourse(ParsedCourse course) async {
    saveCalls++;
  }
}
