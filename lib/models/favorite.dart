class Favorite {
  final String id;
  final String customerId;
  final String providerId;
  final String createdAt;

  Favorite({
    required this.id,
    required this.customerId,
    required this.providerId,
    required this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      providerId: json['providerId'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'providerId': providerId,
      'createdAt': createdAt,
    };
  }
}
