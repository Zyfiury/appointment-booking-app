class AvailabilityException {
  final String id;
  final String providerId;
  final String date; // yyyy-mm-dd
  final String? startTime; // HH:MM (optional if day off)
  final String? endTime; // HH:MM
  final List<String> breaks; // ['12:00-13:00']
  final bool isAvailable; // false = day off
  final String? note;

  AvailabilityException({
    required this.id,
    required this.providerId,
    required this.date,
    this.startTime,
    this.endTime,
    this.breaks = const [],
    this.isAvailable = true,
    this.note,
  });

  factory AvailabilityException.fromJson(Map<String, dynamic> json) {
    return AvailabilityException(
      id: json['id'] ?? '',
      providerId: json['providerId'] ?? json['provider_id'] ?? '',
      date: json['date'] ?? '',
      startTime: json['startTime'] ?? json['start_time'],
      endTime: json['endTime'] ?? json['end_time'],
      breaks: json['breaks'] != null ? List<String>.from(json['breaks']) : const [],
      isAvailable: json['isAvailable'] ?? json['is_available'] ?? true,
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'breaks': breaks,
      'isAvailable': isAvailable,
      'note': note,
    };
  }
}

