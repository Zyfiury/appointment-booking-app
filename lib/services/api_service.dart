import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  // Production URL: https://accurate-solace-app22.up.railway.app/api
  // For development, uses localhost/emulator URLs automatically
  // To use production API: flutter run --dart-define=API_URL=https://accurate-solace-app22.up.railway.app/api
  static String get baseUrl {
    // Check if API URL is set via environment variable (highest priority)
    const apiUrl = String.fromEnvironment('API_URL', defaultValue: '');
    if (apiUrl.isNotEmpty) {
      return apiUrl;
    }
    
    // Check if production mode is enabled
    if (AppConfig.isProduction && AppConfig.apiBaseUrl.isNotEmpty) {
      return AppConfig.apiBaseUrl;
    }
    
    // Development URLs (automatic detection)
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiService.baseUrl,
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        debugPrint('🌐 API Request: ${options.method} ${options.baseUrl}${options.path}');
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('✅ API Response: ${response.statusCode} ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('❌ API Error: ${error.type} - ${error.message}');
        if (error.response != null) {
          debugPrint('   Status: ${error.response?.statusCode}');
          debugPrint('   Data: ${error.response?.data}');
        }
        if (error.response?.statusCode == 401) {
          // Handle unauthorized - could trigger logout
        }
        return handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}
