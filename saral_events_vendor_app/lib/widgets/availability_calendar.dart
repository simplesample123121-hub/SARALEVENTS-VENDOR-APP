import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../features/services/availability_service.dart';

enum DaySlot { morning, afternoon, evening, night }
enum DayStatus { booked, available, partial }

class AvailabilityCalendarController {
  final Map<DateTime, ServiceAvailabilityOverride> _overrides = <DateTime, ServiceAvailabilityOverride>{};

  List<ServiceAvailabilityOverride> getOverrides() => _overrides.values.toList();

  void setOverride(ServiceAvailabilityOverride override) {
    final key = DateTime(override.date.year, override.date.month, override.date.day);
    _overrides[key] = override;
  }

  ServiceAvailabilityOverride? getFor(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _overrides[key];
  }
}

class AvailabilityCalendar extends StatefulWidget {
  final String? serviceId; // optional during create flow
  final AvailabilityService availabilityService;
  final AvailabilityCalendarController? controller; // captures in-memory overrides

  const AvailabilityCalendar({
    super.key,
    required this.availabilityService,
    this.serviceId,
    this.controller,
  });

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _loading = false;
  final Map<DateTime, ServiceAvailabilityOverride> _overrides = <DateTime, ServiceAvailabilityOverride>{};

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    if (widget.serviceId == null) {
      // Create flow: use controller state only
      setState(() {
        _loading = false;
        _overrides
          ..clear()
          ..addEntries(widget.controller?._overrides.entries ?? const <MapEntry<DateTime, ServiceAvailabilityOverride>>[]);
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final rows = await widget.availabilityService.getOverrides(
        serviceId: widget.serviceId!,
        month: _visibleMonth,
      );
      _overrides
        ..clear()
        ..addEntries(rows.map((o) => MapEntry(DateTime(o.date.year, o.date.month, o.date.day), o)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    });
    _loadMonth();
  }

  ServiceAvailabilityOverride _currentFor(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _overrides[key] ?? ServiceAvailabilityOverride(date: key, morningAvailable: true, afternoonAvailable: true);
  }

  DayStatus _statusFor(DateTime day) {
    final o = _currentFor(day);
    if (!o.morningAvailable && !o.afternoonAvailable && !o.eveningAvailable && !o.nightAvailable) return DayStatus.booked;
    if (o.morningAvailable && o.afternoonAvailable && o.eveningAvailable && o.nightAvailable) return DayStatus.available;
    return DayStatus.partial;
  }

  Future<void> _toggle(DateTime day, DaySlot slot, bool value) async {
    final cur = _currentFor(day);
    final updated = ServiceAvailabilityOverride(
      date: cur.date,
      morningAvailable: slot == DaySlot.morning ? value : cur.morningAvailable,
      afternoonAvailable: slot == DaySlot.afternoon ? value : cur.afternoonAvailable,
      eveningAvailable: slot == DaySlot.evening ? value : cur.eveningAvailable,
      nightAvailable: slot == DaySlot.night ? value : cur.nightAvailable,
      customStart: cur.customStart,
      customEnd: cur.customEnd,
    );
    setState(() {
      _overrides[DateTime(day.year, day.month, day.day)] = updated;
    });
    // Capture in controller for create flow
    widget.controller?.setOverride(updated);
    // Persist immediately if editing an existing service
    if (widget.serviceId != null) {
      await widget.availabilityService.upsertOverride(widget.serviceId!, updated);
    }
  }

  Future<void> _toggleFullDayBooked(DateTime day, bool booked) async {
    final newVal = ServiceAvailabilityOverride(
      date: DateTime(day.year, day.month, day.day),
      morningAvailable: !booked,
      afternoonAvailable: !booked,
      eveningAvailable: !booked,
      nightAvailable: !booked,
    );
    setState(() {
      _overrides[DateTime(day.year, day.month, day.day)] = newVal;
    });
    widget.controller?.setOverride(newVal);
    if (widget.serviceId != null) {
      await widget.availabilityService.upsertOverride(widget.serviceId!, newVal);
    }
  }

  void _openDayEditor(BuildContext context, DateTime day) {
    final cur = _currentFor(day);
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        bool fullBooked = !cur.morningAvailable && !cur.afternoonAvailable;
        bool morning = cur.morningAvailable;
        bool afternoon = cur.afternoonAvailable;
        bool evening = cur.eveningAvailable;
        bool night = cur.nightAvailable;
        final TextEditingController startCtrl = TextEditingController(text: cur.customStart ?? '');
        final TextEditingController endCtrl = TextEditingController(text: cur.customEnd ?? '');
        return StatefulBuilder(
          builder: (ctx, setS) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit ${DateFormat('EEE, MMM d').format(day)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Full day booked'),
                    Switch(
                      value: fullBooked,
                      onChanged: (v) async {
                        setS(() {
                          fullBooked = v;
                          morning = !v;
                          afternoon = !v;
                          evening = !v;
                          night = !v;
                        });
                        await _toggleFullDayBooked(day, v);
                      },
                    )
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Morning available'),
                    Switch(
                      value: morning,
                      onChanged: fullBooked
                          ? null
                          : (v) async {
                              setS(() => morning = v);
                              await _toggle(day, DaySlot.morning, v);
                            },
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Afternoon available'),
                    Switch(
                      value: afternoon,
                      onChanged: fullBooked
                          ? null
                          : (v) async {
                              setS(() => afternoon = v);
                              await _toggle(day, DaySlot.afternoon, v);
                            },
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Evening available'),
                    Switch(
                      value: evening,
                      onChanged: fullBooked
                          ? null
                          : (v) async {
                              setS(() => evening = v);
                              await _toggle(day, DaySlot.evening, v);
                            },
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Night available'),
                    Switch(
                      value: night,
                      onChanged: fullBooked
                          ? null
                          : (v) async {
                              setS(() => night = v);
                              await _toggle(day, DaySlot.night, v);
                            },
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text('Custom time window (optional)', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startCtrl,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.schedule), labelText: 'Start (HH:mm)'),
                        keyboardType: TextInputType.datetime,
                        onSubmitted: (_) async {
                          final cur2 = _currentFor(day);
                          final up = ServiceAvailabilityOverride(
                            date: cur2.date,
                            morningAvailable: cur2.morningAvailable,
                            afternoonAvailable: cur2.afternoonAvailable,
                            eveningAvailable: cur2.eveningAvailable,
                            nightAvailable: cur2.nightAvailable,
                            customStart: startCtrl.text.trim().isEmpty ? null : startCtrl.text.trim(),
                            customEnd: endCtrl.text.trim().isEmpty ? null : endCtrl.text.trim(),
                          );
                          setS(() {});
                          widget.controller?.setOverride(up);
                          if (widget.serviceId != null) {
                            await widget.availabilityService.upsertOverride(widget.serviceId!, up);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endCtrl,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.schedule), labelText: 'End (HH:mm)'),
                        keyboardType: TextInputType.datetime,
                        onSubmitted: (_) async {
                          final cur2 = _currentFor(day);
                          final up = ServiceAvailabilityOverride(
                            date: cur2.date,
                            morningAvailable: cur2.morningAvailable,
                            afternoonAvailable: cur2.afternoonAvailable,
                            eveningAvailable: cur2.eveningAvailable,
                            nightAvailable: cur2.nightAvailable,
                            customStart: startCtrl.text.trim().isEmpty ? null : startCtrl.text.trim(),
                            customEnd: endCtrl.text.trim().isEmpty ? null : endCtrl.text.trim(),
                          );
                          setS(() {});
                          widget.controller?.setOverride(up);
                          if (widget.serviceId != null) {
                            await widget.availabilityService.upsertOverride(widget.serviceId!, up);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(_visibleMonth);
    final firstWeekday = DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday; // 1=Mon..7=Sun
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingEmpty = (firstWeekday % 7); // convert Monday=1..Sunday=7 to 0..6 starting on Sunday visually

    final items = <Widget>[];
    for (int i = 0; i < leadingEmpty; i++) {
      items.add(const SizedBox());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final day = DateTime(_visibleMonth.year, _visibleMonth.month, d);
      final status = _statusFor(day);
      items.add(_StatusDayTile(
        day: day,
        status: status,
        onTap: () => _openDayEditor(context, day),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(monthLabel, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: _loading ? null : () => _changeMonth(-1)),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: _loading ? null : () => _changeMonth(1)),
                ],
              )
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: items,
        ),
        const SizedBox(height: 16),
        _Legend(),
      ],
    );
  }
}

class _StatusDayTile extends StatelessWidget {
  final DateTime day;
  final DayStatus status;
  final VoidCallback onTap;

  const _StatusDayTile({required this.day, required this.status, required this.onTap});

  Color _statusColor(BuildContext context) {
    switch (status) {
      case DayStatus.booked:
        return Colors.redAccent;
      case DayStatus.available:
        return Colors.green;
      case DayStatus.partial:
        return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        alignment: Alignment.center,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: color.withOpacity(0.18), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text('${day.day}', style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        ),
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SlotRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String label) => Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label),
          ],
        );
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            item(Colors.redAccent, 'Booked'),
            item(Colors.green, 'Available'),
            item(Colors.orangeAccent, 'Partially Available'),
          ],
        ),
      ],
    );
  }
}


