import 'package:flutter/foundation.dart';
import '../../../models/favorite.dart';
import '../../../services/favorites_service.dart';

typedef FavoritesLoader = Future<List<Favorite>> Function();
typedef FavoriteRemover = Future<void> Function(String id);

enum FavoritesStatus { loading, content, empty, error }

class FavoritesController extends ChangeNotifier {
  FavoritesController({FavoritesLoader? load, FavoriteRemover? remove})
    : _load = load ?? FavoritesService.instance.getAll,
      _remove = remove ?? FavoritesService.instance.remove;

  final FavoritesLoader _load;
  final FavoriteRemover _remove;
  FavoritesStatus _status = FavoritesStatus.loading;
  List<Favorite> _favorites = const [];
  int _operation = 0;
  bool _disposed = false;

  FavoritesStatus get status => _status;
  List<Favorite> get favorites => List.unmodifiable(_favorites);

  Future<void> load() async {
    final operation = ++_operation;
    _setStatus(FavoritesStatus.loading);
    try {
      final favorites = await _load();
      if (_disposed || operation != _operation) return;
      _favorites = List.unmodifiable(favorites);
      _setStatus(
        favorites.isEmpty ? FavoritesStatus.empty : FavoritesStatus.content,
      );
    } catch (_) {
      if (_disposed || operation != _operation) return;
      _favorites = const [];
      _setStatus(FavoritesStatus.error);
    }
  }

  Future<void> remove(String id) async {
    final operation = ++_operation;
    try {
      await _remove(id);
      if (_disposed || operation != _operation) return;
      await load();
    } catch (_) {
      if (_disposed || operation != _operation) return;
      _setStatus(FavoritesStatus.error);
    }
  }

  void _setStatus(FavoritesStatus status) {
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
