class User {
  final String id;
  final String email;
  final String name;
  final String role; // 'customer' or 'provider'
  final String? phone;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'customer',
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
    };
  }

  bool get isProvider => role == 'provider';
  bool get isCustomer => role == 'customer';
}
