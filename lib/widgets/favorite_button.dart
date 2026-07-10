import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/favorite.dart';
import '../services/favorites_service.dart';

class FavoriteButton extends StatefulWidget {
  final String favId;
  final String title;
  final String subtitle;
  final String route;
  final String? courseId;

  const FavoriteButton({
    super.key,
    required this.favId,
    required this.title,
    required this.subtitle,
    required this.route,
    this.courseId,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _isFavorite = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final fav = await FavoritesService.instance.isFavorite(widget.favId);
    if (mounted) {
      setState(() {
        _isFavorite = fav;
        _loaded = true;
      });
    }
  }

  Future<void> _toggle() async {
    final s = S.of(context);
    final nowFav = !_isFavorite;
    await FavoritesService.instance.toggle(Favorite(
      id: widget.favId,
      title: widget.title,
      subtitle: widget.subtitle,
      route: widget.route,
      courseId: widget.courseId,
      addedAt: DateTime.now(),
    ));
    if (!mounted) return;
    setState(() => _isFavorite = nowFav);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nowFav ? s.lesezeichenGespeichert : s.lesezeichenEntfernt),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (!_loaded) return const SizedBox(width: 48);
    return IconButton(
      icon: Icon(_isFavorite ? Icons.bookmark : Icons.bookmark_border),
      tooltip: _isFavorite ? s.lesezeichenEntfernen : s.lesezeichenHinzufuegen,
      onPressed: _toggle,
    );
  }
}
