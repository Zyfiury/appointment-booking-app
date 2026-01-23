class Service {
  final String id;
  final String name;
  final String description;
  final int duration; // in minutes
  final double price;
  final String category;
  final String providerId;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.price,
    required this.category,
    required this.providerId,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      providerId: json['providerId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'duration': duration,
      'price': price,
      'category': category,
      'providerId': providerId,
    };
  }
}
