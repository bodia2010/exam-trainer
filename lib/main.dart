import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // No FirebaseOptions passed — Android reads android/app/google-services.json
  // natively via the Google services Gradle plugin.
  await Firebase.initializeApp();
  runApp(const ExamTrainerApp());
}
