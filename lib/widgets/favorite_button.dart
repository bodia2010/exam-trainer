import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/favorite.dart';
import '../ui/features/favorites/favorite_button_controller.dart';

class FavoriteButton extends StatefulWidget {
  final String favId;
  final String title;
  final String subtitle;
  final String route;
  final String? courseId;
  final FavoriteButtonController? controller;

  const FavoriteButton({
    super.key,
    required this.favId,
    required this.title,
    required this.subtitle,
    required this.route,
    this.courseId,
    this.controller,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  late final FavoriteButtonController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? FavoriteButtonController();
    _controller.load(_favorite);
  }

  Favorite get _favorite => Favorite(
    id: widget.favId,
    title: widget.title,
    subtitle: widget.subtitle,
    route: widget.route,
    courseId: widget.courseId,
    addedAt: DateTime.now(),
  );

  @override
  void didUpdateWidget(covariant FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.favId != widget.favId) {
      _controller.load(_favorite);
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final s = S.of(context);
    final wasError = _controller.status == FavoriteButtonStatus.error;
    final success = wasError
        ? await _controller.retry()
        : await _controller.toggle(_favorite);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.deviceLimitFehler)));
      return;
    }
    if (wasError) return;
    final nowFav = _controller.isFavorite;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowFav ? s.lesezeichenGespeichert : s.lesezeichenEntfernt,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final busy =
            _controller.status == FavoriteButtonStatus.loading ||
            _controller.status == FavoriteButtonStatus.saving;
        final isFavorite = _controller.isFavorite;
        return Semantics(
          button: true,
          enabled: !busy,
          label: isFavorite ? s.lesezeichenEntfernen : s.lesezeichenHinzufuegen,
          child: IconButton(
            icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border),
            tooltip: isFavorite
                ? s.lesezeichenEntfernen
                : s.lesezeichenHinzufuegen,
            onPressed: busy ? null : _toggle,
          ),
        );
      },
    );
  }
}
