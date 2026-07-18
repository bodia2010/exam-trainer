import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:exam_trainer/models/favorite.dart';
import 'package:exam_trainer/ui/features/favorites/favorites_controller.dart';

Favorite _favorite(String id) => Favorite(
  id: id,
  title: 'Übung $id',
  subtitle: 'Teil 1',
  route: '/course/c/lesen_teil1/0',
  courseId: 'c',
  addedAt: DateTime(2026, 1, 1),
);

void main() {
  test('load exposes content and empty as terminal states', () async {
    final controller = FavoritesController(load: () async => [_favorite('a')]);
    await controller.load();
    expect(controller.status, FavoritesStatus.content);
    expect(controller.favorites.single.id, 'a');

    final empty = FavoritesController(load: () async => const []);
    await empty.load();
    expect(empty.status, FavoritesStatus.empty);
    controller.dispose();
    empty.dispose();
  });

  test('load failure exposes error and retry can recover', () async {
    var attempts = 0;
    final controller = FavoritesController(
      load: () async {
        attempts++;
        if (attempts == 1) throw StateError('storage');
        return [_favorite('a')];
      },
    );
    await controller.load();
    expect(controller.status, FavoritesStatus.error);
    await controller.load();
    expect(controller.status, FavoritesStatus.content);
    controller.dispose();
  });

  test('stale completion cannot overwrite a newer load', () async {
    final first = Completer<List<Favorite>>();
    final second = Completer<List<Favorite>>();
    var calls = 0;
    final controller = FavoritesController(
      load: () => ++calls == 1 ? first.future : second.future,
    );
    final old = controller.load();
    final current = controller.load();
    second.complete([_favorite('new')]);
    await current;
    first.complete([_favorite('old')]);
    await old;
    expect(controller.favorites.single.id, 'new');
    controller.dispose();
  });

  test('completion after dispose does not notify or throw', () async {
    final pending = Completer<List<Favorite>>();
    final controller = FavoritesController(load: () => pending.future);
    final load = controller.load();
    controller.dispose();
    pending.complete([_favorite('late')]);
    await load;
  });
}
