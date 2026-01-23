class Service {
  final String id;
  final String name;
  final String description;
  final int duration; // in minutes
  final double price;
  final String category;
  final String? subcategory; // Subcategory (e.g., "Haircut", "Nails")
  final List<String> tags; // Searchable tags (e.g., ["fade", "beard", "taper"])
  final String providerId;
  final int capacity; // Number of concurrent appointments allowed (default: 1)
  final bool isActive; // Service availability status

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.price,
    required this.category,
    this.subcategory,
    this.tags = const [],
    required this.providerId,
    this.capacity = 1, // Default: one customer at a time
    this.isActive = true,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      subcategory: json['subcategory'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      providerId: json['providerId'] ?? '',
      capacity: json['capacity'] ?? 1,
      isActive: json['isActive'] ?? true,
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
      'subcategory': subcategory,
      'tags': tags,
      'providerId': providerId,
      'capacity': capacity,
      'isActive': isActive,
    };
  }
}
