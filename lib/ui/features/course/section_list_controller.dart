import 'package:flutter/foundation.dart';
import '../../../widgets/course_load_state.dart';

enum SectionListStatus { loading, content, notFound, error }

class SectionListController extends ChangeNotifier {
  SectionListController({required this._loader});

  final CourseLoader _loader;
  SectionListStatus _status = SectionListStatus.loading;
  List<dynamic> _variants = const [];
  int _operation = 0;
  bool _disposed = false;

  SectionListStatus get status => _status;
  List<dynamic> get variants => List.unmodifiable(_variants);

  Future<void> load(String courseId, String sectionType) async {
    final operation = ++_operation;
    _variants = const [];
    _setStatus(SectionListStatus.loading);
    try {
      final all = await _loader();
      if (_disposed || operation != _operation) return;
      final course = all.where((item) => item.id == courseId).firstOrNull;
      final variants = course?.sections[sectionType] ?? const [];
      for (final variant in variants) {
        variant as Map<String, dynamic>;
      }
      if (_disposed || operation != _operation) return;
      _variants = List.unmodifiable(variants);
      _setStatus(
        course == null ? SectionListStatus.notFound : SectionListStatus.content,
      );
    } catch (_) {
      if (_disposed || operation != _operation) return;
      _variants = const [];
      _setStatus(SectionListStatus.error);
    }
  }

  void _setStatus(SectionListStatus status) {
    if (_disposed) return;
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _operation++;
    super.dispose();
  }
}
