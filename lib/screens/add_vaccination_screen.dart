import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/health_models.dart';
import '../services/database_service.dart';

class AddVaccinationScreen extends StatefulWidget {
  final int petId;
  final Vaccination? vaccination;

  const AddVaccinationScreen({
    super.key,
    required this.petId,
    this.vaccination,
  });

  @override
  State<AddVaccinationScreen> createState() => _AddVaccinationScreenState();
}

class _AddVaccinationScreenState extends State<AddVaccinationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  late final TextEditingController _nameController;
  late final TextEditingController _notesController;

  DateTime? _date;
  DateTime? _nextDueDate;
  bool _saving = false;

  bool get _isEditing => widget.vaccination != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vaccination;
    _nameController = TextEditingController(text: v?.name ?? '');
    _notesController = TextEditingController(text: v?.notes ?? '');
    if (v != null) {
      _date = DateTime.tryParse(v.date);
      _nextDueDate = v.nextDueDate != null ? DateTime.tryParse(v.nextDueDate!) : null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isNextDue}) async {
    final now = DateTime.now();
    final initial = isNextDue ? (_nextDueDate ?? now) : (_date ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isNextDue) {
          _nextDueDate = picked;
        } else {
          _date = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }

    setState(() => _saving = true);

    final vaccination = Vaccination(
      id: widget.vaccination?.id,
      petId: widget.petId,
      name: _nameController.text.trim(),
      date: _date!.toIso8601String(),
      nextDueDate: _nextDueDate?.toIso8601String(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (_isEditing) {
      await _dbService.updateVaccination(vaccination);
    } else {
      await _dbService.insertVaccination(vaccination);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Vaccination' : 'Add Vaccination'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Vaccine Name',
                  prefixIcon: Icon(Icons.vaccines),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _pickDate(isNextDue: false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _date != null
                        ? DateFormat.yMMMd().format(_date!)
                        : 'Select date',
                    style: TextStyle(
                      color: _date != null ? null : Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _pickDate(isNextDue: true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Next Due Date (optional)',
                    prefixIcon: const Icon(Icons.event),
                    suffixIcon: _nextDueDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _nextDueDate = null),
                          )
                        : null,
                  ),
                  child: Text(
                    _nextDueDate != null
                        ? DateFormat.yMMMd().format(_nextDueDate!)
                        : 'Select date',
                    style: TextStyle(
                      color: _nextDueDate != null ? null : Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isEditing ? 'Update' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
