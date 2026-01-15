import '../models/payment.dart';
import 'api_service.dart';

class PaymentService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> createPaymentIntent({
    required String appointmentId,
    required double amount,
    String currency = 'USD',
  }) async {
    try {
      final response = await _api.post('/payments/create-intent', data: {
        'appointmentId': appointmentId,
        'amount': amount,
        'currency': currency,
      });
      return response.data;
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }

  Future<Payment> confirmPayment({
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    try {
      final response = await _api.post('/payments/confirm', data: {
        'paymentIntentId': paymentIntentId,
        'paymentMethodId': paymentMethodId,
      });
      return Payment.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to confirm payment: $e');
    }
  }

  Future<List<Payment>> getPayments() async {
    try {
      final response = await _api.get('/payments');
      final List<dynamic> data = response.data;
      return data.map((json) => Payment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch payments: $e');
    }
  }

  Future<Payment> getPayment(String paymentId) async {
    try {
      final response = await _api.get('/payments/$paymentId');
      return Payment.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch payment: $e');
    }
  }

  Future<void> refundPayment(String paymentId) async {
    try {
      await _api.post('/payments/$paymentId/refund', data: {});
    } catch (e) {
      throw Exception('Failed to refund payment: $e');
    }
  }
}
