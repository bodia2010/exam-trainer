import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';

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

  @override
  void initState() {
    super.initState();
    _firebaseReady = Firebase.initializeApp();
  }

  void _retry() {
    setState(() => _firebaseReady = Firebase.initializeApp());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _firebaseReady,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return const ExamTrainerApp();
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: const Color(0xFF00838F),
            body: SafeArea(
              child: Center(
                child: snapshot.hasError
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Exam Trainer konnte nicht gestartet werden.',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _retry,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Erneut versuchen'),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Exam Trainer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 24),
                          CircularProgressIndicator(color: Colors.white),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
