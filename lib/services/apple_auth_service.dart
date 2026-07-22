import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'api_service.dart';

class AppleAuthService {
  /// Signs in with Apple and authenticates with backend.
  /// Returns same result as ApiService.login() — has 'token', 'user', etc.
  static Future<Map<String, dynamic>?> signIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null) return null;

      // Apple only sends the name on the very first authorization.
      final name = [credential.givenName, credential.familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ')
          .trim();

      return await ApiService.loginWithApple(
        idToken: idToken,
        name: name.isEmpty ? null : name,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null; // user cancelled
      print('APPLE SIGN IN ERROR: $e');
      return null;
    } catch (e) {
      print('APPLE SIGN IN ERROR: $e');
      return null;
    }
  }
}
