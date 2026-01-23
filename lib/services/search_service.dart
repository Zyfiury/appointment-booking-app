import '../models/provider.dart';
import '../models/service.dart';
import 'api_service.dart';

class SearchFilters {
  final String? query;
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final double? latitude;
  final double? longitude;
  final double? radius; // in kilometers
  final String? sortBy; // 'rating', 'price', 'distance', 'name'

  SearchFilters({
    this.query,
    this.category,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.latitude,
    this.longitude,
    this.radius,
    this.sortBy,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (query != null && query!.isNotEmpty) params['q'] = query;
    if (category != null) params['category'] = category;
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    if (minRating != null) params['minRating'] = minRating;
    if (latitude != null) params['latitude'] = latitude;
    if (longitude != null) params['longitude'] = longitude;
    if (radius != null) params['radius'] = radius;
    if (sortBy != null) params['sortBy'] = sortBy;
    return params;
  }
}

class SearchService {
  final ApiService _api = ApiService();

  Future<List<Provider>> searchProviders(SearchFilters filters) async {
    try {
      final response = await _api.get(
        '/users/providers/search',
        queryParameters: filters.toQueryParams(),
      );
      final List<dynamic> data = response.data;
      return data.map((json) => Provider.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search providers: $e');
    }
  }

  Future<List<Service>> searchServices(SearchFilters filters) async {
    try {
      final response = await _api.get(
        '/services/search',
        queryParameters: filters.toQueryParams(),
      );
      final List<dynamic> data = response.data;
      return data.map((json) => Service.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search services: $e');
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await _api.get('/services/categories');
      return List<String>.from(response.data);
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }
}
