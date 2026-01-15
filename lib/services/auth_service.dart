import 'package:dio/dio.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return {
        'success': true,
        'token': response.data['token'],
        'user': response.data['user'],
      };
    } catch (e) {
      String errorMessage = 'Login failed';
      if (e is DioException) {
        if (e.response != null) {
          errorMessage = e.response?.data['error'] ?? 
                        e.response?.data['message'] ?? 
                        'Login failed: ${e.response?.statusCode}';
        } else if (e.type == DioExceptionType.connectionTimeout ||
                   e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Connection timeout. Please check if the server is running.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Cannot connect to server. Please check if the server is running on http://localhost:5000';
        } else {
          errorMessage = e.message ?? 'Network error occurred';
        }
      } else {
        errorMessage = e.toString();
      }
      return {
        'success': false,
        'error': errorMessage,
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  }) async {
    try {
      final response = await _api.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
        'role': role,
        'phone': phone,
      });
      return {
        'success': true,
        'token': response.data['token'],
        'user': response.data['user'],
      };
    } catch (e) {
      String errorMessage = 'Registration failed';
      if (e is DioException) {
        if (e.response != null) {
          errorMessage = e.response?.data['error'] ?? 
                        e.response?.data['message'] ?? 
                        'Registration failed: ${e.response?.statusCode}';
        } else if (e.type == DioExceptionType.connectionTimeout ||
                   e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Connection timeout. Please check if the server is running.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Cannot connect to server. Please check if the server is running on http://localhost:5000';
        } else {
          errorMessage = e.message ?? 'Network error occurred';
        }
      } else {
        errorMessage = e.toString();
      }
      return {
        'success': false,
        'error': errorMessage,
      };
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await _api.get('/auth/me');
      return User.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }
}
