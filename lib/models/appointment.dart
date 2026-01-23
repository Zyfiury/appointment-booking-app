import 'service.dart';
import 'user.dart';

class Appointment {
  final String id;
  final String date;
  final String time;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final Service service;
  final User provider;
  final User customer;
  final String? notes;

  Appointment({
    required this.id,
    required this.date,
    required this.time,
    required this.status,
    required this.service,
    required this.provider,
    required this.customer,
    this.notes,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? 'pending',
      service: Service.fromJson(json['service'] ?? {}),
      provider: User.fromJson(json['provider'] ?? {}),
      customer: User.fromJson(json['customer'] ?? {}),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'status': status,
      'service': service.toJson(),
      'provider': provider.toJson(),
      'customer': customer.toJson(),
      'notes': notes,
    };
  }

  String get formattedDate {
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date;
    }
  }
}
