import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../l10n/strings.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';

class DeviceLimitScreen extends StatefulWidget {
  const DeviceLimitScreen({super.key});

  @override
  State<DeviceLimitScreen> createState() => _DeviceLimitScreenState();
}

class _DeviceLimitScreenState extends State<DeviceLimitScreen> {
  bool _loading = false;

  Future<void> _useThisDevice() async {
    setState(() => _loading = true);
    try {
      await DeviceService.instance.forceRegisterCurrentDevice();
      deviceGateAllow();
      if (mounted) context.go('/');
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.devices_other_rounded,
                    color: Colors.white, size: 48),
              ),
              const SizedBox(height: 32),
              Text(
                s.deviceLimitTitel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.deviceLimitBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _useThisDevice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A237E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF1A237E),
                          ),
                        )
                      : Text(
                          s.deviceLimitBenutzen,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _signOut,
                child: Text(
                  s.abmelden,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
