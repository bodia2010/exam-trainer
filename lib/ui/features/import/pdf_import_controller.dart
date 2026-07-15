import 'package:flutter/foundation.dart';

enum PdfImportPhase {
  idle,
  selecting,
  validating,
  converting,
  processing,
  saving,
  success,
  error,
  cancelled,
}

@immutable
class PdfImportState {
  const PdfImportState({
    this.phase = PdfImportPhase.idle,
    this.status = '',
    this.error,
  });

  final PdfImportPhase phase;
  final String status;
  final String? error;

  bool get isRunning => switch (phase) {
    PdfImportPhase.selecting ||
    PdfImportPhase.validating ||
    PdfImportPhase.converting ||
    PdfImportPhase.processing ||
    PdfImportPhase.saving => true,
    _ => false,
  };
}

/// Owns the lifetime of one import attempt. Starting another attempt or
/// disposing the controller immediately makes all older operation ids stale.
class PdfImportController extends ChangeNotifier {
  PdfImportState _state = const PdfImportState();
  int _generation = 0;
  bool _disposed = false;

  PdfImportState get state => _state;

  int start() {
    final operationId = ++_generation;
    _set(operationId, const PdfImportState(phase: PdfImportPhase.selecting));
    return operationId;
  }

  bool isCurrent(int operationId) => !_disposed && operationId == _generation;

  void update(int operationId, PdfImportPhase phase, {String status = ''}) {
    _set(operationId, PdfImportState(phase: phase, status: status));
  }

  void reset(int operationId) {
    _set(operationId, const PdfImportState());
  }

  void fail(int operationId, String message) {
    _set(
      operationId,
      PdfImportState(phase: PdfImportPhase.error, error: message),
    );
  }

  void succeed(int operationId) {
    _set(operationId, const PdfImportState(phase: PdfImportPhase.success));
  }

  void cancel() {
    if (_disposed) return;
    _generation++;
    _state = const PdfImportState(phase: PdfImportPhase.cancelled);
    notifyListeners();
  }

  void _set(int operationId, PdfImportState next) {
    if (!isCurrent(operationId)) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
