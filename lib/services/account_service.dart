import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import 'course_storage.dart';
import 'favorites_service.dart';

enum AccountDeleteOutcome {
  /// Firestore data + Firebase Auth account both confirmed deleted.
  success,

  /// Firestore data is gone, but the Auth account itself survived —
  /// local data is still cleared (nothing left server-side to keep it in
  /// sync with), but the account needs a retry/support contact.
  partialFailure,

  /// Nothing was deleted (e.g. network error, or the Firestore step
  /// itself failed) — safe/expected to just retry, account is untouched.
  failure,
}

class AccountDeleteResult {
  final AccountDeleteOutcome outcome;
  final String? serverMessage;
  const AccountDeleteResult(this.outcome, [this.serverMessage]);
}

/// Handles the "delete my account" flow: calls the backend, which deletes
/// Firestore data + the Firebase Auth account, then clears whatever local
/// data is scoped to the current UID. Does NOT sign out or navigate —
/// callers (UI) own that decision based on the returned outcome.
class AccountService {
  AccountService._();
  static final instance = AccountService._();
  static const _timeout = Duration(seconds: 30);

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.instance.requireIdToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<AccountDeleteResult> deleteAccount() async {
    // Fetched BEFORE the call — once the backend deletes the Firebase Auth
    // account, this device's cached ID token stops being usable for
    // anything else anyway, so there's nothing to preserve by deferring it.
    final headers = await _authHeaders();

    http.Response res;
    try {
      res = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/api/account'),
            headers: headers,
          )
          .timeout(_timeout);
    } catch (_) {
      // Network failure: we genuinely don't know if the request even
      // reached the server. Treat as a full failure — nothing local is
      // cleared, the user is told to retry rather than left guessing.
      return const AccountDeleteResult(AccountDeleteOutcome.failure);
    }

    Map<String, dynamic> body = {};
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      // Non-JSON body (e.g. a gateway error page) — fall through with an
      // empty body, handled the same as any other non-2xx below.
    }

    if (res.statusCode == 200 && body['ok'] == true) {
      await _clearLocalData();
      return const AccountDeleteResult(AccountDeleteOutcome.success);
    }

    final message = body['error'] as String?;
    if (body['dataDeleted'] == true) {
      await _clearLocalData();
      return AccountDeleteResult(AccountDeleteOutcome.partialFailure, message);
    }

    return AccountDeleteResult(AccountDeleteOutcome.failure, message);
  }

  Future<void> _clearLocalData() async {
    await CourseStorage.instance.deleteAllLocal();
    await FavoritesService.instance.clearAll();
  }
}
