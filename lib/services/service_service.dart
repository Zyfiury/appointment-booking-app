import '../models/service.dart';
import '../models/provider.dart';
import 'api_service.dart';

class ServiceService {
  final ApiService _api = ApiService();

  Future<List<Provider>> getProviders() async {
    try {
      final response = await _api.get('/users/providers');
      final List<dynamic> data = response.data;
      return data.map((json) => Provider.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch providers: $e');
    }
  }

  Future<List<Service>> getServices({String? providerId}) async {
    try {
      final response = await _api.get(
        '/services',
        queryParameters: providerId != null ? {'providerId': providerId} : null,
      );
      final List<dynamic> data = response.data;
      return data.map((json) => Service.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch services: $e');
    }
  }

  Future<Service> createService({
    required String name,
    required String description,
    required int duration,
    required double price,
    required String category,
  }) async {
    try {
      final response = await _api.post('/services', data: {
        'name': name,
        'description': description,
        'duration': duration,
        'price': price,
        'category': category,
      });
      return Service.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create service: $e');
    }
  }

  Future<Service> updateService(
    String serviceId, {
    String? name,
    String? description,
    int? duration,
    double? price,
    String? category,
  }) async {
    try {
      final response = await _api.patch('/services/$serviceId', data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (duration != null) 'duration': duration,
        if (price != null) 'price': price,
        if (category != null) 'category': category,
      });
      return Service.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update service: $e');
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await _api.delete('/services/$serviceId');
    } catch (e) {
      throw Exception('Failed to delete service: $e');
    }
  }
}
