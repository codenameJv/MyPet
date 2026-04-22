import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_models.dart';
import '../models/pet_models.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'add_appointment_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _dbService = DatabaseService();

  void _refresh() => setState(() {});

  Future<void> _deleteAppointment(Appointment appt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (appt.notificationId != null) {
        await NotificationService().cancelNotification(appt.notificationId!);
      }
      await _dbService.deleteAppointment(appt.id!);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Appointments'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AppointmentList(
              future: _dbService.getUpcomingAppointments(),
              emptyMessage: 'No upcoming appointments',
              onDelete: _deleteAppointment,
              onEdit: (appt) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddAppointmentScreen(appointment: appt),
                  ),
                );
                _refresh();
              },
            ),
            _AppointmentList(
              future: _dbService.getPastAppointments(),
              emptyMessage: 'No past appointments',
              onDelete: _deleteAppointment,
              onEdit: (appt) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddAppointmentScreen(appointment: appt),
                  ),
                );
                _refresh();
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddAppointmentScreen()),
            );
            _refresh();
          },
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final Future<List<Appointment>> future;
  final String emptyMessage;
  final Function(Appointment) onDelete;
  final Function(Appointment) onEdit;

  const _AppointmentList({
    required this.future,
    required this.emptyMessage,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    return FutureBuilder<List<Appointment>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final appointments = snapshot.data ?? [];
        if (appointments.isEmpty) {
          return Center(
            child: Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appt = appointments[index];
            final dt = DateTime.tryParse(appt.dateTime);
            final dateStr = dt != null
                ? DateFormat('MMM d, y – h:mm a').format(dt)
                : appt.dateTime;

            return FutureBuilder<Pet?>(
              future: appt.petId != null
                  ? dbService.getPetById(appt.petId!)
                  : Future.value(null),
              builder: (context, petSnap) {
                final petName = petSnap.data?.name;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(_typeIcon(appt.type)),
                    ),
                    title: Text(appt.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateStr),
                        if (petName != null)
                          Text(
                            petName,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') onEdit(appt);
                        if (value == 'delete') onDelete(appt);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    isThreeLine: petName != null,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'vet':
        return Icons.local_hospital;
      case 'medication':
        return Icons.medication;
      case 'vaccination':
        return Icons.vaccines;
      default:
        return Icons.event;
    }
  }
}
