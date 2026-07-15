import 'dart:io';

import 'package:exam_trainer/ui/features/import/pdf_import_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('pdf-import-test-');
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('rejects a PDF above the limit before reading its contents', () async {
    final file = File('${directory.path}/large.pdf');
    final handle = await file.open(mode: FileMode.write);
    await handle.truncate(maxPdfImportBytes + 1);
    await handle.close();

    expect(
      const PdfFileValidator().validate(
        PickedPdfFile(path: file.path, name: 'large.pdf'),
      ),
      throwsA(
        isA<PdfFileValidationException>().having(
          (error) => error.error,
          'error',
          PdfFileValidationError.tooLarge,
        ),
      ),
    );
  });

  test('rejects a .pdf file without the PDF magic signature', () async {
    final file = File('${directory.path}/fake.pdf');
    await file.writeAsString('not a pdf');

    expect(
      const PdfFileValidator().validate(
        PickedPdfFile(path: file.path, name: 'fake.pdf'),
      ),
      throwsA(
        isA<PdfFileValidationException>().having(
          (error) => error.error,
          'error',
          PdfFileValidationError.invalidSignature,
        ),
      ),
    );
  });

  test('accepts a file at the limit with a PDF signature', () async {
    final file = File('${directory.path}/valid.pdf');
    final handle = await file.open(mode: FileMode.write);
    await handle.writeFrom('%PDF-'.codeUnits);
    await handle.truncate(maxPdfImportBytes);
    await handle.close();

    final validated = await const PdfFileValidator().validate(
      PickedPdfFile(path: file.path, name: 'valid.pdf'),
    );

    expect(validated.size, maxPdfImportBytes);
  });
}
