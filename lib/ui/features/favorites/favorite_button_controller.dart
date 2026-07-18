import 'package:flutter/foundation.dart';
import '../../../models/favorite.dart';
import '../../../services/favorites_service.dart';

typedef FavoriteChecker = Future<bool> Function(String id);
typedef FavoriteToggler = Future<void> Function(Favorite favorite);

enum FavoriteButtonStatus { loading, ready, saving, error }

class FavoriteButtonController extends ChangeNotifier {
  FavoriteButtonController({FavoriteChecker? check, FavoriteToggler? toggle})
    : _check = check ?? FavoritesService.instance.isFavorite,
      _toggleService = toggle ?? FavoritesService.instance.toggle;

  final FavoriteChecker _check;
  final FavoriteToggler _toggleService;
  FavoriteButtonStatus _status = FavoriteButtonStatus.loading;
  bool _isFavorite = false;
  Favorite? _favorite;
  _FavoriteAction _lastAction = _FavoriteAction.load;
  int _operation = 0;
  bool _disposed = false;

  FavoriteButtonStatus get status => _status;
  bool get isFavorite => _isFavorite;

  Future<void> load(Favorite favorite) async {
    final operation = ++_operation;
    _favorite = favorite;
    _lastAction = _FavoriteAction.load;
    _setStatus(FavoriteButtonStatus.loading);
    try {
      final isFavorite = await _check(favorite.id);
      if (!_isCurrent(operation, favorite.id)) return;
      _isFavorite = isFavorite;
      _setStatus(FavoriteButtonStatus.ready);
    } catch (_) {
      if (!_isCurrent(operation, favorite.id)) return;
      _setStatus(FavoriteButtonStatus.error);
    }
  }

  Future<bool> toggle(Favorite favorite) async {
    if (_status != FavoriteButtonStatus.ready) return false;
    final operation = ++_operation;
    _favorite = favorite;
    _lastAction = _FavoriteAction.toggle;
    _setStatus(FavoriteButtonStatus.saving);
    try {
      await _toggleService(favorite);
      if (!_isCurrent(operation, favorite.id)) return false;
      _isFavorite = !_isFavorite;
      _setStatus(FavoriteButtonStatus.ready);
      return true;
    } catch (_) {
      if (!_isCurrent(operation, favorite.id)) return false;
      _setStatus(FavoriteButtonStatus.error);
      return false;
    }
  }

  Future<bool> retry() async {
    final favorite = _favorite;
    if (favorite == null) return false;
    if (_lastAction == _FavoriteAction.load) {
      await load(favorite);
      return _status == FavoriteButtonStatus.ready;
    }
    _setStatus(FavoriteButtonStatus.ready);
    return toggle(favorite);
  }

  bool _isCurrent(int operation, String id) =>
      !_disposed && operation == _operation && _favorite?.id == id;

  void _setStatus(FavoriteButtonStatus status) {
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

enum _FavoriteAction { load, toggle }
