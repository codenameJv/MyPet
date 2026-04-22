import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/health_models.dart';
import '../services/database_service.dart';

class AddMedicationScreen extends StatefulWidget {
  final int petId;
  final Medication? medication;

  const AddMedicationScreen({
    super.key,
    required this.petId,
    this.medication,
  });

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _notesController;

  String _frequency = 'Daily';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;

  bool get _isEditing => widget.medication != null;

  static const _frequencies = ['Daily', 'Weekly', 'Monthly', 'As Needed'];

  @override
  void initState() {
    super.initState();
    final m = widget.medication;
    _nameController = TextEditingController(text: m?.name ?? '');
    _dosageController = TextEditingController(text: m?.dosage ?? '');
    _notesController = TextEditingController(text: m?.notes ?? '');
    if (m != null) {
      _frequency = m.frequency;
      _startDate = DateTime.tryParse(m.startDate);
      _endDate = m.endDate != null ? DateTime.tryParse(m.endDate!) : null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isEnd}) async {
    final now = DateTime.now();
    final initial = isEnd ? (_endDate ?? now) : (_startDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isEnd) {
          _endDate = picked;
        } else {
          _startDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date')),
      );
      return;
    }

    setState(() => _saving = true);

    final medication = Medication(
      id: widget.medication?.id,
      petId: widget.petId,
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      frequency: _frequency,
      startDate: _startDate!.toIso8601String(),
      endDate: _endDate?.toIso8601String(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (_isEditing) {
      await _dbService.updateMedication(medication);
    } else {
      await _dbService.insertMedication(medication);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Medication' : 'Add Medication'),
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
                  labelText: 'Medication Name',
                  prefixIcon: Icon(Icons.medication),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  prefixIcon: Icon(Icons.science),
                  hintText: 'e.g. 50mg',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Dosage is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  prefixIcon: Icon(Icons.repeat),
                ),
                items: _frequencies
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _frequency = v);
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _pickDate(isEnd: false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _startDate != null
                        ? DateFormat.yMMMd().format(_startDate!)
                        : 'Select date',
                    style: TextStyle(
                      color: _startDate != null ? null : Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _pickDate(isEnd: true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'End Date (optional)',
                    prefixIcon: const Icon(Icons.event),
                    suffixIcon: _endDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _endDate = null),
                          )
                        : null,
                  ),
                  child: Text(
                    _endDate != null
                        ? DateFormat.yMMMd().format(_endDate!)
                        : 'Select date',
                    style: TextStyle(
                      color: _endDate != null ? null : Theme.of(context).hintColor,
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
