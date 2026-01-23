import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';

class GoogleAuthService {
  // For Android Google Sign-In, you need TWO OAuth clients:
  // 1. Android OAuth Client (in AndroidManifest/strings.xml) - identifies your app
  // 2. Web OAuth Client (serverClientId) - used for ID token requests
  // 
  // Android Client: 621611382404-4icdg8qfel11ls8vt33jgdgqfc65o0lm... (in AndroidManifest)
  // Web Client: 621611382404-5ok4d81afc7gl6av994evqa1hfmitchf... (for serverClientId)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Use Web OAuth Client ID for serverClientId (for backend token verification)
    serverClientId: '621611382404-5ok4d81afc7gl6av994evqa1hfmitchf.apps.googleusercontent.com',
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
        // Handle specific error types
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          return {
            'success': false,
            'error': 'Connection timeout. Please check if the backend server is running on port 5000.',
          };
        } else if (e.type == DioExceptionType.connectionError) {
          return {
            'success': false,
            'error': 'Cannot connect to server. Make sure the backend is running at http://10.0.2.2:5000',
          };
        } else if (e.response?.statusCode == 404) {
          return {
            'success': false,
            'error': 'Account not found. Please register first.',
          };
        } else if (e.response != null) {
          return {
            'success': false,
            'error': e.response?.data['error'] ?? 'Google sign in failed: ${e.message}',
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
