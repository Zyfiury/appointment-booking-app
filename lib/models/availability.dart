class Availability {
  final String id;
  final String providerId;
  final String dayOfWeek; // 'monday', 'tuesday', etc.
  final String startTime; // '09:00'
  final String endTime; // '17:00'
  final List<String> breaks; // ['12:00-13:00'] - lunch breaks
  final bool isAvailable;

  Availability({
    required this.id,
    required this.providerId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.breaks = const [],
    this.isAvailable = true,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      id: json['id'] ?? '',
      providerId: json['providerId'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      breaks: json['breaks'] != null ? List<String>.from(json['breaks']) : [],
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'breaks': breaks,
      'isAvailable': isAvailable,
    };
  }
}
