import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

class GoogleAuthService {
  static final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '648637095953-hqn00mf8e9ua3c6c3go3r08jffku9kql.apps.googleusercontent.com',
  );

  /// Signs in with Google and authenticates with backend.
  /// Returns same result as ApiService.login() — has 'token', 'user', etc.
  static Future<Map<String, dynamic>?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null; // user cancelled

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) return null;

      return await ApiService.loginWithGoogle(idToken: idToken);
    } catch (e) {
      print('GOOGLE SIGN IN ERROR: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('GOOGLE SIGN OUT ERROR: $e');
    }
  }
}
