// CR-11: ApiException.toString() (the only thing a stray debugPrint/log
// line would ever show) and debugDetails must never include the raw response
// body. Status
// code -> kind/retryable mapping is also pinned here since import_screen.dart
// and ParseService._parseWithRetry both branch on it.
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:exam_trainer/services/api_exception.dart';

void main() {
  test('toString never includes the response body', () {
    final error = ApiException.fromResponse(
      'convert',
      http.Response('Stack trace: secret internal path /home/user/...', 500),
    );
    expect(error.toString(), isNot(contains('secret internal path')));
    expect(error.toString(), isNot(contains('Stack trace')));
    expect(error.debugDetails, isNot(contains('secret internal path')));
    expect(error.debugDetails, isNot(contains('Stack trace')));
  });

  test('debugDetails records size without copying a very long body', () {
    final error = ApiException.fromResponse(
      'convert',
      http.Response('x' * 1000, 500),
    );
    expect(error.debugDetails.length, lessThan(400));
    expect(error.debugDetails, contains('responseBytes=1000'));
    expect(error.debugDetails, isNot(contains('xxxxxxxx')));
  });

  final cases = <int, (ApiErrorKind, bool)>{
    401: (ApiErrorKind.unauthorized, false),
    403: (ApiErrorKind.forbidden, false),
    413: (ApiErrorKind.payloadTooLarge, false),
    429: (ApiErrorKind.rateLimited, false),
    500: (ApiErrorKind.serverError, true),
    503: (ApiErrorKind.serverError, true),
    418: (ApiErrorKind.unknown, true),
  };

  for (final entry in cases.entries) {
    test(
      'status ${entry.key} maps to ${entry.value.$1} (retryable: ${entry.value.$2})',
      () {
        final error = ApiException.fromResponse(
          'ctx',
          http.Response('', entry.key),
        );
        expect(error.statusCode, entry.key);
        expect(error.kind, entry.value.$1);
        expect(error.retryable, entry.value.$2);
      },
    );
  }

  test('networkOrTimeout has no status code and is retryable', () {
    final error = ApiException.networkOrTimeout('convert', 'timed out');
    expect(error.statusCode, isNull);
    expect(error.kind, ApiErrorKind.networkOrTimeout);
    expect(error.retryable, isTrue);
  });

  test('malformedResponse is serverError-shaped and retryable', () {
    final error = ApiException.malformedResponse('parse', 'bad json');
    expect(error.kind, ApiErrorKind.serverError);
    expect(error.retryable, isTrue);
  });
}
