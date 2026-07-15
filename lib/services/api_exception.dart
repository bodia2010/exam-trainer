import 'package:http/http.dart' as http;

/// Coarse, UI-safe category for a failed backend call. Deliberately does
/// NOT carry the raw response body, including in diagnostic text. See CR-11:
/// a raw `Exception('...${res.statusCode}: ${res.body}')`
/// used to be the only signal available, so any future caller that ever
/// printed the exception risked leaking a backend stack trace, an internal
/// error message, or (for other endpoints) response content to the user.
enum ApiErrorKind {
  /// 401 — the ID token was rejected. The session itself is the problem;
  /// retrying the same request can't help without re-authenticating.
  unauthorized,

  /// 403 — the request was authenticated but rejected by policy (e.g. a
  /// free-tier account importing a brand-new document, which requires
  /// Premium). Retrying is pointless without changing the request itself.
  forbidden,

  /// 413 — the request body was rejected as too large.
  payloadTooLarge,

  /// 429 — a rate/quota limit was hit. Worth retrying, but only after a
  /// real delay, not immediately.
  rateLimited,

  /// Any 5xx, or a 200 whose body didn't parse the way the caller expected
  /// (a bug or transient backend issue either way) — worth an immediate
  /// retry.
  serverError,

  /// The request never got a response at all (offline, DNS, connection
  /// reset, or [ApiException.timeout]).
  networkOrTimeout,

  /// Any other status code not covered above.
  unknown,
}

/// Typed error for a failed `exam-trainer-api` call. [statusCode] and
/// [kind] are always safe to branch on for UI copy. Diagnostic details expose
/// only metadata, never backend response content.
class ApiException implements Exception {
  const ApiException._({
    required this.kind,
    required this.statusCode,
    required this.retryable,
    required this.debugDetails,
  });

  final ApiErrorKind kind;
  final int? statusCode;

  /// Whether an immediate retry of the same request has any real chance of
  /// succeeding. `false` for unauthorized/forbidden/payloadTooLarge (the
  /// request itself needs to change first) and for rateLimited (needs a
  /// real delay, not an instant retry).
  final bool retryable;

  /// Endpoint context, status, and response size for diagnostics. The raw
  /// response is deliberately excluded because crash logs can be exported.
  final String debugDetails;

  factory ApiException.fromResponse(String context, http.Response res) {
    final kind = switch (res.statusCode) {
      401 => ApiErrorKind.unauthorized,
      403 => ApiErrorKind.forbidden,
      413 => ApiErrorKind.payloadTooLarge,
      429 => ApiErrorKind.rateLimited,
      _ when res.statusCode >= 500 => ApiErrorKind.serverError,
      _ => ApiErrorKind.unknown,
    };
    final retryable = switch (kind) {
      ApiErrorKind.unauthorized ||
      ApiErrorKind.forbidden ||
      ApiErrorKind.payloadTooLarge ||
      ApiErrorKind.rateLimited => false,
      ApiErrorKind.serverError || ApiErrorKind.unknown => true,
      ApiErrorKind.networkOrTimeout => true,
    };
    return ApiException._(
      kind: kind,
      statusCode: res.statusCode,
      retryable: retryable,
      debugDetails:
          '$context ${res.statusCode}; responseBytes=${res.bodyBytes.length}',
    );
  }

  factory ApiException.malformedResponse(String context, Object error) =>
      ApiException._(
        kind: ApiErrorKind.serverError,
        statusCode: null,
        retryable: true,
        debugDetails: '$context malformed response: $error',
      );

  factory ApiException.networkOrTimeout(String context, Object error) =>
      ApiException._(
        kind: ApiErrorKind.networkOrTimeout,
        statusCode: null,
        retryable: true,
        debugDetails: '$context network/timeout: $error',
      );

  @override
  String toString() => 'ApiException(kind: $kind, statusCode: $statusCode)';
}
