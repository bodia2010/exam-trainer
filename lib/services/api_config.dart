class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Installed builds must work without extra --dart-define flags. Local
    // development can still target the Android emulator with:
    // --dart-define=API_BASE_URL=http://10.0.2.2:3000
    defaultValue: 'https://exam-trainer-api.vercel.app',
  );
}
