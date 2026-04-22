import 'package:flutter/material.dart';
import '../models/note_models.dart';
import '../services/database_service.dart';

class AddNoteScreen extends StatefulWidget {
  final int petId;
  final PetNote? note;

  const AddNoteScreen({super.key, required this.petId, this.note});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();
  late final TextEditingController _contentController;
  bool _saving = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final note = PetNote(
      id: widget.note?.id,
      petId: widget.petId,
      content: _contentController.text.trim(),
      createdAt: widget.note?.createdAt ?? DateTime.now().toIso8601String(),
      isPinned: widget.note?.isPinned ?? false,
    );

    if (_isEditing) {
      await _dbService.updateNote(note);
    } else {
      await _dbService.insertNote(note);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Note' : 'Add Note'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _contentController,
            decoration: const InputDecoration(
              hintText: 'Write your note...',
              border: InputBorder.none,
            ),
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Note cannot be empty' : null,
          ),
        ),
      ),
    );
  }
}
