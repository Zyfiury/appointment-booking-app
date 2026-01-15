import '../models/appointment.dart';
import 'api_service.dart';

class AppointmentService {
  final ApiService _api = ApiService();

  Future<List<Appointment>> getAppointments() async {
    try {
      final response = await _api.get('/appointments');
      final List<dynamic> data = response.data;
      return data.map((json) => Appointment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch appointments: $e');
    }
  }

  Future<Appointment> createAppointment({
    required String providerId,
    required String serviceId,
    required String date,
    required String time,
    String? notes,
  }) async {
    try {
      final response = await _api.post('/appointments', data: {
        'providerId': providerId,
        'serviceId': serviceId,
        'date': date,
        'time': time,
        'notes': notes,
      });
      return Appointment.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
    }
  }

  Future<void> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    try {
      await _api.patch('/appointments/$appointmentId', data: {
        'status': status,
      });
    } catch (e) {
      throw Exception('Failed to update appointment: $e');
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _api.delete('/appointments/$appointmentId');
    } catch (e) {
      throw Exception('Failed to delete appointment: $e');
    }
  }
}
