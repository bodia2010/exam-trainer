import 'package:exam_trainer/services/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('installed builds use the production API by default', () {
    expect(ApiConfig.baseUrl, 'https://exam-trainer-api.vercel.app');
  });
}
