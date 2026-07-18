import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _router(
  ValueNotifier<bool> authenticated, {
  String? initialLocation,
}) => GoRouter(
  initialLocation: initialLocation ?? '/',
  refreshListenable: authenticated,
  redirect: (_, state) {
    const publicPaths = {'/login', '/terms'};
    if (!authenticated.value && !publicPaths.contains(state.matchedLocation)) {
      return '/login';
    }
    if (authenticated.value && state.matchedLocation == '/login') {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, _) => const Text('home')),
    GoRoute(path: '/login', builder: (_, _) => const Text('login')),
    GoRoute(path: '/terms', builder: (_, _) => const Text('terms')),
    GoRoute(
      path: '/course/:id',
      builder: (_, state) => Text('course:${state.pathParameters['id']}'),
      routes: [
        GoRoute(
          path: ':section',
          builder: (_, state) =>
              Text('section:${state.pathParameters['section']}'),
          routes: [
            GoRoute(
              path: ':index',
              builder: (_, state) =>
                  Text('index:${state.pathParameters['index']}'),
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (_, _) => const Text('route-not-found'),
);

void main() {
  testWidgets(
    'auth redirect protects nested deep links and preserves public pages',
    (tester) async {
      final authenticated = ValueNotifier(false);
      final router = _router(
        authenticated,
        initialLocation: '/course/demo/lesen_teil1/0',
      );
      addTearDown(() {
        router.dispose();
        authenticated.dispose();
      });

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('login'), findsOneWidget);

      authenticated.value = true;
      router.go('/course/demo/lesen_teil1/0');
      await tester.pumpAndSettle();
      expect(find.text('index:0'), findsOneWidget);

      final publicRouter = _router(
        ValueNotifier(false),
        initialLocation: '/terms',
      );
      addTearDown(publicRouter.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: publicRouter));
      await tester.pumpAndSettle();
      expect(find.text('terms'), findsOneWidget);
    },
  );

  testWidgets(
    'go_router 17 keeps production paths case-sensitive and terminal',
    (tester) async {
      final authenticated = ValueNotifier(true);
      final router = _router(
        authenticated,
        initialLocation: '/Course/demo/lesen_teil1/0',
      );
      addTearDown(() {
        router.dispose();
        authenticated.dispose();
      });

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('route-not-found'), findsOneWidget);

      router.go('/course/demo/lesen_teil1/0');
      await tester.pumpAndSettle();
      expect(find.text('index:0'), findsOneWidget);
    },
  );
}
