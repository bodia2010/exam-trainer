import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../l10n/strings.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _busy = false;
  bool _gdprAccepted = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      // Successful sign-in updates FirebaseAuth's authStateChanges stream —
      // the router listens to that and navigates away on its own.
    } on GoogleSignInException catch (e) {
      // User closing the account picker isn't an error — nothing to show.
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      if (mounted) setState(() => _error = S.of(context).anmeldefehler);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _friendlyError(S.of(context), e));
    } catch (e) {
      debugPrint('Login error: $e');
      if (mounted) setState(() => _error = S.of(context).anmeldefehler);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(S s, FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-email' => s.ungueltigeEmail,
      'user-not-found' || 'wrong-password' || 'invalid-credential' =>
        s.falscheAnmeldedaten,
      'email-already-in-use' => s.emailBereitsRegistriert,
      'weak-password' => s.passwortZuSchwach,
      _ => e.message ?? s.anmeldefehler,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.school_rounded, size: 64, color: Color(0xFF1A237E)),
                const SizedBox(height: 16),
                const Text('Exam Trainer',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A237E))),
                const SizedBox(height: 8),
                Text(_isRegistering ? s.kontoErstellen : s.zumFortfahrenAnmelden,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 32),

                ElevatedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() => AuthService.instance.signInWithGoogle()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1F2937),
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.g_mobiledata, size: 28, color: Color(0xFF4285F4)),
                  label: Text(s.mitGoogleAnmelden,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),

                const SizedBox(height: 20),
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(s.oder, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 20),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: s.passwort,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_error!,
                        style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_isRegistering) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _gdprAccepted,
                        activeColor: const Color(0xFF1A237E),
                        onChanged: (v) =>
                            setState(() => _gdprAccepted = v ?? false),
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[700]),
                            children: [
                              TextSpan(text: s.ichAkzeptiereDie),
                              TextSpan(
                                text: s.datenschutzerklaerung,
                                style: const TextStyle(
                                    color: Color(0xFF1A237E),
                                    decoration: TextDecoration.underline),
                                recognizer: TapGestureRecognizer()
                                  ..onTap =
                                      () => context.push('/privacy-policy'),
                              ),
                              TextSpan(text: s.undDie),
                              TextSpan(
                                text: s.nutzungsbedingungen,
                                style: const TextStyle(
                                    color: Color(0xFF1A237E),
                                    decoration: TextDecoration.underline),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => context.push('/terms'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                ElevatedButton(
                  onPressed: _busy
                      ? null
                      : () {
                          if (_isRegistering && !_gdprAccepted) {
                            setState(() =>
                                _error = s.bitteDatenschutzZustimmen);
                            return;
                          }
                          _run(() async {
                            final email = _emailController.text.trim();
                            final password = _passwordController.text;
                            if (_isRegistering) {
                              await AuthService.instance
                                  .registerWithEmail(email, password);
                            } else {
                              await AuthService.instance
                                  .signInWithEmail(email, password);
                            }
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(_isRegistering ? s.registrieren : s.anmelden,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),

                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _isRegistering = !_isRegistering;
                            _error = null;
                          }),
                  child: Text(_isRegistering
                      ? s.bereitsRegistriert
                      : s.nochKeinKonto),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _LegalLink(
                        label: s.datenschutz,
                        onTap: () => context.push('/privacy-policy')),
                    Text('·',
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 11)),
                    _LegalLink(
                        label: s.nutzungsbedingungen,
                        onTap: () => context.push('/terms')),
                    Text('·',
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 11)),
                    _LegalLink(
                        label: s.impressum,
                        onTap: () => context.push('/impressum')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LegalLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.grey[500], fontSize: 11),
      ),
    );
  }
}
