// CR-11: a failed backend call during import must show a distinct,
// localized, actionable message per failure kind (401/403/413/429/timeout)
// instead of one generic "please try again" for everything — and must
// never leak the raw ApiException/response body into the UI.
import 'package:exam_trainer/models/parsed_course.dart';
import 'package:exam_trainer/screens/import_screen.dart';
import 'package:exam_trainer/services/api_exception.dart';
import 'package:exam_trainer/services/parse_service.dart';
import 'package:exam_trainer/ui/features/import/pdf_import_file.dart';
import 'package:exam_trainer/ui/features/import/pdf_import_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  const pdf = PickedPdfFile(path: '/not-read.pdf', name: 'fixture.pdf');

  Future<void> pumpWithFailingConvert(WidgetTester tester, Object error) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ImportScreen(
          filePicker: const _FakePicker(pdf),
          fileValidator: const _FakeValidator(),
          services: _FailingConvertServices(error),
        ),
      ),
    );
    await tester.tap(find.text('Choose PDF'));
    await tester.pumpAndSettle();
  }

  testWidgets('401 shows a session-expired message', (tester) async {
    await pumpWithFailingConvert(
      tester,
      ApiException.fromResponse(
        'convert',
        http.Response('secret internal detail, should never render', 401),
      ),
    );
    expect(find.textContaining('session has expired'), findsOneWidget);
    expect(find.textContaining('secret internal detail'), findsNothing);
  });

  testWidgets('403 shows a Premium-required message', (tester) async {
    await pumpWithFailingConvert(
      tester,
      ApiException.fromResponse('convert', http.Response('', 403)),
    );
    expect(find.textContaining('requires Premium'), findsOneWidget);
  });

  testWidgets('413 shows a file-too-large-for-server message', (tester) async {
    await pumpWithFailingConvert(
      tester,
      ApiException.fromResponse('convert', http.Response('', 413)),
    );
    expect(find.textContaining('too large for the server'), findsOneWidget);
  });

  testWidgets('429 shows a rate-limit message', (tester) async {
    await pumpWithFailingConvert(
      tester,
      ApiException.fromResponse('convert', http.Response('', 429)),
    );
    expect(find.textContaining('Too many requests'), findsOneWidget);
  });

  testWidgets('a network/timeout failure shows a connection message', (
    tester,
  ) async {
    await pumpWithFailingConvert(
      tester,
      ApiException.networkOrTimeout('convert', 'socket closed'),
    );
    expect(find.textContaining('Connection problem'), findsOneWidget);
  });

  testWidgets('a 500 falls back to the generic import error, not raw text', (
    tester,
  ) async {
    await pumpWithFailingConvert(
      tester,
      ApiException.fromResponse(
        'convert',
        http.Response('Traceback (most recent call last): ...', 500),
      ),
    );
    expect(find.textContaining('could not be imported'), findsOneWidget);
    expect(find.textContaining('Traceback'), findsNothing);
  });
}

class _FakePicker implements PdfFilePicker {
  const _FakePicker(this.file);
  final PickedPdfFile file;

  @override
  Future<PickedPdfFile?> pick() async => file;
}

class _FakeValidator extends PdfFileValidator {
  const _FakeValidator();

  @override
  Future<ValidatedPdfFile> validate(PickedPdfFile picked) async =>
      ValidatedPdfFile(path: picked.path, name: picked.name, size: 12);
}

class _FailingConvertServices implements PdfImportServices {
  _FailingConvertServices(this.error);
  final Object error;

  @override
  Future<String> convertPdf(ValidatedPdfFile file) => Future.error(error);

  @override
  Future<bool> isPremium() async => true;

  @override
  Future<Map<String, List<dynamic>>?> getCachedSections(
    String markdown,
  ) async => null;

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
  Future<void> saveCourse(ParsedCourse course) async {}
}
