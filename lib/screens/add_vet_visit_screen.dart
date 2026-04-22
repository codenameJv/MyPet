import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/health_models.dart';
import '../services/database_service.dart';

class AddVetVisitScreen extends StatefulWidget {
  final int petId;
  final VetVisit? vetVisit;

  const AddVetVisitScreen({
    super.key,
    required this.petId,
    this.vetVisit,
  });

  @override
  State<AddVetVisitScreen> createState() => _AddVetVisitScreenState();
}

class _AddVetVisitScreenState extends State<AddVetVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  late final TextEditingController _reasonController;
  late final TextEditingController _diagnosisController;
  late final TextEditingController _treatmentController;
  late final TextEditingController _costController;
  late final TextEditingController _vetNameController;
  late final TextEditingController _notesController;

  DateTime? _date;
  bool _saving = false;

  bool get _isEditing => widget.vetVisit != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vetVisit;
    _reasonController = TextEditingController(text: v?.reason ?? '');
    _diagnosisController = TextEditingController(text: v?.diagnosis ?? '');
    _treatmentController = TextEditingController(text: v?.treatment ?? '');
    _costController = TextEditingController(
      text: v?.cost != null ? v!.cost.toString() : '',
    );
    _vetNameController = TextEditingController(text: v?.vetName ?? '');
    _notesController = TextEditingController(text: v?.notes ?? '');
    if (v != null) {
      _date = DateTime.tryParse(v.date);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _costController.dispose();
    _vetNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
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

    final costText = _costController.text.trim();
    final vetVisit = VetVisit(
      id: widget.vetVisit?.id,
      petId: widget.petId,
      date: _date!.toIso8601String(),
      reason: _reasonController.text.trim(),
      diagnosis: _diagnosisController.text.trim().isEmpty ? null : _diagnosisController.text.trim(),
      treatment: _treatmentController.text.trim().isEmpty ? null : _treatmentController.text.trim(),
      cost: costText.isNotEmpty ? double.tryParse(costText) : null,
      vetName: _vetNameController.text.trim().isEmpty ? null : _vetNameController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (_isEditing) {
      await _dbService.updateVetVisit(vetVisit);
    } else {
      await _dbService.insertVetVisit(vetVisit);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Vet Visit' : 'Add Vet Visit'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: _pickDate,
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
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  prefixIcon: Icon(Icons.description),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Reason is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _diagnosisController,
                decoration: const InputDecoration(
                  labelText: 'Diagnosis (optional)',
                  prefixIcon: Icon(Icons.medical_information),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _treatmentController,
                decoration: const InputDecoration(
                  labelText: 'Treatment (optional)',
                  prefixIcon: Icon(Icons.healing),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Cost (optional)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vetNameController,
                decoration: const InputDecoration(
                  labelText: 'Vet Name (optional)',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
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
