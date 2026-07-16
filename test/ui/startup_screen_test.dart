import 'dart:async';

import 'package:exam_trainer/ui/core/theme/exam_theme.dart';
import 'package:exam_trainer/ui/features/startup/startup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('startup overlay stays until prepared page has painted', (
    tester,
  ) async {
    StartupCoordinator.instance.reset();
    await tester.pumpWidget(
      MaterialApp(
        theme: ExamTheme.light(),
        home: const StartupOverlay(child: Text('Prepared page')),
      ),
    );

    expect(find.byKey(const ValueKey('app_startup_overlay')), findsOneWidget);

    StartupCoordinator.instance.markReady();
    await tester.pump();
    expect(find.byKey(const ValueKey('app_startup_overlay')), findsNothing);
    expect(find.text('Prepared page'), findsOneWidget);

    StartupCoordinator.instance.reset();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('signed-out redirect removes startup overlay', (tester) async {
    StartupCoordinator.instance.reset();
    final redirectGate = Completer<void>();
    final testRouter = GoRouter(
      initialLocation: '/',
      redirect: (context, state) async {
        if (state.matchedLocation == '/login') return null;
        await redirectGate.future;
        return '/login';
      },
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('Home page')),
        GoRoute(path: '/login', builder: (_, _) => const Text('Login page')),
      ],
    );
    addTearDown(testRouter.dispose);
    addTearDown(StartupCoordinator.instance.reset);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: ExamTheme.light(),
        routerConfig: testRouter,
        builder: (context, child) => RouterStartupOverlay(
          routeListenable: testRouter.routerDelegate,
          resolvedPath: () {
            final configuration =
                testRouter.routerDelegate.currentConfiguration;
            return configuration.isEmpty ? null : configuration.uri.path;
          },
          child: child ?? const SizedBox.expand(),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('app_startup_overlay')), findsOneWidget);

    // GoRouter resolves this internally on its delegate. The external route
    // information provider may still describe the originally requested `/`.
    redirectGate.complete();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('app_startup_overlay')), findsNothing);
    expect(find.text('Login page'), findsOneWidget);
  });

  testWidgets('empty and Home routes keep overlay until Home is ready', (
    tester,
  ) async {
    StartupCoordinator.instance.reset();
    final resolvedPath = ValueNotifier<String?>(null);
    addTearDown(resolvedPath.dispose);
    addTearDown(StartupCoordinator.instance.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ExamTheme.light(),
        home: RouterStartupOverlay(
          routeListenable: resolvedPath,
          resolvedPath: () => resolvedPath.value,
          child: const Text('Home page'),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('app_startup_overlay')), findsOneWidget);

    resolvedPath.value = '/';
    await tester.pump();
    expect(find.byKey(const ValueKey('app_startup_overlay')), findsOneWidget);

    StartupCoordinator.instance.markReady();
    await tester.pump();
    expect(find.byKey(const ValueKey('app_startup_overlay')), findsNothing);
    expect(find.text('Home page'), findsOneWidget);
  });

  testWidgets('startup screen renders branded loader', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: ExamTheme.light(), home: const StartupScreen()),
    );

    expect(find.text('Exam Trainer'), findsOneWidget);
    expect(find.text('Prüfungstrainer wird vorbereitet …'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('startup error offers retry action', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ExamTheme.light(),
        home: StartupScreen(error: true, onRetry: () => retried = true),
      ),
    );

    await tester.tap(find.text('Erneut versuchen'));
    expect(retried, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
