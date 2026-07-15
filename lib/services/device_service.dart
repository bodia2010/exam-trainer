import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'api_config.dart';
import 'auth_service.dart';

enum DeviceCheckResult { allowed, limitReached }

/// Firebase Auth places no limit on how many devices can be signed into
/// the same account at once — a leaked or resold login/password otherwise
/// costs nothing extra to use. This registers the current device against
/// the account (server-side, via /api/device) and enforces a hard cap —
/// the only real check against that risk.
class DeviceService {
  DeviceService._();
  static final instance = DeviceService._();
  static const _deviceIdKey = 'device_id';
  static const _timeout = Duration(seconds: 15);

  /// Test seam for stubbing the device-gate HTTP calls. `null` (the
  /// default, untouched in production) means "use the shared production
  /// client".
  @visibleForTesting
  static http.Client? debugHttpClient;

  final http.Client _productionHttpClient = http.Client();
  http.Client get _httpClient => debugHttpClient ?? _productionHttpClient;

  /// Test seam standing in for [AuthService.requireIdToken] — a plain unit
  /// test has no real signed-in Firebase user/app. `null` (the default,
  /// untouched in production) means "use the real Firebase ID token".
  @visibleForTesting
  static Future<String> Function()? debugIdTokenOverride;

  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceIdKey);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_deviceIdKey, id);
    }
    return id;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token =
        await (debugIdTokenOverride?.call() ??
            AuthService.instance.requireIdToken());
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// CR-10 product decision: the ONLY outcome that ever blocks is a genuine
  /// `200 {allowed: false}` from the backend. An auth failure (401/403), a
  /// server error (5xx), a malformed response, or offline/timeout all fail
  /// open exactly like today — a paying user must never be locked out by a
  /// transient backend problem. The categories are still told apart below
  /// (distinct debugPrint per case) purely for diagnosability; none of them
  /// changes the returned result.
  Future<DeviceCheckResult> registerDevice() async {
    final http.Response res;
    try {
      final deviceId = await getDeviceId();
      res = await _httpClient
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/device'),
            headers: await _authHeaders(),
            body: jsonEncode({
              'deviceId': deviceId,
              'deviceName': await _deviceName(),
            }),
          )
          .timeout(_timeout);
    } catch (e) {
      debugPrint('Device gate: network/timeout ($e) — failing open.');
      return DeviceCheckResult.allowed;
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      debugPrint('Device gate: auth error (${res.statusCode}) — failing open.');
      return DeviceCheckResult.allowed;
    }
    if (res.statusCode != 200) {
      debugPrint(
        'Device gate: server error (${res.statusCode}) — failing open.',
      );
      return DeviceCheckResult.allowed;
    }
    final Object? allowed;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('response must be an object');
      }
      allowed = decoded['allowed'];
      if (allowed is! bool) {
        throw const FormatException('allowed must be a boolean');
      }
    } catch (e) {
      debugPrint('Device gate: malformed response ($e) — failing open.');
      return DeviceCheckResult.allowed;
    }
    return allowed ? DeviceCheckResult.allowed : DeviceCheckResult.limitReached;
  }

  /// Unlike [registerDevice] this is a user-initiated action (tapping "use
  /// this device" on the limit screen) with a real cost if it silently
  /// fails: the caller must NOT treat the request as successful, evict its
  /// UI state, and navigate to Home unless the backend actually confirmed
  /// it. Returns whether the call is confirmed successful.
  Future<bool> forceRegisterCurrentDevice() async {
    try {
      final deviceId = await getDeviceId();
      final res = await _httpClient
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/device/force'),
            headers: await _authHeaders(),
            body: jsonEncode({
              'deviceId': deviceId,
              'deviceName': await _deviceName(),
            }),
          )
          .timeout(_timeout);
      if (res.statusCode != 200) return false;
      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic> && decoded['ok'] == true;
    } catch (e) {
      debugPrint('Device force-register failed: $e');
      return false;
    }
  }

  Future<String> _deviceName() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return '${info.brand} ${info.model}';
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return info.name;
      }
    } catch (_) {}
    return 'Unknown Device';
  }
}
