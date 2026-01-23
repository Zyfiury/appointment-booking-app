import 'package:dio/dio.dart';
import '../models/favorite.dart';
import '../models/provider.dart' as provider_model;
import 'api_service.dart';

class FavoriteService {
  final ApiService _api = ApiService();

  Future<List<provider_model.Provider>> getFavorites() async {
    try {
      final response = await _api.get('/favorites');
      return (response.data as List)
          .map((json) => provider_model.Provider.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load favorites: $e');
    }
  }

  Future<bool> isFavorite(String providerId) async {
    try {
      final response = await _api.get('/favorites/check/$providerId');
      return response.data['isFavorite'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> addFavorite(String providerId) async {
    try {
      await _api.post('/favorites/$providerId');
    } catch (e) {
      throw Exception('Failed to add favorite: $e');
    }
  }

  Future<void> removeFavorite(String providerId) async {
    try {
      await _api.delete('/favorites/$providerId');
    } catch (e) {
      throw Exception('Failed to remove favorite: $e');
    }
  }

  Future<void> toggleFavorite(String providerId, bool isCurrentlyFavorite) async {
    if (isCurrentlyFavorite) {
      await removeFavorite(providerId);
    } else {
      await addFavorite(providerId);
    }
  }
}
