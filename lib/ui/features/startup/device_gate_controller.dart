import 'dart:async';

import '../../../services/device_service.dart';

typedef DeviceGateCheck = Future<DeviceCheckResult> Function();
typedef CurrentUid = String? Function();

/// Keeps the non-blocking device check scoped to the active auth session.
/// A result from an older UID/generation is ignored before it can update
/// cached routing state or navigate.
class DeviceGateController {
  DeviceGateController({
    required DeviceGateCheck check,
    required CurrentUid currentUid,
    required void Function() onLimitReached,
  }) : this._(check, currentUid, onLimitReached);

  DeviceGateController._(this._check, this._currentUid, this._onLimitReached);

  final DeviceGateCheck _check;
  final CurrentUid _currentUid;
  final void Function() _onLimitReached;

  String? _checkedUid;
  String? _inFlightUid;
  var _allowed = true;
  var _generation = 0;

  bool isBlockedFor(String uid) => _checkedUid == uid && !_allowed;

  void reset() {
    _generation++;
    _checkedUid = null;
    _inFlightUid = null;
    _allowed = true;
  }

  void allow(String? uid) {
    _generation++;
    _checkedUid = uid;
    _inFlightUid = null;
    _allowed = true;
  }

  void ensureChecked(String uid) {
    if (_checkedUid == uid || _inFlightUid == uid) return;
    final generation = ++_generation;
    _inFlightUid = uid;
    unawaited(_run(uid, generation));
  }

  Future<void> _run(String uid, int generation) async {
    final result = await _check();
    if (generation != _generation || _currentUid() != uid) return;
    _inFlightUid = null;
    _checkedUid = uid;
    _allowed = result == DeviceCheckResult.allowed;
    if (!_allowed) _onLimitReached();
  }
}
