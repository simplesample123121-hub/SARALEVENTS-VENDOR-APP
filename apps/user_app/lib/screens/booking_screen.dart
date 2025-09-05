import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_models.dart';
import '../services/booking_service.dart';
import '../widgets/user_availability_calendar.dart';
import '../widgets/time_slot_picker.dart';
import '../services/availability_service.dart';

class BookingScreen extends StatefulWidget {
  final ServiceItem service;

  const BookingScreen({super.key, required this.service});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late final BookingService _bookingService;
  late final AvailabilityService _availabilityService;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  List<TimeSlot> _availableTimeSlots = [];
  TimeSlot? _selectedTimeSlot;

  @override
  void initState() {
    super.initState();
    _bookingService = BookingService(Supabase.instance.client);
    _availabilityService = AvailabilityService(Supabase.instance.client);
    
    // Debug: Print service information
    print('=== BOOKING SCREEN DEBUG ===');
    print('Service Name: ${widget.service.name}');
    print('Service ID: ${widget.service.id}');
    print('Vendor ID: ${widget.service.vendorId}');
    print('Service Price: ${widget.service.price}');
    print('============================');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _onDateSelected(DateTime date, TimeOfDay? time) {
    setState(() {
      _selectedDate = date;
      _selectedTime = time;
      _selectedTimeSlot = null;
      _availableTimeSlots = [];
    });
    
    // Load available time slots for the selected date
    _loadTimeSlotsForDate(date);
  }

  void _onTimeSlotSelected(TimeSlot slot) {
    setState(() {
      _selectedTimeSlot = slot;
      _selectedTime = slot.startTime;
    });
  }

  Future<void> _loadTimeSlotsForDate(DateTime date) async {
    try {
      final timeSlotsData = await _availabilityService.getAvailableTimeSlots(widget.service.id, date);
      
      final slots = timeSlotsData.map((slotData) {
        final startTimeParts = slotData['start_time'].split(':');
        final endTimeParts = slotData['end_time'].split(':');
        
        return TimeSlot(
          startTime: TimeOfDay(
            hour: int.parse(startTimeParts[0]),
            minute: int.parse(startTimeParts[1]),
          ),
          endTime: TimeOfDay(
            hour: int.parse(endTimeParts[0]),
            minute: int.parse(endTimeParts[1]),
          ),
          isAvailable: slotData['is_available'] as bool,
        );
      }).toList();
      
      setState(() {
        _availableTimeSlots = slots;
      });
    } catch (e) {
      print('Error loading time slots: $e');
      setState(() {
        _availableTimeSlots = [];
      });
    }
  }



  Future<void> _createBooking() async {
    print('Creating booking for service: ${widget.service.name}');
    print('Service ID: ${widget.service.id}');
    print('Vendor ID: ${widget.service.vendorId}');
    print('Vendor Name: ${widget.service.vendorName}');
    
    if (widget.service.vendorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid vendor information - vendor ID is empty')),
      );
      return;
    }

    if (widget.service.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid service information - service ID is empty')),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date for your booking')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _bookingService.createBooking(
        serviceId: widget.service.id,
        vendorId: widget.service.vendorId,
        bookingDate: _selectedDate!,
        bookingTime: _selectedTime,
        amount: widget.service.price,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (success) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDBB42),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Booking Successful!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Your booking has been created successfully. The vendor will review and confirm your booking.',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to catalog
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFDBB42),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create booking. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Book Service',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Details Card
            _buildServiceCard(),
            const SizedBox(height: 24),

            // Availability Calendar
            _buildSectionTitle('Select Date & Time', Icons.calendar_today),
            const SizedBox(height: 12),
            _buildAvailabilityCalendar(),
            const SizedBox(height: 24),

            // Time Slots (if date is selected)
            if (_selectedDate != null && _availableTimeSlots.isNotEmpty) ...[
              _buildSectionTitle('Available Time Slots', Icons.access_time),
              const SizedBox(height: 12),
              _buildTimeSlotPicker(),
              const SizedBox(height: 24),
            ],

            // Notes
            _buildSectionTitle('Additional Notes', Icons.note),
            const SizedBox(height: 12),
            _buildNotesField(),
            const SizedBox(height: 32),

            // Booking Summary
            _buildBookingSummary(),
            const SizedBox(height: 24),

            // Book Now Button
            _buildBookButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFDBB42).withOpacity(0.1),
                const Color(0xFFFDBB42).withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Service Icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDBB42),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFDBB42).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getServiceIcon(widget.service.name),
                    size: 35,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                // Service Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.service.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.store,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.service.vendorName.isNotEmpty ? widget.service.vendorName : 'Vendor',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '₹',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFDBB42),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            widget.service.price.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFDBB42).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFFFDBB42),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: UserAvailabilityCalendar(
          serviceId: widget.service.id,
          vendorId: widget.service.vendorId,
          onDateSelected: _onDateSelected,
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
        ),
      ),
    );
  }

  Widget _buildTimeSlotPicker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TimeSlotPicker(
          availableSlots: _availableTimeSlots,
          selectedSlot: _selectedTimeSlot,
          onSlotSelected: _onTimeSlotSelected,
        ),
      ),
    );
  }


  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'Add any special requirements or notes...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFFFDBB42).withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDBB42),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Booking Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSummaryRow('Service', widget.service.name),
                _buildSummaryRow('Vendor', widget.service.vendorName),
                _buildSummaryRow('Date', _selectedDate != null ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}' : 'Not selected'),
                if (_selectedTime != null)
                  _buildSummaryRow('Time', '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '₹',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFDBB42),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          widget.service.price.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFDBB42).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFDBB42),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Confirm Booking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  IconData _getServiceIcon(String serviceName) {
    final name = serviceName.toLowerCase();
    if (name.contains('photography') || name.contains('photo') || name.contains('camera')) {
      return Icons.camera_alt;
    } else if (name.contains('catering') || name.contains('food') || name.contains('meal')) {
      return Icons.restaurant;
    } else if (name.contains('decoration') || name.contains('decor') || name.contains('flower')) {
      return Icons.local_florist;
    } else if (name.contains('music') || name.contains('dj') || name.contains('sound')) {
      return Icons.music_note;
    } else if (name.contains('venue') || name.contains('hall') || name.contains('place')) {
      return Icons.location_on;
    } else if (name.contains('transport') || name.contains('car') || name.contains('vehicle')) {
      return Icons.directions_car;
    } else if (name.contains('makeup') || name.contains('beauty') || name.contains('salon')) {
      return Icons.face;
    } else if (name.contains('dress') || name.contains('clothing') || name.contains('suit')) {
      return Icons.checkroom;
    } else {
      return Icons.miscellaneous_services;
    }
  }

}
