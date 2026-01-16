import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';

class GoogleAuthService {
  // Use the serverClientId from AndroidManifest.xml (default_web_client_id)
  // This is automatically read from strings.xml via AndroidManifest meta-data
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // serverClientId is automatically read from AndroidManifest.xml meta-data
    // If that doesn't work, uncomment and set explicitly:
    // serverClientId: '621611382404-3su41a8p8bucc44leffirbva6a3eac8p.apps.googleusercontent.com',
  );
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> signIn() async {
    try {
      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return {
          'success': false,
          'error': 'Sign in cancelled',
        };
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Send to backend for verification and token generation
      try {
        final response = await _apiService.post('/auth/google', data: {
          'idToken': googleAuth.idToken,
          'accessToken': googleAuth.accessToken,
          'email': googleUser.email,
          'name': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
        });

        return {
          'success': true,
          'token': response.data['token'],
          'user': response.data['user'],
        };
      } on DioException catch (e) {
        // If user doesn't exist, backend should create account
        if (e.response?.statusCode == 404) {
          return {
            'success': false,
            'error': 'Account not found. Please register first.',
          };
        }
        throw e;
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Google sign in failed: $e',
      };
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  Future<GoogleSignInAccount?> getCurrentUser() async {
    return _googleSignIn.currentUser;
  }
}
