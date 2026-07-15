import 'package:exam_trainer/ui/features/import/pdf_import_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a stale operation cannot overwrite a newer import state', () {
    final controller = PdfImportController();
    addTearDown(controller.dispose);

    final first = controller.start();
    controller.update(first, PdfImportPhase.converting, status: 'first');
    final second = controller.start();
    controller.update(second, PdfImportPhase.processing, status: 'second');

    controller.fail(first, 'stale error');
    controller.update(first, PdfImportPhase.saving, status: 'stale save');

    expect(controller.isCurrent(first), isFalse);
    expect(controller.isCurrent(second), isTrue);
    expect(controller.state.phase, PdfImportPhase.processing);
    expect(controller.state.status, 'second');
    expect(controller.state.error, isNull);
  });

  test('dispose invalidates an in-flight operation', () {
    final controller = PdfImportController();
    final operation = controller.start();

    controller.dispose();

    expect(controller.isCurrent(operation), isFalse);
  });
}
