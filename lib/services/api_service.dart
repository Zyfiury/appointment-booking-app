import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'secure_storage_service.dart';

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

    // Always use production API for now (can be changed back to localhost for local development)
    // To use localhost: flutter run --dart-define=USE_LOCAL=true
    const useLocal = String.fromEnvironment('USE_LOCAL', defaultValue: 'false');
    if (useLocal == 'true') {
      // Development URLs
      if (kIsWeb) {
        return 'http://localhost:5000/api';
      }
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000/api';
      }
      return 'http://localhost:5000/api';
    }

    // Production API URL
    return 'https://accurate-solace-app22.up.railway.app/api';
  }

  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiService.baseUrl,
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 30), // Connection timeout
      receiveTimeout: const Duration(seconds: 30), // Response timeout
      sendTimeout: const Duration(seconds: 30), // Send timeout
      validateStatus: (status) => status != null && status < 400, // Only accept success status codes (< 400)
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        debugPrint('🌐 API Request: ${options.method} ${options.baseUrl}${options.path}');
        // Use secure storage for token
        final token = await SecureStorageService.getToken();
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
        debugPrint('   URL: ${error.requestOptions.baseUrl}${error.requestOptions.path}');
        if (error.response != null) {
          debugPrint('   Status: ${error.response?.statusCode}');
          debugPrint('   Data: ${error.response?.data}');
        } else {
          // Connection/timeout errors
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout) {
            debugPrint('   ⚠️ Connection timeout - Check network or server status');
            debugPrint('   Current API URL: ${ApiService.baseUrl}');
          }
        }
        if (error.response?.statusCode == 401) {
          // Token is invalid/expired - clear secure storage
          SecureStorageService.clearAll();
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
