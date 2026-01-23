import '../models/availability.dart';
import '../models/availability_exception.dart';
import 'api_service.dart';

class AvailabilityService {
  final ApiService _api = ApiService();

  Future<List<Availability>> getAvailability(String providerId) async {
    try {
      final response = await _api.get('/availability/provider/$providerId');
      final List<dynamic> data = response.data;
      return data.map((json) => Availability.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch availability: $e');
    }
  }

  Future<List<Availability>> getMyAvailability() async {
    try {
      final response = await _api.get('/availability');
      final List<dynamic> data = response.data;
      return data.map((json) => Availability.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch availability: $e');
    }
  }

  Future<Availability> createOrUpdateAvailability({
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    List<String> breaks = const [],
    bool isAvailable = true,
  }) async {
    try {
      final response = await _api.post('/availability', data: {
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'breaks': breaks,
        'isAvailable': isAvailable,
      });
      return Availability.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to save availability: $e');
    }
  }

  Future<void> deleteAvailability(String id) async {
    try {
      await _api.delete('/availability/$id');
    } catch (e) {
      throw Exception('Failed to delete availability: $e');
    }
  }

  Future<List<AvailabilityException>> getMyExceptions() async {
    try {
      final response = await _api.get('/availability/exceptions');
      final List<dynamic> data = response.data;
      return data.map((json) => AvailabilityException.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch exceptions: $e');
    }
  }

  Future<List<AvailabilityException>> getProviderExceptions(String providerId) async {
    try {
      final response = await _api.get('/availability/provider/$providerId/exceptions');
      final List<dynamic> data = response.data;
      return data.map((json) => AvailabilityException.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch exceptions: $e');
    }
  }

  Future<AvailabilityException> createOrUpdateException({
    required String date, // yyyy-mm-dd
    bool isAvailable = true,
    String? startTime,
    String? endTime,
    List<String> breaks = const [],
    String? note,
  }) async {
    try {
      final response = await _api.post('/availability/exceptions', data: {
        'date': date,
        'isAvailable': isAvailable,
        'startTime': startTime,
        'endTime': endTime,
        'breaks': breaks,
        'note': note,
      });
      return AvailabilityException.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to save exception: $e');
    }
  }

  Future<void> deleteException(String id) async {
    try {
      await _api.delete('/availability/exceptions/$id');
    } catch (e) {
      throw Exception('Failed to delete exception: $e');
    }
  }

  // Helper method to get available time slots for a specific date
  Future<List<String>> getAvailableTimeSlots({
    required String providerId,
    required String serviceId,
    required DateTime date,
    int slotInterval = 30, // Default 30-minute slots
  }) async {
    try {
      // Prefer server-computed slots (includes current bookings + capacity)
      final dateStr =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final resp = await _api.get(
        '/appointments/available-slots',
        queryParameters: {
          'providerId': providerId,
          'serviceId': serviceId,
          'date': dateStr,
          'interval': slotInterval,
        },
      );
      
      // Handle different response formats (similar to appointment service)
      dynamic responseData = resp.data;
      
      // Check if response is an error object
      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('error')) {
          final errorMsg = responseData['error'] ?? 'Unknown error';
          throw Exception(errorMsg);
        }
      }
      
      // Check if response is a List
      if (responseData is List) {
        return List<String>.from(responseData);
      }
      
      // If response is not a List and not an error, log and throw
      throw Exception('Invalid response format: expected List, got ${responseData.runtimeType}');
      // Fallback to local generation if the server response isn't a list
      final availability = await getAvailability(providerId);
      final dayOfWeek = _getDayOfWeek(date);
      final dayAvailability = availability.firstWhere(
        (a) => a.dayOfWeek == dayOfWeek && a.isAvailable,
        orElse: () => Availability(
          id: '',
          providerId: providerId,
          dayOfWeek: dayOfWeek,
          startTime: '09:00',
          endTime: '17:00',
          isAvailable: false,
        ),
      );

      if (!dayAvailability.isAvailable) return [];

      // Need service duration for fallback slot generation; if server isn't available, we can't infer it safely.
      // For now, default to 30 minutes in fallback.
      final serviceDuration = 30;
      final startParts = dayAvailability.startTime.split(':');
      final endParts = dayAvailability.endTime.split(':');
      final startHour = int.tryParse(startParts[0]) ?? 9;
      final startMin = int.tryParse(startParts.length > 1 ? startParts[1] : '0') ?? 0;
      final endHour = int.tryParse(endParts[0]) ?? 17;
      final endMin = int.tryParse(endParts.length > 1 ? endParts[1] : '0') ?? 0;
      final startMinutes = startHour * 60 + startMin;
      final endMinutes = endHour * 60 + endMin;

      final slots = <String>[];
      var currentMinutes = startMinutes;
      while (currentMinutes + serviceDuration <= endMinutes) {
        bool conflictsWithBreak = false;
        for (final breakTime in dayAvailability.breaks) {
          final parts = breakTime.split('-');
          if (parts.length != 2) continue;
          final bs = parts[0].split(':');
          final be = parts[1].split(':');
          final bsh = int.tryParse(bs[0]) ?? 0;
          final bsm = int.tryParse(bs.length > 1 ? bs[1] : '0') ?? 0;
          final beh = int.tryParse(be[0]) ?? 0;
          final bem = int.tryParse(be.length > 1 ? be[1] : '0') ?? 0;
          final breakStartMinutes = bsh * 60 + bsm;
          final breakEndMinutes = beh * 60 + bem;
          final endOfSlot = currentMinutes + serviceDuration;
          if (currentMinutes < breakEndMinutes && endOfSlot > breakStartMinutes) {
            conflictsWithBreak = true;
            break;
          }
        }

        if (!conflictsWithBreak) {
          final hour = currentMinutes ~/ 60;
          final minute = currentMinutes % 60;
          slots.add('${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
        }
        currentMinutes += slotInterval;
      }
      return slots;
    } catch (e) {
      throw Exception('Failed to get available time slots: $e');
    }
  }

  String _getDayOfWeek(DateTime date) {
    const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    return days[date.weekday % 7];
  }
}
