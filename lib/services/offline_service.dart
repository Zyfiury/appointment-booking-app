import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service to handle offline data caching and sync
class OfflineService {
  static const String _pendingActionsKey = 'pending_actions';
  static const String _cachedProvidersKey = 'cached_providers';
  static const String _cachedAppointmentsKey = 'cached_appointments';

  /// Save pending action to be synced when online
  Future<void> savePendingAction(String action, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingActions = await getPendingActions();
    
    pendingActions.add({
      'action': action,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await prefs.setString(_pendingActionsKey, json.encode(pendingActions));
  }

  /// Get all pending actions
  Future<List<Map<String, dynamic>>> getPendingActions() async {
    final prefs = await SharedPreferences.getInstance();
    final actionsJson = prefs.getString(_pendingActionsKey);
    
    if (actionsJson == null) return [];
    
    try {
      final List<dynamic> decoded = json.decode(actionsJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Clear pending actions after successful sync
  Future<void> clearPendingActions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingActionsKey);
  }

  /// Cache providers data
  Future<void> cacheProviders(List<dynamic> providers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedProvidersKey, json.encode(providers));
    await prefs.setString('${_cachedProvidersKey}_timestamp', 
        DateTime.now().toIso8601String());
  }

  /// Get cached providers
  Future<List<Map<String, dynamic>>?> getCachedProviders() async {
    final prefs = await SharedPreferences.getInstance();
    final providersJson = prefs.getString(_cachedProvidersKey);
    
    if (providersJson == null) return null;
    
    try {
      final List<dynamic> decoded = json.decode(providersJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  /// Check if cached data is still valid (within 1 hour)
  Future<bool> isCacheValid(String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    final timestampStr = prefs.getString('${cacheKey}_timestamp');
    
    if (timestampStr == null) return false;
    
    try {
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();
      return now.difference(timestamp).inHours < 1;
    } catch (e) {
      return false;
    }
  }

  /// Cache appointments
  Future<void> cacheAppointments(List<dynamic> appointments) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedAppointmentsKey, json.encode(appointments));
    await prefs.setString('${_cachedAppointmentsKey}_timestamp', 
        DateTime.now().toIso8601String());
  }

  /// Get cached appointments
  Future<List<Map<String, dynamic>>?> getCachedAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final appointmentsJson = prefs.getString(_cachedAppointmentsKey);
    
    if (appointmentsJson == null) return null;
    
    try {
      final List<dynamic> decoded = json.decode(appointmentsJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedProvidersKey);
    await prefs.remove(_cachedAppointmentsKey);
    await prefs.remove('${_cachedProvidersKey}_timestamp');
    await prefs.remove('${_cachedAppointmentsKey}_timestamp');
  }
}
