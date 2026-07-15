import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'services/auth_service.dart';
import 'services/locale_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/import_screen.dart';
import 'screens/course_screen.dart';
import 'screens/section_list_screen.dart';
import 'screens/hoeren_teil1_exercise_screen.dart';
import 'screens/telefonnotiz_exercise_screen.dart';
import 'screens/sprachbausteine_exercise_screen.dart';
import 'screens/sprachbausteine2_exercise_screen.dart';
import 'screens/beschwerde_exercise_screen.dart';
import 'screens/universal_exercise_screen.dart';
import 'screens/sprechen_levels_screen.dart';
import 'screens/sprechen_screen.dart';
import 'screens/sprechen_teil1_list_screen.dart';
import 'screens/sprechen_exercise_screen.dart';
import 'screens/smalltalk_list_screen.dart';
import 'screens/smalltalk_exercise_screen.dart';
import 'screens/sprechen_teil3_list_screen.dart';
import 'screens/sprechen_teil3_exercise_screen.dart';
import 'screens/legal/impressum_screen.dart';
import 'screens/legal/privacy_policy_screen.dart';
import 'screens/legal/terms_screen.dart';
import 'screens/device_limit_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/probe_pruefung_screen.dart';
import 'screens/exam_profile_screen.dart';
import 'services/device_service.dart';
import 'ui/core/theme/exam_theme.dart';

/// Turns Firebase's auth-state stream into a Listenable GoRouter can watch,
/// so a sign-in/sign-out anywhere in the app immediately re-runs [redirect]
/// instead of waiting for the next unrelated navigation.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh() {
    _sub = AuthService.instance.authStateChanges.listen((_) {
      _resetDeviceGate();
      notifyListeners();
    });
  }
  late final StreamSubscription _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// The device-registration check (/api/device) only needs to run once per
// signed-in session, not on every navigation redirect fires for — result is
// cached here until sign-out. `deviceGateAllow()` lets the device-limit
// screen mark the gate open immediately after evicting other devices,
// without waiting for another network round trip.
String? _deviceGateUid;
bool _deviceGateAllowed = true;

void _resetDeviceGate() {
  _deviceGateUid = null;
  _deviceGateAllowed = true;
}

void deviceGateAllow() {
  _deviceGateUid = AuthService.instance.currentUser?.uid;
  _deviceGateAllowed = true;
}

Future<bool> _deviceGateCheck(String uid) async {
  if (_deviceGateUid == uid) return _deviceGateAllowed;
  final result = await DeviceService.instance.registerDevice();
  _deviceGateUid = uid;
  _deviceGateAllowed = result == DeviceCheckResult.allowed;
  return _deviceGateAllowed;
}

final router = GoRouter(
  refreshListenable: _AuthRefresh(),
  redirect: (context, state) async {
    final uid = AuthService.instance.currentUser?.uid;
    final loggedIn = uid != null;
    final onLoginPage = state.matchedLocation == '/login';
    final onDeviceLimitPage = state.matchedLocation == '/device-limit';
    // Legal pages must be readable BEFORE registering (the sign-up consent
    // checkbox links to them), so they bypass the login wall.
    const publicPages = {'/login', '/impressum', '/privacy-policy', '/terms'};
    if (!loggedIn && !publicPages.contains(state.matchedLocation)) {
      return '/login';
    }
    if (loggedIn && onLoginPage) return '/';
    if (loggedIn &&
        !onDeviceLimitPage &&
        !publicPages.contains(state.matchedLocation)) {
      final allowed = await _deviceGateCheck(uid);
      if (!allowed) return '/device-limit';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(
      path: '/device-limit',
      builder: (_, _) => const DeviceLimitScreen(),
    ),
    GoRoute(path: '/impressum', builder: (_, _) => const ImpressumScreen()),
    GoRoute(
      path: '/privacy-policy',
      builder: (_, _) => const PrivacyPolicyScreen(),
    ),
    GoRoute(path: '/terms', builder: (_, _) => const TermsScreen()),
    GoRoute(path: '/favorites', builder: (_, _) => const FavoritesScreen()),
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/exam-profile',
      builder: (_, _) => const ExamProfileScreen(),
    ),
    GoRoute(
      path: '/import',
      builder: (_, state) => ImportScreen(profile: state.extra as ExamProfile?),
    ),
    // Sprechen ("Mündliche Prüfung"): fixed topic banks, independent of any
    // imported PDF course — lives at the top level, not nested under
    // /course/:id. /sprechen picks a level (only b2-beruf ships content
    // today; more levels are just another sibling route + LevelsScreen
    // card later, not a routing rework).
    GoRoute(
      path: '/sprechen',
      builder: (_, _) => const SprechenLevelsScreen(),
      routes: [
        GoRoute(
          path: 'b2-beruf',
          builder: (_, _) => const SprechenScreen(),
          routes: [
            GoRoute(
              path: 'teil1',
              builder: (_, _) => const SprechenTeil1ListScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => SprechenExerciseScreen(
                    exerciseId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'teil2',
              builder: (_, _) => const SmalltalkListScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => SmalltalkExerciseScreen(
                    exerciseId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'teil3',
              builder: (_, _) => const SprechenTeil3ListScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => SprechenTeil3ExerciseScreen(
                    exerciseId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/course/:id',
      builder: (_, state) => CourseScreen(id: state.pathParameters['id']!),
      routes: [
        // Declared before ':section' so this static segment wins the match
        // instead of being swallowed as a (nonexistent) section type.
        GoRoute(
          path: 'probe-pruefung',
          builder: (_, state) =>
              ProbePruefungScreen(courseId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: ':section',
          builder: (_, state) => SectionListScreen(
            courseId: state.pathParameters['id']!,
            sectionType: state.pathParameters['section']!,
          ),
          routes: [
            GoRoute(
              path: ':index',
              builder: (_, state) {
                final courseId = state.pathParameters['id']!;
                final section = state.pathParameters['section']!;
                final index = int.parse(state.pathParameters['index']!);
                return switch (section) {
                  'telefonnotiz' => TelefonnotizExerciseScreen(
                    courseId: courseId,
                    index: index,
                  ),
                  'sprachbausteine_teil1' => SprachbausteineExerciseScreen(
                    courseId: courseId,
                    index: index,
                  ),
                  'hoeren_teil1' => HoerenTeil1ExerciseScreen(
                    courseId: courseId,
                    index: index,
                  ),
                  'beschwerde' => BeschwerdeExerciseScreen(
                    courseId: courseId,
                    index: index,
                  ),
                  'sprachbausteine_teil2' => Sprachbausteine2ExerciseScreen(
                    courseId: courseId,
                    index: index,
                  ),
                  // All other sections use the universal schema/screen
                  _ => UniversalExerciseScreen(
                    courseId: courseId,
                    sectionType: section,
                    index: index,
                  ),
                };
              },
            ),
          ],
        ),
      ],
    ),
  ],
);

class ExamTrainerApp extends StatefulWidget {
  const ExamTrainerApp({super.key});

  @override
  State<ExamTrainerApp> createState() => _ExamTrainerAppState();
}

class _ExamTrainerAppState extends State<ExamTrainerApp> {
  @override
  void initState() {
    super.initState();
    LocaleService.instance.addListener(_onLocaleChanged);
    LocaleService.instance.load();
  }

  void _onLocaleChanged() => setState(() {});

  @override
  void dispose() {
    LocaleService.instance.removeListener(_onLocaleChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manualLocale = LocaleService.instance.locale;
    return MaterialApp.router(
      title: 'Exam Trainer',
      routerConfig: router,
      theme: ExamTheme.light(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de'),
        Locale('en'),
        Locale('ru'),
        Locale('uk'),
      ],
      locale: manualLocale ?? const Locale('de'),
    );
  }
}
