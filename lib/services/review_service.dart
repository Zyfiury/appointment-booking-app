import '../models/review.dart';
import 'api_service.dart';

class ReviewService {
  final ApiService _api = ApiService();

  Future<List<Review>> getReviews({String? providerId}) async {
    try {
      final response = await _api.get(
        '/reviews',
        queryParameters: providerId != null ? {'providerId': providerId} : null,
      );
      final List<dynamic> data = response.data;
      return data.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  Future<Review> createReview({
    required String appointmentId,
    required String providerId,
    required int rating,
    required String comment,
    List<String>? photos,
  }) async {
    try {
      final response = await _api.post('/reviews', data: {
        'appointmentId': appointmentId,
        'providerId': providerId,
        'rating': rating,
        'comment': comment,
        'photos': photos,
      });
      return Review.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  Future<Review> updateReview(
    String reviewId, {
    int? rating,
    String? comment,
    List<String>? photos,
  }) async {
    try {
      final response = await _api.patch('/reviews/$reviewId', data: {
        if (rating != null) 'rating': rating,
        if (comment != null) 'comment': comment,
        if (photos != null) 'photos': photos,
      });
      return Review.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      await _api.delete('/reviews/$reviewId');
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  Future<Map<String, dynamic>> getProviderStats(String providerId) async {
    try {
      final response = await _api.get('/reviews/stats/$providerId');
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch provider stats: $e');
    }
  }
}
