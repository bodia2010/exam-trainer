import 'package:flutter/foundation.dart';
import '../../../models/parsed_course.dart';
import '../../../widgets/course_load_state.dart';

enum CourseScreenStatus { loading, content, notFound, error }

class CourseScreenController extends ChangeNotifier {
  CourseScreenController({required this._loader});

  final CourseLoader _loader;
  CourseScreenStatus _status = CourseScreenStatus.loading;
  ParsedCourse? _course;
  int _operation = 0;
  bool _disposed = false;

  CourseScreenStatus get status => _status;
  ParsedCourse? get course => _course;

  Future<void> load(String id) async {
    final operation = ++_operation;
    _course = null;
    _setStatus(CourseScreenStatus.loading);
    try {
      final all = await _loader();
      if (_disposed || operation != _operation) return;
      final course = all.where((item) => item.id == id).firstOrNull;
      _course = course;
      _setStatus(
        course == null
            ? CourseScreenStatus.notFound
            : CourseScreenStatus.content,
      );
    } catch (_) {
      if (_disposed || operation != _operation) return;
      _course = null;
      _setStatus(CourseScreenStatus.error);
    }
  }

  void _setStatus(CourseScreenStatus status) {
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
