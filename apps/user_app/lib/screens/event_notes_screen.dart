import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_planning_models.dart';
import '../services/event_planning_service.dart';

class EventNotesScreen extends StatefulWidget {
  final Event event;

  const EventNotesScreen({super.key, required this.event});

  @override
  State<EventNotesScreen> createState() => _EventNotesScreenState();
}

class _EventNotesScreenState extends State<EventNotesScreen> {
  late final EventPlanningService _eventService;
  List<EventNote> _notes = [];
  List<Event> _allEvents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _eventService = EventPlanningService(Supabase.instance.client);
    _loadNotes();
    _loadEventsForSwitcher();
  }

  Future<void> _loadEventsForSwitcher() async {
    try {
      final events = await _eventService.getEvents();
      if (mounted) setState(() { _allEvents = events; });
    } catch (_) {}
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notes = await _eventService.getEventNotes(widget.event.id);
      if (mounted) {
        setState(() {
          _notes = notes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Notes'),
        actions: [
          PopupMenuButton<Event>(
            tooltip: 'Switch Event',
            child: Row(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    widget.event.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down),
                const SizedBox(width: 8),
              ],
            ),
            onSelected: (ev) {
              if (ev.id == widget.event.id) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => EventNotesScreen(event: ev)),
              );
            },
            itemBuilder: (context) {
              return <PopupMenuEntry<Event>>[
                const PopupMenuItem<Event>(
                  enabled: false,
                  child: Text('Select Event'),
                ),
                const PopupMenuDivider(),
                ..._allEvents.map((e) => PopupMenuItem<Event>(
                  value: e,
                  child: Row(
                    children: [
                      Icon(e.type.icon, color: e.type.color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.name, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                )),
              ];
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddNoteDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _notes.isEmpty
                  ? const Center(child: Text('No notes yet'))
                  : ListView.builder(
                      itemCount: _notes.length,
                      itemBuilder: (context, index) {
                        final note = _notes[index];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(note.title),
                            subtitle: Text(note.content),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    _showEditNoteDialog(note);
                                    break;
                                  case 'delete':
                                    _deleteNote(note.id);
                                    break;
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  void _showAddNoteDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _addNote(titleController.text, contentController.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addNote(String title, String content) async {
    if (title.trim().isEmpty || content.trim().isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    final note = EventNote(
      id: 'note_${DateTime.now().millisecondsSinceEpoch}',
      eventId: widget.event.id,
      userId: user?.id ?? 'local_user',
      title: title.trim(),
      content: content.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _eventService.saveEventNote(note);
      Navigator.pop(context);
      _loadNotes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding note: $e')),
      );
    }
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      await _eventService.deleteEventNote(noteId);
      _loadNotes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting note: $e')),
      );
    }
  }

  void _showEditNoteDialog(EventNote note) {
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = EventNote(
                id: note.id,
                eventId: note.eventId,
                userId: note.userId,
                title: titleController.text.trim(),
                content: contentController.text.trim(),
                category: note.category,
                isPinned: note.isPinned,
                attachments: note.attachments,
                createdAt: note.createdAt,
                updatedAt: DateTime.now(),
              );
              try {
                await _eventService.saveEventNote(updated);
                Navigator.pop(context);
                _loadNotes();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating note: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
