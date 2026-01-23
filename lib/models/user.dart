class User {
  final String id;
  final String email;
  final String name;
  final String role; // 'customer' or 'provider'
  final String? phone;
  final String? profilePicture;
  final double? latitude;
  final double? longitude;
  final String? address;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.profilePicture,
    this.latitude,
    this.longitude,
    this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'customer',
      phone: json['phone'],
      profilePicture: json['profilePicture'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'profilePicture': profilePicture,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? phone,
    String? profilePicture,
    double? latitude,
    double? longitude,
    String? address,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      profilePicture: profilePicture ?? this.profilePicture,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
    );
  }

  bool get isProvider => role == 'provider';
  bool get isCustomer => role == 'customer';
}
