import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:exam_trainer/models/favorite.dart';
import 'package:exam_trainer/ui/features/favorites/favorite_button_controller.dart';

Favorite _fav(String id) => Favorite(
  id: id,
  title: id,
  subtitle: 'subtitle',
  route: '/favorites',
  courseId: 'course',
  addedAt: DateTime(2026),
);

void main() {
  test('loads current value and handles storage failure', () async {
    final controller = FavoriteButtonController(
      check: (id) async => id == 'yes',
    );
    await controller.load(_fav('yes'));
    expect(controller.status, FavoriteButtonStatus.ready);
    expect(controller.isFavorite, isTrue);
    controller.dispose();

    final failed = FavoriteButtonController(
      check: (_) async => throw StateError('raw'),
    );
    await failed.load(_fav('x'));
    expect(failed.status, FavoriteButtonStatus.error);
    failed.dispose();
  });

  test('double toggle is serialized and stale load cannot overwrite', () async {
    final first = Completer<bool>();
    final second = Completer<bool>();
    var checks = 0;
    var toggles = 0;
    final controller = FavoriteButtonController(
      check: (_) => ++checks == 1 ? first.future : second.future,
      toggle: (_) async => toggles++,
    );
    final old = controller.load(_fav('old'));
    final current = controller.load(_fav('new'));
    second.complete(false);
    await current;
    first.complete(true);
    await old;
    expect(controller.isFavorite, isFalse);
    final firstToggle = controller.toggle(_fav('new'));
    final secondToggle = controller.toggle(_fav('new'));
    expect(await firstToggle, isTrue);
    expect(await secondToggle, isFalse);
    expect(toggles, 1);
    controller.dispose();
  });

  test(
    'completion after dispose is ignored and failed toggle keeps value',
    () async {
      final pending = Completer<bool>();
      final controller = FavoriteButtonController(check: (_) => pending.future);
      final load = controller.load(_fav('x'));
      controller.dispose();
      pending.complete(true);
      await load;

      var shouldFail = true;
      final retryable = FavoriteButtonController(
        check: (_) async => true,
        toggle: (_) async {
          if (shouldFail) throw StateError('raw');
        },
      );
      await retryable.load(_fav('x'));
      expect(await retryable.toggle(_fav('x')), isFalse);
      expect(retryable.isFavorite, isTrue);
      shouldFail = false;
      expect(await retryable.retry(), isTrue);
      expect(retryable.isFavorite, isFalse);
      retryable.dispose();
    },
  );
}
