import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/invitation_service.dart';
import '../models/invitation_models.dart';

class InvitationsListScreen extends StatefulWidget {
  const InvitationsListScreen({super.key});

  @override
  State<InvitationsListScreen> createState() => _InvitationsListScreenState();
}

class _InvitationsListScreenState extends State<InvitationsListScreen> {
  final InvitationService _service = InvitationService(Supabase.instance.client);
  List<InvitationItem> _items = <InvitationItem>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; });
    final rows = await _service.listMyInvitations();
    setState(() { _items = rows; _loading = false; });
  }

  void _createNew() async {
    final created = await context.push('/invites/new');
    if (created == true) {
      _load();
    }
  }

  void _openPreview(InvitationItem item) {
    context.push('/invites/${item.slug}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My E-Invitations')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNew,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No invitations yet'))
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ListTile(
                      leading: (item.coverImageUrl != null)
                          ? CircleAvatar(backgroundImage: NetworkImage(item.coverImageUrl!))
                          : const CircleAvatar(child: Icon(Icons.event)),
                      title: Text(item.title),
                      subtitle: Text(item.eventDate != null
                          ? '${item.eventDate!.toLocal().toString().split(' ')[0]} ${item.eventTime ?? ''}'
                          : 'Draft'),
                      trailing: IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () async {
                          final url = 'https://saralevents.vercel.app/invite/${item.slug}';
                          await Clipboard.setData(ClipboardData(text: url));
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Link copied: $url')),
                          );
                        },
                      ),
                      onTap: () => _openPreview(item),
                    );
                  },
                ),
    );
  }
}


