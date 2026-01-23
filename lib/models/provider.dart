class Provider {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final double? rating;
  final int? reviewCount;
  final double? latitude;
  final double? longitude;
  final String? address;
  final double? distance; // in kilometers
  final String? profilePicture;

  Provider({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.rating,
    this.reviewCount,
    this.latitude,
    this.longitude,
    this.address,
    this.distance,
    this.profilePicture,
  });

  factory Provider.fromJson(Map<String, dynamic> json) {
    return Provider(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewCount: json['reviewCount'] ?? json['review_count'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      address: json['address'],
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      profilePicture: json['profilePicture'] ?? json['profile_picture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'rating': rating,
      'reviewCount': reviewCount,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'distance': distance,
      'profilePicture': profilePicture,
    };
  }
}
