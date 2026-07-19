import 'dart:convert';

import 'package:exam_trainer/services/parse_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  tearDown(() {
    ParseService.debugHttpClient = null;
    ParseService.debugAuthHeaders = null;
  });

  test(
    'answer repair rollout uses an isolated parse cache and opt-in format',
    () {
      expect(ParseService.debugParseCacheVersion, 'v38');
      expect(ParseService.debugAnswerMarkerHeaders, {
        'X-Exam-Trainer-Answer-Markers': 'v38',
      });
    },
  );

  test('parse request carries the v38 opt-in header', () async {
    late http.Request captured;
    ParseService.debugAuthHeaders = const {'Authorization': 'Bearer test'};
    ParseService.debugHttpClient = MockClient((request) async {
      captured = request;
      return http.Response(jsonEncode([]), 200);
    });

    await ParseService.instance.parseSection('fixture markdown', 'beschwerde');

    expect(captured.url.path, '/api/parse');
    expect(captured.headers['X-Exam-Trainer-Answer-Markers'], 'v38');
  });
}
