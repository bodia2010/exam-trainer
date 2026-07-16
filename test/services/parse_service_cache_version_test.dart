import 'package:exam_trainer/services/parse_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('voice metadata rollout invalidates pre-metadata parse cache', () {
    expect(ParseService.debugParseCacheVersion, 'v37');
  });
}
