import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _loading = false;

  User? get user => _user;
  String? get token => _token;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;

  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    _loading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      final userJson = prefs.getString('user');
      
      if (_token != null && userJson != null) {
        _user = User.fromJson(json.decode(userJson));
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _loading = true;
      _lastError = null;
      notifyListeners();

      final result = await _authService.login(email, password);
      
      if (result['success'] == true) {
        _token = result['token'];
        _user = User.fromJson(result['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(result['user']));

        _loading = false;
        _lastError = null;
        notifyListeners();
        return true;
      } else {
        _loading = false;
        _lastError = result['error'] ?? 'Login failed';
        debugPrint('Login error: $_lastError');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _loading = false;
      _lastError = 'Unexpected error: $e';
      debugPrint('Login exception: $e');
      notifyListeners();
      return false;
    }
  }

  String? _lastError;

  String? get lastError => _lastError;

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  }) async {
    try {
      _loading = true;
      _lastError = null;
      notifyListeners();

      final result = await _authService.register(
        email: email,
        password: password,
        name: name,
        role: role,
        phone: phone,
      );
      
      if (result['success'] == true) {
        _token = result['token'];
        _user = User.fromJson(result['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(result['user']));

        _loading = false;
        _lastError = null;
        notifyListeners();
        return true;
      } else {
        _loading = false;
        _lastError = result['error'] ?? 'Registration failed';
        debugPrint('Registration error: $_lastError');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _loading = false;
      _lastError = 'Unexpected error: $e';
      debugPrint('Registration exception: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    
    notifyListeners();
  }

  Future<void> loadUserProfile() async {
    try {
      final response = await _apiService.get('/users/profile');
      _user = User.fromJson(response.data);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(response.data));
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? profilePicture,
  }) async {
    try {
      _loading = true;
      _lastError = null;
      notifyListeners();

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      if (phone != null) updates['phone'] = phone;
      if (profilePicture != null) updates['profilePicture'] = profilePicture;

      final response = await _apiService.patch('/users/profile', data: updates);
      _user = User.fromJson(response.data);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(response.data));

      _loading = false;
      _lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      _lastError = 'Failed to update profile: $e';
      debugPrint('Update profile error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _loading = true;
      _lastError = null;
      notifyListeners();

      final googleAuthService = GoogleAuthService();
      final result = await googleAuthService.signIn();

      if (result['success'] == true) {
        _token = result['token'];
        _user = User.fromJson(result['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(result['user']));

        _loading = false;
        _lastError = null;
        notifyListeners();
        return true;
      } else {
        _loading = false;
        _lastError = result['error'] ?? 'Google sign in failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _loading = false;
      _lastError = 'Google sign in error: $e';
      debugPrint('Google sign in exception: $e');
      notifyListeners();
      return false;
    }
  }
}
