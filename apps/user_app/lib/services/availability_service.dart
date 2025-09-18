import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/cache/simple_cache.dart';

class AvailabilityService {
  final SupabaseClient _supabase;

  AvailabilityService(this._supabase);

  Future<Map<String, dynamic>> getServiceAvailability(String serviceId, DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final startNextMonth = DateTime(month.year, month.month + 1, 1);
      // Convert LOCAL month boundaries to UTC, so comparisons align with vendor writes
      final startUtc = startOfMonth.toUtc();
      final nextUtc = startNextMonth.toUtc();
      final cacheKey = 'availability:$serviceId:${startOfMonth.year}-${startOfMonth.month.toString().padLeft(2, '0')}';

      final data = await CacheManager.instance.getOrFetch<List<dynamic>>(
        cacheKey,
        const Duration(minutes: 2),
        () async {
          final response = await _supabase
              .from('service_availability')
              .select('*')
              .eq('service_id', serviceId)
              .gte('date', startUtc.toIso8601String())
              .lt('date', nextUtc.toIso8601String());
          return response;
        },
      );

      return {
        'success': true,
        'data': data,
      };
    } catch (e) {
      print('Error fetching availability: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableTimeSlots(String serviceId, DateTime date) async {
    try {
      // Use LOCAL midnight converted to UTC for the window [dayStart, nextDayStart)
      final localStart = DateTime(date.year, date.month, date.day);
      final dateUtc = localStart.toUtc();
      final key = 'timeslots:$serviceId:${_dateOnly(date)}';
      final response = await CacheManager.instance.getOrFetch<List<dynamic>>(
        key,
        const Duration(minutes: 1),
        () async {
          final res = await _supabase
              .from('service_availability')
              .select('*')
              .eq('service_id', serviceId)
              .gte('date', dateUtc.toIso8601String())
              .lt('date', dateUtc.add(const Duration(days: 1)).toIso8601String());
          return res;
        },
      );

      if (response.isEmpty) {
        return [];
      }

      final availability = response.first;
      
      // Get availability for different time periods
      final morningAvailable = availability['morning_available'] as bool? ?? false;
      final afternoonAvailable = availability['afternoon_available'] as bool? ?? false;
      final eveningAvailable = availability['evening_available'] as bool? ?? false;
      final nightAvailable = availability['night_available'] as bool? ?? false;
      final customStart = availability['custom_start'] as String?;
      final customEnd = availability['custom_end'] as String?;

      List<Map<String, dynamic>> timeSlots = [];

      // Add time slots based on availability
      if (morningAvailable) {
        timeSlots.add({
          'start_time': '09:00',
          'end_time': '12:00',
          'is_available': true,
        });
      }
      
      if (afternoonAvailable) {
        timeSlots.add({
          'start_time': '12:00',
          'end_time': '17:00',
          'is_available': true,
        });
      }
      
      if (eveningAvailable) {
        timeSlots.add({
          'start_time': '17:00',
          'end_time': '21:00',
          'is_available': true,
        });
      }
      
      if (nightAvailable) {
        timeSlots.add({
          'start_time': '21:00',
          'end_time': '23:00',
          'is_available': true,
        });
      }
      
      // Add custom time slots if available
      if (customStart != null && customEnd != null) {
        timeSlots.add({
          'start_time': customStart,
          'end_time': customEnd,
          'is_available': true,
        });
      }
      
      return timeSlots;
    } catch (e) {
      print('Error fetching time slots: $e');
      return [];
    }
  }

  String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
