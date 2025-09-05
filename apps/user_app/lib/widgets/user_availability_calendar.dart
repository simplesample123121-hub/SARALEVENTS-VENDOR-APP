import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum DayStatus {
  available,
  partiallyAvailable,
  booked,
  unavailable,
}

class DaySlot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAvailable;

  const DaySlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });
}

class UserAvailabilityCalendar extends StatefulWidget {
  final String serviceId;
  final String vendorId;
  final Function(DateTime date, TimeOfDay? time) onDateSelected;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;

  const UserAvailabilityCalendar({
    super.key,
    required this.serviceId,
    required this.vendorId,
    required this.onDateSelected,
    this.selectedDate,
    this.selectedTime,
  });

  @override
  State<UserAvailabilityCalendar> createState() => _UserAvailabilityCalendarState();
}

class _UserAvailabilityCalendarState extends State<UserAvailabilityCalendar> {
  final SupabaseClient _supabase = Supabase.instance.client;
  DateTime _currentMonth = DateTime.now();
  Map<DateTime, DayStatus> _availabilityMap = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch availability data for the current month
      print('=== AVAILABILITY CALENDAR DEBUG ===');
      print('Service ID: ${widget.serviceId}');
      print('Vendor ID: ${widget.vendorId}');
      print('Current Month: ${_currentMonth.month}/${_currentMonth.year}');
      print('Date Range: ${_getMonthStart(_currentMonth).toIso8601String()} to ${_getMonthEnd(_currentMonth).toIso8601String()}');
      
      // Also check if there's ANY availability data for this service (regardless of month)
      final anyAvailability = await _supabase
          .from('service_availability')
          .select('*')
          .eq('service_id', widget.serviceId)
          .limit(1);
      print('Any availability data for this service: ${anyAvailability.length > 0 ? "YES" : "NO"}');
      if (anyAvailability.isNotEmpty) {
        print('Sample availability record: ${anyAvailability.first}');
      }
      
      // TEMPORARY DEBUG: Show ALL availability data for September 2025
      final allSeptemberData = await _supabase
          .from('service_availability')
          .select('*')
          .gte('date', '2025-09-01')
          .lt('date', '2025-10-01');
      print('All September 2025 availability data: $allSeptemberData');
      
      final response = await _supabase
          .from('service_availability')
          .select('*')
          .eq('service_id', widget.serviceId)
          .gte('date', _getMonthStart(_currentMonth).toIso8601String())
          .lte('date', _getMonthEnd(_currentMonth).toIso8601String());
          
      print('Database Response: $response');
      print('Number of records found: ${response.length}');

      final Map<DateTime, DayStatus> availabilityMap = {};

      for (final data in response) {
        try {
          final dateString = data['date'];
          if (dateString == null) continue;
          
          final date = DateTime.parse(dateString);
          
          // Get availability for different time periods
          final morningAvailable = data['morning_available'] as bool? ?? false;
          final afternoonAvailable = data['afternoon_available'] as bool? ?? false;
          final eveningAvailable = data['evening_available'] as bool? ?? false;
          final nightAvailable = data['night_available'] as bool? ?? false;
          final customStart = data['custom_start'] as String?;
          final customEnd = data['custom_end'] as String?;

          print('Processing date: ${date.day}/${date.month}/${date.year}');
          print('  Morning: $morningAvailable, Afternoon: $afternoonAvailable, Evening: $eveningAvailable, Night: $nightAvailable');

          DayStatus dayStatus;

          // Determine overall day status based on availability
          final totalAvailable = (morningAvailable ? 1 : 0) + 
                                (afternoonAvailable ? 1 : 0) + 
                                (eveningAvailable ? 1 : 0) + 
                                (nightAvailable ? 1 : 0);

          if (totalAvailable == 0) {
            // No time periods available
            dayStatus = DayStatus.booked;
            print('  → Status: BOOKED (no availability)');
          } else if (totalAvailable == 4) {
            // All time periods available
            dayStatus = DayStatus.available;
            print('  → Status: AVAILABLE (all periods)');
          } else if (customStart != null && customEnd != null) {
            // Custom time slots
            dayStatus = DayStatus.partiallyAvailable;
            print('  → Status: PARTIALLY AVAILABLE (custom slots)');
          } else {
            // Some time periods available
            dayStatus = DayStatus.partiallyAvailable;
            print('  → Status: PARTIALLY AVAILABLE (some periods)');
          }

          availabilityMap[date] = dayStatus;
        } catch (e) {
          print('Error processing availability data: $e');
          continue;
        }
      }

      // If no availability data found, show all dates as unavailable
      if (availabilityMap.isEmpty) {
        print('❌ No availability data found for service: ${widget.serviceId}');
        print('   This means the vendor has not set availability for this service yet.');
        print('   Please ask the vendor to set availability in the vendor app.');
        
      } else {
        print('✅ Final availability map:');
        availabilityMap.forEach((date, status) {
          print('  ${date.day}/${date.month}/${date.year}: $status');
        });
      }
      
      print('============================');

      setState(() {
        _availabilityMap = availabilityMap;
        _isLoading = false;
      });
      
      print('🔄 Calendar state updated with ${_availabilityMap.length} availability records');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  DateTime _getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  DateTime _getMonthEnd(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }


  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _loadAvailability();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _loadAvailability();
  }

  DayStatus _getDayStatus(DateTime date) {
    final status = _availabilityMap[date] ?? DayStatus.unavailable;
    if (status != DayStatus.unavailable) {
      print('  Found status for ${date.day}/${date.month}/${date.year}: $status');
    }
    return status;
  }

  Color _getDayColor(DayStatus status) {
    Color color;
    switch (status) {
      case DayStatus.available:
        color = Colors.green;
        break;
      case DayStatus.partiallyAvailable:
        color = Colors.orange;
        break;
      case DayStatus.booked:
        color = Colors.red;
        break;
      case DayStatus.unavailable:
        color = Colors.grey;
        break;
    }
    print('Getting color for $status: $color');
    return color;
  }

  void _onDayTap(DateTime date) {
    final status = _getDayStatus(date);
    if (status == DayStatus.available || status == DayStatus.partiallyAvailable) {
      widget.onDateSelected(date, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 Building calendar with ${_availabilityMap.length} availability records');
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Unable to load availability',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAvailability,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDBB42),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show message if no availability data is found
    if (_availabilityMap.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Availability Set',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The vendor has not set availability for this service yet.\nPlease contact the vendor to set their availability.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAvailability,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDBB42),
                foregroundColor: Colors.white,
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    print('🎨 Building calendar UI with ${_availabilityMap.length} records');
    return Column(
      children: [
        // Month navigation
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),

        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),

        const SizedBox(height: 8),

        // Calendar grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildCalendarGrid(),
        ),

        const SizedBox(height: 16),

        // Legend
        _buildLegend(),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    print('🔧 Building calendar grid with ${_availabilityMap.length} availability records');
    final firstDayOfMonth = _getMonthStart(_currentMonth);
    final lastDayOfMonth = _getMonthEnd(_currentMonth);
    final firstWeekday = firstDayOfMonth.weekday % 7; // Convert to 0-based Sunday start
    final daysInMonth = lastDayOfMonth.day;

    final List<Widget> dayWidgets = [];

    // Add empty cells for days before the first day of the month
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox(height: 40));
    }

    // Add day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final status = _getDayStatus(date);
      final isSelected = widget.selectedDate != null &&
          widget.selectedDate!.year == date.year &&
          widget.selectedDate!.month == date.month &&
          widget.selectedDate!.day == date.day;
          
      // Debug: Print status for each day
      print('Calendar Grid - Day $day (${date.day}/${date.month}/${date.year}): $status');
      if (status != DayStatus.unavailable) {
        print('  → This day has availability data!');
      }

      dayWidgets.add(
        GestureDetector(
          onTap: () => _onDayTap(date),
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? const Color(0xFFFDBB42)
                  : (status == DayStatus.unavailable ? Colors.transparent : _getDayColor(status)),
              border: isSelected
                  ? null
                  : Border.all(
                      color: status == DayStatus.unavailable ? Colors.grey[300]! : Colors.transparent,
                      width: 1,
                    ),
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (status == DayStatus.unavailable ? Colors.grey[400] : Colors.white),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Create rows of 7 days each
    final List<Widget> rows = [];
    for (int i = 0; i < dayWidgets.length; i += 7) {
      final rowDays = dayWidgets.sublist(i, (i + 7).clamp(0, dayWidgets.length));
      rows.add(
        Row(
          children: rowDays.map((day) => Expanded(child: day)).toList(),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildLegendItem(Colors.green, 'Available', '8:00 AM - 11:00 PM'),
          const SizedBox(height: 8),
          _buildLegendItem(Colors.orange, 'Partially Available', 'Custom time slots'),
          const SizedBox(height: 8),
          _buildLegendItem(Colors.red, 'Booked', 'Not available'),
          const SizedBox(height: 8),
          _buildLegendItem(Colors.grey, 'Unavailable', 'Not available'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String timeRange) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                timeRange,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
