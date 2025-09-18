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
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _eventService = EventPlanningService(Supabase.instance.client);
    _loadNotes();
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
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteNote(note.id),
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
}
