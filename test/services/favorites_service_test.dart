// Tests FavoritesService.removeByCourse's cascade behavior: when a course
// is deleted, CourseStorage.delete() calls removeByCourse(courseId) so no
// bookmark is left pointing at exercises that no longer exist. Favorites
// not tied to that course (or not tied to any course at all — the fixed
// Sprechen bank) must survive untouched.
//
// shared_preferences is faked (setMockInitialValues); no Firebase/network
// touched — FavoritesService.debugUidOverride swaps the UID the same way
// CourseStorage's does, so _uid never falls through to a real signed-in
// Firebase user that doesn't exist in this test environment. Each test
// uses its own UID so FavoritesService's in-memory cache (keyed by
// _cacheUid, and shared across tests since the service is a singleton)
// always reloads from the freshly-reset mock store instead of serving a
// previous test's stale state.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exam_trainer/models/favorite.dart';
import 'package:exam_trainer/services/favorites_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    FavoritesService.debugUidOverride = null;
  });

  Favorite fav(String id, String? courseId) => Favorite(
        id: id,
        title: 'Title $id',
        subtitle: 'Sub $id',
        route: '/route/$id',
        courseId: courseId,
        addedAt: DateTime(2026, 1, 1),
      );

  test('removeByCourse removes only favorites belonging to that course',
      () async {
    FavoritesService.debugUidOverride = 'uid-cascade';
    final svc = FavoritesService.instance;
    await svc.toggle(fav('f1', 'course-1'));
    await svc.toggle(fav('f2', 'course-1'));
    await svc.toggle(fav('f3', 'course-2'));
    await svc.toggle(fav('f4', null)); // fixed content, no course

    await svc.removeByCourse('course-1');

    final remainingIds = (await svc.getAll()).map((f) => f.id).toSet();
    expect(remainingIds, {'f3', 'f4'});
    expect(await svc.isFavorite('f1'), isFalse);
    expect(await svc.isFavorite('f2'), isFalse);
    expect(await svc.isFavorite('f3'), isTrue);
    expect(await svc.isFavorite('f4'), isTrue);
  });

  test('removeByCourse for a course with no favorites is a no-op', () async {
    FavoritesService.debugUidOverride = 'uid-noop';
    final svc = FavoritesService.instance;
    await svc.toggle(fav('f1', 'course-1'));

    await svc.removeByCourse('nonexistent-course');

    expect(await svc.isFavorite('f1'), isTrue);
  });
}
