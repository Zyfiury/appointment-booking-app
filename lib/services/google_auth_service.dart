import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';

class GoogleAuthService {
  // For Android, we use the client ID from AndroidManifest (strings.xml)
  // For server-side verification, we'll use serverClientId
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // serverClientId is optional on Android - it will use the one from AndroidManifest
    // But we set it explicitly for backend token verification
    serverClientId: '621611382404-4icdg8qfel11ls8vt33jgdgqfc65o0lm.apps.googleusercontent.com',
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
