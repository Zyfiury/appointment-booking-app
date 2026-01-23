import 'package:dio/dio.dart';
import 'api_service.dart';

class PolicyService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getCancellationPolicy() async {
    try {
      final response = await _api.get('/policies/cancellation');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch cancellation policy: $e');
    }
  }

  Future<Map<String, dynamic>> getTermsOfService() async {
    try {
      final response = await _api.get('/policies/terms');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch terms of service: $e');
    }
  }

  Future<Map<String, dynamic>> getPrivacyPolicy() async {
    try {
      final response = await _api.get('/policies/privacy');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch privacy policy: $e');
    }
  }
}
