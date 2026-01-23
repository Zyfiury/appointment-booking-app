import 'package:dio/dio.dart';
import '../models/provider_image.dart';
import 'api_service.dart';

class ProviderImageService {
  final ApiService _api = ApiService();

  Future<List<ProviderImage>> getProviderImages(String providerId) async {
    try {
      final response = await _api.get('/provider-images/$providerId');
      return (response.data as List)
          .map((json) => ProviderImage.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load provider images: $e');
    }
  }

  Future<List<ProviderImage>> getMyImages() async {
    try {
      final response = await _api.get('/provider-images');
      return (response.data as List)
          .map((json) => ProviderImage.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load my images: $e');
    }
  }

  Future<ProviderImage> addImage({
    required String url,
    String? caption,
    String type = 'gallery',
    int order = 0,
  }) async {
    try {
      final response = await _api.post('/provider-images', data: {
        'url': url,
        'caption': caption,
        'type': type,
        'order': order,
      });
      return ProviderImage.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to add image: $e');
    }
  }

  Future<ProviderImage> updateImage(String id, {
    String? url,
    String? caption,
    String? type,
    int? order,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (url != null) data['url'] = url;
      if (caption != null) data['caption'] = caption;
      if (type != null) data['type'] = type;
      if (order != null) data['order'] = order;

      final response = await _api.patch('/provider-images/$id', data: data);
      return ProviderImage.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update image: $e');
    }
  }

  Future<void> deleteImage(String id) async {
    try {
      await _api.delete('/provider-images/$id');
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }
}
