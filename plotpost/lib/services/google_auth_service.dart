import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Result of asking Google for an ID token.
class GoogleTokenResult {
  const GoogleTokenResult({this.idToken, this.cancelled = false, this.message = ''});

  final String? idToken;
  final bool cancelled;
  final String message;
}

/// Wraps the google_sign_in package (7.x). The app only needs a Google ID
/// token; the PlotPost server checks it with Google and logs the user in.
///
/// Needs the Web OAuth client ID from Google Cloud Console, passed as:
///   --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
/// The Android OAuth client (package digitus.com.plotpost + SHA-1) must also
/// exist in the same Google Cloud project, but its ID isn't used in code.
class GoogleAuthService {
  GoogleAuthService._();

  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static Future<void>? _initialized;

  static Future<void> _ensureInitialized() {
    return _initialized ??= GoogleSignIn.instance.initialize(
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    );
  }

  static Future<GoogleTokenResult> getIdToken() async {
    if (kIsWeb) {
      return const GoogleTokenResult(
        message: 'Google sign-in is available in the PlotPost mobile app.',
      );
    }
    if (serverClientId.isEmpty) {
      return const GoogleTokenResult(message: 'Google sign-in is not set up yet.');
    }
    try {
      await _ensureInitialized();
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        return const GoogleTokenResult(
          message: 'Google sign-in is not supported on this device.',
        );
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return const GoogleTokenResult(
          message: 'Google sign-in failed. Please try again.',
        );
      }
      return GoogleTokenResult(idToken: idToken);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return const GoogleTokenResult(cancelled: true, message: 'Sign-in cancelled.');
      }
      return const GoogleTokenResult(
        message: 'Google sign-in failed. Please try again.',
      );
    } catch (_) {
      return const GoogleTokenResult(
        message: 'Google sign-in failed. Please try again.',
      );
    }
  }

  /// Forgets the Google account on this phone so the next sign-in asks again.
  static Future<void> signOut() async {
    if (kIsWeb || serverClientId.isEmpty) return;
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Nothing to undo if Google sign-in was never used.
    }
  }
}
