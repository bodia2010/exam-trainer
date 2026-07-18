import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/strings.dart';
import '../models/favorite.dart';
import '../ui/core/theme/exam_theme.dart';
import '../ui/features/favorites/favorites_controller.dart';

class FavoritesScreen extends StatefulWidget {
  final FavoritesController? controller;

  const FavoritesScreen({super.key, this.controller});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final FavoritesController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? FavoritesController();
    _controller.load();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ExamColors.canvas,
        foregroundColor: ExamColors.ink,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.lesezeichen,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              s.gespeicherteUebungen,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      backgroundColor: ExamColors.canvas,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.status == FavoritesStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: ExamColors.teal),
            );
          }
          if (_controller.status == FavoritesStatus.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 56,
                    color: ExamColors.coral,
                  ),
                  const SizedBox(height: 12),
                  Text(s.deviceLimitFehler, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: _controller.load,
                    child: Text(s.wiederholenAction),
                  ),
                ],
              ),
            );
          }
          final favorites = _controller.favorites;
          if (_controller.status == FavoritesStatus.empty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bookmark_border_rounded,
                    size: 72,
                    color: ExamColors.teal,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.keineLesezeichen,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: ExamColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      s.lesezeichenHinweis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: ExamColors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final fav = favorites[index];
              return _FavoriteCard(
                favorite: fav,
                onTap: () => context.push(fav.route),
                onRemove: () => _controller.remove(fav.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final Favorite favorite;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteCard({
    required this.favorite,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(favorite.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: ExamColors.coral,
          borderRadius: BorderRadius.circular(ExamRadius.medium),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onRemove(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: ExamColors.surface,
            borderRadius: BorderRadius.circular(ExamRadius.medium),
            border: Border.all(color: ExamColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ExamColors.tealSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bookmark_rounded,
                    color: ExamColors.teal,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        favorite.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ExamColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        favorite.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ExamColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
