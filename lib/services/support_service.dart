import 'api_service.dart';

class SupportService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> contactSupport({
    required String subject,
    required String message,
    String? category,
  }) async {
    try {
      final response = await _api.post('/support/contact', data: {
        'subject': subject,
        'message': message,
        if (category != null) 'category': category,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to submit support request: $e');
    }
  }
}
