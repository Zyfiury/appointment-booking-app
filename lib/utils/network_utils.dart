import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Network utility functions
class NetworkUtils {
  /// Check if device is online
  static Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Get user-friendly error message from DioException
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please check your internet connection and try again.';
        
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network settings.';
        
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final errorMessage = error.response?.data?['error'] ?? 
                              error.response?.data?['message'];
          
          if (errorMessage != null) {
            return errorMessage.toString();
          }
          
          switch (statusCode) {
            case 400:
              return 'Invalid request. Please check your input.';
            case 401:
              return 'Session expired. Please log in again.';
            case 403:
              return 'You don\'t have permission to perform this action.';
            case 404:
              return 'Resource not found.';
            case 409:
              return 'This action conflicts with existing data.';
            case 422:
              return 'Invalid data provided. Please check your input.';
            case 500:
              return 'Server error. Please try again later.';
            case 503:
              return 'Service temporarily unavailable. Please try again later.';
            default:
              return 'An error occurred. Please try again.';
          }
        
        case DioExceptionType.cancel:
          return 'Request cancelled.';
        
        case DioExceptionType.sendTimeout:
          return 'Request timeout. Please try again.';
        
        case DioExceptionType.badCertificate:
          return 'Security certificate error. Please contact support.';
        
        case DioExceptionType.unknown:
        default:
          if (error.error is SocketException) {
            return 'No internet connection. Please check your network.';
          }
          return 'Network error. Please check your connection and try again.';
      }
    }
    
    return error.toString().replaceAll('Exception: ', '');
  }

  /// Check if error is network-related
  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
             error.type == DioExceptionType.connectionTimeout ||
             error.type == DioExceptionType.receiveTimeout ||
             error.error is SocketException;
    }
    return false;
  }

  /// Check if error is retryable
  static bool isRetryable(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      // Don't retry client errors (4xx) except 408, 429
      if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        return statusCode == 408 || statusCode == 429;
      }
      // Retry server errors (5xx) and network errors
      return statusCode == null || statusCode >= 500;
    }
    return false;
  }
}
