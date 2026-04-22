import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_models.dart';
import '../models/pet_models.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class AddAppointmentScreen extends StatefulWidget {
  final Appointment? appointment;

  const AddAppointmentScreen({super.key, this.appointment});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  late final TextEditingController _titleController;
  late final TextEditingController _notesController;

  DateTime _dateTime = DateTime.now().add(const Duration(hours: 1));
  String _type = 'vet';
  int? _selectedPetId;
  List<Pet> _pets = [];
  bool _saving = false;

  bool get _isEditing => widget.appointment != null;

  static const _types = ['vet', 'medication', 'vaccination', 'other'];
  static const _typeLabels = {
    'vet': 'Vet',
    'medication': 'Medication',
    'vaccination': 'Vaccination',
    'other': 'Other',
  };

  @override
  void initState() {
    super.initState();
    final a = widget.appointment;
    _titleController = TextEditingController(text: a?.title ?? '');
    _notesController = TextEditingController(text: a?.notes ?? '');
    if (a != null) {
      _dateTime = DateTime.tryParse(a.dateTime) ?? _dateTime;
      _type = a.type;
      _selectedPetId = a.petId;
    }
    _loadPets();
  }

  Future<void> _loadPets() async {
    final pets = await _dbService.getPets();
    setState(() => _pets = pets);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null) return;

    setState(() {
      _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    // Cancel old notification if editing
    if (_isEditing && widget.appointment!.notificationId != null) {
      await NotificationService()
          .cancelNotification(widget.appointment!.notificationId!);
    }

    // Schedule notification for future appointments
    int? notificationId;
    if (_dateTime.isAfter(DateTime.now())) {
      notificationId = Random().nextInt(1000000);
      await NotificationService().scheduleNotification(
        id: notificationId,
        title: _titleController.text.trim(),
        body: 'Appointment reminder',
        scheduledDate: _dateTime.subtract(const Duration(hours: 1)),
      );
    }

    final appointment = Appointment(
      id: widget.appointment?.id,
      petId: _selectedPetId,
      title: _titleController.text.trim(),
      dateTime: _dateTime.toIso8601String(),
      type: _type,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      notificationId: notificationId,
    );

    if (_isEditing) {
      await _dbService.updateAppointment(appointment);
    } else {
      await _dbService.insertAppointment(appointment);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Appointment' : 'Add Appointment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDateTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date & Time',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(
                    DateFormat('MMM d, y – h:mm a').format(_dateTime),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _types
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_typeLabels[t]!),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                initialValue: _selectedPetId,
                decoration: const InputDecoration(
                  labelText: 'Pet (optional)',
                  prefixIcon: Icon(Icons.pets),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ..._pets.map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name),
                      )),
                ],
                onChanged: (v) => setState(() => _selectedPetId = v),
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
