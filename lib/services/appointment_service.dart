import 'package:flutter/foundation.dart';
import '../models/appointment.dart';
import 'api_service.dart';

class AppointmentService {
  final ApiService _api = ApiService();

  Future<List<Appointment>> getAppointments() async {
    try {
      final response = await _api.get('/appointments');
      
      // Handle different response formats
      dynamic responseData = response.data;
      
      debugPrint('📦 Appointment response type: ${responseData.runtimeType}');
      
      // Check if response is an error object (401, 403, etc. now properly handled by Dio)
      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('error')) {
          final errorMsg = responseData['error'] ?? 'Unknown error';
          debugPrint('❌ API Error: $errorMsg');
          // If it's an auth error, return empty list (user will be logged out by interceptor)
          if (errorMsg.toString().toLowerCase().contains('token') || 
              errorMsg.toString().toLowerCase().contains('auth') ||
              errorMsg.toString().toLowerCase().contains('unauthorized')) {
            return [];
          }
          throw Exception(errorMsg);
        }
        
        // Check if it's a paginated response { data: [...], pagination: {...} }
        if (responseData.containsKey('data') && responseData['data'] is List) {
          debugPrint('📄 Paginated response detected, extracting data array');
          responseData = responseData['data'];
        } else if (!responseData.containsKey('data')) {
          // If it's a map but not paginated and not an error, log it
          debugPrint('⚠️ Unexpected map response: $responseData');
          throw Exception('Invalid response format: expected List, got Map with keys: ${responseData.keys.join(", ")}');
        }
      }
      
      // Ensure we have a list
      if (responseData is! List) {
        debugPrint('❌ Invalid response type: ${responseData.runtimeType}');
        debugPrint('   Response data: $responseData');
        throw Exception('Invalid response format: expected List, got ${responseData.runtimeType}');
      }
      
      final List<dynamic> data = responseData as List<dynamic>;
      debugPrint('✅ Parsing ${data.length} appointments');
      
      return data.map((json) {
        try {
          return Appointment.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          debugPrint('❌ Error parsing appointment: $e');
          debugPrint('   Appointment data: $json');
          rethrow;
        }
      }).toList();
    } on DioException catch (e) {
      // Handle Dio errors (401, 403, etc.)
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        debugPrint('❌ Authentication error: ${e.response?.statusCode}');
        return []; // Return empty list, token will be cleared by interceptor
      }
      debugPrint('❌ Failed to fetch appointments: ${e.message}');
      throw Exception('Failed to fetch appointments: ${e.message}');
    } catch (e) {
      debugPrint('❌ Failed to fetch appointments: $e');
      throw Exception('Failed to fetch appointments: $e');
    }
  }

  Future<Appointment> createAppointment({
    required String providerId,
    required String serviceId,
    required String date,
    required String time,
    String? notes,
  }) async {
    try {
      final response = await _api.post('/appointments', data: {
        'providerId': providerId,
        'serviceId': serviceId,
        'date': date,
        'time': time,
        'notes': notes,
      });
      return Appointment.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
    }
  }

  Future<void> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    try {
      await _api.patch('/appointments/$appointmentId', data: {
        'status': status,
      });
    } catch (e) {
      throw Exception('Failed to update appointment: $e');
    }
  }

  Future<void> rescheduleAppointment({
    required String appointmentId,
    required String date, // yyyy-mm-dd
    required String time, // HH:MM
  }) async {
    try {
      await _api.patch('/appointments/$appointmentId', data: {
        'date': date,
        'time': time,
      });
    } catch (e) {
      throw Exception('Failed to reschedule appointment: $e');
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _api.delete('/appointments/$appointmentId');
    } catch (e) {
      throw Exception('Failed to delete appointment: $e');
    }
  }
}
