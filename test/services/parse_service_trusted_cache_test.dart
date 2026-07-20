import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:exam_trainer/services/parse_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final service = ParseService.instance;

  Map<String, dynamic> validComplaint() => {
    'variant_number': 1,
    'texts': ['Beschwerdetext'],
    'questions': [
      {'number': 1, 'type': 'true_false', 'answer': 'richtig'},
      {'number': 2, 'type': 'true_false', 'answer': 'falsch'},
    ],
  };

  setUp(() {
    ParseService.debugAuthHeaders = const {'Authorization': 'Bearer test'};
  });

  tearDown(() {
    ParseService.debugHttpClient = null;
    ParseService.debugAuthHeaders = null;
  });

  test(
    'discovery publishes the exact parsed value with backend proof',
    () async {
      const markdown = 'first line\nsecond line';
      const proof = 'signed-discovery-capability';
      final parsed = [
        {
          'section_type': 'beschwerde',
          'variant_number': 1,
          'start_line': 0,
          'anchor': 'first line',
        },
      ];
      final cacheWrite = Completer<Map<String, dynamic>>();

      ParseService.debugHttpClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/cache') {
          return http.Response(jsonEncode({'hit': false}), 200);
        }
        if (request.url.path == '/api/parse') {
          return http.Response(
            jsonEncode(parsed),
            200,
            headers: {'X-Exam-Trainer-Cache-Proof': proof},
          );
        }
        if (request.method == 'POST' && request.url.path == '/api/cache') {
          cacheWrite.complete(jsonDecode(request.body) as Map<String, dynamic>);
          return http.Response(jsonEncode({'ok': true}), 200);
        }
        fail('Unexpected request: ${request.method} ${request.url}');
      });

      final discovered = await service.discoverSections(markdown);
      final write = await cacheWrite.future.timeout(const Duration(seconds: 1));
      final hash = sha256.convert(utf8.encode('discover|$markdown'));

      expect(discovered, hasLength(1));
      expect(write['hash'], 'v30|discover|$hash');
      expect(write['value'], parsed);
      expect(write['proof'], proof);
    },
  );

  test('validated group publishes raw backend value with proof', () async {
    const proof = 'signed-group-capability';
    final raw = [validComplaint()];
    final cacheWrite = Completer<Map<String, dynamic>>();

    ParseService.debugHttpClient = MockClient((request) async {
      if (request.method == 'GET' && request.url.path == '/api/cache') {
        return http.Response(jsonEncode({'hit': false}), 200);
      }
      if (request.url.path == '/api/parse') {
        return http.Response(
          jsonEncode(raw),
          200,
          headers: {'X-Exam-Trainer-Cache-Proof': proof},
        );
      }
      if (request.method == 'POST' && request.url.path == '/api/cache') {
        cacheWrite.complete(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response(jsonEncode({'ok': true}), 200);
      }
      fail('Unexpected request: ${request.method} ${request.url}');
    });

    final result = await service.parseVariantGroups(const [
      VariantGroup(variantNumber: 1, chunks: ['source']),
    ], 'beschwerde');
    final write = await cacheWrite.future.timeout(const Duration(seconds: 1));

    expect(result.errors, isEmpty);
    expect(result.items, hasLength(1));
    expect(write['value'], raw);
    expect(write['proof'], proof);
  });

  test('a parse response without proof cannot trigger a cache write', () async {
    var cachePosts = 0;
    ParseService.debugHttpClient = MockClient((request) async {
      if (request.method == 'GET' && request.url.path == '/api/cache') {
        return http.Response(jsonEncode({'hit': false}), 200);
      }
      if (request.url.path == '/api/parse') {
        return http.Response(
          jsonEncode([
            {
              'section_type': 'beschwerde',
              'variant_number': 1,
              'start_line': 0,
              'anchor': 'first line',
            },
          ]),
          200,
        );
      }
      if (request.method == 'POST' && request.url.path == '/api/cache') {
        cachePosts++;
        return http.Response(jsonEncode({'ok': true}), 200);
      }
      fail('Unexpected request: ${request.method} ${request.url}');
    });

    await service.discoverSections('first line');
    await Future<void>.delayed(Duration.zero);

    expect(cachePosts, 0);
  });

  test('invalid fresh discovery is not published despite a proof', () async {
    var cachePosts = 0;
    ParseService.debugHttpClient = MockClient((request) async {
      if (request.method == 'GET' && request.url.path == '/api/cache') {
        return http.Response(jsonEncode({'hit': false}), 200);
      }
      if (request.url.path == '/api/parse') {
        return http.Response(
          jsonEncode([
            {
              'section_type': 'beschwerde',
              'variant_number': 1,
              'start_line': 0,
              'anchor': 'hallucinated heading',
            },
          ]),
          200,
          headers: {'X-Exam-Trainer-Cache-Proof': 'must-not-be-used'},
        );
      }
      if (request.method == 'POST' && request.url.path == '/api/cache') {
        cachePosts++;
        return http.Response(jsonEncode({'ok': true}), 200);
      }
      fail('Unexpected request: ${request.method} ${request.url}');
    });

    await service.discoverSections('real source heading');
    await Future<void>.delayed(Duration.zero);

    expect(cachePosts, 0);
  });

  test(
    'invalid cached discovery is treated as a miss and self-heals',
    () async {
      var parseCalls = 0;
      var cachePosts = 0;
      ParseService.debugHttpClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/cache') {
          return http.Response(jsonEncode({'hit': true, 'value': []}), 200);
        }
        if (request.url.path == '/api/parse') {
          parseCalls++;
          return http.Response(
            jsonEncode([
              {
                'section_type': 'beschwerde',
                'variant_number': 1,
                'start_line': 0,
                'anchor': 'real source heading',
              },
            ]),
            200,
            headers: {'X-Exam-Trainer-Cache-Proof': 'replacement-proof'},
          );
        }
        if (request.method == 'POST' && request.url.path == '/api/cache') {
          cachePosts++;
          return http.Response(jsonEncode({'ok': true}), 200);
        }
        fail('Unexpected request: ${request.method} ${request.url}');
      });

      final result = await service.discoverSections('real source heading');
      await Future<void>.delayed(Duration.zero);

      expect(parseCalls, 1);
      expect(cachePosts, 1);
      expect(result, hasLength(1));
    },
  );

  test(
    'malformed cached group is ignored and replaced by a fresh parse',
    () async {
      var parseCalls = 0;
      ParseService.debugHttpClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/cache') {
          return http.Response(
            jsonEncode({
              'hit': true,
              'value': [
                {'variant_number': 1, 'texts': [], 'questions': []},
              ],
            }),
            200,
          );
        }
        if (request.url.path == '/api/parse') {
          parseCalls++;
          return http.Response(jsonEncode([validComplaint()]), 200);
        }
        fail('Unexpected request: ${request.method} ${request.url}');
      });

      final result = await service.parseVariantGroups(const [
        VariantGroup(variantNumber: 1, chunks: ['source']),
      ], 'beschwerde');

      expect(parseCalls, 1);
      expect(result.errors, isEmpty);
      expect(result.items, hasLength(1));
    },
  );
}
