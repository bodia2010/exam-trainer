import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../models/parsed_course.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/course_storage.dart';
import '../../../../services/parse_service.dart';

typedef CourseLoader = Future<List<ParsedCourse>> Function();
typedef PremiumLoader = Future<bool> Function();
typedef CourseDeleter = Future<void> Function(String id);

class HomeViewModel extends ChangeNotifier {
  factory HomeViewModel({
    required CourseLoader loadCourses,
    required PremiumLoader loadPremium,
    required CourseDeleter deleteCourse,
    required Listenable courseRevision,
    required Stream<Object?> authChanges,
  }) => HomeViewModel._(
    loadCourses: loadCourses,
    loadPremium: loadPremium,
    deleteCourse: deleteCourse,
    courseRevision: courseRevision,
    authChanges: authChanges,
  );

  HomeViewModel._({
    required this._loadCourses,
    required this._loadPremium,
    required this._deleteCourse,
    required this._courseRevision,
    required this._authChanges,
  });

  factory HomeViewModel.production() => HomeViewModel(
    loadCourses: CourseStorage.instance.loadAll,
    loadPremium: ParseService.instance.isPremium,
    deleteCourse: CourseStorage.instance.delete,
    courseRevision: CourseStorage.instance.revision,
    authChanges: AuthService.instance.authStateChanges,
  );

  final CourseLoader _loadCourses;
  final PremiumLoader _loadPremium;
  final CourseDeleter _deleteCourse;
  final Listenable _courseRevision;
  final Stream<Object?> _authChanges;

  StreamSubscription<Object?>? _authSubscription;
  var _started = false;
  var _generation = 0;
  var _courses = const <ParsedCourse>[];
  var _loading = true;
  var _isPremium = false;

  List<ParsedCourse> get courses => _courses;
  bool get loading => _loading;
  bool get isPremium => _isPremium;
  ParsedCourse? get recentCourse => _courses.isEmpty ? null : _courses.first;

  void start() {
    if (_started) return;
    _started = true;
    _courseRevision.addListener(_onExternalChange);
    _authSubscription = _authChanges.listen((_) => refresh());
    refresh();
  }

  void _onExternalChange() => refreshCourses();

  Future<void> refresh() async {
    await Future.wait([refreshCourses(), refreshPremium()]);
  }

  Future<void> refreshCourses() async {
    final generation = ++_generation;
    _loading = true;
    notifyListeners();
    try {
      final loaded = await _loadCourses();
      if (generation != _generation) return;
      _courses = List.unmodifiable(loaded);
    } catch (_) {
      if (generation != _generation) return;
      _courses = const [];
    } finally {
      if (generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshPremium() async {
    try {
      _isPremium = await _loadPremium();
      notifyListeners();
    } catch (_) {
      _isPremium = false;
      notifyListeners();
    }
  }

  Future<void> delete(ParsedCourse course) async {
    await _deleteCourse(course.id);
    await refreshCourses();
  }

  @override
  void dispose() {
    _courseRevision.removeListener(_onExternalChange);
    _authSubscription?.cancel();
    super.dispose();
  }
}
