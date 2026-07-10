import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
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
    final token = await AuthService.instance.requireIdToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<DeviceCheckResult> registerDevice() async {
    try {
      final deviceId = await getDeviceId();
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/device'),
            headers: await _authHeaders(),
            body: jsonEncode(
                {'deviceId': deviceId, 'deviceName': await _deviceName()}),
          )
          .timeout(_timeout);
      if (res.statusCode != 200) return DeviceCheckResult.allowed;
      final allowed =
          (jsonDecode(res.body) as Map<String, dynamic>)['allowed'] == true;
      return allowed ? DeviceCheckResult.allowed : DeviceCheckResult.limitReached;
    } catch (_) {
      // Fail open — a network hiccup here must never lock a paying user out.
      return DeviceCheckResult.allowed;
    }
  }

  Future<void> forceRegisterCurrentDevice() async {
    final deviceId = await getDeviceId();
    try {
      await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/device/force'),
            headers: await _authHeaders(),
            body: jsonEncode(
                {'deviceId': deviceId, 'deviceName': await _deviceName()}),
          )
          .timeout(_timeout);
    } catch (_) {}
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
