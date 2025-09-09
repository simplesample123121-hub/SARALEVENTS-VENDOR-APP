import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/invitation_service.dart';
import '../models/invitation_models.dart';

class InvitationPreviewScreen extends StatefulWidget {
  final String slug;
  const InvitationPreviewScreen({super.key, required this.slug});

  @override
  State<InvitationPreviewScreen> createState() => _InvitationPreviewScreenState();
}

class _InvitationPreviewScreenState extends State<InvitationPreviewScreen> {
  final InvitationService _service = InvitationService(Supabase.instance.client);
  InvitationItem? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final item = await _service.getBySlug(widget.slug);
    setState(() { _item = item; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invitation')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_item == null)
              ? const Center(child: Text('Invitation not found'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_item!.coverImageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(_item!.coverImageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
                      ),
                    const SizedBox(height: 16),
                    Text(_item!.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_item!.description != null) Text(_item!.description!),
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(Icons.event),
                      const SizedBox(width: 8),
                      Text([
                        if (_item!.eventDate != null) _item!.eventDate!.toLocal().toString().split(' ')[0],
                        if (_item!.eventTime != null) _item!.eventTime!
                      ].join(' • ')),
                    ]),
                    const SizedBox(height: 8),
                    if (_item!.venueName != null || _item!.address != null)
                      Row(children: [
                        const Icon(Icons.location_on_outlined),
                        const SizedBox(width: 8),
                        Expanded(child: Text([_item!.venueName, _item!.address].whereType<String>().join(', '))),
                      ]),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _service.createRsvp(invitationId: _item!.id, status: 'yes');
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('RSVP sent')));
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('RSVP Yes'),
                    ),
                    const SizedBox(height: 8),
                    Text('Share link: https://saral-events.com/invite/${_item!.slug}', style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
    );
  }
}


