import 'dart:io';

import 'package:exam_trainer/models/parsed_course.dart';
import 'package:exam_trainer/screens/import_screen.dart';
import 'package:exam_trainer/services/api_exception.dart';
import 'package:exam_trainer/services/parse_service.dart';
import 'package:exam_trainer/ui/features/import/pdf_import_file.dart';
import 'package:exam_trainer/ui/features/import/pdf_import_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android SAF returns a readable PDF path without contacting backend',
    (tester) async {
      final services = _RecordingOfflineServices();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          home: ImportScreen(services: services),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('import-pdf-picker')));
      await tester.pump();

      final deadline = DateTime.now().add(const Duration(minutes: 4));
      while (services.convertedFile == null &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        await tester.pump();
      }

      final file = services.convertedFile;
      expect(file, isNotNull, reason: 'Select exam-trainer-saf-valid.pdf');
      expect(file!.name, 'exam-trainer-saf-valid.pdf');
      expect(file.size, greaterThan(5));
      expect(await File(file.path).exists(), isTrue);

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('import-pdf-error')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(services.convertCalls, 1);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

class _RecordingOfflineServices implements PdfImportServices {
  ValidatedPdfFile? convertedFile;
  int convertCalls = 0;

  @override
  Future<String> convertPdf(ValidatedPdfFile file) {
    convertedFile = file;
    convertCalls++;
    throw ApiException.networkOrTimeout('SAF smoke', 'offline fake');
  }

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
