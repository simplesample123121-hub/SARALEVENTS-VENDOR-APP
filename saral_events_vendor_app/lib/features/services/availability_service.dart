import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents per-day availability overrides for a service.
/// By default, every day is available. Overrides specify un/available slots.
/// Slots: Morning, Afternoon, Evening, Night. Optional custom time window.
class ServiceAvailabilityOverride {
  final DateTime date; // yyyy-mm-dd (local)
  final bool morningAvailable;
  final bool afternoonAvailable;
  final bool eveningAvailable;
  final bool nightAvailable;
  final String? customStart; // 'HH:mm'
  final String? customEnd;   // 'HH:mm'

  const ServiceAvailabilityOverride({
    required this.date,
    required this.morningAvailable,
    required this.afternoonAvailable,
    this.eveningAvailable = true,
    this.nightAvailable = true,
    this.customStart,
    this.customEnd,
  });

  Map<String, dynamic> toRow(String serviceId) {
    final day = DateTime(date.year, date.month, date.day);
    return {
      'service_id': serviceId,
      'date': day.toUtc().toIso8601String(),
      'morning_available': morningAvailable,
      'afternoon_available': afternoonAvailable,
      'evening_available': eveningAvailable,
      'night_available': nightAvailable,
      'custom_start': customStart,
      'custom_end': customEnd,
    };
  }

  static ServiceAvailabilityOverride fromRow(Map<String, dynamic> row) {
    final d = DateTime.parse(row['date']).toLocal();
    return ServiceAvailabilityOverride(
      date: DateTime(d.year, d.month, d.day),
      morningAvailable: (row['morning_available'] as bool?) ?? true,
      afternoonAvailable: (row['afternoon_available'] as bool?) ?? true,
      eveningAvailable: (row['evening_available'] as bool?) ?? true,
      nightAvailable: (row['night_available'] as bool?) ?? true,
      customStart: row['custom_start'] as String?,
      customEnd: row['custom_end'] as String?,
    );
  }
}

class AvailabilityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ServiceAvailabilityOverride>> getOverrides({
    required String serviceId,
    required DateTime month,
  }) async {
    // Query all overrides for the month window [firstDay, lastDay]
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final fromIso = DateTime.utc(firstDay.year, firstDay.month, firstDay.day).toIso8601String();
    final toIso = DateTime.utc(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59).toIso8601String();

    final rows = await _supabase
        .from('service_availability')
        .select()
        .eq('service_id', serviceId)
        .gte('date', fromIso)
        .lte('date', toIso);

    return rows.map<ServiceAvailabilityOverride>(ServiceAvailabilityOverride.fromRow).toList();
  }

  Future<void> upsertOverride(String serviceId, ServiceAvailabilityOverride override) async {
    await _supabase
        .from('service_availability')
        .upsert(override.toRow(serviceId), onConflict: 'service_id,date');
  }

  Future<void> deleteOverride(String serviceId, DateTime date) async {
    final d = DateTime(date.year, date.month, date.day);
    final iso = DateTime.utc(d.year, d.month, d.day).toIso8601String();
    await _supabase
        .from('service_availability')
        .delete()
        .eq('service_id', serviceId)
        .eq('date', iso);
  }
}


