import 'user.dart';

class Review {
  final String id;
  final String appointmentId;
  final String providerId;
  final String customerId;
  final String customerName;
  final int rating; // 1-5
  final String comment;
  final DateTime createdAt;
  final List<String>? photos;

  Review({
    required this.id,
    required this.appointmentId,
    required this.providerId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.photos,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      appointmentId: json['appointmentId'] ?? '',
      providerId: json['providerId'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? json['customer']?['name'] ?? 'Anonymous',
      rating: json['rating'] ?? 5,
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      photos: json['photos'] != null
          ? List<String>.from(json['photos'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'providerId': providerId,
      'customerId': customerId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'photos': photos,
    };
  }
}
