class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
  static const secret = String.fromEnvironment(
    'API_SECRET',
    defaultValue: 'test-secret',
  );
}
