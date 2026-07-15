import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'ui/core/theme/exam_theme.dart';
import 'ui/features/startup/startup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapApp());
}

/// Paints the first Flutter frame immediately instead of holding the native
/// splash screen while Firebase starts. On a slow cold start the user now sees
/// an intentional branded loading screen rather than a frozen black window.
class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  late Future<void> _firebaseReady;

  Future<void> _initialize() async {
    final minimumDisplay = Future<void>.delayed(
      const Duration(milliseconds: 1200),
    );
    await Firebase.initializeApp();
    await Future.wait([minimumDisplay, prepareAppStartup()]);
  }

  @override
  void initState() {
    super.initState();
    _firebaseReady = _initialize();
  }

  void _retry() {
    setState(() => _firebaseReady = _initialize());
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ExamColors.canvas,
      child: FutureBuilder<void>(
        future: _firebaseReady,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasError) {
            return const ExamTrainerApp();
          }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ExamTheme.light(),
            home: StartupScreen(
              error: snapshot.hasError,
              onRetry: snapshot.hasError ? _retry : null,
            ),
          );
        },
      ),
    );
  }
}
