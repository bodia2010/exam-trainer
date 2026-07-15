import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wraps Firebase Auth + Google Sign-In. Every backend request now carries
/// this user's Firebase ID token instead of the single shared APP_SECRET
/// that used to be baked into every build of the app — extractable from any
/// APK and, once leaked, usable to run up the Gemini/Upstash bill with no
/// way to tell which install was responsible.
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  // "Web client ID" from Firebase Console -> Authentication -> Sign-in
  // method -> Google -> Web SDK configuration. Not a secret — it's a public
  // OAuth client identifier, safe to compile into the app.
  static const _webClientId =
      '1090518699549-q6qt8rcshncv9vumh8c2m87d0lf1f5df.apps.googleusercontent.com';

  bool _googleSignInReady = false;

  Future<void> _ensureGoogleSignInReady() async {
    if (_googleSignInReady) return;
    await GoogleSignIn.instance.initialize(serverClientId: _webClientId);
    _googleSignInReady = true;
  }

  Stream<User?> get authStateChanges =>
      FirebaseAuth.instance.authStateChanges();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleSignInReady();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw Exception('Google не вернул idToken — попробуйте ещё раз.');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail(String email, String password) {
    return FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (_googleSignInReady) {
      await GoogleSignIn.instance.signOut();
    }
  }

  /// The token every backend request now authenticates with. Firebase
  /// caches and auto-refreshes this locally — cheap to call before every
  /// request, no manual expiry handling needed.
  Future<String> requireIdToken() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Не авторизован');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('Не удалось получить токен авторизации');
    }
    return token;
  }
}
