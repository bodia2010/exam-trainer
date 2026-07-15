import 'package:flutter/foundation.dart';

class ProbeItem {
  final String sectionName;
  final String partLabel;
  final String exerciseName;
  final String route;

  const ProbeItem({
    required this.sectionName,
    required this.partLabel,
    required this.exerciseName,
    required this.route,
  });

  String get shortLabel => '$sectionName · $partLabel';
}

/// Tracks the walk-through state of one mock-exam run. Purely in-memory
/// and reset every time the screen is reopened — there's no persistent
/// stats feature in this app to record completion against, so "done"
/// here just means "visited this part during the current run".
class ProbeExamService extends ChangeNotifier {
  ProbeExamService._();
  static final instance = ProbeExamService._();

  List<ProbeItem>? _items;
  int _currentIdx = -1;
  final Set<int> _visited = {};

  bool get isActive => _items != null && _currentIdx >= 0;
  int get currentIdx => _currentIdx;
  int get totalItems => _items?.length ?? 0;
  Set<int> get visited => _visited;

  ProbeItem? get current => isActive ? _items![_currentIdx] : null;

  ProbeItem? get next => isActive && _currentIdx + 1 < _items!.length
      ? _items![_currentIdx + 1]
      : null;

  bool get hasNext => next != null;
  bool get isLast => isActive && _currentIdx == (_items!.length - 1);

  void start(List<ProbeItem> items) {
    _items = items;
    _currentIdx = -1;
    _visited.clear();
    notifyListeners();
  }

  void goTo(int idx) {
    _currentIdx = idx;
    notifyListeners();
  }

  void goToNext() {
    if (_items != null && _currentIdx + 1 < _items!.length) {
      _currentIdx++;
      notifyListeners();
    }
  }

  void markVisited(int idx) {
    if (_visited.add(idx)) notifyListeners();
  }

  void clearCurrent() {
    if (_currentIdx != -1) {
      _currentIdx = -1;
      notifyListeners();
    }
  }

  void stop() {
    _items = null;
    _currentIdx = -1;
    _visited.clear();
    notifyListeners();
  }
}
